#!/bin/bash
#SBATCH --time=12:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=16
#SBATCH --account=PAS2598
#SBATCH --job-name=cellranger_count
#SBATCH --output=/fs/scratch/PAS2598/senes_raw/logs/cellranger_%A_%a.log

echo "=========================================="
echo "Cell Ranger Count Processing - Simple Version"
echo "Job ID: $SLURM_JOB_ID"
echo "Date: $(date)"
echo "Node: $HOSTNAME"
echo "=========================================="

# Set up environment
source ~/.bashrc
module load cellranger/7.2.0

# Define paths
BASE_DIR="/fs/scratch/PAS2598/senes_raw"
TRIMMED_READS_DIR="${BASE_DIR}/trimmed_reads"
CELLRANGER_OUTPUT_DIR="${BASE_DIR}/cellranger_results"
SYMLINK_DIR="${BASE_DIR}/cellranger_fastqs"
TRANSCRIPTOME="/fs/ess/PAS2598/ggaitos/2025/data/references/refdata-gex-GRCh38-2020-A"

# Create organized directories
mkdir -p ${CELLRANGER_OUTPUT_DIR}/{cDNA,HTO}
mkdir -p ${SYMLINK_DIR}/{cDNA,HTO}

echo "Processing files directly from trimmed_reads directories..."

# Get sample name from command line argument or use first available
if [[ -n "$1" ]]; then
    SAMPLE_PREFIX="$1"
else
    echo "Usage: sbatch cellranger_count.sh SAMPLE_PREFIX"
    echo "Available samples:"
    ls ${TRIMMED_READS_DIR}/cDNA/ | cut -d'_' -f1 | sort -u | head -10
    exit 1
fi

echo "Processing sample: $SAMPLE_PREFIX"

# Function to process a library type
process_library() {
    local library_type="$1"
    local sample_prefix="$2"
    
    echo ""
    echo "Processing ${library_type} for ${sample_prefix}..."
    
    # Find R1 and R2 files
    local r1_file=$(ls ${TRIMMED_READS_DIR}/${library_type}/${sample_prefix}_*R1_trimmed.fastq.gz 2>/dev/null | head -1)
    local r2_file=$(ls ${TRIMMED_READS_DIR}/${library_type}/${sample_prefix}_*R2_trimmed.fastq.gz 2>/dev/null | head -1)
    
    if [[ ! -f "$r1_file" || ! -f "$r2_file" ]]; then
        echo "Skipping ${library_type}: Files not found for ${sample_prefix}"
        return 1
    fi
    
    echo "Found files:"
    echo "  R1: $(basename $r1_file)"  
    echo "  R2: $(basename $r2_file)"
    
    # Create Cell Ranger compatible symlinks
    local symlink_r1="${SYMLINK_DIR}/${library_type}/${sample_prefix}_S1_L001_R1_001.fastq.gz"
    local symlink_r2="${SYMLINK_DIR}/${library_type}/${sample_prefix}_S1_L001_R2_001.fastq.gz"
    
    ln -sf "$r1_file" "$symlink_r1"
    ln -sf "$r2_file" "$symlink_r2"
    
    # Check if already processed
    local output_dir="${CELLRANGER_OUTPUT_DIR}/${library_type}/${sample_prefix}"
    if [[ -f "${output_dir}/outs/filtered_feature_bc_matrix/barcodes.tsv.gz" ]]; then
        echo "Already processed: ${sample_prefix} ${library_type}"
        return 0
    fi
    
    # Remove incomplete runs
    [[ -d "${output_dir}" ]] && rm -rf "${output_dir}"
    
    # Run Cell Ranger
    cd ${CELLRANGER_OUTPUT_DIR}/${library_type}
    
    echo "Running Cell Ranger for ${sample_prefix} ${library_type}..."
    cellranger count \
        --id="${sample_prefix}" \
        --transcriptome="${TRANSCRIPTOME}" \
        --fastqs="${SYMLINK_DIR}/${library_type}" \
        --sample="${sample_prefix}" \
        --expect-cells=5000 \
        --localcores=${SLURM_CPUS_PER_TASK} \
        --localmem=56 \
        --disable-ui \
        --nosecondary
    
    # Check success
    if [[ -f "${output_dir}/outs/filtered_feature_bc_matrix/barcodes.tsv.gz" ]]; then
        local cell_count=$(zcat "${output_dir}/outs/filtered_feature_bc_matrix/barcodes.tsv.gz" | wc -l)
        echo "SUCCESS: ${sample_prefix} ${library_type} - ${cell_count} cells"
        return 0
    else
        echo "FAILED: ${sample_prefix} ${library_type}"
        return 1
    fi
}

# Process both library types
start_time=$(date +%s)

process_library "cDNA" "$SAMPLE_PREFIX"
cdna_result=$?

process_library "HTO" "$SAMPLE_PREFIX"  
hto_result=$?

# Summary
end_time=$(date +%s)
duration=$(( (end_time - start_time) / 60 ))

echo ""
echo "=========================================="
echo "Processing Complete for ${SAMPLE_PREFIX}"
echo "Duration: ${duration} minutes"
echo "cDNA: $([ $cdna_result -eq 0 ] && echo "SUCCESS" || echo "FAILED")"
echo "HTO: $([ $hto_result -eq 0 ] && echo "SUCCESS" || echo "FAILED")"
echo "=========================================="

exit $(( cdna_result + hto_result ))

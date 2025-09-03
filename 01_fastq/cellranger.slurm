#!/bin/bash
#SBATCH --time=12:00:00
#SBATCH --mem=128G
#SBATCH --cpus-per-task=16
#SBATCH --account=PAS2598
#SBATCH --job-name=cellranger_multimodal
#SBATCH --output=/fs/scratch/PAS2598/senes_raw/logs/cellranger_%A_%a.log

echo "=========================================="
echo "Cell Ranger Multimodal Processing (cDNA + HTO)"
echo "Job ID: $SLURM_JOB_ID"
echo "Date: $(date)"
echo "Node: $HOSTNAME"
echo "=========================================="

# Set up environment
source ~/.bashrc
export PATH="/fs/ess/PAS2598/Senescence/packages/cellranger-9.0.1:$PATH"

# Define paths
BASE_DIR="/fs/scratch/PAS2598/senes_raw"
TRIMMED_READS_DIR="${BASE_DIR}/trimmed_reads"
CELLRANGER_OUTPUT_DIR="${BASE_DIR}/cellranger_multimodal"
SYMLINK_DIR="${BASE_DIR}/cellranger_fastqs"
TRANSCRIPTOME="/fs/ess/PAS2598/ggaitos/2025/data/references/refdata-gex-GRCh38-2020-A"
SCRIPTS_DIR="${BASE_DIR}/scripts"

# Create organized directories
mkdir -p ${CELLRANGER_OUTPUT_DIR}
mkdir -p ${SYMLINK_DIR}/{cDNA,HTO}
mkdir -p ${SCRIPTS_DIR}

# Get base sample name from command line argument
if [[ -z "$1" ]]; then
    echo "Usage: sbatch cellranger_multimodal.sh BASE_SAMPLE_NAME"
    echo "Example: sbatch cellranger_multimodal.sh NPSAD-147-A1"
    exit 1
fi

BASE_SAMPLE="$1"
echo "Processing multimodal sample: $BASE_SAMPLE"

# Convert Cell Ranger sample name to metadata Set_name format for HTO lookup
# Remove the -A1 or -A2 suffix and convert to Set_name format (e.g., NPSAD-174-A1 -> NPSAD_174_A)
SET_NAME=$(echo "$BASE_SAMPLE" | sed 's/-/_/g' | sed 's/_A[12]$/_A/')
echo "Looking up HTOs for Set_name: $SET_NAME"

# Create HTO feature reference file
HASHING_METADATA="${BASE_DIR}/NPS-AD_nucleus_hashing_metadata.csv"
HTO_REFERENCE="${SCRIPTS_DIR}/${BASE_SAMPLE}_hto_reference.csv"

echo "Creating HTO feature reference..."

if [[ ! -f "$HASHING_METADATA" ]]; then
    echo "ERROR: Hashing metadata not found: $HASHING_METADATA"
    exit 1
fi

# Extract HTO barcodes for this set
echo "id,name,read,pattern,sequence,feature_type" > "$HTO_REFERENCE"

while IFS=',' read -r individual_id hto_barcode set_name rest; do
    if [[ "$set_name" == "$SET_NAME" ]]; then
        echo "HTO_${hto_barcode:0:8},${hto_barcode},R2,5PNNNNNNNNNN(BC),${hto_barcode},Antibody Capture" >> "$HTO_REFERENCE"
    fi
done < <(tail -n +2 "$HASHING_METADATA")

hto_count=$(tail -n +2 "$HTO_REFERENCE" | wc -l)
if [[ $hto_count -eq 0 ]]; then
    echo "ERROR: No HTOs found for Set_name: $SET_NAME"
    exit 1
fi

echo "Created HTO reference with $hto_count barcodes"
echo "HTO reference file: $HTO_REFERENCE"

# Function to find and symlink fastq files
setup_fastqs() {
    local library_type="$1"
    local base_sample="$2"
    
    echo ""
    echo "Setting up fastqs for ${library_type}..."
    
    # Construct the expected sample prefix
    local sample_prefix="${base_sample}-${library_type}"
    
    # Find R1 and R2 files
    local r1_file=$(ls ${TRIMMED_READS_DIR}/${library_type}/${sample_prefix}_*R1_trimmed.fastq.gz 2>/dev/null | head -1)
    local r2_file=$(ls ${TRIMMED_READS_DIR}/${library_type}/${sample_prefix}_*R2_trimmed.fastq.gz 2>/dev/null | head -1)
    
    if [[ ! -f "$r1_file" || ! -f "$r2_file" ]]; then
        echo "ERROR: Files not found for ${sample_prefix}"
        echo "  Looking for: ${TRIMMED_READS_DIR}/${library_type}/${sample_prefix}_*R1_trimmed.fastq.gz"
        echo "  Looking for: ${TRIMMED_READS_DIR}/${library_type}/${sample_prefix}_*R2_trimmed.fastq.gz"
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
    
    echo "Created symlinks:"
    echo "  $(basename $symlink_r1) -> $(basename $r1_file)"
    echo "  $(basename $symlink_r2) -> $(basename $r2_file)"
    
    return 0
}

# Setup fastq files for both libraries
echo "Setting up fastq files..."
setup_fastqs "cDNA" "$BASE_SAMPLE"
cdna_setup=$?

setup_fastqs "HTO" "$BASE_SAMPLE"
hto_setup=$?

if [[ $cdna_setup -ne 0 ]] || [[ $hto_setup -ne 0 ]]; then
    echo "ERROR: Failed to setup fastq files"
    exit 1
fi

# Create libraries.csv file
LIBRARIES_CSV="${SCRIPTS_DIR}/${BASE_SAMPLE}_libraries.csv"
echo "Creating libraries file: $LIBRARIES_CSV"

cat > "$LIBRARIES_CSV" << EOF
fastqs,sample,library_type
${SYMLINK_DIR}/cDNA,${BASE_SAMPLE}-cDNA,Gene Expression
${SYMLINK_DIR}/HTO,${BASE_SAMPLE}-HTO,Antibody Capture
EOF

echo "Libraries file created:"
cat "$LIBRARIES_CSV"

# Check if already processed
OUTPUT_DIR="${CELLRANGER_OUTPUT_DIR}/${BASE_SAMPLE}"
if [[ -f "${OUTPUT_DIR}/outs/filtered_feature_bc_matrix/barcodes.tsv.gz" ]]; then
    echo "Already processed: ${BASE_SAMPLE}"
    
    # Check if it has both gene expression and HTO features
    feature_count=$(zcat "${OUTPUT_DIR}/outs/filtered_feature_bc_matrix/features.tsv.gz" | wc -l)
    hto_features=$(zcat "${OUTPUT_DIR}/outs/filtered_feature_bc_matrix/features.tsv.gz" | grep -c "Antibody Capture" || true)
    
    echo "Existing output has $feature_count total features, $hto_features HTO features"
    
    if [[ $hto_features -gt 0 ]]; then
        echo "Multimodal data already exists. Exiting."
        exit 0
    else
        echo "Existing data lacks HTOs. Reprocessing..."
        rm -rf "${OUTPUT_DIR}"
    fi
fi

# Remove incomplete runs
[[ -d "${OUTPUT_DIR}" ]] && rm -rf "${OUTPUT_DIR}"

# Run multimodal Cell Ranger
cd ${CELLRANGER_OUTPUT_DIR}

echo ""
echo "=========================================="
echo "Running Cell Ranger multimodal analysis..."
echo "Sample: $BASE_SAMPLE"
echo "Libraries: $LIBRARIES_CSV"
echo "HTO reference: $HTO_REFERENCE"
echo "Expected cells: 5000"
echo "=========================================="

start_time=$(date +%s)

cellranger count \
    --id="${BASE_SAMPLE}" \
    --create-bam=true \
    --libraries="$LIBRARIES_CSV" \
    --feature-ref="$HTO_REFERENCE" \
    --transcriptome="${TRANSCRIPTOME}" \
    --expect-cells=5000 \
    --localcores=${SLURM_CPUS_PER_TASK} \
    --localmem=120 \
    --disable-ui

end_time=$(date +%s)
duration=$(( (end_time - start_time) / 60 ))

# Check success and analyze output
if [[ -f "${OUTPUT_DIR}/outs/filtered_feature_bc_matrix/barcodes.tsv.gz" ]]; then
    echo ""
    echo "=========================================="
    echo "Cell Ranger completed successfully!"
    echo "Duration: ${duration} minutes"
    
    # Analyze the output
    total_features=$(zcat "${OUTPUT_DIR}/outs/filtered_feature_bc_matrix/features.tsv.gz" | wc -l)
    gene_features=$(zcat "${OUTPUT_DIR}/outs/filtered_feature_bc_matrix/features.tsv.gz" | grep -c "Gene Expression" || true)
    hto_features=$(zcat "${OUTPUT_DIR}/outs/filtered_feature_bc_matrix/features.tsv.gz" | grep -c "Antibody Capture" || true)
    total_cells=$(zcat "${OUTPUT_DIR}/outs/filtered_feature_bc_matrix/barcodes.tsv.gz" | wc -l)
    
    echo ""
    echo "Output Analysis:"
    echo "- Total cells: $total_cells"
    echo "- Total features: $total_features"
    echo "- Gene features: $gene_features"  
    echo "- HTO features: $hto_features"
    
    if [[ $hto_features -gt 0 ]]; then
        echo ""
        echo "✓ SUCCESS: Multimodal data with HTOs generated!"
        echo "✓ Ready for HTO demultiplexing!"
        
        echo ""
        echo "HTO features detected:"
        zcat "${OUTPUT_DIR}/outs/filtered_feature_bc_matrix/features.tsv.gz" | grep "Antibody Capture" | head -10
        
        success_code=0
    else
        echo ""
        echo "✗ WARNING: No HTO features found in output!"
        echo "Check Cell Ranger logs for feature processing issues."
        success_code=1
    fi
    
    echo ""
    echo "Output location: ${OUTPUT_DIR}/"
    echo "Web summary: ${OUTPUT_DIR}/outs/web_summary.html"
    
else
    echo ""
    echo "✗ FAILED: Cell Ranger processing failed"
    echo "Check logs: ${OUTPUT_DIR}/outs/"
    success_code=1
fi

# Cleanup temporary files
rm -f "$LIBRARIES_CSV" "$HTO_REFERENCE"

echo ""
echo "=========================================="
echo "Multimodal Cell Ranger Complete: $BASE_SAMPLE"
echo "$([ $success_code -eq 0 ] && echo "Status: SUCCESS" || echo "Status: FAILED")"
echo "Date: $(date)"
echo "=========================================="

exit $success_code

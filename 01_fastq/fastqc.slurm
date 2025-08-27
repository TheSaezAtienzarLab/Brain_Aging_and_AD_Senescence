#!/bin/bash
#SBATCH --time=96:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=20
#SBATCH --account=PAS2598
#SBATCH --job-name=fastqc_928files
#SBATCH --output=/fs/scratch/PAS2598/senes_raw/logs/fastqc_928files_%j.log

echo "=========================================="
echo "FastQC Processing for 928 Files Started"
echo "Job ID: $SLURM_JOB_ID"
echo "Date: $(date)"
echo "Node: $HOSTNAME"
echo "=========================================="

# Fix conda activation issue
#source ~/.bashrc
eval "$(conda shell.bash hook)"
conda activate synapse-py

echo "Conda environment: $CONDA_DEFAULT_ENV"
echo "FastQC version: $(fastqc --version)"
echo "Available cores: $SLURM_CPUS_PER_TASK"

# Define paths
BASE_DIR="/fs/scratch/PAS2598/senes_raw"
MANIFEST_FILE="${BASE_DIR}/manifests/fastqc_manifest_all.csv"
OUTPUT_DIR="${BASE_DIR}/fastqc_results"
PROGRESS_FILE="${BASE_DIR}/logs/fastqc_progress_${SLURM_JOB_ID}.log"

# Create output directories
mkdir -p ${OUTPUT_DIR}/{cDNA,HTO}
mkdir -p ${BASE_DIR}/logs

# Check if manifest exists
if [[ ! -f ${MANIFEST_FILE} ]]; then
    echo "ERROR: Manifest file not found: ${MANIFEST_FILE}"
    exit 1
fi

echo "Starting FastQC processing..."
echo "Input manifest: ${MANIFEST_FILE}"
echo "Output directory: ${OUTPUT_DIR}"
echo "Progress log: ${PROGRESS_FILE}"

# Count files in manifest
total_files=$(( $(wc -l < ${MANIFEST_FILE}) - 1 ))
cdna_in_manifest=$(awk -F',' '$2=="cDNA"' ${MANIFEST_FILE} | wc -l)
hto_in_manifest=$(awk -F',' '$2=="HTO"' ${MANIFEST_FILE} | wc -l)

echo "Total files in manifest: ${total_files}"
echo "cDNA files in manifest: ${cdna_in_manifest}"
echo "HTO files in manifest: ${hto_in_manifest}"

# Count existing reports
existing_cdna=$(find ${OUTPUT_DIR}/cDNA -name "*.html" 2>/dev/null | wc -l)
existing_hto=$(find ${OUTPUT_DIR}/HTO -name "*.html" 2>/dev/null | wc -l)

echo "Existing cDNA reports: ${existing_cdna}"
echo "Existing HTO reports: ${existing_hto}"

# Initialize progress log
echo "$(date): Starting FastQC processing for ${total_files} files" > ${PROGRESS_FILE}

# Initialize counters
processed_cdna=0
processed_hto=0
failed_cdna=0
failed_hto=0
skipped_cdna=0
skipped_hto=0

start_time=$(date +%s)

# Function to log progress
log_progress() {
    local current_time=$(date)
    local elapsed=$(($(date +%s) - start_time))
    local total_processed=$((processed_cdna + processed_hto))
    local total_skipped=$((skipped_cdna + skipped_hto))
    local total_failed=$((failed_cdna + failed_hto))
    local total_attempted=$((total_processed + total_skipped + total_failed))
    
    if [[ $total_attempted -gt 0 && $elapsed -gt 0 ]]; then
        local rate=$((total_attempted * 3600 / elapsed))
        local eta=$(( (total_files - total_attempted) * elapsed / total_attempted ))
        local eta_hours=$((eta / 3600))
        local eta_min=$(((eta % 3600) / 60))
        
        echo "$(date): Progress ${total_attempted}/${total_files} (${rate} files/hour, ETA: ${eta_hours}h ${eta_min}m)" | tee -a ${PROGRESS_FILE}
    fi
}

# Process cDNA files
echo ""
echo "Processing cDNA files..."
echo "$(date): Starting cDNA processing" >> ${PROGRESS_FILE}

while IFS=',' read -r sample_id file_type batch tech_replicate file_path; do
    if [[ "$file_type" == "cDNA" ]]; then
        output_file="${OUTPUT_DIR}/cDNA/$(basename ${file_path%.fastq.gz})_fastqc.html"
        
        if [[ -f "$output_file" ]]; then
            ((skipped_cdna++))
            if (( skipped_cdna % 50 == 0 )); then
                echo "Skipped ${skipped_cdna} cDNA files (already processed)"
            fi
        elif [[ -f "$file_path" ]]; then
            echo "Processing cDNA: $(basename $file_path)"
            if fastqc "$file_path" --outdir=${OUTPUT_DIR}/cDNA --threads=10 --quiet; then
                ((processed_cdna++))
            else
                echo "✗ Failed: $(basename $file_path)"
                ((failed_cdna++))
            fi
        else
            echo "✗ File not found: $file_path"
            ((failed_cdna++))
        fi
        
        # Progress update every 25 files
        if (( (processed_cdna + failed_cdna + skipped_cdna) % 25 == 0 )); then
            echo "cDNA Progress: ${processed_cdna} processed, ${skipped_cdna} skipped, ${failed_cdna} failed"
            log_progress
        fi
    fi
done < <(tail -n +2 "$MANIFEST_FILE")

echo "✓ cDNA processing complete: ${processed_cdna} processed, ${skipped_cdna} skipped, ${failed_cdna} failed"
echo "$(date): cDNA complete - ${processed_cdna} processed, ${skipped_cdna} skipped, ${failed_cdna} failed" >> ${PROGRESS_FILE}

# Process HTO files
echo ""
echo "Processing HTO files..."
echo "$(date): Starting HTO processing" >> ${PROGRESS_FILE}

while IFS=',' read -r sample_id file_type batch tech_replicate file_path; do
    if [[ "$file_type" == "HTO" ]]; then
        output_file="${OUTPUT_DIR}/HTO/$(basename ${file_path%.fastq.gz})_fastqc.html"
        
        if [[ -f "$output_file" ]]; then
            ((skipped_hto++))
            if (( skipped_hto % 100 == 0 )); then
                echo "Skipped ${skipped_hto} HTO files (already processed)"
            fi
        elif [[ -f "$file_path" ]]; then
            if (( processed_hto % 50 == 0 )) && [[ $processed_hto -gt 0 ]]; then
                echo "Processing HTO #${processed_hto}: $(basename $file_path)"
            fi
            if fastqc "$file_path" --outdir=${OUTPUT_DIR}/HTO --threads=10 --quiet; then
                ((processed_hto++))
            else
                echo "✗ Failed HTO: $(basename $file_path)"
                ((failed_hto++))
            fi
        else
            echo "✗ HTO file not found: $file_path"
            ((failed_hto++))
        fi
        
        # Progress update every 50 files for HTO
        if (( (processed_hto + failed_hto + skipped_hto) % 50 == 0 )); then
            echo "HTO Progress: ${processed_hto} processed, ${skipped_hto} skipped, ${failed_hto} failed"
            log_progress
        fi
    fi
done < <(tail -n +2 "$MANIFEST_FILE")

echo "✓ HTO processing complete: ${processed_hto} processed, ${skipped_hto} skipped, ${failed_hto} failed"
echo "$(date): HTO complete - ${processed_hto} processed, ${skipped_hto} skipped, ${failed_hto} failed" >> ${PROGRESS_FILE}

# Calculate duration
end_time=$(date +%s)
duration=$((end_time - start_time))
duration_hours=$((duration / 3600))
duration_min=$(((duration % 3600) / 60))

echo ""
echo "=========================================="
echo "FastQC Processing Complete"
echo "Duration: ${duration_hours}h ${duration_min}m"
echo "=========================================="

# Final counts
final_cdna_reports=$(find ${OUTPUT_DIR}/cDNA -name "*.html" 2>/dev/null | wc -l)
final_hto_reports=$(find ${OUTPUT_DIR}/HTO -name "*.html" 2>/dev/null | wc -l)
total_reports=$((final_cdna_reports + final_hto_reports))

echo "Final Results:"
echo ""
echo "cDNA:"
echo "  Processed this run: ${processed_cdna}"
echo "  Skipped (already done): ${skipped_cdna}"
echo "  Failed: ${failed_cdna}"
echo "  Total reports now: ${final_cdna_reports}"
echo ""
echo "HTO:"
echo "  Processed this run: ${processed_hto}"
echo "  Skipped (already done): ${skipped_hto}"
echo "  Failed: ${failed_hto}"
echo "  Total reports now: ${final_hto_reports}"
echo ""
echo "Overall:"
echo "  Total new reports: $((processed_cdna + processed_hto))"
echo "  Total reports now: ${total_reports}"
echo "  Expected: ${total_files}"
echo "  Success rate: $(( (final_cdna_reports + final_hto_reports) * 100 / total_files ))%"

# Log final results
echo "$(date): COMPLETE - ${total_reports}/${total_files} reports generated in ${duration_hours}h ${duration_min}m" >> ${PROGRESS_FILE}

if [[ ${total_reports} -ge $((total_files * 95 / 100)) ]]; then
    echo "✓ SUCCESS: >95% of files processed successfully"
    exit_status=0
elif [[ ${total_reports} -ge $((total_files * 80 / 100)) ]]; then
    echo "⚠ PARTIAL SUCCESS: >80% of files processed"
    exit_status=0
else
    echo "⚠ LOW SUCCESS RATE: <80% of files processed"
    exit_status=1
fi

echo ""
echo "Progress log: ${PROGRESS_FILE}"
echo "Next step: sbatch 04_multiqc_report.slurm"
echo "=========================================="

exit $exit_status

#!/bin/bash
#SBATCH --time=4:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4
#SBATCH --account=PAS2598
#SBATCH --job-name=multiqc_report
#SBATCH --output=/fs/scratch/PAS2598/senes_raw/logs/multiqc_report_%j.log

echo "=========================================="
echo "MultiQC Report Generation Started"
echo "Job ID: $SLURM_JOB_ID"
echo "Date: $(date)"
echo "=========================================="

# Set up environment
#source ~/.bashrc
eval "$(conda shell.bash hook)"
conda activate synapse-py

echo "Conda environment: $CONDA_DEFAULT_ENV"

# Check if MultiQC is available
if ! command -v multiqc &> /dev/null; then
    echo "MultiQC not found, installing..."
    conda install -c bioconda multiqc -y
fi

echo "MultiQC version: $(multiqc --version)"

# Define paths
BASE_DIR="/fs/scratch/PAS2598/senes_raw"
FASTQC_DIR="${BASE_DIR}/fastqc_results"
OUTPUT_DIR="${BASE_DIR}/multiqc_report"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create output directory
mkdir -p ${OUTPUT_DIR}

echo "Input directory: ${FASTQC_DIR}"
echo "Output directory: ${OUTPUT_DIR}"

# Count FastQC reports
cdna_reports=$(find ${FASTQC_DIR}/cDNA -name "*.html" 2>/dev/null | wc -l)
hto_reports=$(find ${FASTQC_DIR}/HTO -name "*.html" 2>/dev/null | wc -l)
total_reports=$((cdna_reports + hto_reports))

echo "FastQC reports found:"
echo "  cDNA reports: ${cdna_reports}"
echo "  HTO reports: ${hto_reports}"
echo "  Total reports: ${total_reports}"

if [[ ${total_reports} -eq 0 ]]; then
    echo "ERROR: No FastQC reports found in ${FASTQC_DIR}"
    exit 1
fi

echo ""
echo "Generating MultiQC report..."

# Generate MultiQC report
multiqc ${FASTQC_DIR} \
    --outdir ${OUTPUT_DIR} \
    --filename "multiqc_report_${TIMESTAMP}" \
    --title "SENES RNA-seq QC Report - $(date +%Y-%m-%d)" \
    --comment "Quality control analysis for 679 FastQC reports (113 cDNA + 566 HTO files)" \
    --dirs \
    --dirs-depth 2 \
    --interactive \
    --export \
    --verbose

# Check if report was generated successfully
if [[ -f "${OUTPUT_DIR}/multiqc_report_${TIMESTAMP}.html" ]]; then
    echo ""
    echo "=========================================="
    echo "MultiQC Report Generation Complete"
    echo "=========================================="
    echo "Success! MultiQC report generated:"
    echo "  Report: ${OUTPUT_DIR}/multiqc_report_${TIMESTAMP}.html"
    echo "  Data: ${OUTPUT_DIR}/multiqc_report_${TIMESTAMP}_data/"
    echo ""
    echo "Report includes:"
    echo "  - ${cdna_reports} cDNA FastQC reports"
    echo "  - ${hto_reports} HTO FastQC reports"
    echo "  - ${total_reports} total samples analyzed"
    echo ""
    echo "To view the report:"
    echo "  1. Download the HTML file to your local computer"
    echo "  2. Open multiqc_report_${TIMESTAMP}.html in your web browser"
    echo ""
    echo "Report location: ${OUTPUT_DIR}/multiqc_report_${TIMESTAMP}.html"
else
    echo ""
    echo "ERROR: MultiQC report generation failed"
    echo "Check the log above for error messages"
    exit 1
fi

echo "=========================================="
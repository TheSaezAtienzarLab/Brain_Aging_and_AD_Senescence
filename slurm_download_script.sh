#!/bin/bash
#SBATCH --job-name=synapse_download
#SBATCH --account=PAS2598
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32GB
#SBATCH --output=/fs/scratch/PAS2598/senes_raw/LOGS/synapse_download_%j.out
#SBATCH --error=/fs/scratch/PAS2598/senes_raw/LOGS/synapse_download_%j.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=gerald.gaitos@osumc.edu

# Job information
echo "Job ID: $SLURM_JOB_ID"
echo "Job Name: $SLURM_JOB_NAME"
echo "Node: $SLURM_NODELIST"
echo "Start Time: $(date)"
echo "Working Directory: $PWD"
echo ""

# Create necessary directories
echo "Setting up directories..."
mkdir -p /fs/scratch/PAS2598/senes_raw/LOGS
mkdir -p /fs/scratch/PAS2598/senes_raw/CONTROLS
mkdir -p /fs/scratch/PAS2598/senes_raw/SCRIPTS

# Load necessary modules (adjust based on your cluster)
echo "Loading modules..."
# module load python/3.10  # Uncomment if needed
# module load conda        # Uncomment if needed

# Activate conda environment
echo "Activating conda environment..."
source ~/.bashrc  # Ensure conda is initialized
conda activate synapse-py

# Verify environment
echo "Python version: $(python --version)"
echo "Conda environment: $CONDA_DEFAULT_ENV"
echo "Current directory: $PWD"
echo ""

# Check if required files exist
echo "Checking for required files..."
if [ ! -f "healthy_controls.csv" ]; then
    echo "ERROR: healthy_controls.csv not found in current directory!"
    echo "Current directory contents:"
    ls -la
    exit 1
fi

if [ ! -f "synapse_unified_downloader.py" ]; then
    echo "ERROR: synapse_unified_downloader.py not found in current directory!"
    echo "Current directory contents:"
    ls -la
    exit 1
fi

echo "✓ Required files found"
echo ""

# Set up Python path and verify imports
echo "Verifying Python dependencies..."
python -c "import synapseclient, pandas, sys; print(f'✓ synapseclient: {synapseclient.__version__}'); print(f'✓ pandas: {pandas.__version__}')" || {
    echo "ERROR: Missing required Python packages"
    exit 1
}
echo ""

# Run the unified download and integrity check script
echo "Starting Synapse unified downloader (check + download)..."
echo "=================================================="
python synapse_unified_downloader.py

# Check exit status
if [ $? -eq 0 ]; then
    echo ""
    echo "=================================================="
    echo "✓ Download completed successfully!"
    
    # Show summary of downloaded files
    echo ""
    echo "Download Summary:"
    echo "=================="
    if [ -f "/fs/scratch/PAS2598/senes_raw/CONTROLS/download_summary.csv" ]; then
        echo "Summary file created: /fs/scratch/PAS2598/senes_raw/CONTROLS/download_summary.csv"
        echo ""
        echo "First few lines of summary:"
        head -10 /fs/scratch/PAS2598/senes_raw/CONTROLS/download_summary.csv
    fi
    
    # Count total downloaded files
    echo ""
    echo "File counts:"
    echo "============="
    total_files=$(find /fs/scratch/PAS2598/senes_raw/CONTROLS -name "*.fastq.gz" | wc -l)
    total_dirs=$(find /fs/scratch/PAS2598/senes_raw/CONTROLS -mindepth 1 -maxdepth 1 -type d | wc -l)
    echo "Total fastq.gz files downloaded: $total_files"
    echo "Total individual directories: $total_dirs"
    
    # Show disk usage
    echo ""
    echo "Disk usage:"
    echo "==========="
    du -sh /fs/scratch/PAS2598/senes_raw/CONTROLS
    
else
    echo ""
    echo "=================================================="
    echo "✗ Download failed with exit code: $?"
    echo "Check the error log for details:"
    echo "/fs/scratch/PAS2598/senes_raw/LOGS/synapse_download_${SLURM_JOB_ID}.err"
    exit 1
fi

echo ""
echo "Job completed at: $(date)"
echo "Total runtime: $SECONDS seconds"
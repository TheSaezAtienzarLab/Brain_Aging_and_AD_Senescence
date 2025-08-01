#!/bin/bash
# Quick submission script for Synapse download job

echo "🧬 Synapse Fastq Download Job Submission"
echo "========================================"

# Check if we're in the right directory
if [ ! -f "healthy_controls.csv" ] || [ ! -f "synapse_unified_downloader.py" ]; then
    echo "❌ ERROR: Required files not found in current directory!"
    echo "   Please make sure you have:"
    echo "   - healthy_controls.csv"
    echo "   - synapse_unified_downloader.py"
    echo "   - synapse_download.slurm"
    echo ""
    echo "Current directory: $PWD"
    echo "Files found:"
    ls -la *.csv *.py *.slurm 2>/dev/null || echo "   (no matching files)"
    exit 1
fi

# Check if SLURM script exists
if [ ! -f "synapse_download.slurm" ]; then
    echo "❌ ERROR: synapse_download.slurm not found!"
    exit 1
fi

# Create logs directory
mkdir -p /fs/scratch/PAS2598/senes_raw/LOGS

# Show current queue status
echo ""
echo "Current SLURM queue status for your account:"
squeue -u $USER

echo ""
echo "Submitting job..."
job_id=$(sbatch synapse_download.slurm | grep -o '[0-9]\+')

if [ ! -z "$job_id" ]; then
    echo "✅ Job submitted successfully!"
    echo "   Job ID: $job_id"
    echo "   Job Name: synapse_download"
    echo ""
    echo "📊 Monitor your job with:"
    echo "   squeue -j $job_id"
    echo "   scontrol show job $job_id"
    echo ""
    echo "📝 View logs with:"
    echo "   tail -f /fs/scratch/PAS2598/senes_raw/LOGS/synapse_download_${job_id}.out"
    echo "   tail -f /fs/scratch/PAS2598/senes_raw/LOGS/synapse_download_${job_id}.err"
    echo ""
    echo "📧 You'll receive email notifications at job completion."
    echo ""
    echo "Expected download location:"
    echo "   /fs/scratch/PAS2598/senes_raw/CONTROLS/"
else
    echo "❌ Job submission failed!"
    echo "Check your SLURM configuration and try again."
    exit 1
fi
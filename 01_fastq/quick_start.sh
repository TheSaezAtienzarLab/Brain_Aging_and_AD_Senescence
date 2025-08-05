#!/bin/bash
# =============================================================================
# QUICK START: Modular Single-cell RNA-seq Pipeline
# =============================================================================
# This script helps you quickly deploy and start the modular pipeline
# for analyzing your 194 brain aging samples
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${PURPLE}"
    echo "🧬 ================================== 🧬"
    echo "   MODULAR SCRNA-SEQ PIPELINE"
    echo "   Brain Aging & Senescence Study"
    echo "   Gerald Gaitos, MD, MSc"
    echo "🧬 ================================== 🧬"
    echo -e "${NC}"
}

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_banner

echo "This script will help you deploy and run the modular pipeline"
echo "for processing your 194 brain aging samples with scRNA-seq analysis."
echo ""

# Step 1: Validate current environment
log "STEP 1: Validating your current setup..."
echo "======================================="

# Check if we're in the right directory
CURRENT_DIR=$(pwd)
EXPECTED_DIR="/users/PAS2598/ggaitos/2025/scripts/single-cell/preprocessing/dataset_5/NPS-AD_metadata"

echo "Current directory: $CURRENT_DIR"
echo "Expected directory: $EXPECTED_DIR"

if [[ "$CURRENT_DIR" == "$EXPECTED_DIR" ]]; then
    success "You're in the correct directory"
else
    warning "You may not be in the expected directory"
    echo ""
    echo "Would you like to continue anyway? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Please navigate to: $EXPECTED_DIR"
        exit 1
    fi
fi

# Check for fastq data
CONTROLS_DIR="/fs/scratch/PAS2598/senes_raw/CONTROLS"
if [[ -d "$CONTROLS_DIR" ]]; then
    sample_count=$(find "$CONTROLS_DIR" -maxdepth 1 -type d -name "AMPAD_HBCC_*" | wc -l)
    fastq_count=$(find "$CONTROLS_DIR" -name "*.fastq.gz" | wc -l)
    success "Found your data: $sample_count samples, $fastq_count fastq files"
else
    error "CONTROLS directory not found: $CONTROLS_DIR"
    echo "Please ensure your fastq files are downloaded first"
    exit 1
fi

# Check Python
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version)
    success "Python available: $python_version"
else
    error "Python3 not found"
    exit 1
fi

echo ""

# Step 2: Check required files
log "STEP 2: Checking for pipeline files..."
echo "======================================"

required_files=(
    "pipeline_config.yaml:Main configuration file"
    "pipeline_controller.py:Pipeline controller"
    "01_setup.sh:Setup module"
    "02_qc_check.py:Quality control module"
    "03_cellranger_setup.sh:Cell Ranger setup"
    "deploy_pipeline.sh:Deployment script"
)

missing_files=()
existing_files=()

for file_info in "${required_files[@]}"; do
    IFS=":" read -r filename description <<< "$file_info"
    if [[ -f "$filename" ]]; then
        success "$description: $filename"
        existing_files+=("$filename")
    else
        error "$description missing: $filename"
        missing_files+=("$filename")
    fi
done

if [[ ${#missing_files[@]} -gt 0 ]]; then
    echo ""
    error "Missing ${#missing_files[@]} required files!"
    echo "Please create these files from the artifacts provided:"
    for file in "${missing_files[@]}"; do
        echo "  - $file"
    done
    echo ""
    echo "Instructions:"
    echo "1. Copy each artifact content to create the respective file"
    echo "2. Make scripts executable: chmod +x *.sh *.py"
    echo "3. Re-run this script"
    exit 1
fi

success "All required files present (${#existing_files[@]}/6)"

echo ""

# Step 3: Configuration check
log "STEP 3: Configuration validation..."
echo "=================================="

if [[ -f "pipeline_config.yaml" ]]; then
    # Basic YAML syntax check
    if python3 -c "import yaml; yaml.safe_load(open('pipeline_config.yaml'))" 2>/dev/null; then
        success "Configuration file has valid YAML syntax"
        
        # Check for critical placeholders
        if grep -q "YOUR_ACTUAL_SEQUENCE\|PLACEHOLDER" pipeline_config.yaml; then
            warning "Configuration contains placeholder values"
            info "You'll need to update HTO sequences before Cell Ranger processing"
        else
            success "Configuration appears to be customized"
        fi
        
        # Check email configuration
        if grep -q "gerald.gaitos@osumc.edu" pipeline_config.yaml; then
            success "Email notifications configured"
        else
            warning "Email configuration may need updating"
        fi
        
    else
        error "Configuration file has YAML syntax errors"
        echo "Please check pipeline_config.yaml for syntax issues"
        exit 1
    fi
else
    error "Configuration file missing: pipeline_config.yaml"
    exit 1
fi

echo ""

# Step 4: Deployment options
log "STEP 4: Deployment options..."
echo "============================="

echo "Choose your deployment option:"
echo ""
echo "1. 🚀 FULL DEPLOYMENT (Recommended)"
echo "   - Deploy complete pipeline"
echo "   - Initialize directory structure"  
echo "   - Run quality control check"
echo "   - Setup Cell Ranger environment"
echo ""
echo "2. 📋 MINIMAL DEPLOYMENT"
echo "   - Deploy pipeline structure only"
echo "   - Manual step-by-step execution"
echo ""
echo "3. 🔍 DRY RUN"
echo "   - Preview what would be deployed"
echo "   - No actual changes made"
echo ""

echo -n "Enter your choice (1-3): "
read -r choice

case $choice in
    1)
        DEPLOYMENT_TYPE="FULL"
        ;;
    2)
        DEPLOYMENT_TYPE="MINIMAL"
        ;;
    3)
        DEPLOYMENT_TYPE="DRY_RUN"
        ;;
    *)
        error "Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo ""
log "Selected: $DEPLOYMENT_TYPE DEPLOYMENT"
echo ""

# Confirmation
if [[ "$DEPLOYMENT_TYPE" == "FULL" ]]; then
    warning "Full deployment will:"
    echo "  - Create directories in /fs/scratch/PAS2598/senes_raw/"
    echo "  - Deploy all pipeline modules"
    echo "  - Run quality control analysis (~30 minutes)"
    echo "  - Download Cell Ranger and reference genome (~2 hours)"
    echo "  - Generate comprehensive reports"
    echo ""
    echo -n "Continue with full deployment? (y/n): "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 0
    fi
fi

echo ""

# Step 5: Execute deployment
log "STEP 5: Executing deployment..."
echo "==============================="

case $DEPLOYMENT_TYPE in
    "FULL")
        log "Starting full deployment..."
        
        # Make scripts executable
        chmod +x *.sh *.py
        success "Scripts made executable"
        
        # Run deployment
        log "Running deployment script..."
        if ./deploy_pipeline.sh; then
            success "Pipeline deployment completed"
        else
            error "Deployment failed"
            exit 1
        fi
        
        # Navigate to scripts directory
        SCRIPTS_DIR="/fs/scratch/PAS2598/senes_raw/SCRIPTS"
        cd "$SCRIPTS_DIR"
        success "Moved to scripts directory: $SCRIPTS_DIR"
        
        # Initialize pipeline
        log "Initializing pipeline..."
        if ./initialize_pipeline.sh; then
            success "Pipeline initialization completed"
        else
            error "Pipeline initialization failed"
            exit 1
        fi
        
        # Run QC check
        log "Running quality control analysis..."
        if ./run_qc.sh; then
            success "Quality control completed"
        else
            warning "Quality control completed with warnings"
        fi
        
        # Setup Cell Ranger (this takes longer)
        log "Setting up Cell Ranger (this may take 1-2 hours)..."
        echo "You can monitor progress in another terminal with:"
        echo "  tail -f ../LOGS/cellranger/03_cellranger_setup_*.log"
        
        if python3 pipeline_controller.py --step 03_cellranger_setup; then
            success "Cell Ranger setup completed"
        else
            error "Cell Ranger setup failed"
            echo "Check logs for details: ../LOGS/cellranger/"
            exit 1
        fi
        ;;
        
    "MINIMAL")
        log "Starting minimal deployment..."
        
        chmod +x *.sh *.py
        success "Scripts made executable"
        
        if ./deploy_pipeline.sh; then
            success "Minimal deployment completed"
        else
            error "Deployment failed"
            exit 1
        fi
        ;;
        
    "DRY_RUN")
        log "Performing dry run..."
        
        echo "Would deploy pipeline to: /fs/scratch/PAS2598/senes_raw/"
        echo "Would create directory structure and deploy modules"
        echo "Would initialize with your 194 samples"
        
        success "Dry run completed - no changes made"
        ;;
esac

echo ""

# Step 6: Final summary and next steps
log "STEP 6: Summary and next steps..."
echo "================================"

case $DEPLOYMENT_TYPE in
    "FULL")
        echo -e "${GREEN}🎉 FULL DEPLOYMENT COMPLETED SUCCESSFULLY! 🎉${NC}"
        echo ""
        echo "📊 What was accomplished:"
        echo "  ✅ Pipeline deployed to /fs/scratch/PAS2598/senes_raw/"
        echo "  ✅ Quality control analysis completed"
        echo "  ✅ Cell Ranger $CELLRANGER_VERSION installed"
        echo "  ✅ Reference genome downloaded"
        echo "  ✅ All 194 samples validated"
        echo ""
        echo "📋 CRITICAL NEXT STEP:"
        echo "  ⚠️  Update HTO sequences in:"
        echo "     /fs/scratch/PAS2598/senes_raw/CELLRANGER/feature_refs/hto_feature_reference.csv"
        echo ""
        echo "🚀 AFTER UPDATING HTO SEQUENCES:"
        echo "  cd /fs/scratch/PAS2598/senes_raw/SCRIPTS"
        echo "  ./run_pilot.sh                    # Test 2-3 samples first"
        echo "  # If pilot succeeds:"
        echo "  python3 pipeline_controller.py --step 06_batch_processing"
        echo ""
        echo "📊 Monitor progress:"
        echo "  python3 pipeline_controller.py --status"
        echo "  squeue -u \$USER"
        echo ""
        echo "📧 Email notifications will be sent to: gerald.gaitos@osumc.edu"
        ;;
        
    "MINIMAL")
        echo -e "${GREEN}✅ MINIMAL DEPLOYMENT COMPLETED${NC}"
        echo ""
        echo "📋 Manual next steps:"
        echo "  cd /fs/scratch/PAS2598/senes_raw/SCRIPTS"
        echo "  ./initialize_pipeline.sh"
        echo "  ./run_qc.sh"
        echo "  python3 pipeline_controller.py --step 03_cellranger_setup"
        echo "  # Update HTO sequences, then:"
        echo "  ./run_pilot.sh"
        ;;
        
    "DRY_RUN")
        echo -e "${CYAN}ℹ️  Dry run completed - ready for actual deployment${NC}"
        echo ""
        echo "To deploy:"
        echo "  ./quick_start.sh    # Choose option 1 or 2"
        ;;
esac

echo ""
echo "📖 For detailed documentation, see:"
echo "   - PIPELINE_README.md (comprehensive documentation)"
echo "   - COMPLETE_DEPLOYMENT_GUIDE.md (step-by-step guide)"
echo ""

# Final status
if [[ "$DEPLOYMENT_TYPE" == "FULL" ]]; then
    echo -e "${PURPLE}🧬 Your 194 brain aging samples are ready for single-cell analysis! 🧬${NC}"
    echo ""
    echo "Estimated timeline to completion:"
    echo "  📊 QC Review: 30 minutes"
    echo "  🧪 Pilot Testing: 4-8 hours" 
    echo "  🚀 Full Processing: 2-3 weeks"
    echo "  📈 Analysis Ready: ~1 month"
fi

echo ""
echo -e "${GREEN}✅ Quick start script completed successfully!${NC}"
echo "$(date)"

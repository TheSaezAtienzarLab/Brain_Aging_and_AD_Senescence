# 🧬 Single-cell RNA-seq Analysis of Brain Aging and Senescence

[![Project Status](https://img.shields.io/badge/Status-Ready%20for%20Demultiplexing-green)](https://github.com)
[![Python](https://img.shields.io/badge/Python-3.10-blue)](https://www.python.org/)
[![Cell Ranger](https://img.shields.io/badge/Cell%20Ranger-9.0.1-green)](https://support.10xgenomics.com/single-cell-gene-expression/software/overview/welcome)
[![Reference](https://img.shields.io/badge/Reference-GRCh38--2020--A-orange)](https://www.10xgenomics.com/)

> **Large-scale investigation of cellular senescence patterns in aging human brain tissue using multiplexed single-cell RNA sequencing.**

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Experimental Design](#-experimental-design)
- [Analysis Workflow](#-analysis-workflow)
- [Current Progress](#-current-progress)
- [Multiplexed Sample Structure](#-multiplexed-sample-structure)
- [Post-Demultiplexing Strategy](#-post-demultiplexing-strategy)
- [Contact Information](#-contact-information)

## 🎯 Project Overview

**Objective**: Investigate cellular senescence patterns in aging human brain tissue using single-cell RNA sequencing across a large cohort of healthy aging controls.

### 🔬 Experimental Design

| Parameter | Value |
|-----------|-------|
| **Tissue** | Human prefrontal cortex |
| **Sample Type** | Healthy aging controls |
| **Multiplexed Pools** | n=113 pools |
| **Individual Donors** | ~678 individuals (6 per pool average) |
| **Technology** | Single-cell RNA-seq with HTO multiplexing |
| **Multiplexing Strategy** | 1-6 donors per pool with unique HTO barcodes |
| **Technical Replicates** | 2 per pool (A1, A2) |
| **Exclusion Criteria** | CERAD or BRAAK scores >0 |
| **Reference Genome** | hg38/GRCh38-2020-A |
| **Data Source** | [Synapse syn53254216](https://www.synapse.org/#!Synapse:syn53254216) |

## 🧪 Multiplexed Sample Structure

### **Pool Organization:**
```
Pool Example: NPSAD_147_A
├── 6 Individual Donors (mixed together)
│   ├── AMPAD_MSSM_0000083136 → HTO: CTTATCACCGCTCAA
│   ├── AMPAD_MSSM_0000094462 → HTO: TGACGCCGTTGTTGT
│   ├── AMPAD_HBCC_0000000392 → HTO: GCCTAGTATGATCCA
│   ├── AMPAD_HBCC_0000000433 → HTO: AGTCACAGTATTCCA
│   ├── AMPAD_MSSM_0000036121 → HTO: TTCCTGCCATTACTA
│   └── AMPAD_MSSM_0000037330 → HTO: CCGTACCTCATTGTT
├── Technical Replicate 1 (A1)
│   ├── cDNA library: NPSAD-147-A1-cDNA_*.fastq.gz
│   └── HTO library: NPSAD-147-A1-HTO_*.fastq.gz
└── Technical Replicate 2 (A2)
    ├── cDNA library: NPSAD-147-A2-cDNA_*.fastq.gz
    └── HTO library: NPSAD-147-A2-HTO_*.fastq.gz
```

### **Scale:**
- **113 multiplexed pools** × **~6 donors per pool** = **~678 individual donors**
- **226 technical replicates** (113 pools × 2 replicates each)
- **Expected total cells**: ~3.4 million cells (~5K per replicate)

## 🔄 Analysis Workflow

```
📊 Raw Multiplexed Data (✅ COMPLETED)
    ├── 113 pools with 1-6 donors each
    └── 678 individual donors total
    ↓
🔍 Quality Control & Cleaning (✅ COMPLETED)
    ├── FastQC → 📈 Quality Assessment
    ├── fastp → 🧹 Adapter/Quality Trimming
    └── MultiQC → 📋 Aggregated Reports
    ↓
🧮 Cell Ranger Multimodal Processing (✅ COMPLETED)
    ├── Multimodal Analysis → 📊 cDNA + HTO Combined Matrices
    ├── Gene Expression → 🧬 ~36K genes per sample
    └── HTO Features → 🏷️ ~6 HTO barcodes per sample
    ↓
🔬 HTO Demultiplexing (🚀 READY TO RUN)
    ├── HTODemux → 🧪 Individual Donor Assignment
    ├── Doublet Retention → 📊 Keep ALL Cells (Singlets + Doublets)
    └── Donor Separation → 👤 ~520 Individual Matrices with Demographics
    ↓
📊 Data Integration (📋 NEXT)
    ├── Age Metadata Mapping → 📅 Age for Each Donor
    ├── Quality Control → 📈 Cell/Gene Filtering
    └── Batch Effect Correction → ⚖️ Pool Harmonization
    ↓
📈 Senescence Analysis (📋 FUTURE)
    ├── Cell Type Identification → 🧠 Brain Cell Populations
    ├── Senescence Markers → ⏰ Age-Related Expression
    └── Population Analysis → 📊 Aging Patterns (n=~520)
```

## 📊 Current Progress

### ✅ Completed
- [x] Multiplexed sample download (113 pools)
- [x] HTO barcode mapping metadata integration
- [x] FastQC quality assessment on raw data
- [x] MultiQC report generation and evaluation
- [x] fastp cleaning and quality trimming
- [x] Sample pairing analysis (cDNA ↔ HTO matching)
- [x] Cell Ranger multimodal processing (87 paired samples)
- [x] **Multimodal matrices generated with genes + HTOs**

### 🚀 Ready to Run  
- [ ] **HTO demultiplexing (87 samples ready for processing)**
- [ ] Individual donor extraction with full demographics
- [ ] Quality assessment across all donors

### 📋 Next Steps (Critical Path)
- [ ] Run HTODemux on all 87 samples (retain doublets)
- [ ] Extract ~520 individual donors with demographics
- [ ] Quality control across individual donor matrices
- [ ] Batch effect correction across pools

## 🧮 Cell Ranger Processing Status

**✅ COMPLETED Configuration:**
- **Processing approach**: Multimodal Cell Ranger 9.0.1 ✅
- **Input per sample**: cDNA + HTO processed together ✅
- **Output per sample**: Single matrix with genes + HTO features ✅
- **Samples processed**: 87/87 samples completed ✅
- **Total compute time**: ~520 CPU hours ✅

**Output Structure:**
```
/fs/scratch/PAS2598/senes_raw/cellranger_multimodal/
├── NPSAD-147-A1/
│   └── outs/filtered_feature_bc_matrix/
│       ├── barcodes.tsv.gz     # Cell barcodes
│       ├── features.tsv.gz     # Genes + HTO barcodes
│       └── matrix.mtx.gz       # Combined count matrix
├── NPSAD-147-A2/
└── [85 more samples...]
```

## 🔬 **HTO Demultiplexing Strategy (CORRECTED)**

### **Key Updates Made:**
1. **✅ Path Corrections**: Fixed to use `cellranger_multimodal/` directory
2. **✅ Doublet Retention**: Script now keeps ALL cells (singlets + doublets)
3. **✅ Multimodal Input**: Handles combined gene + HTO matrices correctly

### **Updated HTODemux Workflow:**
```r
# Load multimodal data with both genes and HTOs
multimodal.data <- Read10X("cellranger_multimodal/SAMPLE/outs/filtered_feature_bc_matrix/")

# Create Seurat object with gene expression
pbmc <- CreateSeuratObject(multimodal.data$`Gene Expression`)

# Add HTO data as separate assay
pbmc[["HTO"]] <- CreateAssayObject(multimodal.data$`Antibody Capture`)

# Demultiplex using HTOs
pbmc <- HTODemux(pbmc, assay = "HTO")

# IMPORTANT: Retain ALL cells (singlets + doublets)
all_cells <- pbmc  # Keep everything, filter only negatives
```

### **Individual Donor Extraction (ENHANCED):**
1. **✅ Load multimodal Cell Ranger output** (genes + HTOs combined)
2. **✅ Map HTO barcodes to IndividualIDs** using NPS-AD metadata
3. **✅ Extract cells for each donor** (singlets + doublets)
4. **✅ Include full demographics** (age, sex, PMI, Braak scores)
5. **✅ Create individual H5/MTX files** for each donor
6. **✅ Retain doublet information** in metadata

### **Expected Final Dataset:**
- **~520 individual donor matrices** (from 87 samples)
- **Rich demographics**: Age at death, sex, PMI, pathology scores
- **Age range**: 26-100 years (based on metadata)
- **Cell counts**: ~1,000-8,000 cells per donor
- **Doublets included**: For downstream doublet analysis
- **Ready for population-scale senescence analysis**

## 📈 Quality Metrics Targets (UPDATED)

| Stage | Metric | Target | Expected |
|-------|--------|--------|----------|
| **Multimodal** | Gene features | ~36,000 | ✅ 36,601 |
| | HTO features | ~6 | ✅ 3-6 |
| | Total cells | ~5,000 | ✅ 3,000-50,000 |
| **Post-Demux** | Singlet rate | >70% | 70-85% |
| | Doublet rate | <15% | 5-15% |
| | **Cells retained** | **100%** | **Singlets + Doublets** |
| **Per Donor** | Cells recovered | >500 | 500-8,000 |
| | Genes per cell | >1,000 | 800-4,000 |

## 🚀 **Ready-to-Run Commands**

### **Run HTO demultiplexing on all samples:**
```bash
# Process all 87 samples with corrected demultiplexing
for sample in $(ls /fs/scratch/PAS2598/senes_raw/cellranger_multimodal/); do
    echo "Submitting: $sample"
    sbatch hto_demux_corrected.sh $sample
done
```

### **Monitor demultiplexing progress:**
```bash
# Check processing status
squeue -u $USER | grep hto_demux

# Check completed samples
ls /fs/scratch/PAS2598/senes_raw/demultiplexed_data/individual_donors/

# Count total donors extracted
find /fs/scratch/PAS2598/senes_raw/demultiplexed_data/individual_donors/ -name "*.h5" | wc -l
```

### **Verify doublet retention:**
```bash
# Check that doublets are retained in summary files
head /fs/scratch/PAS2598/senes_raw/demultiplexed_data/qc_reports/*_demux_summary.csv
```

## 💾 Resource Requirements

| Resource | Current | Post-Demux | Final Analysis |
|----------|---------|------------|----------------|
| **Storage** | ~6TB | ~8TB | ~12TB |
| **Processing** | ✅ Complete | 87 samples | 520 donors |
| **Memory** | 128GB/job | 128GB/job | 256GB+ |
| **Compute Time** | ✅ 520 hrs | ~350 CPU hrs | Variable |

## 🎯 Expected Scientific Impact

### **Study Power:**
- **Sample size**: ~520 individuals (unprecedented for sc-RNA-seq aging)
- **Age coverage**: 26-100 years for robust aging analysis  
- **Cell resolution**: ~3.4M cells total for rare cell type detection
- **Demographic richness**: Sex, race, APOE status, pathology scores
- **Doublet analysis**: Enabled by retaining doublet cells
- **Statistical power**: Large N for senescence marker validation

### **Key Analyses Enabled:**
- **Population-scale senescence patterns**
- **Age-stratified cell type analysis** 
- **Sex-specific aging effects**
- **APOE4 vs aging interactions**
- **Doublet-informed quality assessment**
- **Rare senescent cell identification**
- **Brain aging biomarker discovery**
- **Cellular senescence heterogeneity**

## 📞 Contact Information

- **👨‍🔬 Principal Investigator**: Sara Saez-Atienzar, PhD
- **👩‍💻 Data Analyst**: Gerald Gaitos, MD, MSc
- **🔗 Synapse Project**: [syn53254216](https://www.synapse.org/#!Synapse:syn53254216)
- **📧 Email**: gerald.gaitos@osumc.edu
- **🖥️ Platform**: Ohio Supercomputer Center (OSC)

---

<div align="center">

**🧬 Single-cell RNA-seq | 🧠 Brain Aging | 🔬 Senescence Research**

*Last Updated: September 2025 | Status: Phase 4 - HTO Demultiplexing Ready*

**Dataset: 87 Processed Samples | ~520 Individual Donors | ~3.4M Cells | Doublets Retained**

</div>

# 🧬 Single-cell RNA-seq Analysis of Brain Aging and Senescence

[![Project Status](https://img.shields.io/badge/Status-Multimodal%20Cell%20Ranger-orange)](https://github.com)
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
🧮 Cell Ranger Multimodal Processing (🔄 IN PROGRESS)
    ├── Multimodal Analysis → 📊 cDNA + HTO Combined Matrices
    ├── Gene Expression → 🧬 ~36K genes per sample
    └── HTO Features → 🏷️ ~6 HTO barcodes per sample
    ↓
🔬 HTO Demultiplexing (📋 NEXT)
    ├── HTODemux → 🧪 Individual Donor Assignment
    ├── Quality Filtering → 🔍 Remove Doublets/Negatives
    └── Donor Separation → 👤 ~678 Individual Matrices with Demographics
    ↓
📊 Data Integration (📋 PLANNED)
    ├── Age Metadata Mapping → 📅 Age for Each Donor
    ├── Quality Control → 📈 Cell/Gene Filtering
    └── Batch Effect Correction → ⚖️ Pool Harmonization
    ↓
📈 Senescence Analysis (📋 FUTURE)
    ├── Cell Type Identification → 🧠 Brain Cell Populations
    ├── Senescence Markers → ⏰ Age-Related Expression
    └── Population Analysis → 📊 Aging Patterns (n=678)
```

## 📊 Current Progress

### ✅ Completed
- [x] Multiplexed sample download (113 pools)
- [x] HTO barcode mapping metadata integration
- [x] FastQC quality assessment on raw data
- [x] MultiQC report generation and evaluation
- [x] fastp cleaning and quality trimming
- [x] Sample pairing analysis (cDNA ↔ HTO matching)
- [x] Cell Ranger summary analysis (87 paired samples identified)

### 🔄 In Progress  
- [ ] Cell Ranger multimodal processing (0/87 samples completed)
- [ ] Combined cDNA + HTO matrix generation per sample

### 📋 Next Steps (Critical Path)
- [ ] Complete multimodal Cell Ranger for all 87 paired samples
- [ ] Validate HTO feature integration in all outputs
- [ ] HTODemux: Separate pools into individual donors
- [ ] Extract ~520 individual donors with full demographics
- [ ] Quality control across individual donor matrices
- [ ] Batch effect correction across pools

## 🧮 Cell Ranger Processing Status

**CORRECTED Configuration:**
- **Processing approach**: Multimodal Cell Ranger 9.0.1
- **Input per sample**: cDNA + HTO processed together
- **Expected output per sample**: Single matrix with genes + HTO features
- **Processing time**: ~6 hours per sample
- **Total compute time**: ~520 CPU hours

**Previous Issue (RESOLVED):**
- ❌ Previously processed cDNA and HTO separately (incorrect)
- ✅ Now processing as multimodal (cDNA + HTO together) (correct)

**Output Structure:**
```
cellranger_multimodal/
├── NPSAD-147-A1/
│   └── outs/filtered_feature_bc_matrix/
│       ├── barcodes.tsv.gz     # Cell barcodes
│       ├── features.tsv.gz     # Genes + HTO barcodes
│       └── matrix.mtx.gz       # Combined count matrix
├── NPSAD-147-A2/
└── [85 more samples...]
```

## 🔬 Post-Demultiplexing Strategy

### **HTODemux Workflow (UPDATED):**
```r
# Load multimodal data with both genes and HTOs
pbmc <- Read10X("cellranger_multimodal/SAMPLE/outs/filtered_feature_bc_matrix/")
pbmc <- CreateSeuratObject(pbmc$`Gene Expression`)
pbmc[["HTO"]] <- CreateAssayObject(pbmc$`Antibody Capture`)

# Demultiplex using HTOs
pbmc <- HTODemux(pbmc, assay = "HTO")

# Expected output per pool:
table(pbmc$HTO_maxID)
# CTTATCACCGCTCAA  TGACGCCGTTGTTGT  GCCTAGTATGATCCA  
#      820              780              790
# AGTCACAGTATTCCA  TTCCTGCCATTACTA  CCGTACCTCATTGTT
#      800              760              820
```

### **Individual Donor Extraction (ENHANCED):**
1. **Load multimodal Cell Ranger output** (genes + HTOs combined)
2. **Map HTO barcodes to IndividualIDs** using NPS-AD metadata
3. **Extract cells for each donor** from pooled data  
4. **Include full demographics** (age, sex, PMI, Braak scores, APOE status)
5. **Create individual H5/MTX files** for each donor
6. **Quality filter each donor** separately

### **Expected Final Dataset:**
- **~520 individual donor matrices** (from 87 paired samples)
- **Rich demographics**: Age at death, sex, PMI, pathology scores
- **Age range**: 26-100 years (based on metadata)
- **Cell counts**: ~1,000-8,000 cells per donor
- **Ready for population-scale senescence analysis**

## 📈 Quality Metrics Targets

| Stage | Metric | Target | Expected |
|-------|--------|--------|----------|
| **Multimodal** | Gene features | ~36,000 | 36,601 |
| | HTO features | ~6 | 3-6 |
| | Total cells | ~5,000 | 3,000-50,000 |
| **Post-Demux** | Singlet rate | >70% | 70-85% |
| | Doublet rate | <15% | 5-15% |
| **Per Donor** | Cells recovered | >500 | 500-8,000 |
| | Genes per cell | >1,000 | 800-4,000 |

## 💾 Resource Requirements

| Resource | Current | Post-Demux | Final Analysis |
|----------|---------|------------|----------------|
| **Storage** | ~4TB | ~6TB | ~10TB |
| **Processing** | 87 samples | 520 donors | Population study |
| **Memory** | 128GB/job | 64GB/donor | 256GB+ |
| **Compute Time** | 520 CPU hrs | 200 CPU hrs | Variable |

## 🎯 Expected Scientific Impact

### **Study Power:**
- **Sample size**: ~520 individuals (unprecedented for sc-RNA-seq aging)
- **Age coverage**: 26-100 years for robust aging analysis  
- **Cell resolution**: ~2-3M cells total for rare cell type detection
- **Demographic richness**: Sex, race, APOE status, pathology scores
- **Statistical power**: Large N for senescence marker validation

### **Key Analyses Enabled:**
- **Population-scale senescence patterns**
- **Age-stratified cell type analysis** 
- **Sex-specific aging effects**
- **APOE4 vs aging interactions**
- **Rare senescent cell identification**
- **Brain aging biomarker discovery**
- **Cellular senescence heterogeneity**

## 🚀 Usage Instructions

### **Run multimodal Cell Ranger on all samples:**
```bash
# Process all 87 paired samples with multimodal approach
bash batch_multimodal_processing.sh
```

### **Monitor progress:**
```bash
# Check processing status
bash /fs/scratch/PAS2598/senes_raw/scripts/check_multimodal_progress.sh

# Verify HTO integration
zcat /fs/scratch/PAS2598/senes_raw/cellranger_multimodal/SAMPLE/outs/filtered_feature_bc_matrix/features.tsv.gz | grep "Antibody Capture"
```

### **Demultiplex individual donors:**
```bash
# Once multimodal processing completes
sbatch hto_demux.sh NPSAD-147-A1
```

## 📞 Contact Information

- **👨‍🔬 Principal Investigator**: Sara Saez-Atienzar, PhD
- **👩‍💻 Data Analyst**: Gerald Gaitos, MD, MSc
- **🔗 Synapse Project**: [syn53254216](https://www.synapse.org/#!Synapse:syn53254216)
- **📧 Email**: gerald.gaitos@osumc.edu
- **🖥️ Platform**: Ohio Supercomputer Center (OSC)

---

<div align="center">

**🧬 Single-cell RNA-seq | 🧠 Brain Aging | 🔬 Senescence Research**

*Last Updated: September 2025 | Status: Phase 3 - Multimodal Cell Ranger Processing*

**Dataset: 87 Paired Samples | ~520 Individual Donors | ~2.5M Cells**

</div>

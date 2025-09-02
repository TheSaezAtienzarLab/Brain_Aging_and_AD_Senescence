# 🧬 Single-cell RNA-seq Analysis of Brain Aging and Senescence

[![Project Status](https://img.shields.io/badge/Status-Cell%20Ranger%20Processing-green)](https://github.com)
[![Python](https://img.shields.io/badge/Python-3.10-blue)](https://www.python.org/)
[![Cell Ranger](https://img.shields.io/badge/Cell%20Ranger-7.2.0-green)](https://support.10xgenomics.com/single-cell-gene-expression/software/overview/welcome)
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
🧮 Cell Ranger Processing (🔄 IN PROGRESS)
    ├── Per-Pool Processing → 📊 Count Matrices
    ├── cDNA Libraries → 🧬 Gene Expression (~20K genes)
    └── HTO Libraries → 🏷️ Hashtag Oligo Counts (~6 HTOs)
    ↓
🔬 HTO Demultiplexing (📋 NEXT)
    ├── HTODemux → 🧪 Individual Donor Assignment
    ├── Quality Filtering → 🔍 Remove Doublets/Negatives
    └── Donor Separation → 👤 ~678 Individual Matrices
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

### 🔄 In Progress  
- [ ] Cell Ranger processing (0/113 pools completed)
- [ ] Count matrix generation for each pool

### 📋 Next Steps (Critical Path)
- [ ] Complete Cell Ranger for all 113 pools
- [ ] HTODemux: Separate pools into individual donors
- [ ] Map HTO barcodes to IndividualIDs using metadata
- [ ] Integrate age/demographic data for ~678 donors
- [ ] Quality control across individual donor matrices
- [ ] Batch effect correction across pools

## 🧮 Cell Ranger Processing Status

**Current Configuration:**
- **Processing unit**: 1 pool = 1 Cell Ranger job
- **Input per pool**: cDNA + HTO paired libraries
- **Expected output per pool**: 2 count matrices (mixed donors)
- **Processing time**: ~4 hours per pool
- **Total compute time**: ~450 CPU hours

**Output Structure:**
```
cellranger_results/
├── cDNA/
│   ├── NPSAD-147-A1/    # Pool A1 - mixed 6 donors
│   ├── NPSAD-147-A2/    # Pool A2 - mixed 6 donors
│   └── [111 more pools...]
└── HTO/
    ├── NPSAD-147-A1/    # HTO counts for donor separation
    ├── NPSAD-147-A2/
    └── [111 more pools...]
```

## 🔬 Post-Demultiplexing Strategy

### **HTODemux Workflow:**
```r
# For each pool (e.g., NPSAD_147_A1)
pbmc <- HTODemux(pbmc, assay = "HTO")

# Expected output per pool:
table(pbmc$HTO_maxID)
# CTTATCACCGCTCAA  TGACGCCGTTGTTGT  GCCTAGTATGATCCA  
#      820              780              790
# AGTCACAGTATTCCA  TTCCTGCCATTACTA  CCGTACCTCATTGTT
#      800              760              820
```

### **Individual Donor Extraction:**
1. **Map HTO barcodes to IndividualIDs** using metadata table
2. **Extract cells for each donor** from pooled data
3. **Create individual count matrices** (one per donor)
4. **Quality filter each donor** separately
5. **Integrate age metadata** for senescence analysis

### **Expected Final Dataset:**
- **~678 individual donor matrices**
- **Age range**: Likely 50-100+ years
- **Cell counts**: ~3,000-8,000 cells per donor
- **Ready for population-scale senescence analysis**

## 📈 Quality Metrics Targets

| Stage | Metric | Target | Expected |
|-------|--------|--------|----------|
| **Per Pool** | Estimated cells | ~5,000 | 3,000-8,000 |
| | Reads per cell | >20,000 | 15,000-50,000 |
| **Post-Demux** | Singlet rate | >70% | 70-85% |
| | Doublet rate | <15% | 5-15% |
| **Per Donor** | Cells recovered | >1,000 | 500-2,000 |
| | Genes per cell | >1,000 | 800-3,000 |

## 💾 Resource Requirements

| Resource | Current | Post-Demux | Final Analysis |
|----------|---------|------------|----------------|
| **Storage** | ~3TB | ~5TB | ~8TB |
| **Processing** | 113 pools | 678 donors | Population study |
| **Memory** | 64GB/job | 32GB/donor | 128GB+ |
| **Compute Time** | 450 CPU hrs | 200 CPU hrs | Variable |

## 🎯 Expected Scientific Impact

### **Study Power:**
- **Sample size**: ~678 individuals (unprecedented for sc-RNA-seq aging)
- **Age coverage**: Broad age range for robust aging analysis
- **Cell resolution**: ~3.4M cells total for rare cell type detection
- **Statistical power**: Large N for senescence marker validation

### **Key Analyses Enabled:**
- **Population-scale senescence patterns**
- **Age-stratified cell type analysis**
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

*Last Updated: September 2025 | Status: Phase 3 - Cell Ranger Processing*

**Dataset: 113 Multiplexed Pools | ~678 Individual Donors | ~3.4M Cells**

</div>

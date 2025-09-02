# 🧬 Single-cell RNA-seq Analysis of Brain Aging and Senescence

[![Project Status](https://img.shields.io/badge/Status-Cell%20Ranger%20Processing-green)](https://github.com)
[![Python](https://img.shields.io/badge/Python-3.10-blue)](https://www.python.org/)
[![Cell Ranger](https://img.shields.io/badge/Cell%20Ranger-7.2.0-green)](https://support.10xgenomics.com/single-cell-gene-expression/software/overview/welcome)
[![Reference](https://img.shields.io/badge/Reference-GRCh38--2020--A-orange)](https://www.10xgenomics.com/)

> **Investigating cellular senescence patterns in aging human brain tissue using single-cell RNA sequencing as a baseline for future case-control studies.**

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Study Design](#-study-design)
- [Environment Requirements](#-environment-requirements)
- [Analysis Workflow](#-analysis-workflow)
- [Current Progress](#-current-progress)
- [Sample Selection Details](#-sample-selection-details)
- [Contact Information](#-contact-information)

## 🎯 Project Overview

**Objective**: Investigate cellular senescence patterns in aging human brain tissue using single-cell RNA sequencing as a baseline for future case-control studies.

### 🔬 Study Design

| Parameter | Value |
|-----------|-------|
| **Tissue** | Human prefrontal cortex |
| **Sample Type** | Healthy aging controls |
| **Final Sample Size** | n=113 (paired samples) |
| **Original Dataset** | n=195 (reduced to paired samples only) |
| **Technology** | Single-cell RNA-seq with HTO multiplexing |
| **Exclusion Criteria** | CERAD or BRAAK scores >0 |
| **Reference Genome** | hg38/GRCh38-2020-A |
| **Data Source** | [Synapse syn53254216](https://www.synapse.org/#!Synapse:syn53254216) |

## 🛠️ Environment Requirements

- **Computing Platform**: Ohio Supercomputer Center (OSC) HPC
- **Memory**: 64GB RAM for Cell Ranger processing
- **Storage**: ~3TB total (2TB raw + 1TB processed)
- **Dependencies**: Cell Ranger 7.2.0, FastQC, fastp, MultiQC, Scanpy

## 🔄 Analysis Workflow

```
📊 Raw Fastq Data (✅ COMPLETED)
    ↓
🔍 Quality Control Assessment (✅ COMPLETED)
    ├── FastQC → 📈 Per-Sample Quality Reports
    ├── MultiQC → 📋 Aggregated QC Summary
    └── Quality Metrics → 📊 Sample Assessment
    ↓
✨ Fastq Cleaning (✅ COMPLETED)
    ├── fastp Processing → 🧹 Adapter/Quality Trimming
    └── Post-Cleaning QC → ✅ Quality Improvement Validated
    ↓
🧮 Cell Ranger Processing (🔄 IN PROGRESS)
    ├── Count Matrix Generation → 📊 Gene × Cell Counts
    ├── cDNA Library Processing → 🧬 Gene Expression Data
    └── HTO Library Processing → 🏷️ Hashtag Oligo Data
    ↓
🔬 HTO Demultiplexing (📋 NEXT)
    ├── HashSolo Processing → 🧪 Sample Assignment
    ├── Cell Quality Filtering → 🔍 Remove Doublets/Negatives
    └── Sample Separation → 🏷️ Individual Sample Matrices
    ↓
📈 Senescence Analysis (📋 PLANNED)
    ├── Cell Type Identification → 🧠 Brain Cell Populations
    ├── Senescence Markers → ⏰ Aging-Related Gene Expression
    └── Age Correlation Analysis → 📊 Senescence Patterns
```

## 📊 Current Progress

### ✅ Completed
- [x] Sample selection and metadata curation
- [x] Synapse data download setup
- [x] Raw fastq file download (original 195 samples)
- [x] FastQC quality assessment on raw data
- [x] MultiQC report generation and quality evaluation
- [x] Fastq cleaning and filtering with fastp
- [x] Post-cleaning quality control validation
- [x] Sample pairing analysis (cDNA ↔ HTO matching)

### 🔄 In Progress  
- [ ] Cell Ranger count matrix generation (0/113 paired samples)
- [ ] cDNA library processing for gene expression
- [ ] HTO library processing for sample demultiplexing

### 📋 Next Steps
- [ ] Complete Cell Ranger processing for all 113 paired samples
- [ ] HTO demultiplexing using HashSolo or demuxlet
- [ ] Age metadata integration and distribution analysis
- [ ] Quality control of count matrices
- [ ] Cell type identification and annotation
- [ ] Senescence marker analysis

## 🔍 Sample Selection Details

### **From 195 to 113 Samples**

| Library Type | Files | Unique Samples | Status |
|--------------|-------|----------------|--------|
| **cDNA** | 226 files | 113 samples | ✅ Complete |
| **HTO** | 566 files | 283 samples | ⚠️ Subset used |
| **Paired** | 452 files | **113 samples** | ✅ **Final dataset** |

**Rationale for Sample Reduction:**
- Only samples with **both cDNA and HTO** libraries can be demultiplexed
- 113 samples have complete paired data required for downstream analysis
- Remaining 170 samples (283 HTO - 113 paired) lack cDNA libraries
- Quality over quantity approach for robust senescence analysis

### **Processing Statistics**

| Stage | Original | After QC | After Pairing | Success Rate |
|-------|----------|----------|---------------|--------------|
| **Raw Data** | 195 samples | - | - | 100% |
| **FastQ Trimming** | 195 samples | 113 cDNA + 283 HTO | - | Variable |
| **Library Pairing** | 396 total | 113 paired | **113 final** | **58% paired** |

## 🧮 Cell Ranger Processing

**Current Processing Status:**
- **Samples queued**: 113 paired samples
- **Expected output**: ~5,000 cells per sample (~565K total cells)
- **Processing time**: ~4 hours per sample
- **Total estimated time**: ~450 CPU hours

**Output Organization:**
```
cellranger_results/
├── cDNA/
│   ├── NPSAD-122-A1/
│   │   ├── outs/filtered_feature_bc_matrix/
│   │   ├── outs/web_summary.html
│   │   └── outs/metrics_summary.csv
│   └── [112 more samples...]
└── HTO/
    ├── NPSAD-122-A1/    # Matching sample name
    └── [112 more samples...]
```

## 📈 Expected Quality Metrics

| Metric | Target | Expected Range |
|--------|--------|----------------|
| **Estimated cells** | ~5,000 per sample | 3,000-8,000 |
| **Reads per cell** | >20,000 | 15,000-50,000 |
| **Genes per cell** | >1,000 | 800-3,000 |
| **Total genes detected** | >15,000 | 15,000-20,000 |
| **Mitochondrial %** | <20% | 5-15% |

## 💾 Resource Requirements

| Resource | Allocated | Usage |
|----------|-----------|-------|
| **Storage** | ~3TB total | 2TB raw + 1TB processed |
| **Memory** | 64GB per job | Cell Ranger processing |
| **CPU** | 16 cores per job | Parallel alignment |
| **Time** | 12 hours per job | Buffer for completion |
| **Jobs** | 113 concurrent | One per paired sample |

## 📌 Software Versions

| Tool | Version | Purpose |
|------|---------|---------|
| Python | 3.10 | Analysis environment |
| Cell Ranger | 7.2.0 | Single-cell processing |
| FastQC | 0.12.1 | Quality assessment |
| fastp | 0.23.4 | Read cleaning |
| MultiQC | 1.15 | Report aggregation |
| Reference | GRCh38-2020-A | Human genome |

## 🎯 Expected Outputs

### Current Phase (Cell Ranger)
- **📊 Count Matrices**: 113 × 2 = 226 count matrices (cDNA + HTO)
- **📈 QC Reports**: 226 Cell Ranger web summaries
- **📋 Metrics Files**: Processing and quality statistics
- **🏷️ HTO Data**: Hashtag oligo counts for demultiplexing

### Next Phases
- **🧪 Demultiplexed Data**: Individual sample assignments per cell
- **🔍 Quality Metrics**: Cell/sample statistics post-demultiplexing
- **⏰ Senescence Profiles**: Age-related expression patterns
- **🧠 Cell Type Annotations**: Brain-specific cell populations

## 🔮 Immediate Next Steps

1. **🧮 Complete Cell Ranger**: Process all 113 paired samples
2. **📊 Age Metadata**: Integrate age information for samples
3. **🔬 HTO Demultiplexing**: Use HashSolo for sample separation
4. **📈 Quality Assessment**: Evaluate Cell Ranger outputs
5. **🧠 Cell Type Annotation**: Identify brain cell populations
6. **⏰ Senescence Analysis**: Examine aging markers and patterns

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

**Final Dataset: 113 Paired Samples | ~565K Expected Cells**

</div>

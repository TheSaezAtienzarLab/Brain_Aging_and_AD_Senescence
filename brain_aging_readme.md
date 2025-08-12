# 🧬 Single-cell RNA-seq Analysis of Brain Aging and Senescence

[![Project Status](https://img.shields.io/badge/Status-Quality%20Control-yellow)](https://github.com)
[![Python](https://img.shields.io/badge/Python-3.10-blue)](https://www.python.org/)
[![Cell Ranger](https://img.shields.io/badge/Cell%20Ranger-7.2.0-green)](https://support.10xgenomics.com/single-cell-gene-expression/software/overview/welcome)
[![Reference](https://img.shields.io/badge/Reference-GRCh38--2020--A-orange)](https://www.10xgenomics.com/)

> **Investigating cellular senescence patterns in aging human brain tissue using single-cell RNA sequencing as a baseline for future case-control studies.**

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Study Design](#-study-design)
- [Environment Requirements](#-environment-requirements)
- [Analysis Workflow](#-analysis-workflow)
- [Quality Control](#-quality-control)
- [Current Progress](#-current-progress)
- [Contact Information](#-contact-information)

## 🎯 Project Overview

**Objective**: Investigate cellular senescence patterns in aging human brain tissue using single-cell RNA sequencing as a baseline for future case-control studies.

### 🔬 Study Design

| Parameter | Value |
|-----------|-------|
| **Tissue** | Human prefrontal cortex |
| **Sample Type** | Healthy aging controls |
| **Sample Size** | n=195 |
| **Technology** | Single-cell RNA-seq with HTO multiplexing |
| **Exclusion Criteria** | CERAD or BRAAK scores >0 |
| **Reference Genome** | hg38/GRCh38-2020-A |
| **Data Source** | [Synapse syn53254216](https://www.synapse.org/#!Synapse:syn53254216) |

## 🛠️ Environment Requirements

- **Computing Platform**: Ohio Supercomputer Center (OSC) HPC
- **Memory**: >64GB RAM for Cell Ranger processing
- **Storage**: ~3TB total (2TB raw + 1TB processed)
- **Dependencies**: Conda environments with FastQC, fastp, MultiQC, Cell Ranger, Scanpy

## 🔄 Analysis Workflow

```
📊 Raw Fastq Data (✅ DOWNLOADED)
    ↓
🔍 Quality Control Assessment (🔄 IN PROGRESS)
    ├── FastQC → 📈 Per-Sample Quality Reports
    ├── MultiQC → 📋 Aggregated QC Summary
    └── Quality Metrics → 📊 Sample Assessment
    ↓
✨ Fastq Cleaning (📋 PLANNED)
    ├── fastp Processing → 🧹 Adapter/Quality Trimming
    └── Post-Cleaning QC → ✅ Improvement Validation
    ↓
🧮 Cell Ranger Processing (📋 PLANNED)
    ├── Count Matrix Generation → 📊 Gene × Cell Counts
    ├── HTO Demultiplexing → 🏷️ Sample Separation
    └── Quality Filtering → 🔍 Cell/Gene Selection
    ↓
📈 Senescence Analysis (📋 FUTURE)
    ├── Cell Type Identification → 🧠 Brain Cell Populations
    ├── Senescence Markers → ⏰ Aging-Related Genes
    └── Age Correlation Analysis → 📊 Expression Patterns
```

## 🔍 Quality Control

### 📊 MultiQC Reporting

MultiQC aggregates QC results from multiple tools and samples into a single interactive HTML report:

- ✅ Comparing quality across all 195 samples
- ✅ Identifying batch effects or problematic samples  
- ✅ Tracking improvements after cleaning
- ✅ Generating publication-ready QC summaries

### 📈 Key Metrics to Monitor

| Stage | Metric | Target |
|-------|--------|--------|
| **Fastq QC** | Per-base quality | >Q20 |
| | Adapter content | <5% after cleaning |
| | GC content | ~45% (human transcriptome) |
| **Cell Ranger** | Estimated cells | ~5,000 per sample |
| | Reads per cell | >20,000 |
| | Genes per cell | >1,000 |
| | Total genes | >15,000 |

### 🔧 FastQC Processing Parameters

**For cDNA libraries (gene expression):**
```bash
fastp \
    --in1 ${R1_FILE} --in2 ${R2_FILE} \
    --out1 ${CLEAN_R1} --out2 ${CLEAN_R2} \
    --detect_adapter_for_pe \
    --qualified_quality_phred 20 \
    --unqualified_percent_limit 40 \
    --n_base_limit 5 \
    --length_required 20 \
    --low_complexity_filter \
    --complexity_threshold 30 \
    --overrepresentation_analysis \
    --thread 4
```

**For HTO libraries (more permissive):**
```bash
fastp \
    --in1 ${R1_FILE} --in2 ${R2_FILE} \
    --out1 ${CLEAN_R1} --out2 ${CLEAN_R2} \
    --detect_adapter_for_pe \
    --qualified_quality_phred 15 \
    --unqualified_percent_limit 50 \
    --n_base_limit 10 \
    --length_required 15 \
    --thread 4
```

## 📊 Current Progress

### ✅ Completed
- [x] Sample selection and metadata curation
- [x] Synapse data download setup
- [x] Raw fastq file download (195 samples)

### 🔄 In Progress  
- [ ] FastQC quality assessment on raw data
- [ ] MultiQC report generation
- [ ] Quality metrics evaluation

### 📋 Planned
- [ ] Fastq cleaning and filtering with fastp
- [ ] Post-cleaning quality control validation
- [ ] Cell Ranger count matrix generation
- [ ] HTO demultiplexing and sample separation
- [ ] Downstream senescence analysis

## 💾 Resource Requirements

| Resource | Requirement | Usage |
|----------|-------------|-------|
| **Storage** | ~3TB total | 2TB raw + 1TB processed |
| **Memory** | 64GB RAM | Cell Ranger processing |
| **CPU** | 8-16 cores | Parallel processing |
| **Time** | 2-4 hours per sample | Cell Ranger |
| **Platform** | OSC HPC | High-performance computing |

## 📌 Software Versions

| Tool | Version | Purpose |
|------|---------|---------|
| Python | 3.10 | Analysis environment |
| FastQC | 0.12.1 | Quality assessment |
| fastp | 0.23.4 | Read cleaning |
| MultiQC | 1.15 | Report aggregation |
| Cell Ranger | 7.2.0 | Single-cell processing |
| Reference | GRCh38-2020-A | Human genome |

## 🎯 Expected Outputs

### Current Phase (QC)
- **📊 FastQC Reports**: ~780 HTML files (195 samples × 4 files)
- **📈 MultiQC Reports**: Aggregated quality summaries  
- **📋 Quality Metrics**: Sample-level statistics

### Future Phases
- **🧮 Count Matrices**: Cell × gene expression data
- **🏷️ HTO Results**: Demultiplexed sample assignments
- **📝 Processing Logs**: Detailed execution logs
- **⏰ Senescence Profiles**: Aging-related expression patterns

## 🔮 Next Steps

1. **📊 Complete FastQC**: Finish quality assessment of all 195 samples
2. **📈 Generate MultiQC**: Create comprehensive quality report
3. **🧹 Fastq Cleaning**: Apply fastp with optimized parameters
4. **🧮 Cell Ranger**: Process cleaned fastq files to count matrices
5. **🏷️ HTO Demultiplexing**: Separate multiplexed samples
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

*Last Updated: August 2025 | Status: Phase 2 - Quality Control*

</div>
# 🧬 Single-cell RNA-seq Analysis of Brain Aging and Senescence

[![Project Status](https://img.shields.io/badge/Status-Data%20Download-yellow)](https://github.com)
[![Python](https://img.shields.io/badge/Python-3.10-blue)](https://www.python.org/)
[![Cell Ranger](https://img.shields.io/badge/Cell%20Ranger-7.2.0-green)](https://support.10xgenomics.com/single-cell-gene-expression/software/overview/welcome)
[![Reference](https://img.shields.io/badge/Reference-GRCh38--2020--A-orange)](https://www.10xgenomics.com/)
[![License](https://img.shields.io/badge/License-MIT-lightgrey)](LICENSE)

> **Investigating cellular senescence patterns in aging human brain tissue using single-cell RNA sequencing as a baseline for future case-control studies.**

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Study Design](#-study-design)
- [Directory Structure](#-directory-structure)
- [Installation](#-installation)
- [Workflow](#-workflow)
- [Quality Control](#-quality-control)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

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

## 📁 Directory Structure

```
/fs/scratch/PAS2598/senes_raw/
├── 🗂️ CONTROLS/                      # Raw fastq files by individualID
│   ├── AMPAD_HBCC_0000000003/
│   │   ├── *_cDNA_*_R1.fastq.gz     # 🧬 cDNA libraries (gene expression)
│   │   ├── *_cDNA_*_R2.fastq.gz
│   │   ├── *_HTO_*_R1.fastq.gz      # 🏷️ HTO libraries (demultiplexing)
│   │   └── *_HTO_*_R2.fastq.gz
│   └── download_summary.csv          # 📊 Download tracking
├── 🔍 QC/                            # Quality control reports
│   ├── fastqc_raw/                   # Pre-cleaning QC
│   ├── fastqc_clean/                 # Post-cleaning QC
│   └── multiqc_report.html           # Aggregated QC report
├── ✨ CLEANED/                        # Cleaned fastq files
├── 🧮 CELLRANGER/                     # Cell Ranger outputs
│   ├── reference/                    # Reference genome files
│   ├── counts/                       # Count matrices
│   └── aggregated/                   # Combined analysis
├── 📈 ANALYSIS/                       # Downstream analysis
├── 📝 LOGS/                          # Processing logs
├── 🔧 SCRIPTS/                       # Analysis scripts
└── 📋 METADATA/                      # Sample metadata
    └── healthy_controls.csv
```

## 🛠️ Installation

### Prerequisites

- [Conda/Miniconda](https://docs.conda.io/en/latest/miniconda.html)
- [Cell Ranger 7.2.0](https://support.10xgenomics.com/single-cell-gene-expression/software/downloads/latest)
- Access to HPC cluster with >64GB RAM

### Environment Setup

<details>
<summary>Click to expand installation commands</summary>

```bash
# Create conda environment
conda create -n senescence-analysis python=3.10
conda activate senescence-analysis

# Install core bioinformatics tools
conda install -c conda-forge -c bioconda \
    fastqc=0.12.1 \
    fastp=0.23.4 \
    multiqc=1.15 \
    samtools=1.18 \
    pandas=2.1.0 \
    numpy=1.24.0 \
    jupyter=1.0.0

# Install Python packages
pip install synapseclient scanpy seaborn matplotlib

# Create Jupyter kernel
python -m ipykernel install --user --name=senescence-analysis --display-name="Senescence Analysis"
```

</details>

### Cell Ranger Installation

<details>
<summary>Click to expand Cell Ranger setup</summary>

```bash
# Download and install Cell Ranger 7.2.0
cd /fs/scratch/PAS2598/software/
wget -O cellranger-7.2.0.tar.gz \
    "https://cf.10xgenomics.com/releases/cell-exp/cellranger-7.2.0.tar.gz"
tar -zxvf cellranger-7.2.0.tar.gz

# Add to PATH
export PATH=/fs/scratch/PAS2598/software/cellranger-7.2.0:$PATH

# Download reference genome
cd /fs/scratch/PAS2598/senes_raw/CELLRANGER/reference/
wget https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-2020-A.tar.gz
tar -zxvf refdata-gex-GRCh38-2020-A.tar.gz
```

</details>

## 🔄 Workflow

### Phase 1: Data Acquisition
- [x] Sample selection and metadata curation
- [x] Synapse data download setup  
- [ ] Complete fastq file download (195 samples)

### Phase 2: Quality Control and Preprocessing
- [ ] Raw data quality assessment
- [ ] Fastq cleaning and filtering
- [ ] Post-cleaning quality control

### Phase 3: Single-cell Analysis  
- [ ] Cell Ranger processing
- [ ] HTO demultiplexing
- [ ] Quality filtering and normalization

### Phase 4: Senescence Analysis
- [ ] Cell type identification
- [ ] Senescence marker analysis
- [ ] Age-related expression patterns

## 🚀 Quick Start

### 1. Download Raw Data

```bash
conda activate senescence-analysis
cd /fs/scratch/PAS2598/senes_raw/
python synapse_fastq_downloader.py
```

### 2. Quality Control

```bash
# Raw data QC
mkdir -p QC/fastqc_raw
find CONTROLS/ -name "*.fastq.gz" | xargs -P 8 -I {} fastqc {} -o QC/fastqc_raw/

# Generate MultiQC report
multiqc QC/fastqc_raw/ -o QC/ -n multiqc_raw_report
```

### 3. Clean Fastq Files

<details>
<summary>Fastp parameters for single-cell data</summary>

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
    --json ${SAMPLE}_fastp.json \
    --html ${SAMPLE}_fastp.html \
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

</details>

### 4. Cell Ranger Processing

```bash
cellranger count \
    --id=${SAMPLE_ID} \
    --transcriptome=CELLRANGER/reference/refdata-gex-GRCh38-2020-A \
    --fastqs=CLEANED/${INDIVIDUAL_ID}/ \
    --sample=${SAMPLE_PREFIX} \
    --expect-cells=5000 \
    --localcores=8 \
    --localmem=64
```

## 🔍 Quality Control

### 📊 What is MultiQC?

MultiQC aggregates QC results from multiple tools and samples into a single interactive HTML report. **Essential for**:

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

## 💾 Resource Requirements

| Resource | Requirement |
|----------|-------------|
| **Storage** | ~3TB total (2TB raw + 1TB processed) |
| **Memory** | 64GB RAM (Cell Ranger) |
| **CPU** | 8-16 cores recommended |
| **Time** | 2-4 hours per sample (Cell Ranger) |

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

- **📊 FastQC Reports**: ~780 HTML files (pre/post cleaning)
- **📈 MultiQC Reports**: Aggregated quality summaries  
- **🧮 Count Matrices**: Cell × gene expression data
- **📝 Processing Logs**: Detailed execution logs
- **🔍 QC Metrics**: Sample-level quality statistics

## 🔮 Next Steps

1. **🧬 HTO Demultiplexing**: Separate multiplexed samples
2. **🏷️ Cell Type Annotation**: Identify brain cell populations  
3. **⏳ Senescence Analysis**: Examine aging markers
4. **📊 Statistical Analysis**: Age-expression correlations
5. **🔬 Case-Control Prep**: Establish disease comparison baseline

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/analysis-improvement`)
3. Commit changes (`git commit -am 'Add new analysis method'`)
4. Push to branch (`git push origin feature/analysis-improvement`)
5. Create a Pull Request

## 📞 Contact

- **👨‍🔬 Principal Investigator**: Sara Saez-Atienzar, PhD
- **👩‍💻 Data Analyst**: Gerald Gaitos, MD, MSc
- **🔗 Synapse Project**: [syn53254216](https://www.synapse.org/#!Synapse:syn53254216)
- **📧 Email**: gerald.gaitos@osumc.edu

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**🧬 Single-cell RNA-seq | 🧠 Brain Aging | 🔬 Senescence Research**

*Last Updated: January 2025 | Status: Phase 1 - Data Download*

</div>

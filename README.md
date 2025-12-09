# Cellular Senescence Analysis in Aging and Alzheimer's Disease

> Multi-cohort single-nucleus RNA-seq meta-analysis for identifying and characterizing senescent cells in human brain tissue across aging and Alzheimer's disease.

## Overview

This repository contains analytical methods for a comprehensive discovery-replication study of cellular senescence in human brain using single-nucleus RNA sequencing. The pipeline integrates tissue-specific senescence scoring, differential proportion analysis, cross-cohort meta-analysis, and multi-level statistical modeling to characterize senescent cell populations across independent cohorts.

## Multi-Cohort Study Design

### Discovery Cohorts (PsychAD Consortium)

**Aging Discovery**
- **Source**: PsychAD Consortium ([Synapse: syn60084804](https://doi.org/10.7303/syn60084804))
- **Tissue**: Dorsolateral prefrontal cortex (DLPFC)
- **Samples**: 124 donors
- **Age groups**: 7 groups (20-29, 30-39, 40-49, 50-59, 60-69, 70-79, >80 years)
- **Scale**: ~500K nuclei

**AD Discovery**
- **Source**: PsychAD Consortium
- **Tissue**: Dorsolateral prefrontal cortex (DLPFC)
- **Samples**: 172 donors
- **Study groups**: Young_Control, Old_Control, Old_Cases (age ≥60 for old groups)
- **Scale**: ~700K nuclei

### Replication Cohorts

**Aging Replication: PsychENCODE**
- **Source**: PsychENCODE Consortium
- **Tissue**: Dorsolateral prefrontal cortex (DLPFC)
- **Samples**: 69 donors (stratified random sampling for age/sex balance)
- **Age groups**: 30-39 through >80 years
- **Scale**: ~500K nuclei

**AD Replication: Mathys et al.**
- **Source**: Mathys et al. (2019) - [Synapse: syn18681734](https://www.synapse.org/#!Synapse:syn18681734)
- **Tissue**: Frontal cortex (FCX)
- **Samples**: 30 donors (late 70s+)
- **Diagnosis**: NCI, MCI, AD, Other dementia
- **Scale**: ~70K nuclei

**AD Validation: Australian Brain Bank**
- **Source**: Australian Brain Bank
- **Tissue**: Parietal cortex
- **Samples**: 71 donors (age 24-93, mean 69.7y)
- **Groups**: AD (n=32), Control (n=39)
- **Sex-balanced**: 52% Male, 48% Female
- **Note**: Analyzed separately due to different cortical region

## Analysis Pipeline

### 1. **Data Preprocessing** (All Cohorts)
- Quality control and filtering (Scanpy v1.9)
- Batch correction using Harmony (donor-level)
- Normalization: 10,000 counts/cell + log transformation
- Dimensionality reduction (PCA: 50 components, UMAP)
- Cell type annotation using canonical markers

### 2. **Senescence Identification** (All Cohorts)
- **SenePy (v1.0+)**: Hippocampus-specific senescence gene modules
- Cell-type and sex-specific scoring
- Threshold-based classification: mean + 2SD from youngest age group
- Validation using canonical senescence markers and pathway correlation

### 3. **Pan-Cell Type Screening** (Discovery Only)
- Initial senescence assessment across all major cell types
- Identified elevated senescence in glial populations
- **Selected for downstream analysis**: Microglia, Astrocytes, OPCs

### 4. **Cell Type Subclustering** (All Cohorts)
- **Microglia subclustering**: Leiden clustering + marker-based annotation
  - States: Homeostatic, IFN-I/II/III, MHCII, Neuronal Surveillance, Stress
  - Markers from Saez-Atienzar et al. (2024)
- **Astrocyte subclustering**: Leiden clustering + functional state annotation

### 5. **Differential Proportion Analysis** (All Cohorts)
- **Method**: Cube root transformation + GLM (Gaussian family)
- **Covariates**: Sex + Cohort
- **Two-level analysis**:
  1. Cell type composition across study groups
  2. Senescence proportion within cell types
- **Multiple testing**: Benjamini-Hochberg FDR correction

### 6. **Cross-Cohort Meta-Analysis**
- **Aging meta-analysis**: PsychAD + PsychENCODE (both DLPFC)
- **AD meta-analysis**: PsychAD + Mathys (both frontal cortex)
- **Method**: DerSimonian-Laird random-effects model
- **Weighting**: Inverse-variance
- **Heterogeneity**: Cochran's Q, I², τ²
- **Outputs**: Forest plots with individual study contributions

### 7. **Transcriptional Analysis** (Discovery Only)
- **Coefficient of variation (CV)**: Transcriptional heterogeneity analysis
- **Mixed-effects modeling**: Senescence probability with donor random effects
- **Pseudobulk aggregation**: Seurat::AggregateExpression by donor × cell type × senescence state

### 8. **Variance Decomposition** (Discovery Only)
- **variancePartition**: Quantifying biological vs technical variance
- **Gene set**: SenePy hippocampus-specific senescence genes
- **Formula**: 8 scaled continuous covariates + 5 random effects
  - Fixed: MT%, ribo%, PMI, age, senescence score, n_genes, Hb%, n_cells
  - Random: Study_Group, Cohort, Sample, Cluster, Sex

### 9. **Differential Gene Expression** (Discovery Only)
- **Method**: DESeq2 via Seurat::FindMarkers on pseudobulk data
- **Covariates**: Sex + Cohort (latent.vars)
- **Four comparison types per cell type**:
  1. Universal senescence: All SnC vs All Non-SnC
  2. Aging senescence: Old_Control SnC vs Young_Control SnC
  3. Aging non-senescent: Old_Control Non-SnC vs Young_Control Non-SnC
  4. Disease senescence: Old_Cases SnC vs Old_Control SnC
- **Threshold**: p_adj < 0.05 (Benjamini-Hochberg FDR)

### 10. **DEG Signature Validation** (Discovery Only)
- **Comparison of SnC DEGs against established signatures**:
  - Universal aging hallmarks: DDR, oxidative stress, mitochondrial dysfunction, neuroinflammation, autophagy, cell cycle arrest
  - SASP factors: IL6, IL1A/B, TNF, CCL2, CXCL1, MMPs
  - Cell-type-specific aging markers:
    - Microglia: CD68, APOE, TREM2, C1Q genes, SPP1, GPNMB
    - Astrocytes: GFAP, VIM, S100B, SERPINA3, CHI3L1, OSMR
    - OPCs: PDGFRA, CSPG4, TNR, aging-associated markers

### 11. **Pathway Enrichment** (Discovery Only)
- **SCPA**: Single-cell pathway analysis
- **Databases**: Reactome + KEGG (via msigdbr)
- **Comparison**: SnC vs Non-SnC pathway activity
- **Visualization**: Sankey plots showing pathway relationships

## Software Requirements

### Core Packages

**Python (v3.10)**
```
scanpy >= 1.9
senepy >= 1.0
numpy
pandas
harmony-pytorch  # for batch correction
```

**R (v4.x)**
```
Seurat >= 5.0
DESeq2
variancePartition
lme4
SCPA
msigdbr
ComplexHeatmap
dplyr
ggplot2
ggpubr
rstatix
```

### Statistical Methods
- **Proportion transformation**: Cube root for bounded data
- **GLM**: Gaussian family with covariate adjustment
- **Meta-analysis**: DerSimonian-Laird random-effects
- **Mixed models**: glmer (binary), lmer (continuous)
- **Multiple testing**: Benjamini-Hochberg FDR correction throughout
- **Pairwise comparisons**: Wilcoxon rank-sum tests

## Key Methodological Features

### Multi-Cohort Meta-Analysis
- Discovery-replication design with independent cohorts
- Random-effects model accounting for between-study heterogeneity
- Region-specific meta-analysis (DLPFC aging, FCX for AD)
- Forest plots with heterogeneity metrics (I², τ²)

### Differential Proportion Analysis
- Handles bounded proportion data (0-100%)
- Cube root transformation for variance stabilization
- Separate testing for cell type composition and senescence burden
- Covariate adjustment for sex and cohort effects

### Tissue-Specific Senescence Scoring
- Hippocampus-specific gene modules (SenePy)
- Cell-type specific thresholding (mean + 2SD from young controls)
- Sex-aware scoring methodology
- Validation against canonical senescence markers

### Multi-Level Statistical Framework
- **Cell-level**: CV analysis, expression heterogeneity
- **Donor-level**: Pseudobulk aggregation for DEG analysis
- **Population-level**: Mixed-effects modeling with random effects
- **Cross-cohort**: Random-effects meta-analysis

## Reproducibility Standards

### Quality Control Thresholds
- **Cells**: ≥200 genes per cell
- **Genes**: ≥3 cells per gene
- **CV analysis**: ≥10 cells per group, ≥3 paired donors
- **Significance**: p_adj < 0.05 (FDR) across all analyses

### Batch Correction
- **Method**: Harmony integration
- **Batch variable**: Donor ID
- **PCA components**: 50
- **Clustering**: Leiden algorithm

### Covariate Adjustment
All analyses control for:
- **Biological**: Sex, Age, Study Group
- **Technical**: Cohort, QC metrics (MT%, ribo%, etc.)
- **Sample-level**: Donor random effects where appropriate

## Data Availability

### Discovery Data
- **PsychAD Consortium**: https://doi.org/10.7303/syn60084804
- **Access**: Synapse account required

### Replication Data
- **PsychENCODE**: Available through PsychENCODE portal
- **Mathys et al.**: https://www.synapse.org/#!Synapse:syn18681734
- **Australian Brain Bank**: Contact for access

### Analysis Code
- Available upon reasonable request
- Jupyter notebooks for preprocessing and scoring
- R scripts for statistical analysis and visualization

## Citation

If you use these methods, please cite:

**Microglial States:**
Saez-Atienzar et al. (2024). Exploring Cellular Heterogeneity: Single-Cell and Spatial Transcriptomics of Alzheimer Disease Brains and iPSC-Derived Microglia. Research Square. https://doi.org/10.21203/rs.3.rs-5045715/v1

**SenePy:**
Casella et al. (2023). SenePy: a Python library for single-cell senescence analysis.

**PsychAD Dataset:**
Fullard et al. (2025). Single-nucleus transcriptomic atlas of the human brain.
Lee et al. (2024). PsychAD Consortium data release.

**Mathys Dataset:**
Mathys et al. (2019). Single-cell transcriptomic analysis of Alzheimer's disease. Nature.

## Contact

- **Principal Investigator**: Sara Saez-Atienzar, PhD
- **Analyst**: Gerald Gaitos, MD, MSc
- **Institution**: Ohio State University
- **Email**: ggaitos@osumc.edu

---

**Study Design**: Discovery-Replication with Meta-Analysis  
**Total Cohorts**: 4 (PsychAD, PsychENCODE, Mathys, Australian Brain)  
**Total Samples**: 366 donors  
**Total Nuclei**: ~2M nuclei  
**Last Updated**: December 2025  
**Methods Version**: 2.0

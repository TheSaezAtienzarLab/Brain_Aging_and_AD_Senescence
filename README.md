# Cellular Senescence Analysis in Aging and Alzheimer's Disease

> Single-nucleus RNA-seq analysis pipeline for identifying and characterizing senescent cells in human brain tissue across aging and Alzheimer's disease cohorts.

## Overview

This repository contains the analytical methods for comprehensive single-nucleus RNA sequencing analysis of cellular senescence in the dorsolateral prefrontal cortex across aging and Alzheimer's disease. The pipeline integrates senescence scoring, differential proportion analysis, pseudobulk aggregation, and multi-level statistical modeling to characterize senescent cell populations.

## Dataset

- **Source**: PsychAD Consortium ([Synapse: syn60084804](https://doi.org/10.7303/syn60084804))
- **Technology**: Single-nucleus RNA-seq (snRNA-seq)
- **Tissue**: Dorsolateral prefrontal cortex (DLPFC)
- **Cohorts**: 
  - Aging cohort: 7 age groups (20-29 through >80 years)
  - AD cohort: Young_Control, Old_Control, Old_Cases
- **Scale**: 6.3M+ nuclei from 1,494 donors

## Analysis Pipeline

### 1. **Data Preprocessing**
- Quality control and filtering (Scanpy)
- Batch correction using Harmony
- Dimensionality reduction (PCA, UMAP)
- Cell type annotation and validation

### 2. **Senescence Identification**
- **SenePy**: Hippocampus-specific senescence scoring
- Cell-type and sex-specific thresholding
- Validation using canonical markers and correlation analysis

### 3. **Cell Type Selection**
- **Differential proportion analysis**: Cube root transformation + GLM
- Two-level testing:
  - Cell type composition across study groups
  - Senescence proportion within cell types
- Identified cell types: Microglia, Astrocytes, OPCs

### 4. **Transcriptional Analysis**
- **Coefficient of variation (CV)**: Transcriptional heterogeneity
- **Mixed-effects modeling**: Senescence probability with donor random effects
- **Pseudobulk aggregation**: Donor-level expression profiles

### 5. **Variance Decomposition**
- **variancePartition**: Quantifying biological vs technical variance
- Analysis on SenePy gene set
- 8 continuous + 5 random effect variables

### 6. **Differential Expression**
- **DESeq2**: Pseudobulk-level differential expression
- Four comparison types:
  1. Universal senescence (All SnC vs Non-SnC)
  2. Aging senescence (Old_Control SnC vs Young_Control SnC)
  3. Aging non-senescent (Old_Control Non-SnC vs Young_Control Non-SnC)
  4. Disease senescence (Old_Cases SnC vs Old_Control SnC)

### 7. **Pathway Analysis**
- **SCPA**: Single-cell pathway analysis
- Reactome and KEGG pathway databases (MSigDB)
- Visualization with Sankey plots

## Software Requirements

### Core Packages

**Python (v3.10)**
```
scanpy >= 1.9
senepy >= 1.0
numpy
pandas
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
```

### Statistical Methods
- **Transformation**: Cube root for proportions
- **GLM**: Gaussian family with Sex + Cohort covariates
- **Mixed models**: glmer (binary), lmer (continuous)
- **Multiple testing**: Benjamini-Hochberg FDR correction
- **Pairwise tests**: Wilcoxon rank-sum tests

## Key Features

### Differential Proportion Analysis
- Handles bounded proportion data (0-100%)
- Cube root transformation for variance stabilization
- Separate testing for composition and senescence

### Senescence Scoring
- Tissue-specific (hippocampus) gene modules
- Cell-type specific thresholding
- Sex-aware scoring methodology

### Multi-Level Statistical Framework
- Cell-level: CV analysis, expression patterns
- Donor-level: Pseudobulk aggregation
- Population-level: Mixed-effects modeling

## Reproducibility

### Quality Control Thresholds
- Cells: ≥200 genes per cell
- Genes: ≥3 cells per gene
- CV analysis: ≥10 cells per group, ≥3 paired donors
- Significance: p_adj < 0.05 (FDR)

### Batch Correction
- Harmony integration on donor ID
- 50 principal components retained
- Leiden clustering for cell type identification

### Covariate Adjustment
All analyses adjust for:
- Sex
- Cohort
- Technical covariates (QC metrics)

## File Structure

```
.
├── methods/
│   ├── final_methods_section.md          # Complete methods
│   └── supplementary_notes.md            # Additional details
├── scripts/
│   ├── preprocessing/                    # QC and normalization
│   ├── senescence_scoring/               # SenePy workflow
│   ├── differential_analysis/            # Proportion and expression
│   └── visualization/                    # Figure generation
└── data/
    ├── input/                            # Raw data location
    └── output/                           # Results and figures
```

## Usage

### 1. Preprocessing
```python
# Quality control and normalization
import scanpy as sc
adata = sc.read_h5ad("raw_data.h5ad")
sc.pp.filter_cells(adata, min_genes=200)
sc.pp.filter_genes(adata, min_cells=3)
sc.pp.normalize_total(adata, target_sum=1e4)
sc.pp.log1p(adata)
```

### 2. Senescence Scoring
```python
# SenePy scoring
import senepy as sp
hubs = sp.load_hubs(species='Human')
hippocampus_hubs = hubs.merge_hubs(['hippocampus'])
translator = sp.translator(adata)
sp.score_all_cells(adata, hubs=hippocampus_hubs, 
                   translator=translator, 
                   class_col='celltype', sex_col='sex')
```

### 3. Differential Analysis
```r
# Cube root transformation + GLM
data_long <- data %>%
  mutate(cuberoot = (proportion / 100)^(1/3))

model <- glm(cuberoot ~ Study_Group + Sex + Cohort, 
             data = data_long, 
             family = gaussian())
```

### 4. Pseudobulk DEG
```r
# Seurat pseudobulk aggregation
pseudo_data <- AggregateExpression(
  seurat_obj,
  group.by = c("Sample", "cluster", "Study_Group", 
               "hippocampus_SnC", "Sex", "Cohort"),
  assays = "RNA",
  return.seurat = TRUE
)

# DESeq2 analysis
markers <- FindMarkers(pseudo_data,
                      ident.1 = "SnC",
                      ident.2 = "Non-SnC",
                      test.use = "DESeq2",
                      latent.vars = c("Sex", "Cohort"))
```

## Citation

If you use these methods, please cite:

**SenePy:**
Casella et al. (2023). SenePy: a Python library for single-cell senescence analysis.

**PsychAD Dataset:**
Fullard et al. (2025). Single-nucleus transcriptomic atlas of the human brain.
Lee et al. (2024). PsychAD Consortium data release.

## Data Availability

Single-nucleus RNA-seq data are available from the PsychAD Consortium:
- **Synapse**: https://doi.org/10.7303/syn60084804

Analysis code is available upon request.

## Contact

- **Analyst**: Gerald Gaitos
- **Institution**: Ohio State University
- **Email**: [Your email]

---

**Pipeline Status**: Production  
**Last Updated**: November 2025  
**Methods Version**: 1.0

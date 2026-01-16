# Cellular Senescence in Brain Aging and Alzheimer's Disease

**Multi-cohort single-nucleus RNA-seq analysis examining cellular senescence patterns across aging and disease**

[![DOI](https://img.shields.io/badge/DOI-pending-blue)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Overview

This repository contains analysis code for a discovery-replication study investigating cellular senescence in human brain across aging and Alzheimer's disease using single-nucleus RNA-sequencing.

**Study Design:** Discovery (PsychAD) → Replication (PsychENCODE, Mathys) → Meta-Analysis

**Key Questions:**
1. Does cellular senescence increase with age in healthy brain?
2. Does Alzheimer's disease increase senescence beyond normal aging?
3. Which cell types show age- and disease-associated senescence?
4. Do cell type composition changes confound senescence patterns?

---

## Cohorts

| Cohort | Type | n | Age Range | Nuclei | Region |
|--------|------|---|-----------|--------|--------|
| PsychAD Aging | Aging | 124 | 20–90 | ~444K | DLPFC |
| PsychAD AD | Disease | 172 | 60+ | ~700K | DLPFC |
| PsychENCODE | Aging | 69 | 30–90 | ~472K | DLPFC |
| Mathys | Disease | 30 | 70+ | ~70K | FCX |

*Note: PsychAD Aging and PsychAD AD are subsets from the same consortium filtered by analysis type. The AD cohort includes young samples from the aging subset as comparison controls.*

---

## Repository Structure

```
├── scripts/
│   │
│   │ ─── SENESCENCE QUANTIFICATION ───
│   ├── 00_preprocessing.ipynb              # QC, normalization, batch correction
│   ├── 01_cellular_senescence_scoring.ipynb # SenePy scoring and thresholding
│   ├── 02_statistical_analysis.ipynb       # Demographics, composition, LMM, trends
│   ├── 02_5_probability_modeling.ipynb     # Logistic GLMM, Zero-Inflated Beta
│   ├── 03_meta_analysis.ipynb              # Cross-cohort meta-analysis
│   │
│   │ ─── DOWNSTREAM ANALYSIS ───
│   ├── 04_subsetting_conversion.ipynb      # Subsetting, format conversion, subclustering
│   ├── 05_deg_analysis.ipynb               # Pseudobulk DEG (DESeq2)
│   ├── 06_pathway_enrichment.ipynb         # SCPA + GSEApy pathway analysis (planned)
│   ├── 07_cell_communication.ipynb         # CellPhoneDB ligand-receptor (planned)
│   └── 08_expression_variability.ipynb     # CV + variance partition (planned)
│
├── session_info.txt
└── README.md
```

### Module Dependencies

```
00 → 01 → 02 → 02.5 → 03 → 04 → 05 → 06
                               ↘       ↘
                                07      08
```

---

## Statistical Framework

### Module 02: Cohort Characterization

**Cell Type Composition** — Tests whether proportions change with age/disease (potential confounder).
```
(Proportion)^(1/3) ~ Age + Sex + Cohort    [GLM per cell type]
```

**Senescence Proportion (LMM)** — Tests age/disease effect on %SnC per cell type.
```
%SnC ~ Age + Sex + Cohort + (1|Donor)      [LMM per cell type]
```

**Trend Analysis** — Compares models to characterize accumulation pattern across age bins or disease stages.
```
Models compared: ANOVA, Spearman, OLS Linear, Beta Regression, Log-Linear
Model selection: R²(Log-Linear) > R²(OLS) → Exponential; otherwise Linear
```

---

### Module 02.5: Probability Modeling

Advanced models for senescence probability using R (via rpy2).

**Part 1: Cell-Level (Logistic GLMM)** — Binary: Is this cell senescent?
```
is_senescent ~ Age_scaled + Sex + Cohort + (1|Donor)
Output: Odds Ratio per decade
```

**Part 2: Donor-Level (Zero-Inflated Beta)** — Continuous: What proportion are senescent?
```
prop ~ Age_scaled + Sex + Cohort           [Beta component]
zi   ~ Age_scaled + Sex + Cohort           [Zero-inflation component]
Output: exp(β) per decade
```

**Part 3: Group Comparisons** — Categorical comparisons when no continuous trend exists.
```
Mann-Whitney U: %SnC in Old vs Young (or AD vs Control)
Effect size: Cliff's delta
```

---

### Module 03: Meta-Analysis

Combines age effect estimates (β coefficients) from LMM across cohorts.

```
Method: DerSimonian-Laird random effects (primary)
        Fixed effects inverse-variance weighting (sensitivity)
Heterogeneity: I², Cochran's Q, τ²
Correction: FDR for multiple testing
```

---

## Methods Summary

### Data Processing
- **QC:** 200–8,000 genes/cell, <5% mitochondrial, ≥3 cells/gene
- **Normalization:** 10,000 counts/cell, log1p transform
- **Batch Correction:** Harmony (50 PCs)
- **Cell Types:** Harmonized across cohorts (Excitatory, Inhibitory, Astrocyte, Oligodendrocyte, OPC, Microglia, Endothelial, Pericyte, VSMC, VLMC, PVM, Adaptive)

### Senescence Scoring
- **Method:** SenePy (hippocampus modules)
- **Threshold:** Mean + 2SD (youngest group or controls)
- **Scoring:** Cell-type and sex-specific

### Downstream Analysis
- **Subsetting (04):** Format conversion (h5ad → Seurat), subclustering of Microglia (14 states, Harari Lab) and Astrocytes (7 states, Serrano-Pozo et al.)
- **DEG (05):** Pseudobulk DESeq2 (FDR < 0.05, |log₂FC| > 0.5), 6 comparisons per cell type:
  1. Old vs Young (all cells)
  2. SnC vs Non-SnC (all cells)
  3. Old vs Young (SnC only)
  4. Old vs Young (Non-SnC only)
  5. SnC vs Non-SnC (Old only)
  6. SnC vs Non-SnC (Young only)
- **Pathways (06):** SCPA + GSEApy (MSigDB, GO, KEGG, Reactome)
- **Communication (07):** CellPhoneDB (1,000 permutations)
- **Variance (08):** variancePartition decomposition

### Multiple Testing
- **Correction:** Benjamini-Hochberg FDR
- **Threshold:** FDR < 0.05

---

## Software

**Core Dependencies:**
- Python 3.10: scanpy, senepy, statsmodels, scipy, pandas
- R 4.x: lme4, glmmTMB, Seurat, DESeq2

**Complete versions:** See [`session_info.txt`](session_info.txt)

---

## Data Availability

- **PsychAD:** https://doi.org/10.7303/syn60084804
- **PsychENCODE:** https://psychencode.org
- **Mathys:** https://www.synapse.org/#!Synapse:syn18681734

---

## Citation

```bibtex
@article{gaitos2025senescence,
  title={Multi-Cohort Analysis of Cellular Senescence in Brain Aging 
         and Alzheimer's Disease},
  author={Gaitos, Gerald and Souza, Iara and Harari, Oscar and 
          Saez-Atienzar, Sara},
  journal={In preparation},
  year={2025}
}
```

<details>
<summary>Methods Citations</summary>

**SenePy:** Casella et al. 2023  
**PsychAD:** Fullard et al. 2024, Nature  
**Microglia States:** Garg et al. 2024, Research Square  
**Astrocyte States:** Serrano-Pozo et al. 2024, Nature Neuroscience  
**Mathys:** Mathys et al. 2019, Nature

</details>

---

## Contact

**Corresponding Author:** Sara Saez-Atienzar, PhD (Sara.SaezAtienzar@osumc.edu)

---

## License

**Code:** MIT License  
**Data:** Subject to consortium agreements

---

## Acknowledgments

**Data:** PsychAD, PsychENCODE, Mathys et al.  
**Computing:** Ohio Supercomputer Center

**Team:**
- Sara Saez-Atienzar, PhD (PI)
- Gerald Gaitos, MD, MSc
- Gabriel Duarte
- Jacob Morales
- Iara Souza, PhD
- Oscar Harari, PhD

---

<div align="center">

**The Ohio State University Wexner Medical Center**

Last Updated: January 2026

</div>

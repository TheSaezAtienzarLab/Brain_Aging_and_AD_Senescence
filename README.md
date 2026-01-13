# Cellular Senescence in Brain Aging and Alzheimer's Disease

**Multi-cohort single-nucleus RNA-seq analysis examining cellular senescence patterns across aging and disease**

[![DOI](https://img.shields.io/badge/DOI-pending-blue)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Overview

This repository contains analysis code for a discovery-replication study investigating cellular senescence in human brain across aging and Alzheimer's disease using single-nucleus RNA-sequencing.

**Study Design:** Discovery (PsychAD) → Replication (PsychENCODE, Mathys, Australian Brain) → Meta-Analysis

**Key Questions:**
1. Does cellular senescence increase with age in healthy brain?
2. Does Alzheimer's disease increase senescence beyond normal aging?
3. Which cell types show age- and disease-associated senescence?
4. Do cell type composition changes confound senescence patterns?

---

## Cohorts

| Cohort | n | Age | Condition | Region | Nuclei | Analysis |
|--------|---|-----|-----------|--------|--------|----------|
| PsychAD Aging | 124 | 20-80+ | Healthy aging | DLPFC | ~500K | Aging |
| PsychAD AD | 172 | 60+ | Control/AD | DLPFC | ~700K | Disease |
| PsychENCODE | 69 | 30-80+ | Healthy aging | DLPFC | ~500K | Aging |
| Mathys | 30 | 70+ | Control/MCI/AD | FCX | ~70K | Disease |
| Australian | 71 | 24-93 | Control/AD | Parietal | ~360K | Validation |

**Total:** 366 samples, ~2M nuclei

---

## Repository Structure
```
├── scripts/
│   │
│   │ ─── SENESCENCE QUANTIFICATION ───
│   ├── 00_preprocessing.ipynb          # QC, normalization, batch correction
│   ├── 01_senescence_scoring.ipynb     # SenePy scoring and thresholding
│   ├── 02_statistical_analysis.ipynb   # Demographics, composition, LMM, trends
│   ├── 02.5_probability_modeling.ipynb # Logistic GLMM, Zero-Inflated Beta, group comparisons
│   ├── 03_meta_analysis.ipynb          # Cross-cohort meta-analysis
│   │
│   │ ─── DOWNSTREAM ANALYSIS ───
│   ├── 04_subclustering.ipynb          # Cell-type subclustering & label transfer
│   ├── 05_deg_analysis.ipynb           # Pseudobulk DEG (DESeq2), visualization
│   ├── 06_pathway_enrichment.ipynb     # SCPA + GSEApy pathway analysis
│   ├── 07_cell_communication.ipynb     # CellPhoneDB ligand-receptor analysis
│   └── 08_expression_variability.ipynb # CV analysis + variance partition
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

## Statistical Framework for Senescence Analysis

### Module 02: Cohort Characterization

**Section 4: Cell Type Composition**

Tests whether cell type proportions change with age/disease (potential confounder).
```
# Cube root transformation for compositional data
(Proportion)^(1/3) ~ Age + Sex + Cohort    [GLM per cell type]
```

**Section 6: Senescence Proportion (LMM)**

Tests age/disease effect on %SnC per cell type with donor random effect.
```
%SnC ~ Age + Sex + Cohort + (1|Donor)      [LMM per cell type]
```

**Section 9: Study Group Trend Analysis**

Compares multiple models to characterize accumulation pattern across age bins or disease stages.
```
# Five models compared:
1. ANOVA         → Do groups differ at all?
2. Spearman      → Monotonic trend (non-parametric)
3. OLS Linear    → Linear accumulation (β = % per group)
4. Beta Regression → Bounded proportions (logit scale)
5. Log-Linear    → Exponential accumulation (fold-change)

# Model selection by R² comparison:
- R²(Log-Linear) > R²(OLS) → Exponential pattern
- R²(OLS) > R²(Log-Linear) → Linear pattern
```

**Section 11: Sex Interaction**

Tests whether age/disease effects differ between sexes.
```
%SnC ~ Age × Sex + Cohort + (1|Donor)      [LMM per cell type]
```

---

### Module 02.5: Probability Modeling

Advanced models for senescence probability using R (via rpy2).

**Part 1: Cell-Level Analysis (Logistic GLMM)**

Binary outcome: Is this cell senescent?
```
is_senescent ~ Age_scaled + Sex + Cohort + (1|Donor)

# Link function comparison:
- Logit   → Linear odds accumulation
- Cloglog → Exponential risk accumulation
```

**Part 2: Donor-Level Analysis (Zero-Inflated Beta)**

Continuous outcome: What proportion of cells are senescent?
```
# Two-component model:
prop ~ Age_scaled + Sex + Cohort           [Beta: among those with SnC > 0]
zi   ~ Age_scaled + Sex + Cohort           [Zero-inflation: P(SnC = 0)]

# Answers two questions:
1. Does P(having ANY senescent cells) change with age?
2. Among those with SnC, does proportion increase with age?
```

**Part 3: Group Comparisons (Categorical)**

Simple comparisons when no continuous trend exists, or for disease studies.
```
# Unadjusted
Wilcoxon rank-sum: %SnC in Old vs Young
Wilcoxon rank-sum: %SnC in AD vs Control
Effect size: Cliff's delta

# Adjusted (GLM)
prop_cuberoot ~ Age_Group + Sex + Cohort   [Aging: Old vs Young]
prop_cuberoot ~ Disease + Age + Sex + Cohort [Disease: AD vs Control]

# Adjusted (Cell-level Logistic GLMM)
is_senescent ~ Age_Group + Sex + Cohort + (1|Donor)
is_senescent ~ Disease + Age + Sex + Cohort + (1|Donor)
```

---

### Decision Framework
```
                    ┌─────────────────────────┐
                    │  Module 02 Section 9    │
                    │  Trend Analysis         │
                    └───────────┬─────────────┘
                                │
                    ┌───────────▼───────────┐
                    │  Significant trend?    │
                    └───────────┬───────────┘
                                │
              ┌─────────────────┴─────────────────┐
              │                                   │
              ▼ YES                               ▼ NO
    ┌─────────────────────┐             ┌─────────────────────┐
    │ Module 02.5         │             │ Module 02.5         │
    │ Part 1-2            │             │ Part 3              │
    │ Continuous models   │             │ Group comparisons   │
    │ (GLMM, ZI-Beta)     │             │ (Old vs Young)      │
    └─────────────────────┘             └─────────────────────┘
```

**For Disease Studies:** Always use Part 3 (categorical: AD vs Control)

---

## Methods Summary

### Data Processing
- **QC:** 200-8,000 genes/cell, <5% mitochondrial, ≥3 cells/gene
- **Normalization:** 10,000 counts/cell, log1p transform
- **Batch Correction:** Harmony (50 PCs)
- **Cell Types:** 12 major types via canonical markers

### Senescence Scoring
- **Method:** SenePy (hippocampus modules)
- **Threshold:** Mean + 2SD (youngest group or controls)
- **Scoring:** Cell-type and sex-specific

### Multiple Testing
- **Correction:** Benjamini-Hochberg FDR
- **Threshold:** FDR < 0.05

### Meta-Analysis (Module 03)
- **Method:** DerSimonian-Laird random effects
- **Aging:** PsychAD Aging + PsychENCODE
- **Disease:** PsychAD AD + Mathys

### Downstream Analysis
- **Subclustering (04):** scANVI label transfer (Garg, Serrano-Pozo references)
- **DEG (05):** Pseudobulk DESeq2 (6 comparisons per cell type)
- **Pathways (06):** SCPA + GSEApy (MSigDB, GO, KEGG, Reactome)
- **Communication (07):** CellPhoneDB (1,000 permutations)
- **Variance (08):** variancePartition decomposition

--

## Software

**Core Dependencies:**
- Python 3.10: scanpy, senepy, statsmodels, scipy, pandas
- R 4.x: lme4, glmmTMB, Seurat, DESeq2, variancePartition

**Complete versions:** See [`session_info.txt`](session_info.txt)

---

## Data Availability

- **PsychAD:** https://doi.org/10.7303/syn60084804
- **PsychENCODE:** https://psychencode.org
- **Mathys:** https://www.synapse.org/#!Synapse:syn18681734
- **Australian Brain Bank:** Contact for access

---

## Citation
```bibtex
@article{gaitos2025senescence,
  title={Multi-Cohort Analysis of Cellular Senescence in Brain Aging and Alzheimer's Disease},
  author={Gaitos, Gerald and Souza, Iara and Harari, Oscar and Saez-Atienzar, Sara},
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

**Analysis:** Gerald Gaitos (gerald.gaitos@osumc.edu)

---

## License

**Code:** MIT License  
**Data:** Subject to consortium agreements

---

## Acknowledgments

**Data:** PsychAD, PsychENCODE, Mathys et al., Australian Brain Bank  
**Computing:** Ohio Supercomputer Center

**Team:**
- Sara Saez-Atienzar, PhD (PI)
- Gerald Gaitos, MD, MSc
- Iara Souza, PhD
- Oscar Harari, PhD

---

<div align="center">

**The Ohio State University Wexner Medical Center**

Last Updated: January 2026

</div>

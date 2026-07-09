# Cellular Senescence in Brain Aging and Alzheimer's Disease

**Multi-cohort single-nucleus RNA-seq analysis examining cellular senescence patterns across aging and disease**

[![DOI](https://img.shields.io/badge/DOI-pending-blue)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Overview

This repository contains analysis code for a discovery-replication study investigating cellular senescence in human brain across aging and Alzheimer's disease using single-nucleus RNA-sequencing and spatial transcriptomics.

**Study Design:** Discovery (PsychAD) → Replication (PsychENCODE, Mathys) → Meta-Analysis → Downstream Characterization → Spatial Validation

**Key Questions:**
1. Does cellular senescence increase with age in healthy brain?
2. Does Alzheimer's disease increase senescence beyond normal aging?
3. Which cell types show age- and disease-associated senescence?
4. Do senescent cells show canonical hallmarks (cell-cycle arrest, pathway enrichment)?
5. Is microglial senescence distinct from disease-associated microglia (DAM) activation?
6. Do cell-type composition changes confound senescence patterns?

---

## Cohorts

### Main Cohorts (snRNA-seq)

| Cohort | Type | n | Age Range | Nuclei | Region |
|--------|------|---|-----------|--------|--------|
| PsychAD Aging | Aging | 124 | 20–90 | ~444K | DLPFC |
| PsychAD AD | Disease | 172 | 60+ | ~700K | DLPFC |
| PsychENCODE | Aging | 69 | 30–90 | ~472K | DLPFC |
| Mathys | Disease | 30 | 70+ | ~70K | FCX |

*Note: PsychAD Aging and PsychAD AD are subsets from the same consortium filtered by analysis type. The AD cohort includes young samples from the aging subset as comparison controls.*

### Spatial Cohorts (Visium)

| Cohort | Type | Region | Notes |
|--------|------|--------|-------|
| Morabito (Miyoshi & Morabito et al., *Nat Genet* 2024) | Sporadic AD + DSAD | Frontal cortex | SenePy scoring + hallmark module scoring; Cell2Location deconvolution (PsychAD reference) |
| Gate (van Olst et al., *Nat Med* 2025) | AN1792-immunized AD vs Control | Cortex | Cell-type deconvolution estimates from source publication |

---

## Repository Structure

```
├── scripts/
│   │
│   │ ─── SENESCENCE QUANTIFICATION ───
│   ├── 00_preprocessing.ipynb              # QC, normalization, batch correction
│   ├── 00.5_regression.ipynb               # UMI/SnC score regression; Pearson residuals correction
│   ├── 01_senescence_scoring.ipynb         # SenePy scoring and thresholding
│   ├── 02_statistical_analysis.ipynb       # Demographics, composition, proportion/burden/susceptibility models
│   ├── 03_meta_analysis.ipynb              # Cross-cohort DerSimonian-Laird random effects
│   │
│   │ ─── DOWNSTREAM ANALYSIS ───
│   ├── 04_subsetting_conversion.ipynb      # Subsetting, subclustering, microglial state scoring*
│   ├── 05_deg_analysis.ipynb               # Pseudobulk DEG (limma-voom)
│   ├── 06_gsea.ipynb                       # Pathway enrichment (GSEApy, Reactome)
│   ├── 07_variability.ipynb                # Transcriptional variability + variance partition
│   ├── 08_trajectory.ipynb                 # Slingshot pseudotime + SnC×DAM axis separability; pathology progression
│   ├── 09_senescence_enrichment_cell_cycle.ipynb  # Cell-cycle arrest + senescence module scoring (Aging + AD)
│   │
│   │ ─── SPATIAL TRANSCRIPTOMICS ───
│   ├── 10_spatial_morabito.ipynb           # Spatial senescence mapping — Morabito cohort
│   └── 10_spatial_gate.ipynb               # Spatial senescence mapping — Gate cohort
│
├── session_info.txt
└── README.md
```

*\*Module 04 outputs excluded from repository due to file size.*

### Module Dependencies

```
00 → 00.5 → 01 → 02 → 03 → 04 → 05 → 06
                          ↘         ↘
                           08        07
                                     ↘
                                      09
10 (spatial — parallel arm)
```

---

## Statistical Framework

> Full implementation details are documented within each script. This section summarizes key methodological decisions and their rationale.

---

### 🔬 Data Processing

| Step | Method | Rationale |
|------|--------|-----------|
| UMI correction | Pearson residuals regression | Senescence scores strongly correlate with sequencing depth in brain snRNA-seq; removed prior to all downstream analysis |
| Senescence scoring | SenePy hippocampus hub modules | SenePy provides a hippocampal reference hub, applied here to DLPFC/cortical tissue. Threshold: Mean + 2SD of youngest/control group, applied cell-type- and sex-specifically |
| Batch correction | Harmony (50 PCs) | Cross-cohort integration of DLPFC snRNA-seq data |
| Subclustering | Seurat + Harmony | Microglia · Astrocytes · OPCs subclustered and annotated to transcriptional states |

---

### 📊 Primary Statistics

Senescence was decomposed into three complementary donor-level measures — composition, burden, and susceptibility — each modeled separately for aging (continuous age) and disease (AD vs control).

| Measure | Model | Output |
|---------|-------|--------|
| Cell-type composition | Cube-root differential-proportion analysis (Garg et al., 2025): `Prop^(1/3) ~ Age or Disease + Sex + Cohort` | β per decade / per group, FDR |
| Senescent-cell burden (senescent cells of a type as a fraction of all cells) | Logistic GLMM: `is_burden ~ Age or Disease + Sex + Cohort + CT-Proportion + (1\|Donor)` | Odds ratio, FDR |
| Senescence susceptibility (senescent fraction within a type) | Logistic GLMM: `is_senescent ~ Age or Disease + Sex + Cohort + CT-Proportion + (1\|Donor)` | Odds ratio, FDR |
| Donor-level %SnC (complementary) | OLS + robust linear regression | β per decade / per group |

- Aging effects expressed as **OR per decade** (Age/10); disease effects as **OR vs control reference** (neurologically healthy controls).
- Cell-/state-proportion included as a covariate to adjust for compositional abundance (not sequencing depth, which is removed upstream via UMI-regressed scoring).
- Models fitted with `lme4`/`lmerTest`, `bobyqa` optimizer.

> ⚠️ **Pseudoreplication:** All tests use the donor — not the cell — as the unit of analysis via donor random effects.

---

### 🔁 Cross-Cohort Meta-Analysis

| Component | Approach |
|-----------|----------|
| Primary method | DerSimonian-Laird random effects |
| Sensitivity | Fixed-effects inverse-variance weighting |
| Heterogeneity | I², Cochran's Q, τ² |

Aging: PsychAD + PsychENCODE. AD: PsychAD + Mathys.

---

### 🧬 Downstream Characterization

| Module | Method | Details |
|--------|--------|---------|
| Microglial states | Marker-based scoring (`AddModuleScore`) | 5 transcriptional states: Homeostatic, ARM, IRM, Stress, DAM-like |
| DEG | Pseudobulk limma-voom | Multiple contrasts across aging and disease (including SnC×DAM quadrant-axis contrasts) |
| Pathway enrichment | GSEApy (prerank) | Reactome 2022 |
| Senescence vs DAM axis | Slingshot trajectory + quadrant analysis | Pseudotime on data-driven microglial subclusters; senescence and DAM scores overlaid and correlated (Spearman) to test axis separability |
| Pathology progression | Donor ordering by clinical severity | Program scores + %SnC z-scored/smoothed along disease-group → Braak → CDR ordering (Mathys) |
| Variability | variancePartition | Transcriptional variance decomposition |

---

### ✅ Senescence Validation

| Step | Method |
|------|--------|
| Canonical markers | Direct expression of p16 (CDKN2A) and p21 (CDKN1A) in senescent vs non-senescent cells |
| Cell-cycle arrest | Tirosh G1/S and G2/M module scoring |
| Senescence hallmarks | 10 curated Sloan et al. senescence-hallmark gene modules |
| Spatial validation | SenePy scoring on Visium (Morabito, Gate); spatial autocorrelation via Moran's I |

---

### 🔢 Multiple Testing

Benjamini-Hochberg FDR correction throughout — threshold **FDR < 0.05**.

---

## Software

All analyses performed using **Python 3.13.3** and **R 4.3.1**.

**Python:** NumPy, Pandas, SciPy, AnnData, ScanPy, SenePy, GSEApy, statsmodels, scikit-learn, rpy2, Cell2Location, myGene

**R:** Seurat, Harmony, slingshot, SingleCellExperiment, limma, edgeR, variancePartition, lme4, lmerTest, ggplot2

**Spatial:** Cell2Location (GPU required)

**Complete versions:** See [`session_info.txt`](session_info.txt)

---

## Data Availability

- **PsychAD:** https://doi.org/10.7303/syn60084804
- **PsychENCODE:** https://psychencode.org
- **Mathys:** https://www.synapse.org/#!Synapse:syn18681734
- **Morabito:** https://doi.org/10.1038/s41588-024-01961-x (GEO: GSE233208)
- **Gate:** https://doi.org/10.1038/s41591-025-03574-1 (GEO: GSE263038)

---

## Citation

```bibtex
@article{gaitos2026senescence,
  title={Multi-Cohort Analysis of Cellular Senescence in Brain Aging
         and Alzheimer's Disease},
  author={Gaitos, Gerald and Souza, Iara and Harari, Oscar and
          Saez-Atienzar, Sara},
  journal={In preparation},
  year={2026}
}
```

<details>
<summary>Methods Citations</summary>

**SenePy:** Casella et al. 2023
**PsychAD:** Lee, Roussos, Hoffman et al. (PsychAD Consortium) 2024
**Microglia States (DAM-like, Homeostatic):** Keren-Shaul et al. 2017, *Cell*
**Microglia States (ARM, IRM):** Sala Frigerio et al. 2019, *Cell Reports*
**Astrocyte States:** Serrano-Pozo et al. 2024, *Nature Neuroscience*
**Proportion Analysis:** Garg et al. 2025
**Mathys:** Mathys et al. 2019, *Nature*
**Senescence Enrichment:** Sloan et al. 2026, *Cell Genomics*
**Cell2Location:** Kleshchevnikov et al. 2022, *Nature Biotechnology*
**Morabito (Spatial AD):** Miyoshi, Morabito et al. 2024, *Nature Genetics* (DOI: 10.1038/s41588-024-01961-x)
**Gate (Spatial Immunization):** van Olst et al. 2025, *Nature Medicine* (DOI: 10.1038/s41591-025-03574-1)

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

**Data:** PsychAD, PsychENCODE, Mathys et al., Morabito et al., Gate et al.
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

Last Updated: July 2026

</div>

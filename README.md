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
4. Do senescent cells show canonical hallmarks (cell cycle arrest, pathway enrichment)?
5. Do cell type composition changes confound senescence patterns?

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
| Morabito (Miyoshi & Morabito et al., *Nat Genet* 2024) | Sporadic AD + DSAD | Frontal cortex | SenePy scoring + hallmark module scoring; cell type deconvolution from source |
| Gate (van Olst et al., *Nat Med* 2025) | AN1792-immunized AD vs Control | Cortex | Cell2Location deconvolution (PsychAD reference) |

---

## Repository Structure

```
├── scripts/
│   │
│   │ ─── SENESCENCE QUANTIFICATION ───
│   ├── 00_preprocessing.ipynb              # QC, normalization, batch correction
│   ├── 00.5_regression.ipynb               # UMI/SnC score regression; Pearson residuals correction
│   ├── 01_senescence_scoring.ipynb         # SenePy scoring and thresholding
│   ├── 02_statistical_analysis.ipynb       # Demographics, composition, LMM, trends, GLMM, Zero-Inflated Beta
│   ├── 03_meta_analysis.ipynb              # Cross-cohort DerSimonian-Laird random effects
│   │
│   │ ─── DOWNSTREAM ANALYSIS ───
│   ├── 04_subsetting_conversion.ipynb      # Subsetting, subclustering, subtype validation*
│   ├── 05_deg_analysis.ipynb               # Pseudobulk DEG (limma-voom)
│   ├── 06_gsea.ipynb                       # Pathway enrichment (GSEApy)
│   ├── 07_cell_communication.ipynb         # CellPhoneDB ligand-receptor (1,000 permutations)
│   ├── 08_variability.ipynb                # Transcriptional variability + variance partition
│   ├── 09_senescence_enrichment_cell_cycle.ipynb  # Cell cycle arrest + senescence module scoring (Aging + AD)
│   │
│   │ ─── SPATIAL TRANSCRIPTOMICS ───
│   ├── 10_spatial_morabito.ipynb           # Spatial senescence mapping — Morabito AD cohort
│   └── 10_spatial_gates.ipynb             # Spatial senescence mapping — Gates aging cohort
│
├── session_info.txt
└── README.md
```

*\*Module 04 outputs excluded from repository due to file size.*

### Module Dependencies

```
00 → 00.5 → 01 → 02 → 03 → 04 → 05 → 06
                          ↘        ↘
                           07       08
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
| Senescence scoring | SenePy hippocampus hub modules | Threshold: Mean + 2SD of youngest/control group, applied cell type- and sex-specifically |
| Batch correction | Harmony (50 PCs) | Cross-cohort integration of DLPFC snRNA-seq data |
| Subclustering | Seurat + Harmony | Microglia: 14 states · Astrocytes: 7 states · OPCs: 3 substates |

---

### 📊 Primary Statistics

| Question | Model | Output |
|----------|-------|--------|
| Does %SnC change with age/disease? | LMM: `%SnC ~ Age + Sex + Cohort + (1\|Donor)` | β per decade, FDR |
| Linear vs. exponential accumulation? | OLS vs. log-linear R² comparison | Trend shape per cell type |
| Cell-level senescence probability? | Logistic GLMM: `is_senescent ~ Age + Sex + Cohort + (1\|Donor)` | Odds ratio per decade |
| Donor-level proportion modeling? | Zero-Inflated Beta regression | exp(β) per decade |
| Categorical group differences? | Mann-Whitney U + Cliff's delta | Effect size (Old vs Young / AD vs Control) |

> ⚠️ **Pseudoreplication:** All tests use the donor — not the cell — as the unit of analysis.

---

### 🔁 Cross-Cohort Meta-Analysis

| Component | Approach |
|-----------|----------|
| Primary method | DerSimonian-Laird random effects |
| Sensitivity | Fixed-effects inverse-variance weighting |
| Heterogeneity | I², Cochran's Q, τ² |

---

### 🧬 Downstream Analysis

| Module | Method | Details |
|--------|--------|---------|
| DEG | Pseudobulk limma-voom | 6 comparisons per cell type × age group × senescence label |
| Pathway enrichment | GSEApy | MSigDB, GO, KEGG, Reactome |
| Cell communication | CellPhoneDB | 1,000 permutations |
| Variability | variancePartition | Transcriptional variance decomposition |
| Senescence validation | Module scoring + LMM | 10 gene lists + Tirosh cell cycle (G1/S/G2M); astrocytes & OPCs; aging + AD |

---

### ✅ Multiple Testing

Benjamini-Hochberg FDR correction throughout — threshold **FDR < 0.05**

---

## Software

**Core Dependencies:**
- Python 3.10: scanpy, senepy, statsmodels, scipy, pandas, omicverse
- R 4.x: lme4, lmerTest, glmmTMB, limma, edgeR, variancePartition

**Spatial:**
- cell2location (GPU required for Gates cohort)

**Complete versions:** See [`session_info.txt`](session_info.txt)

---

## Data Availability

- **PsychAD:** https://doi.org/10.7303/syn60084804
- **PsychENCODE:** https://psychencode.org
- **Mathys:** https://www.synapse.org/#!Synapse:syn18681734
- **Morabito:** https://doi.org/10.1038/s41588-024-01961-x (GEO: GSE233208)
- **Gates:** https://doi.org/10.1038/s41591-025-03574-1

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
**PsychAD:** Lee, Roussos, Hoffman et al. (PsychAD Consortium) 2024  
**Microglia States:** Garg et al. 2024, Research Square  
**Astrocyte States:** Serrano-Pozo et al. 2024, Nature Neuroscience  
**Mathys:** Mathys et al. 2019, Nature  
**Senescence Enrichment:** Sloan et al. 2026, Cell Genomics  
**Cell2Location:** Kleshchevnikov et al. 2022, Nature Biotechnology
**Morabito (Spatial AD):** Miyoshi, Morabito et al. 2024, Nature Genetics (DOI: 10.1038/s41588-024-01961-x)
**Gate (Spatial Immunization):** van Olst et al. 2025, Nature Medicine (DOI: 10.1038/s41591-025-03574-1)

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

**Data:** PsychAD, PsychENCODE, Mathys et al., Morabito et al., Gates et al.  
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

Last Updated: March 2026

</div>

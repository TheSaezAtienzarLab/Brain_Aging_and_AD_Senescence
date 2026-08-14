# Distinct cellular senescence landscapes characterize physiological aging and Alzheimer's disease

Figure code for a multi-cohort single-nucleus RNA-seq study of cellular senescence across human brain aging and Alzheimer's disease.

[![DOI](https://img.shields.io/badge/DOI-pending-blue)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Overview

Every published panel, regenerated from a released source-data table. One notebook per figure, one table per panel.

No individual-level data is redistributed. The tables in `results/` are the summarized values behind each figure, enough to redraw it and to check any number in the paper against the data it came from.

The analysis pipeline that produced these tables is not in this repository. It needs the primary snRNA-seq objects, which remain under consortium agreement.

---

## Structure

```
├── Main_Figure_1.ipynb           # 1C–1I
├── Main_Figure_2.ipynb           # 2A–2F
├── Main_Figure_3.ipynb           # 3A–3H
├── Main_Figure_4.ipynb           # 4A–4E
├── Main_Figure_5.ipynb           # 5A–5F
├── Supplementary_Figures.ipynb   # S1–S9
├── results/                      # source data, one table per panel
│   └── DEGs/                     # GSEA prerank tables behind Figure 5
└── figures/                      # rendered output
```

Each notebook opens with a settings cell defining rcParams, `PALETTES` and `color_for()`. Run it first, then any panel cell. Panel cells read only from `results/` and never open an `.h5ad` or `.rds`.

Python 3.13 with NumPy, Pandas, Matplotlib and SciPy. Nothing else.

---

## Cohorts

| Cohort | Type | n donors | Age range | Nuclei | Region |
|--------|------|---|-----------|--------|--------|
| PsychAD Aging | Aging | 124 | 20–90 | ~554K | DLPFC |
| PsychAD AD | Disease | 178 | 20–90 | ~717K | DLPFC |
| PsychENCODE | Aging | 69 | 30–90 | ~502K | DLPFC |
| Mathys | Disease | 36 | 70+ | ~70K | FCX |

PsychAD Aging and PsychAD AD are subsets of the same consortium filtered by analysis type. The AD subset is 81 AD + 81 age-matched controls + 16 young healthy controls.

Cohorts are discovery/replication within an arm, not independent tests. Results are pooled by random-effects meta-analysis with heterogeneity reported.

---

## Reading the numbers

**Senescence calls.** SenePy on analytic Pearson residuals, hippocampus hubs, cell-type and sex specific. A cell is senescent above mean + 2SD of the reference group — youngest age bin for aging, controls for disease — computed per cell type. Subclustered objects carry a state-aware recomputation, `is_senescent_state`, used by the astrocyte and OPC state panels. Each table records which call it used.

**Three measures**, donor as the unit of analysis. Age is scaled per decade. For AD, disease group is categorical with healthy controls as reference and age retained as a continuous covariate.

| Measure | Model |
|---|---|
| Susceptibility, cell level | `is_senescent[c∈type] ~ Age_dec + log10(counts+1) + Sex + Contributing Source + (1\|Donor)` |
| Susceptibility, donor level | `%SnC ~ Age_dec + Sex + Contributing Source + log10(counts+1)` |
| Burden | `is_burden[c∈all] ~ Age_dec + CT/State-Proportion_z + log10(counts+1) + Sex + Contributing Source + (1\|Donor)` |

Susceptibility is the proportion of senescent cells within a cell type or state, fitted as a logistic GLMM (`lme4`, binomial logit, donor random effect) and orthogonally as robust linear regression on donor %SnC. Burden is the proportion of senescent cells of a given type among all cells; `is_burden` is 1 for cells that are both senescent and of the target type. The donor's z-scored proportion of that type is included in the burden model only, to separate a change in burden from a change in abundance.

State-level models are the same, refit with states in place of cell types, with BH correction across the states of a given cell type.

**Depth is a covariate.** Depth is regressed out of the SenePy input, and `log10(counts+1)` is also carried in every model. A residual association persists after the expression-matrix correction — Figure S9B shows Spearman correlations from −0.23 to +0.54, sign differing by cell type.

**Meta-analysis.** DerSimonian-Laird random effects, implemented directly in NumPy and SciPy. PsychAD + PsychENCODE for aging, PsychAD + Mathys for AD. Inverse-variance weighting is applied on the scale each model was fitted on — β for the RLR, log-odds for the GLMMs, cube-root proportion for the compositional model. CIs use z = 1.96. Negative τ² truncated to zero. With k = 2, rows with I² above 65 percent have two cohort estimates that disagree and a wide pooled interval for that reason.

**FDR.** Benjamini-Hochberg, threshold 0.05. Each table carries `fdr_family`, the number of tests corrected over. Some families are larger than the rows released, so BH cannot be recomputed from a subset.

**GSEA heatmap colour is NES centred per pathway**, not raw NES. Rows are mean-zero across their four contrasts, so blue means below that pathway's own average, not depletion. Both columns are in the table.

**Other constants.** State boxplots require 20 cells of that state per donor. Figures 1H–1I use Young < 45, Mid 45–64, Old 65+; Figures 3 and S1 use decade bins with a combined 80–100 top bin.

---

## What the tables omit

Per-cell tables carry only what the panel colours by — coordinates, cell type or state, one grouping variable. Never donor plus age plus sex together, since across ~124 donors those approach a fingerprint. Per-donor points are released without identifiers, donors in composition panels are relabelled `D001` onward, and ages are top-coded at 90.

---

## Determinism

Jitter, UMAP draw order and subsampling are seeded. The submitted figures predate these seeds, so regenerated panels are statistically equivalent, not pixel-identical.

Colours live only in the settings cell. `color_for()` names any level with no colour rather than drawing grey.

---

## Data availability

- **PsychAD:** https://doi.org/10.7303/syn60084804
- **PsychENCODE:** https://psychencode.org
- **Mathys:** https://adknowledgeportal.synapse.org/Explore/Studies/DetailsPage/StudyDetails?Study=syn18485175 (snRNAseqPFC_BA10)

Primary objects are not redistributed here.

---

## Citation

```bibtex
@article{gaitos2026senescence,
  title={Distinct cellular senescence landscapes characterize physiological aging and Alzheimer's disease},
  author={Gaitos GM, de Souza I, Harari O and
          Saez-Atienzar, S},
  journal={In preparation},
  year={2026}
}
```

**Methods:** SenePy (Casella 2023) · Pearson residuals (Lause 2021) · PsychAD (Lee, Roussos, Hoffman 2024) · Microglia states (Keren-Shaul 2017, Sala Frigerio 2019) · Astrocyte states (Serrano-Pozo 2024) · Proportions (Garg 2025) · Mathys (2019) · Senescence enrichment (Sloan 2026) · Pseudoreplication (Murphy & Skene 2023)

---

## Contact

Sara Saez-Atienzar, PhD — Sara.SaezAtienzar@osumc.edu

**Team:** Sara Saez-Atienzar (PI), Gerald Gaitos, Gabriel Duarte, Jacob Morales, Iara Souza, Oscar Harari

**Code:** MIT License. **Data:** subject to consortium agreements.

**Data:** PsychAD, PsychENCODE, Mathys et al. **Computing:** Ohio Supercomputer Center.

---

The Ohio State University Wexner Medical Center · Last updated August 2026

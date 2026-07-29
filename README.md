# A coordinated glial senescence program emerges during human brain aging and is rewired in Alzheimer's disease

**Analysis code for a multi-cohort single-nucleus RNA-seq study of cellular senescence across human brain aging and Alzheimer's disease**

[![DOI](https://img.shields.io/badge/DOI-pending-blue)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Overview

This repository contains analysis code for a multi-cohort study of cellular senescence in human brain across aging and Alzheimer's disease, using single-nucleus RNA-sequencing with spatial transcriptomics as an orthogonal validation of the senescence calls.

**Study design:** PsychAD (discovery) + PsychENCODE / Mathys (replication within arm) → random-effects meta-analysis → downstream characterization

**Key questions**

1. Does cellular senescence increase with age in healthy brain?
2. Does Alzheimer's disease increase senescence beyond normal aging?
3. Which cell types show age- and disease-associated senescence?
4. Do senescent cells show canonical hallmarks (cell-cycle arrest, DNA-damage response, pathway enrichment)?
5. **Is glial senescence a transcriptional axis separable from activation-state programs?**
6. Do cell-type composition changes confound senescence patterns?

> Question 5 is evaluated against an activation state selected at run time — Homeostatic, ARM, IRM, Stress or DAM-like. Contrasts, labels, figures and output paths all derive from that selection. See [Running the pipeline](#running-the-pipeline).

---

## Cohorts

### Main cohorts (snRNA-seq)

| Cohort | Type | n donors | Age range | Nuclei | Region |
|--------|------|---|-----------|--------|--------|
| PsychAD Aging | Aging | 124 | 20–90 | ~545K | DLPFC |
| PsychAD AD | Disease | 172 | 60+ | ~700K | DLPFC |
| PsychENCODE | Aging | 69 | 30–90 | ~472K | DLPFC |
| Mathys | Disease | 36 | 70+ | ~70K | FCX |

Mathys: 36 of the 48 published donors are retained after minimum-cells-per-donor filtering (~70K of 80,660 nuclei).

PsychAD Aging and PsychAD AD are subsets of the same consortium filtered by analysis type; the AD subset includes young samples from the aging subset as comparison controls (81 AD + 81 age-matched control + young reference).

Cohorts are **discovery/replication within an arm, not independent tests** — results are pooled by random-effects meta-analysis with heterogeneity reported, and should not be described as independent validation.

### Spatial cohorts (Visium) — control samples only

| Cohort | Samples used | Region | Notes |
|--------|--------------|--------|-------|
| Morabito (Miyoshi & Morabito et al., *Nat Genet* 2024) | 15 controls | Frontal cortex | SenePy scoring + hallmark modules; Cell2Location deconvolution (PsychAD reference) |
| van Olst / Gate (van Olst et al., *Nat Med* 2025) | 6 controls (NND) | Cortex | AN1792 trial cohort; cell-type deconvolution from source publication |

The spatial analysis uses **21 control sections only** and validates the *scoring*, not the disease claim. See [Spatial validation](#-spatial-validation-module-06) for what it can and cannot support.

---

## Repository structure

```
├── scripts/
│   │
│   │ ─── QUANTIFICATION ───
│   ├── 01_preprocessing.ipynb           # QC · normalize · HVG · PCA · Harmony · UMAP
│   ├── 02_depth_regression.ipynb        # Pearson residuals → .X (SenePy input only)
│   ├── 03_senescence_scoring.ipynb      # SenePy scoring · reference-anchored threshold
│   ├── 04_scoring_robustness.ipynb      # Sensitivity asks · alt panels · negative controls
│   │
│   │ ─── VALIDATION ───
│   ├── 05_senescence_validation.ipynb   # Markers · cell cycle · hallmarks · positive control
│   ├── 06_spatial_validation.ipynb      # Moran's I · composition-adjusted residual · Gi* · LISA
│   │
│   │ ─── PRIMARY MODELS ───
│   ├── 07_composition_burden.ipynb      # Composition · burden · susceptibility
│   ├── 08_meta_analysis.ipynb           # DerSimonian-Laird random effects
│   │
│   │ ─── DOWNSTREAM ───
│   ├── 09_subsetting_states.ipynb       # Subset · subcluster · state scoring
│   ├── 10_separability.ipynb            # Senescence × selected-state quadrants
│   ├── 11_deg.ipynb                     # Pseudobulk limma-voom
│   ├── 12_gsea.ipynb                    # GSEApy prerank · Reactome
│   ├── 13_variability.ipynb             # CV + variance partition
│   └── 14_trajectory.ipynb              # Slingshot pseudotime · post-hoc score overlay
│
├── config/                              # One config per dataset — the only file you edit
├── session_info.txt
└── README.md
```

### Module dependencies

```
01 → 02 → 03 → 04
           │
           ├──→ 05 ──┐
           ├──→ 06 ──┤   (validation, parallel)
           │         │
           └──→ 07 → 08
                 │
                 └──→ 09 → 10 → 11 → 12
                            │     └──→ 13
                            └──→ 14
```

`05` and `06` validate the scoring from `03` and run in parallel with the primary models. Results from `07` onward are conditional on the sensitivity analyses in `04`.

---

## Running the pipeline

Everything is driven by one config file per dataset. The two parameters that change what the pipeline does:

```yaml
dataset:  psychad_aging        # psychad_aging | psychad_ad | psychencode | mathys
mode:     aging                # aging | disease  → sets threshold anchor + predictor
state:    IRM                  # IRM | DAM_like | ARM | Stress  → modules 10-14
```

`mode` determines the threshold reference group (youngest age bin vs control) and whether age is the exposure or a covariate. `state` determines the activation axis for the separability analysis. Outputs are namespaced by state, so runs never overwrite each other.

---

## Statistical framework

> Implementation detail lives in each script. This section records the decisions and why.

### 🔬 Data processing

| Step | Method | Rationale |
|------|--------|-----------|
| Batch correction | Harmony | Cross-cohort integration of DLPFC snRNA-seq |
| UMI correction | Analytic Pearson residuals (NB GLM, clip ±30) | Senescence scores correlate with sequencing depth; residuals are computed **as the SenePy input only** |
| Senescence scoring | SenePy, hippocampus hubs, cell-type and sex-specific | Designed for scRNA-seq with cell-type/sex calibration, unlike bulk-fibroblast-derived alternatives. Hippocampus is the closest available brain calibration — a documented approximation, since SenePy has no cortical hub |
| Threshold | Mean + 2SD of the **reference group** (youngest age bin, or control), per cell type | Anchored definition of "elevated". A pooled threshold would slide with the effect being measured |
| Subclustering | Seurat + Harmony | Microglia · Astrocytes · OPCs subclustered and annotated to states |

**Expression layer contract** — enforced at load in every module:

| Layer | Content | Consumed by |
|-------|---------|-------------|
| `.X` | Pearson residuals | **SenePy scoring only** (module 03) |
| `layers['counts']` | Raw counts | DEG (module 11) |
| `layers['lognorm']` | Log-normalized | Module scoring, cell cycle, visualization, variability |

**On sequencing depth.** Senescent cells carry ~1.9× the median UMI of non-senescent cells. This is treated as biology rather than artifact: senescent cells are larger and transcriptionally hyperactive, and SASP is a high-output secretory program. Because depth is already regressed out of the SenePy input, the score is not re-adjusted downstream and **no depth covariate is included in any model** — a second correction would remove real signal. Module 04 reports a depth-matched downsampling sensitivity analysis in support of this.

### 📊 Primary statistics

Senescence is decomposed into three donor-level measures, each modeled separately for aging (continuous age) and disease (case vs control).

| Measure | Model | Output |
|---------|-------|--------|
| Cell-type composition | Cube-root differential proportion (Garg et al. 2025): `Prop^(1/3) ~ Age or Group + Sex + Cohort` | β per decade / per group, FDR |
| Senescent-cell burden (senescent cells of a type as a fraction of all cells) | Logistic GLMM: `is_burden ~ Age or Group + Sex + Cohort + CT-Proportion + (1\|Donor)` | Odds ratio, FDR |
| Susceptibility (senescent fraction within a type) | Logistic GLMM: `is_senescent ~ Age or Group + Sex + Cohort + CT-Proportion + (1\|Donor)` | Odds ratio, FDR |
| Donor-level %SnC (complementary) | OLS + robust linear regression (Huber) | β per decade / per group |

- Aging effects as **OR per decade**; disease effects as **OR vs control**.
- Cell-/state-proportion is a covariate to adjust for compositional abundance.
- Fitted with `lme4`/`lmerTest`, `bobyqa` optimizer.

> **Pseudoreplication.** All tests use the donor, not the cell, as the unit of analysis via donor random effects. A re-analysis of the Mathys dataset found cell-level differential expression returned 14,274 DEGs at FDR<0.05 against 26 under pseudobulk, with permuted donor identifiers still yielding large DEG counts (Murphy & Skene, *eLife* 2023).

> ⚠️ **Minimum-events guard.** Senescent cells are 2–5% of nuclei, so per-donor per-state counts are small. Models below a declared floor on senescent events return "not estimable" rather than an estimate; degenerate fits (near-zero standard errors, collapsed confidence intervals) trigger a donor-level quasi-binomial refit. Cell-cell communication analysis was not pursued for the same reason.

### 🔁 Cross-cohort meta-analysis

| Component | Approach |
|-----------|----------|
| Primary | DerSimonian-Laird random effects |
| Sensitivity | Fixed-effects inverse-variance weighting |
| Heterogeneity | I², Cochran's Q, τ² |

Aging: PsychAD + PsychENCODE. AD: PsychAD + Mathys.

### 🧬 Downstream characterization

| Module | Method | Details |
|--------|--------|---------|
| Glial states | Marker-based module scoring | Microglia: Homeostatic, ARM, IRM, Stress, DAM-like. Astrocyte and OPC states scored from their own reference panels |
| Separability | Senescence × selected-state quadrants | Per-cell scores z-scored and mean-split. Reported as the **distribution across quadrants**, not a correlation — the claim is that senescent cells populate both state-positive and state-negative compartments |
| DEG | Pseudobulk limma-voom, donor as replicate | Four quadrant-axis contrasts |
| Pathway enrichment | GSEApy prerank, Reactome | Pathway blocks derived by enrichment pattern: common (significant in ≥3 contrasts) vs contrast-unique |
| Trajectory | Slingshot on the transcriptional manifold | See constraints below |
| Pathology progression | Donor ordering by clinical severity | Program scores + %SnC z-scored and smoothed along group → Braak → CDR (Mathys) |
| Variability | variancePartition | Transcriptional variance decomposition |

**Trajectory constraints**

- Slingshot fits on the Harmony embedding and data-driven clusters **only**. Senescence and state scores are applied strictly post-hoc. Building the graph on the scores being measured would guarantee the gradient.
- The root is the most homeostatic cluster, chosen on marker expression. Rooting at the senescent end would beg the question.
- Non-monotonic lineages are excluded by an explicit validity filter before any correlation is reported.
- Trajectory correlations use **raw state scores**. Composite `state − homeostatic` axes are excluded here: the shared `−Homeostatic` term makes any two such axes agree with each other (r ≈ 0.82) when the underlying raw scores do not (r ≈ 0.11). Those composite axes remain valid for quadrant and DEG stratification.

### ✅ Senescence validation

Senescence has no ground truth in human tissue, so the calls are validated against internal consistency rather than a gold standard.

| Step | Method |
|------|--------|
| Canonical markers | p16 (CDKN2A), p21 (CDKN1A) expression in senescent vs non-senescent cells |
| Cell-cycle arrest | Tirosh G1/S and G2/M module scoring |
| Senescence hallmarks | 10 curated Sloan et al. hallmark modules |
| Positive control | Per-cell association of senescence score with DNA-damage-response, cell-cycle-arrest and SASP modules — establishes the score detects senescence transcriptomically, so a null result elsewhere is a finding rather than a detection failure |
| Separability control | Hallmark and cell-cycle enrichment in astrocytes and OPCs — cell types with no microglial activation program to confound the signal |

**Robustness (module 04)** — five pre-specified sensitivity analyses:

1. Continuous LMM in parallel to the binary GLMM — does the result hold without thresholding?
2. Threshold sensitivity across a range of SD cutoffs
3. Alternative scoring panels (CellAge, Fridman, Hernández-Segura, SenMayo)
4. Negative control — random gene panels **drawn excluding SenePy genes**, plus HVG-only
5. Depth-matched downsampling and re-scoring

### 🗺️ Spatial validation (module 06)

Tests whether senescence calls are spatially structured rather than randomly distributed, using control sections from two independent Visium datasets.

| Step | Method |
|------|--------|
| Global autocorrelation | Moran's I per section, permutation null |
| Composition control | Moran's I on residuals after regressing out all cell-type proportions per section |
| Local structure | Getis-Ord Gi\* hot/cold spots; LISA quadrants |
| Compartment stratification | Within-GM and within-WM contrasts |
| Cross-dataset pooling | DerSimonian-Laird random effects |

The composition-adjusted residual is the informative one: it separates genuine spatial structure in senescence from spatial structure inherited from tissue architecture. Results are reported in the manuscript.

> **Limitation.** Visium spots (~55 µm) contain several cells. After deconvolution, **no sample in either cohort has enough microglia-dominant spots to test** (0/21 at a ≥50-spot floor; the same holds for OPC and PVM). The spatial arm therefore validates the senescence scoring; it cannot address the microglial separability claim. Bivariate spatial cross-correlation was evaluated and not pursued — cross-cohort sign concordance was 57% with I² frequently above 90%.

### 🔢 Multiple testing

Benjamini-Hochberg FDR throughout — threshold **FDR < 0.05**.

---

## Reproducibility notes

- **Microglial subclustering is frozen.** The clustering cell is unseeded but reproducible when run in order from a fresh kernel (verified twice by barcode and embedding checksum). Adding `set.seed()` before Harmony changes the RNG state and yields a *different* clustering — it replaces the result rather than stabilizing it. Do not add a seed without rebuilding all downstream figures.
- Earlier lineage instability traced to **cell execution order**, not to Harmony being stochastic per run.
- Figures and tables route through the shared `save_figure()` / `save_table()` helpers defined in config. Redefining them inside a notebook shadows the canonical version and changes where output is written.

---

## Software

**Python 3.13.3** and **R 4.3.1**.

**Python:** NumPy, Pandas, SciPy, AnnData, ScanPy, SenePy, GSEApy, statsmodels, scikit-learn, rpy2, Cell2Location, squidpy, myGene
**R:** Seurat, Harmony, slingshot, SingleCellExperiment, limma, edgeR, variancePartition, lme4, lmerTest, robustbase, ggplot2
**Spatial:** Cell2Location (GPU required)

**Complete versions:** [`session_info.txt`](session_info.txt)

---

## Data availability

- **PsychAD:** https://doi.org/10.7303/syn60084804
- **PsychENCODE:** https://psychencode.org
- **Mathys:** https://adknowledgeportal.synapse.org/Explore/Studies/DetailsPage/StudyDetails?Study=syn18485175 (snRNAseqPFC_BA10)
- **Morabito:** https://doi.org/10.1038/s41588-024-01961-x (GEO: GSE233208)
- **van Olst / Gate:** https://doi.org/10.1038/s41591-025-03574-1 (GEO: GSE263038)

---

## Citation

```bibtex
@article{gaitos2026senescence,
  title={A coordinated glial senescence program emerges during human
         brain aging and is rewired in Alzheimer's disease},
  author={Gaitos, Gerald and De Souza, Iara and Harari, Oscar and
          Saez-Atienzar, Sara},
  journal={In preparation},
  year={2026}
}
```

### Methods citations

**SenePy:** Casella et al. 2023
**Pearson residuals:** Lause et al. 2021, *Genome Biology*
**PsychAD:** Lee, Roussos, Hoffman et al. (PsychAD Consortium) 2024
**Microglia states (DAM-like, Homeostatic):** Keren-Shaul et al. 2017, *Cell*
**Microglia states (ARM, IRM):** Sala Frigerio et al. 2019, *Cell Reports*
**Astrocyte states:** Serrano-Pozo et al. 2024, *Nature Neuroscience*
**Proportion analysis:** Garg et al. 2025
**Mathys:** Mathys et al. 2019, *Nature*
**Senescence enrichment:** Sloan et al. 2026, *Cell Genomics*
**Pseudoreplication in snRNA-seq:** Murphy & Skene 2023, *eLife* (re-analysis of Mathys et al. 2019)
**Cell cycle scoring:** Tirosh et al. 2016, *Science*
**Trajectory inference:** Street et al. 2018, *BMC Genomics*
**Cell2Location:** Kleshchevnikov et al. 2022, *Nature Biotechnology*
**Morabito (spatial AD):** Miyoshi, Morabito et al. 2024, *Nature Genetics*
**van Olst (spatial immunization):** van Olst et al. 2025, *Nature Medicine*

---

## Contact

**Corresponding author:** Sara Saez-Atienzar, PhD (Sara.SaezAtienzar@osumc.edu)

---

## License

**Code:** MIT License
**Data:** Subject to consortium agreements

---

## Acknowledgments

**Data:** PsychAD, PsychENCODE, Mathys et al., Morabito et al., van Olst et al.
**Computing:** Ohio Supercomputer Center

**Team**

- Sara Saez-Atienzar, PhD (PI)
- Gerald Gaitos, MD, MSc
- Gabriel Duarte
- Jacob Morales
- Iara Souza, PhD
- Oscar Harari, PhD

---

**The Ohio State University Wexner Medical Center**

Last updated: July 2026

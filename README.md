# A coordinated glial senescence program emerges during human brain aging and is rewired in Alzheimer's disease

**Analysis code for a multi-cohort single-nucleus RNA-seq study of cellular senescence across human brain aging and Alzheimer's disease**

[![DOI](https://img.shields.io/badge/DOI-pending-blue)]()
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Overview

This repository contains analysis code for a multi-cohort study of cellular senescence in human brain across aging and Alzheimer's disease, using single-nucleus RNA-sequencing.

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

| Cohort | Type | n donors | Age range | Nuclei | Region |
|--------|------|---|-----------|--------|--------|
| PsychAD Aging | Aging | 124 | 20–90 | ~545K | DLPFC |
| PsychAD AD | Disease | 172 | 60+ | ~700K | DLPFC |
| PsychENCODE | Aging | 69 | 30–90 | ~472K | DLPFC |
| Mathys | Disease | 36 | 70+ | ~70K | FCX |

Mathys: 36 of the 48 published donors are retained after minimum-cells-per-donor filtering (~70K of 80,660 nuclei).

PsychAD Aging and PsychAD AD are subsets of the same consortium filtered by analysis type; the AD subset includes young samples from the aging subset as comparison controls (81 AD + 81 age-matched control + young reference).

Cohorts are **discovery/replication within an arm, not independent tests** — results are pooled by random-effects meta-analysis with heterogeneity reported, and should not be described as independent validation.

---

## Repository structure

```
├── scripts/
│   │
│   │ ─── QUANTIFICATION ───
│   ├── 01_preprocessing.ipynb           # QC · normalize · HVG · PCA · Harmony · UMAP
│   ├── 02_depth_regression.ipynb        # Pearson residuals → .X (SenePy input only)
│   ├── 03_senescence_scoring.ipynb      # SenePy scoring · reference-anchored threshold
│   ├── 04_scoring_robustness.ipynb      # Sensitivity analyses · alt panels · negative controls
│   │
│   │ ─── VALIDATION ───
│   ├── 05_senescence_validation.ipynb   # Markers · cell cycle · hallmarks · positive control
│   │
│   │ ─── PRIMARY MODELS ───
│   ├── 06_composition_burden.ipynb      # Composition · burden · susceptibility
│   ├── 07_meta_analysis.ipynb           # DerSimonian-Laird random effects
│   │
│   │ ─── DOWNSTREAM ───
│   ├── 08_subsetting_states.ipynb       # Subset · subcluster · state scoring
│   ├── 09_separability.ipynb            # Senescence × selected-state quadrants
│   ├── 10_deg.ipynb                     # Pseudobulk limma-voom
│   ├── 11_gsea.ipynb                    # GSEApy prerank · Reactome · KEGG · Hallmark
│   ├── 12_variability.ipynb             # CV + variance partition
│   └── 13_trajectory.ipynb              # Slingshot pseudotime · post-hoc score overlay
│
├── tools/
│   └── check_donor_overlap.py           # Donor-ID intersection between pooled cohorts
├── .env.example                         # SENESCENCE_DATA / SENESCENCE_REF — copy to .env
├── .gitignore
├── session_info.txt
└── README.md
```

There is no shared config module. Each notebook opens with its own **section 01 · Config**, so it can be read and run without tracing an import into another file. The only thing outside the notebooks is `.env` — the two path roots — and nothing in the repo hardcodes a filesystem path.

### Module dependencies

```
01 → 02 → 03 → 04
           │
           ├──→ 05           (validation, parallel)
           │
           └──→ 06 → 07
                 │
                 └──→ 08 → 09 → 10 → 11
                            │     └──→ 12
                            └──→ 13
```

`05` validates the scoring from `03` and runs in parallel with the primary models. Results from `06` onward are conditional on the sensitivity analyses in `04`.

---

## Running the pipeline

### 1. Paths

Two environment variables, and nothing in the repo hardcodes a filesystem location:

```bash
cp scripts/.env.example .env
# edit the two roots, then
source .env
```

| Variable | Contents |
|---|---|
| `SENESCENCE_DATA` | analysis root — every module writes under it |
| `SENESCENCE_REF` | reference root — published gene panels, read-only |
| `SENESCENCE_R_HOME` | optional; only if rpy2 cannot find R on its own |

### 2. Config

Three parameters change what the pipeline does:

```python
DATASET    = "psychad_aging"   # psychad_aging | psychad_ad | psychencode | mathys
STUDY_TYPE = "aging"           # aging | disease
CELL_TYPE  = "Microglia"       # modules 05, 08-13 run one cell type at a time
```

```r
AXIS <- "IRM"                  # IRM | DAM_like | ARM | Stress   (modules 08-13)
```

`STUDY_TYPE` sets the threshold reference group — youngest age bin versus control — and decides whether age is the exposure or a covariate. `AXIS` selects the activation state: column names, quadrant labels, contrast names, figure titles and output directories all derive from it, and outputs are namespaced by state so runs never overwrite each other.

### 3. Module map

| Module | Language | Set before running |
|---|---|---|
| 01 preprocessing | Python | `DATASET` |
| 02 depth regression | Python | `DATASET` |
| 03 senescence scoring | Python (`senepy`) | `DATASET` |
| 04 scoring robustness | Python | `DATASET` |
| 05 senescence validation | R (`ir`) | `DATASET`, `CELL_TYPE`, `STUDY_TYPE` |
| 06 composition burden | Python | `DATASET`, `STUDY_TYPE`, `REFERENCE_GROUP` |
| 07 meta-analysis | Python | `COHORTS`, `EFFECT` **and** `SLUG` |
| 08 subsetting states | R | `AXIS`, `CELL_TYPE` |
| 09 separability | R | `AXIS`, `CELL_TYPE` |
| 10 deg | R | `AXIS`, `CELL_TYPE` |
| 11 gsea | Python + R via rpy2 | reads the limma tables from 10 |
| 12 variability | Python + R via rpy2 | `DATASET`, `CELL_TYPE` |
| 13 trajectory | R | `AXIS`, `CELL_TYPE` |

Modules 07, 11 and 12 have notes worth reading before the first run: module 07's `SLUG` does not derive from `EFFECT` and must be changed alongside it; modules 11 and 12 each run part of their work through `%%R`, because the house plotting style and `variancePartition` are R-only.

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
| `layers['counts']` | Raw counts | DEG (module 10) |
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

Pooling assumes the cohort estimates are independent. PsychAD AD and Mathys both draw on ROSMAP, so `tools/check_donor_overlap.py` measures the donor-ID intersection rather than assuming there is none — the check compares raw and normalized IDs, because the same donor can be written differently in each object.

### 🧬 Downstream characterization

| Module | Method | Details |
|--------|--------|---------|
| Glial states | Marker-based module scoring | Microglia: Homeostatic, ARM, IRM, Stress, DAM-like. Astrocyte and OPC states scored from their own reference panels. States assigned per subcluster by z-scored argmax, not per cell |
| Separability | Senescence × selected-state quadrants | Per-cell scores z-scored and mean-split. Reported as the **distribution across quadrants**, not a correlation — the claim is that senescent cells populate both state-positive and state-negative compartments. A two-predictor model (`module ~ sen + axis`) reports each axis holding the other fixed |
| DEG | Pseudobulk limma-voom, donor as replicate | Four quadrant-axis contrasts, `duplicateCorrelation` blocked on donor |
| Pathway enrichment | GSEApy prerank — Reactome, KEGG, Hallmark | Pathway blocks derived by enrichment pattern: common (significant in ≥3 contrasts) vs contrast-unique. Ribosome stripping is a run parameter, not a fixed filter, and both passes are compared |
| Trajectory | Slingshot on the transcriptional manifold | See constraints below |
| Pathology progression | Donor ordering by clinical severity | Program scores + %SnC z-scored and smoothed along group → Braak → CDR |
| Variability | CV (DEG- and HVG-stratified) + variancePartition | Transcriptional variance decomposition |

**Trajectory constraints**

- Slingshot fits on the Harmony embedding and data-driven clusters **only**. Senescence and state scores are applied strictly post-hoc. Building the graph on the scores being measured would guarantee the gradient.
- **The root is chosen marker-free** — clusters are ranked by transcriptional entropy and depth-corrected gene diversity, and the least differentiated cluster becomes the root. No biological score enters. Rooting on a homeostatic panel score would use a biological quantity to set the origin the same scores are then correlated against.
- Non-monotonic lineages are excluded by an explicit branch audit before any correlation is reported.
- Trajectory correlations use **raw state scores**. Composite `state − homeostatic` axes are excluded here: the shared `−Homeostatic` term makes any two such axes agree with each other (r ≈ 0.82) when the underlying raw scores do not (r ≈ 0.11). Those composite axes remain valid for quadrant and DEG stratification, and module 09 tests the point directly.

### ✅ Senescence validation

Senescence has no ground truth in human tissue, so the calls are validated against internal consistency rather than a gold standard.

| Step | Method |
|------|--------|
| Canonical markers | p16 (CDKN2A), p21 (CDKN1A) expression in senescent vs non-senescent cells |
| Cell-cycle arrest | Tirosh G1/S and G2/M module scoring |
| Senescence hallmarks | 10 curated Sloan et al. hallmark modules |
| Positive control | Per-cell association of senescence score with DNA-damage-response, cell-cycle-arrest and SASP modules — establishes the score detects senescence transcriptomically, so a null result elsewhere is a finding rather than a detection failure |
| Separability control | Hallmark and cell-cycle enrichment in astrocytes and OPCs — cell types with no microglial activation program to confound the signal |

Each contrast is run under five estimators — donor-paired Wilcoxon, RLM and OLS on paired differences, a cell-level mixed model with a donor random intercept, and a balanced bootstrap — with a cross-model agreement section. A result is reported when the estimators agree, not when one of them reaches significance.

**Robustness (module 04)** — five pre-specified sensitivity analyses:

1. Continuous LMM in parallel to the binary GLMM — does the result hold without thresholding?
2. Threshold sensitivity across a range of SD cutoffs
3. Alternative scoring panels (CellAge, Fridman, Hernández-Segura, SenMayo)
4. Negative control — random gene panels **drawn excluding SenePy genes**, plus HVG-only
5. Depth-matched downsampling and re-scoring

### 🔢 Multiple testing

Benjamini-Hochberg FDR throughout — threshold **FDR < 0.05**.

---

## Reproducibility notes

- **Microglial subclustering is frozen.** The clustering cell is unseeded but reproducible when run in order from a fresh kernel (verified twice by barcode and embedding checksum). Adding `set.seed()` before Harmony changes the RNG state and yields a *different* clustering — it replaces the result rather than stabilizing it. Do not add a seed without rebuilding all downstream figures.
- Earlier lineage instability traced to **cell execution order**, not to Harmony being stochastic per run.
- Figures and tables route through the shared `save_figure()` / `save_table()` helpers defined in each notebook's config section. Redefining them mid-notebook shadows the canonical version and changes where output is written.
- See [`CONTRIBUTING.md`](CONTRIBUTING.md) for behaviour that looks like a bug and is not — inherited naming, known covariate quirks, and the places a section will silently no-op.

---

## Software

**Python 3.13.3** and **R 4.3.1**.

**Python:** NumPy, Pandas, SciPy, AnnData, ScanPy, SenePy, GSEApy, statsmodels, scikit-learn, rpy2, myGene

**R:** Seurat, Harmony, slingshot, SingleCellExperiment, limma, edgeR, variancePartition, lme4, lmerTest, robustbase, ggplot2

**Complete versions:** [`session_info.txt`](session_info.txt)

---

## Data availability

- **PsychAD:** https://doi.org/10.7303/syn60084804
- **PsychENCODE:** https://psychencode.org
- **Mathys:** https://adknowledgeportal.synapse.org/Explore/Studies/DetailsPage/StudyDetails?Study=syn18485175 (snRNAseqPFC_BA10)

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
**Variance partitioning:** Hoffman & Schadt 2016, *BMC Bioinformatics*

---

## Contact

**Corresponding author:** Sara Saez-Atienzar, PhD (Sara.SaezAtienzar@osumc.edu)

---

## License

**Code:** MIT License
**Data:** Subject to consortium agreements

---

## Acknowledgments

**Data:** PsychAD, PsychENCODE, Mathys et al.
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

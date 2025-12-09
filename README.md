# 🧬 Cellular Senescence in Brain Aging and Alzheimer's Disease

<div align="center">

**Multi-Cohort Single-Nucleus RNA-seq Meta-Analysis**

[![Cohorts](https://img.shields.io/badge/Cohorts-4-blue.svg)]()
[![Samples](https://img.shields.io/badge/Samples-366-green.svg)]()
[![Nuclei](https://img.shields.io/badge/Nuclei-2M+-orange.svg)]()
[![Cell Types](https://img.shields.io/badge/Focus-Glia-purple.svg)]()
[![Method](https://img.shields.io/badge/Design-Discovery--Replication-red.svg)]()

*Comprehensive discovery-replication study identifying and validating senescent cell populations across independent human brain cohorts*

[Key Findings](#key-findings) • [Study Design](#study-design) • [Pipeline](#analysis-pipeline) • [Methods](#methods-overview) • [Citation](#citation)

</div>

---

## 📊 At a Glance

| Component | Details |
|-----------|---------|
| **Study Type** | Discovery-Replication with Meta-Analysis |
| **Technology** | Single-nucleus RNA-seq (snRNA-seq) |
| **Discovery** | PsychAD (n=296 samples, aging + AD cohorts) |
| **Replication** | PsychENCODE (n=69), Mathys (n=30), Australian Brain (n=71) |
| **Brain Regions** | DLPFC (primary), Frontal cortex, Parietal cortex |
| **Focus** | Glial senescence (Microglia, Astrocytes, OPCs) |
| **Key Method** | Random-effects meta-analysis (DerSimonian-Laird) |

---

## 🔬 Study Design Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         DISCOVERY PHASE                                 │
│                                                                         │
│  ┌────────────────────────┐        ┌────────────────────────┐           │
│  │   PsychAD Aging        │        │   PsychAD AD           │           │
│  │   ─────────────────    │        │   ────────────         │           │
│  │   • DLPFC              │        │   • DLPFC              │           │
│  │   • n=124 samples      │        │   • n=172 samples      │           │
│  │   • 7 age groups       │        │   • 3 study groups     │           │
│  │   • 20-29 to >80y      │        │   • Young/Old Ctl/AD   │           │
│  │   • ~500K nuclei       │        │   • ~700K nuclei       │           │
│  └────────────────────────┘        └────────────────────────┘           │
│              │                                   │                      │
│              └───────────┬───────────────────────┘                      │
│                          │                                              │
│                          ↓                                              │
│              ┌───────────────────────┐                                  │
│              │ Pan-Cell Type Screen  │                                  │
│              │ ───────────────────── │                                  │
│              │ → Identified: Glia    │                                  │
│              │   (↑ senescence)      │                                  │
│              └───────────────────────┘                                  │
└─────────────────────────────────────────────────────────────────────────┘
                          │
                          ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                      REPLICATION PHASE                                  │
│                                                                         │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐       │
│  │ PsychENCODE      │  │ Mathys FCX       │  │ Australian Brain │       │
│  │ ────────────     │  │ ──────────       │  │ ────────────     │       │
│  │ • DLPFC          │  │ • Frontal ctx    │  │ • Parietal ctx   │       │
│  │ • n=69           │  │ • n=30           │  │ • n=71           │       │
│  │ • Aging cohort   │  │ • AD cohort      │  │ • AD cohort      │       │
│  │ • Age balanced   │  │ • Late 70s+      │  │ • Age 24-93y     │       │
│  │ • Sex balanced   │  │ • NCI/MCI/AD     │  │ • AD vs Control  │       │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘       │
│          │                      │                      │                │
└──────────┼──────────────────────┼──────────────────────┼────────────────┘
           │                      │                      │
           ↓                      ↓                      ↓
    ┌─────────────┐         ┌─────────────┐         ┌────────────┐
    │  AGING      │         │   AD        │         │ VALIDATION │
    │META-ANALYSIS│         │META-ANALYSIS│         │  (Separate)│
    │             │         │             │         │            │
    │ PsychAD +   │         │ PsychAD +   │         │ Australian │
    │PsychENCODE  │         │  Mathys     │         │   Brain    │
    │             │         │             │         │            │
    │ (DLPFC)     │         │   (FCX)     │         │ (Parietal) │
    └─────────────┘         └─────────────┘         └────────────┘
           │                      │                      │
           └──────────────────────┴──────────────────────┘
                                  │
                                  ↓
                    ┌──────────────────────────┐
                    │   INTEGRATED FINDINGS    │
                    │  ─────────────────────   │
                    │  • Cross-cohort patterns │
                    │  • Heterogeneity metrics │
                    │  • Robust conclusions    │
                    └──────────────────────────┘
```

---

## 🧪 Analysis Pipeline

### **PHASE 1** • Data Processing (All Cohorts)

<details>
<summary><b>Click to expand preprocessing details</b></summary>

```python
# Quality Control
├── Filter cells: ≥200 genes/cell
├── Filter genes: ≥3 cells/gene
├── Calculate QC metrics: MT%, ribo%, Hb%
└── Normalize: 10,000 counts/cell + log transform

# Batch Correction
├── Method: Harmony integration
├── Batch variable: Donor ID
├── PCA: 50 components
└── UMAP visualization

# Cell Type Annotation
└── Canonical markers for 11 major brain cell types
```

**Tools:** Scanpy v1.9, Harmony, Python 3.10
</details>

---

### **PHASE 2** • Senescence Identification (All Cohorts)

```
┌─────────────────────────────────────────────────────────┐
│  SenePy Scoring                                         │
│  ───────────────                                        │
│  1. Load hippocampus-specific modules                   │
│  2. Cell-type + sex-specific scoring                    │
│  3. Threshold: mean + 2SD (from youngest age group)     │
│  4. Binary classification: SnC vs Non-SnC               │
│                                                          │
│  Validation:                                             │
│  ✓ Canonical markers (CDKN1A, CDKN2A, TP53)            │
│  ✓ SASP factors (IL6, IL8, CCL2, CXCL1)                │
│  ✓ Pathway correlation analysis                         │
└─────────────────────────────────────────────────────────┘
```

---

### **PHASE 3** • Cell Type Selection

```
Initial Screening → Focus on High-Senescence Populations

ALL CELL TYPES                    SELECTED FOR ANALYSIS
─────────────────                 ─────────────────────
├─ Excitatory neurons        
├─ Inhibitory neurons        
├─ Microglia                 ──→  ✓ MICROGLIA
├─ Astrocytes                ──→  ✓ ASTROCYTES
├─ OPCs                      ──→  ✓ OPCs
├─ Oligodendrocytes          
├─ Endothelial               
└─ Pericytes                 

Reason: Glial cells show highest senescence burden
Method: Differential proportion analysis (cube root + GLM)
```

---

### **PHASE 4** • Subclustering & State Annotation (All Cohorts)

<table>
<tr>
<td width="50%">

**Microglia States**
```
Leiden clustering →
├─ Homeostatic
├─ IFN-I responsive
├─ IFN-II responsive  
├─ IFN-III responsive
├─ MHCII-expressing
├─ Neuronal surveillance
└─ Stress-associated
```
*Markers: Saez-Atienzar et al. (2024)*

</td>
<td width="50%">

**Astrocyte States**
```
Leiden clustering →
├─ Homeostatic
├─ Reactive
├─ Hypertrophic
└─ Disease-associated
```
*Markers: Canonical literature-based*

</td>
</tr>
</table>

---

### **PHASE 5** • Differential Proportion Analysis (All Cohorts)

| Analysis Level | Method | Formula | Purpose |
|---------------|--------|---------|---------|
| **Cell Type Composition** | GLM | `cuberoot ~ StudyGroup + Sex + Cohort` | Test if subcluster proportions differ across groups |
| **Senescence Proportion** | GLM | `cuberoot ~ StudyGroup + Sex + Cohort` | Test if %SnC differs across groups within cell types |

**Key Innovation:** Cube root transformation stabilizes variance for bounded proportion data (0-100%)

---

### **PHASE 6** • Cross-Cohort Meta-Analysis

```
AGING META-ANALYSIS                      AD META-ANALYSIS
───────────────────                      ────────────────
PsychAD (n=124)                         PsychAD (n=172)
      +                                        +
PsychENCODE (n=69)                      Mathys (n=30)
      ↓                                        ↓
Both DLPFC region                       Both Frontal cortex
      ↓                                        ↓
───────────────────────────────────────────────────────────
         DerSimonian-Laird Random-Effects Model
         ─────────────────────────────────────
         • Inverse-variance weighting
         • Heterogeneity: Cochran's Q, I², τ²
         • Pooled estimates + 95% CI
         • Forest plots per cell type × age/diagnosis
───────────────────────────────────────────────────────────
```

**Why meta-analysis?**
- ✓ Accounts for study-level heterogeneity
- ✓ Provides robust cross-cohort evidence
- ✓ Computationally feasible (vs. pooled integration)
- ✓ Standard approach for multi-study synthesis

---

### **PHASE 7** • Molecular Characterization (Discovery Only)

<table>
<tr><th>Analysis</th><th>Method</th><th>Purpose</th></tr>

<tr>
<td><b>Transcriptional Variability</b></td>
<td>Coefficient of variation (CV)</td>
<td>Measure heterogeneity in SnC vs Non-SnC</td>
</tr>

<tr>
<td><b>Mixed-Effects Modeling</b></td>
<td>GLMM with donor random effects</td>
<td>Model senescence probability</td>
</tr>

<tr>
<td><b>Pseudobulk Aggregation</b></td>
<td>Seurat::AggregateExpression</td>
<td>Donor-level profiles for DEG</td>
</tr>

<tr>
<td><b>Variance Partition</b></td>
<td>variancePartition (SenePy genes)</td>
<td>Decompose variance sources</td>
</tr>

<tr>
<td><b>Differential Expression</b></td>
<td>DESeq2 (4 comparisons per cell type)</td>
<td>Identify senescence DEGs</td>
</tr>

<tr>
<td><b>Signature Validation</b></td>
<td>Overlap with established signatures</td>
<td>Confirm biological validity</td>
</tr>

<tr>
<td><b>Pathway Enrichment</b></td>
<td>SCPA (Reactome + KEGG)</td>
<td>Functional interpretation</td>
</tr>

</table>

**Signatures tested:**
- Universal aging hallmarks (DDR, oxidative stress, mitochondrial, neuroinflammation, autophagy, cell cycle)
- SASP factors (cytokines, chemokines, MMPs)
- Cell-type-specific aging markers

---

## 📋 Methods Overview

### Statistical Approaches

| Analysis | Method | Software | Key Parameters |
|----------|--------|----------|----------------|
| **Proportion transformation** | Cube root: `(P/100)^(1/3)` | R | Stabilizes variance |
| **Differential proportion** | GLM (Gaussian) | R (glm) | Covariates: Sex + Cohort |
| **Meta-analysis** | DerSimonian-Laird RE | Custom R | Inverse-variance weighting |
| **Mixed models** | GLMM / LMM | lme4 | Donor random effects |
| **Pseudobulk DEG** | DESeq2 | Seurat v5 | Wald test, Sex/Cohort latent |
| **Variance partition** | Linear mixed model | variancePartition | 8 fixed + 5 random effects |
| **Pathway analysis** | Single-cell pathway | SCPA | Reactome + KEGG databases |
| **Multiple testing** | FDR correction | All analyses | Benjamini-Hochberg |

### Quality Control Standards

```yaml
Cells:
  min_genes: 200
  min_cells_per_gene: 3
  
CV Analysis:
  min_cells_per_group: 10
  min_paired_donors: 3
  
Significance:
  fdr_threshold: 0.05
  method: "Benjamini-Hochberg"
  
Batch Correction:
  method: "Harmony"
  batch_variable: "Donor ID"
  n_pcs: 50
```

---

## 💻 Software Stack

<table>
<tr>
<td width="50%">

**Python 3.10**
```python
# Core
scanpy >= 1.9
senepy >= 1.0
numpy
pandas

# Batch correction
harmony-pytorch

# Visualization
matplotlib
seaborn
```

</td>
<td width="50%">

**R 4.x**
```r
# Core
Seurat >= 5.0
dplyr
ggplot2

# Statistics
DESeq2
lme4
variancePartition

# Pathway
SCPA
msigdbr

# Visualization
ComplexHeatmap
ggpubr
rstatix
```

</td>
</tr>
</table>

---

## 📊 Cohort Details

| Cohort | Role | Region | Samples | Age Range | Groups | Nuclei |
|--------|------|--------|---------|-----------|--------|--------|
| **PsychAD Aging** | Discovery | DLPFC | 124 | 20-80+ | 7 age groups | ~500K |
| **PsychAD AD** | Discovery | DLPFC | 172 | 60+ | Young/Old Ctl/Cases | ~700K |
| **PsychENCODE** | Replication | DLPFC | 69 | 30-80+ | 6 age groups | ~500K |
| **Mathys** | Replication | FCX | 30 | 70+ | NCI/MCI/AD/Other | ~70K |
| **Australian Brain** | Validation | Parietal | 71 | 24-93 | AD vs Control | ~360K |
| **TOTAL** | - | - | **366** | - | - | **~2M** |

---

## 🎯 Key Findings

> *This section will highlight main results once analysis is complete*

**Discovery:**
- Glial cells (microglia, astrocytes, OPCs) show elevated senescence compared to neurons
- Senescence burden increases with age in aging cohort
- Differential senescence patterns in AD vs controls

**Replication:**
- Cross-cohort validation of senescence trends
- Meta-analytic pooled estimates with heterogeneity metrics
- Robust findings across independent datasets

**Molecular Signatures:**
- DEGs enriched for canonical aging hallmarks
- SASP factor expression in senescent glia
- Cell-type-specific aging signatures validated

---

## 📁 Repository Structure

```
.
├── README.md                          # This file
├── methods/
│   ├── complete_methods.md            # Full methods section
│   └── supplementary_methods.md       # Extended details
├── notebooks/
│   ├── 00_preprocessing/              # QC and normalization
│   │   ├── psychad_preprocessing.ipynb
│   │   ├── psychencode_filtering.ipynb
│   │   └── mathys_preprocessing.ipynb
│   ├── 01_senescence_scoring/         # SenePy workflow
│   │   └── senepy_scoring_pipeline.ipynb
│   ├── 02_differential_proportion/    # Proportion analysis
│   │   └── cube_root_glm_analysis.R
│   ├── 03_meta_analysis/              # Cross-cohort meta-analysis
│   │   ├── aging_meta_analysis.ipynb
│   │   └── ad_meta_analysis.ipynb
│   └── 04_molecular_analysis/         # DEG, variance, pathways
│       ├── pseudobulk_deg.R
│       ├── variance_partition.R
│       └── pathway_enrichment.R
├── scripts/
│   ├── utils/                         # Helper functions
│   └── visualization/                 # Plotting scripts
└── data/
    ├── raw/                           # Links to Synapse data
    ├── processed/                     # QC'd datasets
    └── results/                       # Analysis outputs
```

---

## 🚀 Getting Started

### 1. Data Access

**Discovery Data:**
```bash
# PsychAD Consortium (requires Synapse account)
# Visit: https://doi.org/10.7303/syn60084804
```

**Replication Data:**
```bash
# PsychENCODE: Available through PsychENCODE portal
# Mathys: https://www.synapse.org/#!Synapse:syn18681734
# Australian Brain Bank: Contact for access
```

### 2. Environment Setup

```bash
# Python environment
conda create -n senescence python=3.10
conda activate senescence
pip install scanpy>=1.9 senepy numpy pandas harmony-pytorch

# R packages
R -e "install.packages(c('Seurat', 'DESeq2', 'lme4', 'dplyr', 'ggplot2'))"
R -e "BiocManager::install(c('variancePartition', 'SCPA', 'msigdbr'))"
```

### 3. Run Pipeline

```bash
# Step 1: Preprocessing
python notebooks/00_preprocessing/psychad_preprocessing.ipynb

# Step 2: Senescence scoring
python notebooks/01_senescence_scoring/senepy_scoring_pipeline.ipynb

# Step 3: Meta-analysis
python notebooks/03_meta_analysis/aging_meta_analysis.ipynb

# Step 4: Molecular analysis (R)
Rscript notebooks/04_molecular_analysis/pseudobulk_deg.R
```

---

## 📖 Citation

If you use these methods or data, please cite:

**This Study:**
```bibtex
@article{senescence2025,
  title={Multi-Cohort Analysis of Cellular Senescence in Brain Aging and Alzheimer's Disease},
  author={Gaitos, Gerald and Saez-Atienzar, Sara},
  year={2025},
  journal={In preparation}
}
```

**Key References:**

**Microglial States:**
```bibtex
@article{garg2024,
  title={Exploring Cellular Heterogeneity: Single-Cell and Spatial Transcriptomics of Alzheimer Disease Brains},
  author={Saez-Atienzar, S. et al.},
  journal={Research Square},
  year={2024},
  doi={10.21203/rs.3.rs-5045715/v1}
}
```

**SenePy:**
```bibtex
@article{casella2023,
  title={SenePy: a Python library for single-cell senescence analysis},
  author={Casella, G. et al.},
  year={2023}
}
```

**PsychAD:**
```bibtex
@article{psychad2024,
  title={Single-nucleus transcriptomic atlas of the human brain},
  author={Fullard, J.F. et al.},
  journal={Nature},
  year={2024}
}
```

**Mathys:**
```bibtex
@article{mathys2019,
  title={Single-cell transcriptomic analysis of Alzheimer's disease},
  author={Mathys, H. et al.},
  journal={Nature},
  year={2019},
  doi={10.1038/s41586-019-1195-2}
}
```

---

## 👥 Team

**Principal Investigator**
- Sara Saez-Atienzar, PhD | National Institutes of Health

**Lead Analyst**
- Gerald Gaitos, MD, MSc | Ohio State University

**Institution**
- Center for Neurodegeneration Research, Ohio State University

---

## 📬 Contact

**Questions about methods:**
- Email: ggaitos@osumc.edu
- Issues: [GitHub Issues](link-to-repo)

**Data access questions:**
- PsychAD: Contact via Synapse portal
- Collaborations: Email PI

---

## 📝 License

Analysis code: MIT License
Data: Subject to individual consortium data use agreements

---

<div align="center">

**Study Status:** ✅ Analysis Complete | 📊 Manuscript in Preparation

**Last Updated:** December 2025 | **Version:** 2.0

Made with ❤️ for reproducible neuroscience

[⬆ Back to Top](#-cellular-senescence-in-brain-aging-and-alzheimers-disease)

</div>

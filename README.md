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
│                                                         │
│  Validation (2 approaches):                             │
│  ───────────────────────────                            │
│  Approach 1: Paired expression comparison               │
│  ✓ Canonical markers (CDKN1A, CDKN2A, TP53)             │
│  ✓ SASP factors (IL6, IL8, CCL2, CXCL1)                 │
│                                                         │
│  Approach 2: Correlation analysis (SnC vs Non-SnC)      │
│  ✓ Universal aging hallmarks:                           │
│    - DNA damage response (DDR)                          │
│    - Oxidative stress                                   │
│    - Mitochondrial dysfunction                          │
│    - Neuroinflammation                                  │
│    - Autophagy/lysosomal                                │
│    - Cell cycle arrest                                  │
│    - SASP factors                                       │
│  ✓ Pearson correlation: SnC mean vs Non-SnC mean        │
│  ✓ Deviations from y=x line indicate SnC enrichment     │
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
Multi-step annotation workflow:

1. Leiden subclustering (15-20 clusters)
2. Signature scoring (7 signatures)
3. Confidence assessment
4. Brase et al. (2024) alignment

Final States:
├─ astH0_Quiescent (homeostatic)
├─ astH0_Synaptic (synaptic support)
├─ astH0_Transitional (low confidence)
├─ astTinf_Inflammatory (DAA inflammatory)
├─ astMet_Stress (metabolic/heat shock)
├─ astR0_Neurotoxic (A1-like reactive)
├─ astR1_Neuroprotective (A2-like)
└─ astIFN_Novel (interferon - NOVEL)
```
*Reference: Brase et al. (2024) Nature Neuroscience*
*Novel state: astIFN not in Brase classification*

</td>
</tr>
</table>

<details>
<summary><b>📖 Click to expand: Astrocyte Annotation Details</b></summary>

**Gene Signatures Used:**

1. **Homeostatic (astH0)**: GRM3, SLC1A2, SLC1A3, ALDH1L1, AQP4, GLUL
2. **DAA Inflammatory (astTinf)**: CHI3L1, SERPINA3, GFAP, VIM, C3, GBP2
3. **DAA Stress (astMet)**: HSPA1A/B, HSPB1, HSP90AA1, MT1X, MT2A
4. **A1 Reactive (astR0)**: C3, GBP2, SERPING1, PSMB8
5. **A2 Reactive (astR1/R2)**: PTX3, CD14, S100A10, CD109, EMP1
6. **Interferon (astIFN)**: IFIT1/2/3, IFI44L, ISG15, MX1, OAS1, STAT1
7. **Synaptic**: GRM3/5, NTRK2, BDNF, SPARC, SPARCL1, THBS1/2

**Confidence Levels:**
- **High** (score >0.5): Clear signature match, strong marker expression
- **Moderate** (0.3-0.5): Mixed signatures or moderate expression
- **Low** (<0.3): Weak markers, assigned as "Transitional"

**Brase et al. (2024) Reference States:**
- astH0: Homeostatic baseline
- astIM: Immediate early response
- astMet: Metabolic stress
- astTinf: Terminal inflammatory
- astR0/R1/R2: Reactive states 0-2
- astProj: Projection-associated
- astWM: White matter

**Novel Finding:**
- **astIFN**: Interferon-responsive astrocytes with Type I IFN signaling
- Not described in Brase classification
- Characterized by IFIT1/2/3, ISG15, MX1, OAS1 expression

</details>

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
<td><b>DEG Signature Characterization</b></td>
<td>DEG overlap with SenePy, SASP, inflammation</td>
<td>Characterize known vs novel senescence mechanisms</td>
</tr>

<tr>
<td><b>Pathway Enrichment</b></td>
<td>SCPA (Reactome + KEGG)</td>
<td>Functional interpretation</td>
</tr>

<tr>
<td><b>Pathology Correlations</b></td>
<td>GLMM + Spearman/Pearson correlations</td>
<td>Association with neuropathology (Braak, CERAD, CDR, Aβ, NFTs)</td>
</tr>

</table>

**Pathology measures analyzed:**
- Braak stage (neurofibrillary tangle staging)
- CERAD score (neuritic plaque density)
- CDR (Clinical Dementia Rating)
- Amyloid-β areal density (quantitative, primarily Australian Brain)
- Neurofibrillary tangle density (quantitative, primarily Australian Brain)

**Signatures analyzed:**
- **SenePy signatures**: Hippocampus senescence modules (assess if SnC cells are limited to scoring genes)
- **SASP factors**: IL6, IL1A/B, TNF, CCL2/3/5, CXCL1/8/10, MMP3/9/12 (test for secretory phenotype)
- **Inflammation signatures**: TNF, IL1B, IL6, IL18, CCL2/3/4/5, CXCL1/10, TLR2/4 (test for inflammatory activation)

**Purpose**: 
- **High overlap** → Senescence driven by known pathways
- **Low overlap** → Novel/additional mechanisms involved
- **Unique DEGs** → Potential new senescence markers or cell-type-specific programs

**Key Question**: Are senescent cells only expressing known signatures, or are there novel genes driving senescence?

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
  author={Gaitos, Gerald, Souza, Iara, Harari, Oscar, and Saez-Atienzar, Sara},
  year={2025},
  journal={In preparation}
}
```

**Key References:**

**Microglial States:**
```bibtex
@article{garg2024,
  title={Exploring Cellular Heterogeneity: Single-Cell and Spatial Transcriptomics of Alzheimer Disease Brains},
  author={Garg, J. et al.},
  journal={Research Square},
  year={2024},
  doi={10.21203/rs.3.rs-5045715/v1}
}
```

**Astrocyte States:**
```bibtex
@article{brase2024,
  title={Single-nucleus RNA sequencing reveals astrocyte diversity and plasticity in Alzheimer's disease},
  author={Brase, L. et al.},
  journal={Nature Neuroscience},
  year={2024},
  note={Astrocyte nomenclature reference: astH0, astIM, astMet, astTinf, astR0/R1/R2, astProj, astWM}
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
- Department of Neurology, Ohio State University

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

[⬆ Back to Top](#-cellular-senescence-in-brain-aging-and-alzheimers-disease)

</div>

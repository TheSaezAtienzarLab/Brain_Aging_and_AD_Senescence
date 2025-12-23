# 🧬 Cellular Senescence in Brain Aging and Alzheimer's Disease

**Multi-Cohort Single-Nucleus RNA-seq Analysis**

[![Cohorts](https://img.shields.io/badge/Cohorts-4-blue.svg)]()
[![Samples](https://img.shields.io/badge/Samples-366-green.svg)]()
[![Nuclei](https://img.shields.io/badge/Nuclei-2M+-orange.svg)]()

*Discovery-replication study with meta-analysis examining cellular senescence patterns in human brain aging and Alzheimer's disease*

---

## 📊 Study Overview

| Component | Details |
|-----------|---------|
| **Design** | Discovery-Replication with Meta-Analysis |
| **Technology** | Single-nucleus RNA-seq (snRNA-seq) |
| **Discovery** | PsychAD (n=296 samples) |
| **Replication** | PsychENCODE (n=69), Mathys (n=30), Australian Brain (n=71) |
| **Brain Regions** | DLPFC, Frontal cortex, Parietal cortex |
| **Cell Types** | Microglia, Astrocytes, OPCs (glial focus) |
| **Total** | 366 samples, ~2M nuclei |

---

## 🎯 Study Aims

This repository contains analysis code for investigating:
- Cell-type-specific senescence patterns in brain aging
- Disease-associated senescence in Alzheimer's disease
- Cross-cohort validation using random-effects meta-analysis
- Molecular characterization of senescent glial cells

---

## 🔬 Study Design

```
DISCOVERY (PsychAD)
├─ Aging cohort: n=124 (20-80+ years, 7 age groups)
└─ AD cohort: n=172 (Young/Old Control, AD cases)
    ↓
Pan-cell type screening → Identified glial senescence
    ↓
REPLICATION
├─ PsychENCODE: n=69 (DLPFC, aging)
├─ Mathys: n=30 (FCX, AD)
└─ Australian Brain: n=71 (Parietal, AD)
    ↓
META-ANALYSIS (stratified by region)
├─ Aging: PsychAD + PsychENCODE (DLPFC)
├─ AD: PsychAD + Mathys (Frontal cortex)
└─ Validation: Australian Brain (Parietal, separate)
```

---

## 🧪 Analysis Pipeline

### **1. Data Processing**

**Quality Control**
- Cells: ≥200 genes/cell
- Genes: ≥3 cells/gene
- Normalization: 10,000 counts/cell + log transform

**Batch Correction**
- Method: Harmony integration
- Batch variable: Donor ID
- Components: 50 PCs

**Cell Type Annotation**
- 11 major brain cell types via canonical markers

---

### **2. Senescence Identification**

**SenePy Scoring**
1. Hippocampus-specific gene modules
2. Cell-type and sex-specific scoring
3. Threshold: mean + 2SD (youngest age group)
4. Binary classification: SnC vs Non-SnC

**Validation**
- Canonical markers: CDKN1A, CDKN2A, TP53
- SASP factors: IL6, IL8, CCL2, CXCL1
- Correlation with aging hallmarks (DDR, oxidative stress, mitochondrial dysfunction, etc.)

---

### **3. Glial Subclustering**

**Microglia States** (Garg et al., 2024)
- Homeostatic
- IFN-I/II/III responsive
- MHCII-expressing
- Neuronal surveillance
- Stress-associated

**Astrocyte States** (Serrano-Pozo et al., 2024)
- astH0: Homeostatic (quiescent, synaptic, transitional)
- astTinf: DAA inflammatory
- astMet: Metabolic/heat shock stress
- astR0: A1-like neurotoxic reactive
- astR1: A2-like neuroprotective
- astIFN: Interferon-responsive (novel state)

<details>
<summary><b>Astrocyte Annotation Details</b></summary>

**Gene Signatures:**
1. Homeostatic: GRM3, SLC1A2, SLC1A3, ALDH1L1, AQP4, GLUL
2. DAA Inflammatory: CHI3L1, SERPINA3, GFAP, VIM, C3, GBP2
3. Metabolic Stress: HSPA1A/B, HSPB1, HSP90AA1, MT1X, MT2A
4. A1 Reactive: C3, GBP2, SERPING1, PSMB8
5. A2 Reactive: PTX3, CD14, S100A10, CD109, EMP1
6. Interferon: IFIT1/2/3, IFI44L, ISG15, MX1, OAS1, STAT1
7. Synaptic: GRM3/5, NTRK2, BDNF, SPARC, SPARCL1, THBS1/2

**Confidence Assessment:**
- High (>0.5): Clear signature match
- Moderate (0.3-0.5): Mixed signatures
- Low (<0.3): Weak markers → "Transitional"

</details>

---

### **4. Statistical Analysis**

**Age-Associated Senescence**
- Method: Linear mixed-effects models (LMM)
- Formula: `%SnC ~ age × cell_type + sex + cohort + (1|donor)`
- Accounts for within-donor correlation
- Cell-type-specific slopes via interaction terms
- Software: statsmodels MixedLM (Python)

**Cell Type Composition**
- Method: Multiple linear regression with cube root transformation
- Formula: `cuberoot(proportion) ~ Age + Sex + Cohort`
- Variance stabilization for bounded proportions (0-100%)
- Software: sklearn LinearRegression (Python)

**Cross-Cohort Meta-Analysis**
- Method: DerSimonian-Laird random-effects
- Inverse-variance weighting
- Heterogeneity: Cochran's Q, I², τ²
- Stratified by brain region (DLPFC/FCX/Parietal)
- Software: Custom Python (NumPy, SciPy)

**Multiple Testing**
- FDR correction: Benjamini-Hochberg (α=0.05)
- Applied across all cell types

---

### **5. Differential Expression**

**Pseudobulk Aggregation**
- Sum counts per donor × cell type × senescence state
- Creates donor-level profiles

**DESeq2 Analysis**
- Via Seurat FindMarkers (R)
- Covariates: Sex + Cohort
- Age groups: Old ≥70y, Young ≤39y

**Comparisons** (per cell type):
1. Universal senescence: SnC vs Non-SnC
2. Aging-associated: Old SnC vs Young SnC
3. Aging in non-senescent: Old Non-SnC vs Young Non-SnC
4. Disease-associated: AD SnC vs Control SnC

**Thresholds:** FDR < 0.05, |log₂FC| > 0.5

---

### **6. Downstream Analyses**

**Transcriptional Variability**
- Coefficient of variation (CV)
- Minimum: 10 cells per group, 3 paired donors

**Variance Partition**
- Package: variancePartition (R)
- Focus: SenePy gene set
- Model: 8 fixed + 5 random effects

**Pathway Enrichment**
- Tools: SCPA + Enrichr
- Databases: MSigDB, GO Biological Process, KEGG
- Separate analysis for SnC vs Non-SnC DEGs

**Cell-Cell Communication**
- Tool: CellPhoneDB v5.0.0
- Groups: Cell type × senescence status
- QC: ≥200 cells per group
- Permutation testing: 1,000 iterations

**Pathology Correlations**
- Measures: Braak, CERAD, CDR, Aβ, NFTs
- Methods: Spearman/Pearson correlations

---

## 💻 Computational Environment

**Software versions used in this analysis are documented in `session_info.txt`**

**Python 3.10**
- Core: scanpy, senepy, numpy, pandas
- Statistics: statsmodels, scikit-learn, scipy
- Analysis: cellphonedb, gseapy

**R 4.x**
- Core: Seurat, dplyr, ggplot2
- Statistics: DESeq2, lme4, variancePartition
- Pathway: SCPA, msigdbr
- Visualization: ComplexHeatmap, ggpubr

---

## 📊 Cohort Details

| Cohort | Role | Region | n | Age Range | Groups | Nuclei |
|--------|------|--------|---|-----------|--------|--------|
| PsychAD Aging | Discovery | DLPFC | 124 | 20-80+ | 7 age groups | ~500K |
| PsychAD AD | Discovery | DLPFC | 172 | 60+ | Control/AD | ~700K |
| PsychENCODE | Replication | DLPFC | 69 | 30-80+ | 6 age groups | ~500K |
| Mathys | Replication | FCX | 30 | 70+ | NCI/MCI/AD | ~70K |
| Australian | Validation | Parietal | 71 | 24-93 | Control/AD | ~360K |

---

## 📁 Repository Structure

```
├── README.md                   # This file
├── session_info.txt            # Complete environment details
├── LICENSE                     # MIT License
│
├── notebooks/
│   ├── 01_preprocessing/       # QC, normalization, batch correction
│   ├── 02_senescence_scoring/  # SenePy workflow
│   ├── 03_statistical_analysis/# LMM, composition, meta-analysis
│   ├── 04_deg_analysis/        # Differential expression
│   └── 05_downstream/          # Pathway, communication, variance
│
├── scripts/
│   └── utils/                  # Reusable functions
│
└── data/
    └── README.md               # Data access instructions
```

---

## 📊 Data Availability

**Discovery Cohorts**
- PsychAD: https://doi.org/10.7303/syn60084804 (Synapse, requires registration)

**Replication Cohorts**
- PsychENCODE: Available through PsychENCODE portal
- Mathys: https://www.synapse.org/#!Synapse:syn18681734
- Australian Brain Bank: Contact for access

See `data/README.md` for detailed instructions.

---

## 📖 Citation

**This Study:**
```bibtex
@article{gaitos2025senescence,
  title={Multi-Cohort Analysis of Cellular Senescence in Brain Aging and Alzheimer's Disease},
  author={Gaitos, Gerald and Souza, Iara and Harari, Oscar and Saez-Atienzar, Sara},
  journal={In preparation},
  year={2025}
}
```

**Key References:**

**Microglial States:**
```bibtex
@article{garg2024microglia,
  title={Exploring Cellular Heterogeneity: Single-Cell and Spatial Transcriptomics of Alzheimer Disease Brains},
  author={Garg, J. and others},
  journal={Research Square},
  year={2024},
  doi={10.21203/rs.3.rs-5045715/v1}
}
```

**Astrocyte States:**
```bibtex
@article{serrano-pozo2024astrocytes,
  title={Astrocyte transcriptomic changes along the spatiotemporal progression of Alzheimer's disease},
  author={Serrano-Pozo, Alberto and Li, Huan and Li, Zhaozhi and others},
  journal={Nature Neuroscience},
  volume={27},
  number={12},
  pages={2384--2400},
  year={2024},
  doi={10.1038/s41593-024-01791-4}
}
```

**SenePy:**
```bibtex
@article{casella2023senepy,
  title={SenePy: a Python library for single-cell senescence analysis},
  author={Casella, G. and others},
  year={2023}
}
```

**PsychAD:**
```bibtex
@article{fullard2024psychad,
  title={Single-nucleus transcriptomic atlas of the human brain},
  author={Fullard, J.F. and others},
  journal={Nature},
  year={2024}
}
```

**Mathys:**
```bibtex
@article{mathys2019single,
  title={Single-cell transcriptomic analysis of Alzheimer's disease},
  author={Mathys, H. and others},
  journal={Nature},
  volume={570},
  pages={332--337},
  year={2019},
  doi={10.1038/s41586-019-1195-2}
}
```

---

## 👥 Team

**Principal Investigator**
- Sara Saez-Atienzar, PhD | The Ohio State University Wexner Medical Cent

**Lead Analyst**
- Gerald Gaitos, MD, MSc | The Ohio State University Wexner Medical Center

**Collaborators**
- Iara Souza, PhD | The Ohio State University Wexner Medical Cent
- Oscar Harari, PhD | The Ohio State University Wexner Medical Cent

---

## 📬 Contact

**Analysis Questions:**
- Gerald Gaitos: gerald.gaitos@osumc.edu

**Data Access:**
- PsychAD: Via Synapse portal
- Collaborations: Contact PI

---

## 📝 License

**Code:** MIT License (see LICENSE file)

**Data:** Subject to consortium data use agreements
- PsychAD: Synapse Terms of Use
- PsychENCODE: Data access agreement required
- Mathys: Synapse Terms of Use
- Australian Brain Bank: Contact for terms

---

## 🙏 Acknowledgments

**Data Contributors:**
- PsychAD Consortium
- PsychENCODE Consortium
- Mathys et al. study team
- Australian Brain Bank

**Computational Resources:**
- Ohio Supercomputer Center

---

<div align="center">

**Last Updated:** December 2025

[⬆ Back to Top](#-cellular-senescence-in-brain-aging-and-alzheimers-disease)

</div>

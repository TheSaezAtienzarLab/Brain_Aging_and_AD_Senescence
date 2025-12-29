# Cellular Senescence in Brain Aging and Alzheimer's Disease

**Multi-cohort single-nucleus RNA-seq analysis examining cellular senescence patterns across aging and disease**

[![DOI](https://img.shields.io/badge/DOI-pending-blue)]() [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Overview

This repository contains analysis code for a discovery-replication study investigating cellular senescence in human brain across aging and Alzheimer's disease using single-nucleus RNA-sequencing.

**Study Design:** Discovery (PsychAD) → Replication (PsychENCODE, Mathys, Australian Brain) → Meta-Analysis

**Key Questions:**
1. Does cellular senescence increase with age in healthy brain?
2. Does Alzheimer's disease increase senescence beyond normal aging?
3. Which cell types show age- and disease-associated senescence?

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

**Meta-Analysis:**
- Aging: PsychAD Aging + PsychENCODE (DLPFC)
- Disease: PsychAD AD + Mathys (Frontal cortex)
- Validation: Australian Brain (Parietal, independent)

---

## Repository Structure

```
├── config/
│   └── datasets.yaml       # Dataset configurations
│
├── notebooks/              # Analysis notebooks (numbered 00-07)
│   ├── 00_preprocessing/
│   ├── 01_senescence_scoring/
│   ├── 02_glial_subclustering/
│   ├── 03_demographics/
│   ├── 04_composition_analysis/
│   ├── 05_statistical_analysis/
│   ├── 06_deg_analysis/
│   └── 07_downstream_analysis/
│       ├── pathway_enrichment/      # SCPA + GSEApy
│       ├── cell_communication/      # CellPhoneDB
│       └── expression_variability/  # CV + variance partition
│
├── scripts/                # Utility functions
├── session_info.txt        # Software versions
└── README.md              # This file
```

**Execution Guide:** See `notebooks/README.md` for detailed pipeline execution instructions.

---

## Methods Summary

### Data Processing
- **QC:** 200-8,000 genes/cell, <5% mitochondrial (snRNA-seq), ≥3 cells/gene
- **Normalization:** 10,000 counts/cell, log1p transform
- **Batch Correction:** Harmony (50 PCs, dataset-specific batch variable)
- **Cell Types:** 11 major types via canonical markers

### Senescence Scoring
- **Method:** SenePy (hippocampus modules)
- **Threshold:** Mean + 2SD (youngest age group)
- **Cell-type and sex-specific scoring**

### Glial Subclustering
Performed on PsychAD Aging, PsychAD AD, and PsychENCODE only:
- **Microglia:** 5 states (Garg et al. 2024)
- **Astrocytes:** 6 states (Serrano-Pozo et al. 2024)

### Statistical Analysis

**Aging Analysis (PsychAD Aging, PsychENCODE):**
```python
# Linear Mixed Model (Python statsmodels)
%SnC ~ Age × Cell_Type + Sex + Cohort + (1|Donor)

# Meta-Analysis: DerSimonian-Laird random effects
```

**Disease Analysis (PsychAD AD, Mathys, Australian):**
```python
# Linear Mixed Model (Python statsmodels)
%SnC ~ Condition + Age + Sex + Cohort + (1|Donor)

# Primary Comparison: AD Cases vs Age-matched Controls
# Meta-Analysis: DerSimonian-Laird random effects
```

**Multiple Testing:** Benjamini-Hochberg FDR correction

### Differential Expression
- **Aggregation:** Pseudobulk (per Donor × Cell_Type × State) using Seurat (R)
- **Method:** DESeq2
- **Comparisons:** SnC vs Non-SnC, Age effects, Disease effects
- **Thresholds:** FDR < 0.05, |log₂FC| > 0.5
- **Note:** Uses raw counts from `layers['counts']`

### Pathway Analysis
- **SCPA (R):** Cell-level pathway activity scores
- **GSEApy (Python):** Gene-level enrichment analysis using DEG lists
- **Databases:** MSigDB, GO Biological Process, KEGG, Reactome

### Downstream Analyses
- **CellPhoneDB (Python):** Cell-cell communication (1,000 permutations)
- **Transcriptional Variability (Python):** Coefficient of variation analysis
- **Variance Partition (R):** Decompose expression variance by factors

---

## Software

**Complete software versions and package details:** See `session_info.txt`

**Core Dependencies:**
- Python 3.10: scanpy, senepy, statsmodels, scipy, numpy, pandas, cellphonedb, pyyaml
- R 4.x: Seurat, DESeq2, SCPA, variancePartition, msigdbr, dplyr, ggplot2

---

## Data Availability

### Raw Data
- **PsychAD:** https://doi.org/10.7303/syn60084804 (Synapse)
- **PsychENCODE:** https://psychencode.org
- **Mathys:** https://www.synapse.org/#!Synapse:syn18681734
- **Australian Brain Bank:** Contact for access

### Processed Data
Processed h5ad files available upon reasonable request.

### Data Use
All datasets subject to their respective data use agreements. See individual consortium websites for terms.

---

## Citation

If you use this code or data, please cite:

```bibtex
@article{gaitos2025senescence,
  title={Multi-Cohort Analysis of Cellular Senescence in Brain Aging and Alzheimer's Disease},
  author={Gaitos, Gerald and Souza, Iara and Harari, Oscar and Saez-Atienzar, Sara},
  journal={In preparation},
  year={2025}
}
```

### Key Methods Citations

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

**Microglia States:**
```bibtex
@article{garg2024microglia,
  title={Exploring Cellular Heterogeneity in Alzheimer Disease Brains},
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
  author={Serrano-Pozo, Alberto and others},
  journal={Nature Neuroscience},
  volume={27},
  pages={2384--2400},
  year={2024},
  doi={10.1038/s41593-024-01791-4}
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

## Contributing

This repository contains analysis code for a specific study. For questions about methods or code:

**Analysis Questions:** Gerald Gaitos (gerald.gaitos@osumc.edu)  
**Data Access:** See Data Availability section above

---

## License

**Code:** MIT License  
**Data:** Subject to consortium agreements (see Data Availability)

---

## Acknowledgments

**Data Contributors:**
- PsychAD Consortium
- PsychENCODE Consortium  
- Mathys et al. study team
- Australian Brain Bank

**Computational Resources:**
- Ohio Supercomputer Center

**Team:**
- Sara Saez-Atienzar, PhD (PI) - The Ohio State University
- Gerald Gaitos, MD, MSc (Lead Analyst) - The Ohio State University
- Iara Souza, PhD - The Ohio State University
- Oscar Harari, PhD - The Ohio State University

---

## Notes

- **Configuration:** Dataset-specific settings stored in `config/datasets.yaml` for easy customization
- **Preprocessing notebooks** are generic and reusable across cohorts
- **Subclustering** performed only on discovery and primary replication cohorts due to computational constraints
- **Meta-analyses** stratified by brain region (DLPFC vs Frontal vs Parietal)
- **Downstream analyses** (pathways, communication, variability) performed per cohort without cross-cohort comparison
- **Data layers:** Raw counts preserved in `layers['counts']` for DESeq2; log-normalized used for analysis; scaled data stored separately
- All statistical tests use FDR correction for multiple comparisons
- See individual module READMEs for detailed methods

---

<div align="center">

**Last Updated:** December 2025

</div>

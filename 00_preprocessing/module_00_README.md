# Module 00: Preprocessing

Quality control, normalization, batch correction, and clustering for snRNA-seq data.

---

## Quick Start

```python
# In notebook: Change only this line
DATASET = 'psychad_aging'  

# Run all cells → outputs preprocessed h5ad + QC plots
```

---

## Configuration

Dataset settings are in `config/datasets.yaml`. To add a dataset:

```yaml
my_dataset:
  input_file: /path/to/data.h5ad
  batch_key: Sample
  cell_type_column: celltype
```

**Key point:** Different datasets use different batch keys (`Sample`, `Donor`, `individual`, `projid`) - automatically handled by config.

---

## Pipeline Steps

```
Load → QC Filter → Normalize → Log → HVGs → PCA → 
Harmony → UMAP → Cluster → Validate → Save
```

**QC Thresholds:** 200-8000 genes/cell, <5% MT (snRNA-seq), ≥3 cells/gene  
**Outputs:** Preprocessed h5ad with multiple data layers

---

## Data Layers Created

| Layer | Use |
|-------|-----|
| `adata.X` | Log-normalized (active for Python analysis) |
| `layers['counts']` | Raw counts (for DESeq2 in Module 06) |
| `layers['scaled']` | Scaled data (available but not active) |
| `adata.raw` | Full log-normalized matrix (for visualization) |

**Critical:** Raw counts in `layers['counts']` needed for R/DESeq2.

---

## Outputs

```
data/processed/[dataset]_preprocessed.h5ad
figures/00_preprocessing/[dataset]/*.pdf
```

**Figures:** QC before/after, HVGs, PCA variance, batch correction, clusters, cell type validation (Yang-style dotplot)

---

## Troubleshooting

**Config not found:** Check `config/datasets.yaml` exists  
**Batch key error:** Verify column name in your h5ad, update config  
**Memory error:** Use high-memory node  
**No markers found:** Check gene naming (MT- vs mt-), update config

---

## Customization

Edit `config/datasets.yaml` to adjust:
- QC thresholds (MT%, min/max genes)
- Clustering resolution
- Canonical markers for validation

---

## Next Steps

**→ Module 01:** Senescence scoring (uses `adata.X`)  
**→ Module 02:** Glial subclustering  
**→ Module 06:** DEG analysis (uses `layers['counts']`)

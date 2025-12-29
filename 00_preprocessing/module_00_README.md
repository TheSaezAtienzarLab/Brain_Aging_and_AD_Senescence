# Module 00: Preprocessing

Quality control, normalization, batch correction, and clustering for snRNA-seq data.

---

## Quick Start

**Change one line in the notebook:**
```python
DATASET = 'psychad_aging'  # Options: psychad_aging, psychad_ad, psychencode, mathys, australian
```

**Run all cells** → outputs preprocessed h5ad + QC plots

---

## What It Does

```
Load → QC Filter → Normalize → Log → HVGs → PCA → 
Harmony → UMAP → Cluster → Validate → Save
```

**QC Thresholds:** 200-8000 genes/cell, <5% MT (snRNA-seq), ≥3 cells/gene  
**Key Feature:** Raw counts preserved for DESeq2

---

## Configuration

All settings are **in the notebook** - no external files needed.

### Dataset-Specific Settings

Edit the `DATASET_CONFIG` dictionary in Cell 2:

```python
DATASET_CONFIG = {
    'psychad_aging': {
        'input_file': '/path/to/your/aging.h5ad',
        'batch_key': 'Sample',
        'cell_type_column': 'broad_class',
    },
    # Add more datasets here
}
```

**Key point:** Different datasets use different batch keys:
- PsychAD: `Sample`
- PsychENCODE: `Donor`
- Mathys: `individual`
- Australian: `projid`

### Global Parameters

Edit these variables in Cell 2:
- `MIN_GENES`, `MAX_GENES`, `MAX_MT_PERCENT` - QC thresholds
- `TARGET_SUM` - Normalization (10,000)
- `N_TOP_GENES` - HVGs (2,000)
- `N_PCS` - PCA components (50)
- `LEIDEN_RESOLUTION` - Clustering (0.8)
- `BASE_DIR` - Output location

---

## Data Layers Created

| Layer | Use |
|-------|-----|
| `adata.X` | Log-normalized (active for Python analysis) |
| `layers['counts']` | Raw counts (for DESeq2 in Module 06) |
| `layers['scaled']` | Scaled data (available but not active) |
| `adata.raw` | Full log-normalized matrix (for visualization) |

**Critical:** Raw counts in `layers['counts']` needed for R/DESeq2 conversion.

---

## Outputs

```
data/processed/[dataset]_preprocessed.h5ad
figures/00_preprocessing/[dataset]/*.pdf
```

**Figures Generated:**
- QC metrics before filtering
- Highly variable genes
- PCA variance explained
- Batch correction (UMAP)
- Leiden clusters
- Cell type validation (Yang-style dotplot)
- Cell type UMAP

---

## Adding New Datasets

Just add to the config dictionary:

```python
DATASET_CONFIG = {
    # ... existing datasets ...
    
    'my_new_dataset': {
        'input_file': '/path/to/my/data.h5ad',
        'batch_key': 'Sample',  # or Donor, individual, projid
        'cell_type_column': 'celltype',
    },
}
```

Then run with `DATASET = 'my_new_dataset'`

---

## Troubleshooting

**Batch key not found:**
- Check column names in your h5ad: `adata.obs.columns`
- Update `batch_key` in config

**Memory error:**
- Use high-memory node
- Large datasets (>500K cells) need 64+ GB

**No markers found:**
- Check gene naming (MT- vs mt-)
- Update `CANONICAL_MARKERS` dict in config cell

**Wrong cell type column:**
- Check: `adata.obs.columns`
- Update `cell_type_column` in config

---

## Customization

All parameters are at the top of the notebook. Common adjustments:

**Stricter QC:**
```python
MAX_MT_PERCENT = 3  # More strict
MAX_GENES = 6000    # Remove more doublets
```

**More clusters:**
```python
LEIDEN_RESOLUTION = 1.2  # Higher = more clusters
```

**Different markers:**
```python
CANONICAL_MARKERS = {
    'MyCustomCellType': ['GENE1', 'GENE2', 'GENE3'],
}
```

---

## Next Steps

**→ Module 01:** Senescence scoring (uses `adata.X`)  
**→ Module 02:** Glial subclustering  
**→ Module 06:** DEG analysis (uses `layers['counts']`)

---

**Last Updated:** December 2025  
**Note:** Self-contained - no external config files needed

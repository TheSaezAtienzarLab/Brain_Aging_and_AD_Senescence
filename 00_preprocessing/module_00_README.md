# Module 00: Data Preprocessing

Complete preprocessing pipeline for single-nucleus RNA-seq data with external configuration support.

---

## Overview

This module performs comprehensive quality control, normalization, batch correction, and clustering of snRNA-seq data. The pipeline is designed to be reusable across all cohorts with dataset-specific settings managed through an external configuration file.

**Key Features:**
- ✅ External YAML configuration for easy dataset management
- ✅ Appropriate QC thresholds for nuclear RNA-seq
- ✅ Proper data layer management (raw counts preserved for DESeq2)
- ✅ Yang-style publication-quality cell type validation
- ✅ Batch correction with Harmony
- ✅ Comprehensive QC visualizations

---

## Files

```
00_preprocessing/
├── README.md                           # This file
└── 01_preprocessing_complete.ipynb     # Complete preprocessing pipeline
```

**Single comprehensive notebook** - all preprocessing steps in one place for faster execution and easier iteration.

---

## Configuration

### External Configuration File

Dataset-specific settings are stored in `config/datasets.yaml` for easy management:

```yaml
# config/datasets.yaml
datasets:
  psychad_aging:
    input_file: /path/to/psychad_aging_raw.h5ad
    batch_key: Sample
    cell_type_column: broad_class
    ...
```

### Supported Datasets

| Dataset | Batch Key | Cell Type Column | n |
|---------|-----------|------------------|---|
| PsychAD Aging | `Sample` | `broad_class` | 124 |
| PsychAD AD | `Sample` | `broad_class` | 172 |
| PsychENCODE | `Donor` | `cell_type` | 69 |
| Mathys | `individual` | `broad.cell.type` | 30 |
| Australian | `projid` | `celltype` | 71 |

### Adding New Datasets

Simply add a new entry to `config/datasets.yaml`:

```yaml
my_new_dataset:
  input_file: /path/to/data.h5ad
  batch_key: Sample          # or Donor, individual, projid
  cell_type_column: celltype
  sample_column: Sample
  donor_column: Donor
  description: "My dataset description"
  region: DLPFC
  n_samples: 50
  analysis_type: aging       # or disease
```

---

## Parameters

### QC Thresholds (snRNA-seq)

```python
MIN_GENES = 200              # Minimum genes per cell
MAX_GENES = 8000             # Maximum genes (doublet removal)
MAX_MT_PERCENT = 5           # Strict for nuclear RNA-seq
MIN_CELLS = 3                # Genes must be in ≥3 cells
```

**Note:** 5% MT threshold is appropriate for high-quality nuclear RNA-seq. All datasets in this study use snRNA-seq (not whole-cell).

### Normalization

```python
TARGET_SUM = 10000           # CPM normalization
```

### Feature Selection

```python
N_TOP_GENES = 2000           # Highly variable genes
SUBSET_HVG = False           # Keep all genes (don't subset)
```

### Dimensionality Reduction

```python
N_PCS = 50                   # PCA components
BATCH_KEY = [dataset-specific]  # Sample, Donor, individual, or projid
```

### Clustering

```python
N_NEIGHBORS = 30
LEIDEN_RESOLUTION = 0.8
LEIDEN_FLAVOR = 'igraph'     # Fast for large datasets
LEIDEN_N_ITERATIONS = 2
```

---

## Data Layers

The preprocessing pipeline creates multiple data layers for different downstream uses:

| Layer | Content | Purpose |
|-------|---------|---------|
| `adata.X` | Log-normalized | **Active layer** for analysis |
| `adata.layers['counts']` | Raw counts | For DESeq2 (R conversion) |
| `adata.layers['normalized']` | Normalized counts | Intermediate |
| `adata.layers['log1p']` | Log-normalized | Same as adata.X |
| `adata.layers['scaled']` | Scaled data | If needed by specific tools |
| `adata.raw` | Full log-normalized | For visualization |

### Why This Matters

**For Python Analysis (Modules 01-05):**
- Use `adata.X` (log-normalized) ✅

**For R/DESeq2 (Module 06):**
- Use `adata.layers['counts']` (raw integer counts) ✅
- DESeq2 **requires** unnormalized counts

**For Visualization:**
- Use `adata.raw` (all genes, log-normalized) ✅

---

## Cell Type Validation

### Yang-Style Dotplot

Clean, publication-ready visualization using 2-3 canonical markers per cell type:

```python
CANONICAL_MARKERS = {
    'Excitatory': ['SLC17A7', 'SATB2'],
    'Inhibitory': ['GAD1', 'GAD2'],
    'Astrocyte': ['SLC1A2', 'GFAP', 'AQP4'],
    'Oligodendrocyte': ['MBP', 'MOBP', 'MOG'],
    'OPC': ['PDGFRA', 'CSPG4'],
    'Microglia': ['CX3CR1', 'TMEM119', 'CSF1R'],
    'Endothelial': ['CLDN5', 'FLT1'],
    'Pericyte': ['PDGFRB', 'RGS5'],
    'VLMC': ['DCN', 'COL1A1'],
    'VSMC': ['MYH11', 'TAGLN'],
}
```

**Style:**
- Clean, minimal (2-3 markers per type)
- Single color scheme (`cmap='Reds'`)
- Standard variance scaling
- Professional aesthetics (Arial font, 300 DPI)

---

## Usage

### Basic Execution

```python
# In notebook: Change only this line
DATASET = 'psychad_aging'  # Options: psychad_aging, psychad_ad, psychencode, mathys, australian

# Run all cells
# Configuration automatically loaded from config/datasets.yaml
```

### Output Files

**Processed Data:**
```
data/processed/
└── [dataset]_preprocessed.h5ad
```

**Figures:**
```
figures/00_preprocessing/[dataset]/
├── [dataset]_qc_before_filtering.pdf
├── [dataset]_hvgs.pdf
├── [dataset]_pca_variance.pdf
├── [dataset]_batch_correction.pdf
├── [dataset]_leiden_clusters.pdf
├── [dataset]_marker_validation_dotplot.pdf
└── [dataset]_celltypes.pdf
```

---

## Runtime & Resources

### Expected Runtime (per dataset)

| Dataset | Cells | Runtime | Memory |
|---------|-------|---------|--------|
| PsychAD Aging | ~500K | 2-3 hours | 64 GB |
| PsychAD AD | ~700K | 3-4 hours | 96 GB |
| PsychENCODE | ~500K | 2-3 hours | 64 GB |
| Mathys | ~70K | 30 min | 16 GB |
| Australian | ~360K | 1-2 hours | 48 GB |

**Recommendations:**
- Use high-memory nodes for large datasets
- Consider batch submission for multiple cohorts
- Total pipeline: ~10-15 hours for all cohorts

---

## Quality Control Checks

### Automated QC

The notebook includes comprehensive QC visualizations:

1. **Before Filtering:**
   - Genes per cell distribution
   - Total counts distribution
   - Mitochondrial % distribution

2. **Feature Selection:**
   - HVG dispersion plot
   - PCA variance explained

3. **Batch Correction:**
   - UMAP colored by batch
   - Visual assessment of mixing

4. **Clustering:**
   - UMAP with Leiden clusters
   - Cluster size distribution

5. **Cell Type Validation:**
   - Canonical marker dotplot
   - UMAP with cell types

### Manual Checks

After running, verify:
- [ ] QC filtering removed appropriate % of cells (typically 5-15%)
- [ ] Batch effects minimized (UMAP shows good mixing)
- [ ] Canonical markers show expected expression patterns
- [ ] Number of clusters reasonable for dataset
- [ ] No obvious batch-driven clusters

---

## Troubleshooting

### Common Issues

**1. Configuration file not found**
```
Error: Config file not found: ../config/datasets.yaml
```
**Solution:** Ensure `config/datasets.yaml` exists in repository root

**2. Batch key not found**
```
Error: Batch key 'Sample' not found in adata.obs
```
**Solution:** Check column names in input h5ad file, update config

**3. Memory error**
```
MemoryError: Unable to allocate array
```
**Solution:** Request high-memory node or reduce dataset size

**4. No markers found**
```
Warning: No canonical markers found in dataset
```
**Solution:** Check gene naming convention (e.g., MT- vs mt-), update markers in config

**5. Too many cells removed by QC**
```
Warning: >30% of cells removed
```
**Solution:** Check QC thresholds, may need adjustment for specific dataset

---

## Customization

### Adjusting QC Thresholds

Edit `config/datasets.yaml`:

```yaml
parameters:
  qc:
    min_genes: 200           # Adjust if needed
    max_genes: 8000          # Adjust if needed
    max_mt_percent: 5        # For snRNA-seq (strict)
                             # Use 10-20 for scRNA-seq
```

### Adding Custom Markers

Edit `config/datasets.yaml`:

```yaml
canonical_markers:
  MyCustomCellType:
    - GENE1
    - GENE2
    - GENE3
```

### Changing Clustering Resolution

Edit `config/datasets.yaml`:

```yaml
parameters:
  clustering:
    leiden_resolution: 0.8   # Lower = fewer clusters
                             # Higher = more clusters
```

---

## Next Steps

After preprocessing is complete:

**→ Module 01:** Senescence scoring with SenePy
- Input: `[dataset]_preprocessed.h5ad`
- Uses: `adata.X` (log-normalized)

**→ Module 02:** Glial subclustering (Microglia, Astrocytes, OPC)
- Input: `[dataset]_preprocessed.h5ad`
- Subset: Glial cell types only

**→ Module 06:** DEG analysis with DESeq2 (R)
- Input: `[dataset]_preprocessed.h5ad`
- Uses: `adata.layers['counts']` (raw counts)

---

## Software Requirements

**Python Packages:**
- `scanpy >= 1.9.0`
- `scanpy-external`
- `numpy >= 1.21.0`
- `pandas >= 1.3.0`
- `matplotlib >= 3.4.0`
- `seaborn >= 0.11.0`
- `pyyaml >= 5.4.0`
- `scipy >= 1.7.0`

---

## References

**Methods:**
- Normalization: [Hafemeister & Satija, 2019](https://doi.org/10.1186/s13059-019-1874-1)
- Batch Correction: [Korsunsky et al., 2019 (Harmony)](https://doi.org/10.1038/s41592-019-0619-0)
- Clustering: [Leiden algorithm](https://doi.org/10.1038/s41598-019-41695-z)

**Style:**
- Marker validation approach: Yang et al. style (clean, minimal markers)

---

## Notes

- **One comprehensive notebook** approach chosen for efficiency
- **External configuration** enables easy dataset addition
- **Data layer preservation** critical for downstream R analysis
- **5% MT threshold** appropriate for all nuclear RNA-seq datasets
- **Batch keys vary** by dataset - automatically handled by config

---

**Last Updated:** December 2025  
**Module:** 00 - Preprocessing  
**Status:** Production ready

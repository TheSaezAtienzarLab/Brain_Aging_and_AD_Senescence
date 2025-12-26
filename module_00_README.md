# Module 00: Preprocessing

**Quality control, normalization, batch correction, and clustering**

---

## 🎯 Purpose

Prepare raw single-nucleus RNA-seq data for downstream analysis through systematic quality control, normalization, batch correction, and cell type identification.

---

## 📂 Module Contents

```
00_preprocessing/
├── README.md                           # This file
├── 01_quality_control.ipynb           # Filter cells and genes
├── 02_normalization.ipynb             # Normalize and identify HVGs
├── 03_batch_correction.ipynb          # Harmony integration
└── 04_clustering_visualization.ipynb  # UMAP and cell type annotation
```

**Total: 4 notebooks, run sequentially per cohort**

---

## 🔄 Workflow

```
Raw h5ad
    ↓
[01] Quality Control
    ├─ Filter low-quality cells
    ├─ Filter low-count genes
    └─ Calculate QC metrics
    ↓
[02] Normalization
    ├─ Normalize to 10,000 counts/cell
    ├─ Log-transform
    └─ Identify highly variable genes
    ↓
[03] Batch Correction
    ├─ PCA (50 components)
    ├─ Harmony integration (batch = Donor)
    └─ Generate corrected PCA
    ↓
[04] Clustering & Visualization
    ├─ UMAP embedding
    ├─ Leiden clustering
    ├─ Cell type annotation (11 major types)
    └─ Quality visualizations
    ↓
Final preprocessed h5ad
```

---

## 📊 Notebooks

### **01_quality_control.ipynb**

**Purpose:** Remove low-quality cells and uninformative genes

**Input:** 
- Raw h5ad file with counts matrix
- Metadata: Donor, Sample, Age, Sex, Diagnosis, etc.

**QC Thresholds:**
```python
# Cells
MIN_GENES = 200          # Min genes detected per cell
MAX_GENES = 8000         # Max genes (remove potential doublets)
MAX_MT_PERCENT = 20      # Max % mitochondrial reads

# Genes  
MIN_CELLS = 3            # Min cells expressing gene
```

**Metrics Calculated:**
- `n_genes_by_counts`: Number of genes detected
- `total_counts`: Total UMI counts per cell
- `pct_counts_mt`: % mitochondrial gene expression

**Output:**
- `01_qc_filtered_{DATASET}.h5ad`
- QC distribution plots (before/after)
- Summary statistics

**Expected Results:**
- Remove ~10-20% low-quality cells
- Remove ~5-10% low-count genes
- Retain high-quality nuclei for analysis

---

### **02_normalization.ipynb**

**Purpose:** Normalize counts and identify variable genes

**Input:** `01_qc_filtered_{DATASET}.h5ad`

**Normalization:**
```python
# Total-count normalize to 10,000 per cell
sc.pp.normalize_total(adata, target_sum=1e4)

# Log-transform: log(x + 1)
sc.pp.log1p(adata)
```

**Highly Variable Genes (HVGs):**
```python
# Identify top 2,000 HVGs
sc.pp.highly_variable_genes(
    adata,
    n_top_genes=2000,
    flavor='seurat',
    subset=False  # Keep all genes
)
```

**Output:**
- `02_normalized_{DATASET}.h5ad`
- HVG selection plot
- Expression distribution plots

**Expected Results:**
- Normalized counts in `adata.X`
- Raw counts preserved in `adata.raw`
- 2,000 HVGs identified

---

### **03_batch_correction.ipynb**

**Purpose:** Remove donor-specific batch effects using Harmony

**Input:** `02_normalized_{DATASET}.h5ad`

**PCA:**
```python
# Compute PCA on HVGs
sc.tl.pca(
    adata,
    n_comps=50,
    svd_solver='arpack',
    use_highly_variable=True
)
```

**Harmony Integration:**
```python
import scanpy.external as sce

# Batch correction by Donor
sce.pp.harmony_integrate(
    adata,
    key='Donor',           # Batch variable
    basis='X_pca',         # Input PCA
    adjusted_basis='X_pca_harmony'  # Output
)
```

**Output:**
- `03_batch_corrected_{DATASET}.h5ad`
- PCA plots (before/after Harmony)
- Batch effect visualization (UMAP colored by Donor)

**Expected Results:**
- Reduced donor-specific clustering
- Preserved biological variation
- Corrected PCA in `adata.obsm['X_pca_harmony']`

---

### **04_clustering_visualization.ipynb**

**Purpose:** Generate UMAP, cluster cells, and annotate cell types

**Input:** `03_batch_corrected_{DATASET}.h5ad`

**Neighbor Graph:**
```python
# Build KNN graph on Harmony PCs
sc.pp.neighbors(
    adata,
    n_neighbors=30,
    n_pcs=50,
    use_rep='X_pca_harmony'
)
```

**UMAP:**
```python
# Generate 2D embedding
sc.tl.umap(
    adata,
    min_dist=0.3,
    spread=1.0
)
```

**Clustering:**
```python
# Leiden clustering
sc.tl.leiden(
    adata,
    resolution=0.8,
    key_added='leiden'
)
```

**Cell Type Annotation:**

Automated annotation using canonical markers:

| Cell Type | Markers |
|-----------|---------|
| Excitatory Neuron | SLC17A7, SATB2, CAMK2A |
| Inhibitory Neuron | GAD1, GAD2, SLC32A1 |
| Astrocyte | AQP4, GFAP, SLC1A2 |
| Oligodendrocyte | MBP, MOG, PLP1 |
| OPC | PDGFRA, CSPG4, VCAN |
| Microglia | CSF1R, C3, CX3CR1 |
| Endothelial | CLDN5, FLT1, VWF |
| Pericyte | PDGFRB, ABCC9, RGS5 |
| VLMC | COLEC12, MFGE8 |
| VSMC | ACTA2, MYH11, TAGLN |
| Immune | PTPRC, CD3D, MS4A1 |

**Output:**
- `04_clustered_{DATASET}.h5ad` (final preprocessed file)
- UMAP plots (by cell type, QC metrics, batch)
- Cell type proportions
- Marker expression dotplots

**Expected Results:**
- Clear cell type separation
- 11 major cell types identified
- Minimal batch effects visible

---

## 🔧 Configuration

### **Key Parameters (Consistent Across Cohorts)**

```python
# Quality Control
MIN_GENES = 200
MAX_GENES = 8000
MAX_MT_PERCENT = 20
MIN_CELLS = 3

# Normalization
TARGET_SUM = 1e4
N_TOP_GENES = 2000

# PCA & Harmony
N_PCS = 50
BATCH_KEY = 'Donor'

# Clustering
N_NEIGHBORS = 30
LEIDEN_RESOLUTION = 0.8
UMAP_MIN_DIST = 0.3
```

### **Dataset-Specific (Set at Top of Each Notebook)**

```python
# ═══════════════════════════════════════════════════════════════════
# DATASET CONFIGURATION
# ═══════════════════════════════════════════════════════════════════
DATASET = 'psychad_aging'  # CHANGE THIS FOR EACH COHORT

# Options:
# - 'psychad_aging'
# - 'psychad_ad'
# - 'psychencode'
# - 'mathys'
# - 'australian'

RANDOM_SEED = 42
FIGURE_DPI = 300
```

---

## 📁 File Structure

### **Inputs (per cohort):**
```
data/raw/{DATASET}_raw.h5ad
```

### **Outputs (per cohort):**
```
data/processed/
├── 01_qc_filtered_{DATASET}.h5ad
├── 02_normalized_{DATASET}.h5ad
├── 03_batch_corrected_{DATASET}.h5ad
└── 04_clustered_{DATASET}.h5ad

figures/00_preprocessing/{DATASET}/
├── 01_qc_metrics.pdf
├── 02_hvg_selection.pdf
├── 03_batch_correction.pdf
└── 04_cell_types.pdf
```

---

## 🚀 Execution

### **Run Sequentially for Each Cohort:**

```bash
# Set DATASET variable at top of each notebook

# Cohort 1: PsychAD Aging
cd notebooks/00_preprocessing/
jupyter notebook 01_quality_control.ipynb           # Set DATASET='psychad_aging'
jupyter notebook 02_normalization.ipynb             # Set DATASET='psychad_aging'
jupyter notebook 03_batch_correction.ipynb          # Set DATASET='psychad_aging'
jupyter notebook 04_clustering_visualization.ipynb  # Set DATASET='psychad_aging'

# Repeat for other 4 cohorts
# - psychad_ad
# - psychencode
# - mathys
# - australian
```

**Total Executions:** 4 notebooks × 5 cohorts = 20 runs

**Expected Runtime per Cohort:** 2-3 hours (depends on cohort size)

---

## 📊 Quality Checks

### **After 01_quality_control.ipynb:**
- [ ] Cell count reduced by 10-20%
- [ ] MT% distribution looks normal (<20%)
- [ ] No major batch effects in raw data

### **After 02_normalization.ipynb:**
- [ ] 2,000 HVGs identified
- [ ] Expression distribution normalized
- [ ] Raw counts preserved in .raw

### **After 03_batch_correction.ipynb:**
- [ ] Donor effects reduced in PCA
- [ ] No over-correction (biology preserved)
- [ ] Harmony PCs available

### **After 04_clustering_visualization.ipynb:**
- [ ] 11 cell types clearly separated
- [ ] UMAP shows continuous structure (not fragmented)
- [ ] Cell type markers expressed correctly
- [ ] Minimal batch effects in UMAP

---

## 🔬 Technical Details

### **Software Requirements:**

```python
# Core
scanpy >= 1.9.0
anndata >= 0.8.0
numpy >= 1.21.0
pandas >= 1.3.0

# Batch correction
harmonypy >= 0.0.6

# Visualization
matplotlib >= 3.5.0
seaborn >= 0.11.0
```

See `session_info.txt` for complete versions.

### **Memory Requirements:**

| Cohort | Cells | Memory | Time |
|--------|-------|--------|------|
| PsychAD Aging | ~500K | 32 GB | 2-3 hr |
| PsychAD AD | ~700K | 48 GB | 3-4 hr |
| PsychENCODE | ~500K | 32 GB | 2-3 hr |
| Mathys | ~70K | 16 GB | 1 hr |
| Australian | ~360K | 24 GB | 2 hr |

**Recommendation:** Use high-memory compute nodes

---

## 🎨 Visualization Style

All plots follow publication standards:

**Colors:**
- Cell types: Consistent across cohorts
- QC metrics: Blue → Red gradient
- Batch effects: Categorical colors

**Formats:**
- PDF (vector, editable)
- SVG (vector, web)
- DPI: 300 (if raster needed)

**Elements:**
- Clean axes and labels
- Informative titles
- Color bars with units
- Sample size annotations

---

## ⚠️ Common Issues

### **Issue 1: Memory Errors**
**Solution:** Use high-memory nodes or subsample for testing

### **Issue 2: Harmony Fails**
**Solution:** 
- Check that `Donor` column exists
- Ensure ≥2 donors per dataset
- Verify PCA computed correctly

### **Issue 3: Poor Cell Type Separation**
**Solution:**
- Adjust Leiden resolution (try 0.5-1.2)
- Check if batch correction over-corrected
- Verify HVG selection captured biology

### **Issue 4: Batch Effects Remain**
**Solution:**
- Increase Harmony iterations
- Try different batch keys (e.g., Sample + Donor)
- Check if batches are confounded with biology

---

## 📝 Notes

- **Generic notebooks:** Same code for all cohorts (DATASET variable only)
- **Sequential execution:** Each notebook depends on previous output
- **Preserved data:** Raw counts always kept in `.raw`
- **Reproducible:** Fixed random seeds throughout
- **QC stringent:** Better to be conservative early
- **Batch correction:** Harmony chosen for speed and effectiveness

---

## 📚 Next Steps

**After completing Module 00 for all cohorts:**
- [ ] Proceed to Module 01: Senescence Scoring
- [ ] Use `04_clustered_{DATASET}.h5ad` as input
- [ ] Verify cell type annotations before proceeding

---

## 🔗 Related Documentation

- **Main README:** Study overview
- **NOTEBOOK_STRUCTURE.md:** Complete pipeline
- **Module 01 README:** Senescence scoring (next step)

---

<div align="center">

**Module 00: Foundation for all downstream analyses**

[⬆ Back to Pipeline](../../NOTEBOOK_STRUCTURE.md)

</div>

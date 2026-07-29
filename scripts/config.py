"""
Shared configuration for the senescence quantification modules (01-04).

Merged verbatim from the two dataset dicts that already existed in the source
notebooks — no values invented:
  * input_file / batch_key / cell_type_column   <- 00_preprocessing_v4, cell 5
  * type / age_bins / reference_group / diagnosis_column
                                                <- module1p1, cell 6

Usage
-----
    from config import CFG, P
    CFG = CFG.for_dataset('psychad_aging')

The only thing that should differ between runs is the dataset key.
"""
from pathlib import Path

# =============================================================================
# DATASET REGISTRY
# =============================================================================
DATASET_CONFIG = {
    'psychad_aging': {
        'input_file': '/fs/scratch/PAS2598/senes_raw/syn2580853/syn2580853_aging.h5ad',
        'batch_key': ['Sample', 'Cohort'],
        'cell_type_column': 'subclass',
        'type': 'aging',
        'age_bins': [(20, 29), (30, 39), (40, 49), (50, 59), (60, 69), (70, 79), (80, 100)],
        'reference_group': 'Age_20_29',
        'diagnosis_column': None,
    },
    'psychad_aging_norm': {
        'input_file': None,                       # <NOT IN SOURCE — scoring-only variant>
        'batch_key': ['Sample', 'Cohort'],
        'cell_type_column': 'subclass',
        'type': 'aging',
        'age_bins': [(20, 29), (30, 39), (40, 49), (50, 59), (60, 69), (70, 79), (80, 100)],
        'reference_group': 'Age_20_29',
        'diagnosis_column': None,
    },
    'psychad_ad': {
        'input_file': '/fs/ess/PDE0075/senescence/human/syn2580853/syn2580853_cases.h5ad',
        'batch_key': ['Sample', 'Cohort'],
        'cell_type_column': 'subclass',
        'type': 'disease',
        'age_bins': None,
        'reference_group': 'Old_Healthy_Control',
        'diagnosis_column': 'Disease_Group',
    },
    'psychencode': {
        'input_file': ('/fs/ess/PDE0075/senescence/human/PsychENCODE/h5ad/'
                       'PsychENCODE_merged_unfiltered.h5ad'),
        'batch_key': ['sample_id', 'Cohort'],
        'cell_type_column': 'major_celltype',
        'type': 'aging',
        'age_bins': [(30, 39), (40, 49), (50, 59), (60, 69), (70, 79), (80, 100)],
        'reference_group': 'Age_30_39',
        'diagnosis_column': None,
    },
    'psychencode_sub': {
        'input_file': '/fs/ess/PDE0075/senescence/human/PsychENCODE/PsychENCODE_merged.h5ad',
        'batch_key': ['sample_id', 'Cohort'],
        'cell_type_column': 'major_celltype',
        'type': 'aging',
        'age_bins': [(30, 39), (40, 49), (50, 59), (60, 69), (70, 79), (80, 100)],
        'reference_group': 'Age_30_39',
        'diagnosis_column': None,
    },
    'mathys': {
        'input_file': None,                       # <NOT IN SOURCE — add path>
        'batch_key': None,                        # <NOT IN SOURCE>
        'cell_type_column': None,                 # <NOT IN SOURCE>
        'type': 'disease',
        'age_bins': None,
        'reference_group': 'NCI',
        'diagnosis_column': 'Disease_Group',
    },
}

# =============================================================================
# PROCESSING PARAMETERS   (00_preprocessing_v4, cell 5 — verbatim)
# =============================================================================
CONVERT_GENE_IDS  = False   # genes already symbols, not ENSG
MIN_GENES         = 200
MAX_GENES         = 40000
MIN_COUNTS        = 300
MAX_MT_PCT        = 5.0
MAX_RIBO_PCT      = 50.0
MAX_HGB_PCT       = 10.0
MIN_CELLS         = 3
TARGET_SUM        = 10000
N_TOP_GENES       = 2000
N_PCS             = 50
N_NEIGHBORS       = 30
LEIDEN_RESOLUTION = 0.8

# --- depth regression (00.5_regression, cell 4 — verbatim) -------------------
CLIP_VALUE = 30             # Pearson residual clip, SCTransform v2 convention

# --- scoring (module1p1, cell 6 — verbatim) ---------------------------------
SENEPY_TISSUE      = 'hippocampus'
SD_THRESHOLD       = 2.0
CELL_TYPE_COLUMN   = 'subclass'
AGE_COLUMN         = 'Age'
SEX_COLUMN         = 'Sex'
DONOR_COLUMN       = 'Sample'
STUDY_GROUP_COLUMN = 'Study_Group'

# --- minimum-events guard ---------------------------------------------------
# <NEW — not from source> Senescent cells are 2-5% of nuclei, so per-donor
# per-group counts are small. Models below this floor report "not estimable"
# rather than returning a number. Set from what your models actually tolerate.
MIN_SENESCENT_EVENTS = 50

BASE_DIR = Path('/fs/scratch/PAS2598/senescence_analysis')


# =============================================================================
# RESOLVER
# =============================================================================
class Config:
    """Resolves one dataset key into every path and parameter the modules need."""

    def __init__(self, dataset):
        if dataset not in DATASET_CONFIG:
            raise KeyError(f"unknown dataset {dataset!r}; "
                           f"known: {sorted(DATASET_CONFIG)}")
        self.dataset = dataset
        d = DATASET_CONFIG[dataset]
        self.raw               = d
        self.input_file        = Path(d['input_file']) if d['input_file'] else None
        self.batch_key         = d['batch_key']
        self.cell_type_column  = d['cell_type_column'] or CELL_TYPE_COLUMN
        self.mode              = d['type']              # 'aging' | 'disease'
        self.age_bins          = d['age_bins']
        self.reference_group   = d['reference_group']
        self.diagnosis_column  = d['diagnosis_column']
        self.is_aging          = (self.mode == 'aging')
        self.is_disease        = (self.mode == 'disease')

    # --- artifact paths, one per module ------------------------------------
    @property
    def processed_dir(self):
        p = BASE_DIR / 'data' / 'processed'; p.mkdir(parents=True, exist_ok=True); return p

    @property
    def preprocessed(self):  return self.processed_dir / f'{self.dataset}_preprocessed.h5ad'
    @property
    def pearson(self):       return self.processed_dir / f'{self.dataset}_pearson.h5ad'
    @property
    def scored(self):        return self.processed_dir / f'{self.dataset}_pearson_senescence_scored.h5ad'

    def figures(self, module):
        p = BASE_DIR / 'figures' / module / self.dataset
        p.mkdir(parents=True, exist_ok=True); return p

    def results(self, module):
        p = BASE_DIR / 'results' / module / self.dataset
        p.mkdir(parents=True, exist_ok=True); return p

    @staticmethod
    def for_dataset(dataset):
        return Config(dataset)

    def echo(self):
        print("=" * 78)
        print(f"  dataset        : {self.dataset}")
        print(f"  mode           : {self.mode}"
              f"   -> threshold anchored on {self.reference_group!r}")
        print(f"  cell types     : {self.cell_type_column}")
        print(f"  batch key      : {self.batch_key}")
        if self.age_bins:
            print(f"  age bins       : {len(self.age_bins)} "
                  f"({self.age_bins[0][0]}-{self.age_bins[-1][1]})")
        if self.diagnosis_column:
            print(f"  diagnosis col  : {self.diagnosis_column}")
        print("=" * 78)


CFG = Config          # so `from config import CFG; cfg = CFG.for_dataset('...')`


# =============================================================================
# LAYER CONTRACT
# =============================================================================
LAYER_CONTRACT = {
    '.X':                 'Pearson residuals — SenePy scoring ONLY',
    "layers['counts']":   'raw counts — DEG',
    "layers['lognorm']":  'log-normalized — module scoring, cell cycle, viz, variability',
}


def assert_layers(adata, expect_X, require=()):
    """Fail loudly if a module is about to read the wrong matrix.

    <NEW — not from source> The contract itself is documented in
    00.5_regression's markdown; this only turns it into an assertion.
    """
    print(f"  .X expected     : {expect_X}")
    for layer in require:
        if layer not in adata.layers:
            raise ValueError(
                f"layers['{layer}'] missing — required by this module.\n"
                f"  present: {list(adata.layers.keys())}\n"
                f"  contract: {LAYER_CONTRACT}")
        print(f"  layers['{layer}']  present")
    return True

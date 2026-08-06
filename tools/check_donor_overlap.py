#!/usr/bin/env python3
"""
Donor-ID overlap between cohorts pooled in the same meta-analysis arm.

Why this matters
----------------
Random-effects pooling (module 08) assumes the cohort estimates are
independent. PsychAD AD draws on ROSMAP (ROS and MAP), and so does Mathys. If
the same donors appear in both, the two estimates share sampling error: tau^2
is underestimated, the pooled CI is too narrow, and the pooled p-value is
anticonservative. The size of the problem scales with the overlap fraction, so
this has to be measured rather than assumed away.

The check is a set intersection. The hard part is that the same donor can be
written differently in each object - 'ROS:12345', 'R12345', '12345' - so the
comparison runs on both the raw IDs and a normalized form, and reports both.
A raw-zero / normalized-nonzero result means the IDs do overlap and were
formatted differently, which is the outcome most likely to be missed.

Usage
-----
    python tools/check_donor_overlap.py \\
        --a  /path/psychad_ad.h5ad     --a-col Sample  --a-name "PsychAD AD" \\
        --b  /path/mathys.h5ad         --b-col Donor   --b-name "Mathys"

Accepts .h5ad (reads only `obs`, never the matrix) or a CSV/TSV with the ID
column named by --a-col / --b-col.
"""
import argparse
import re
import sys
from pathlib import Path


def load_ids(path, col, label):
    p = Path(path)
    if not p.exists():
        sys.exit(f"{label}: file not found - {p}")

    if p.suffix == ".h5ad":
        try:
            import anndata as ad
        except ImportError:
            sys.exit("anndata is required to read .h5ad; pip install anndata")
        # backed mode: reads obs without pulling the expression matrix
        obs = ad.read_h5ad(p, backed="r").obs
    else:
        import pandas as pd
        sep = "\t" if p.suffix in {".tsv", ".txt"} else ","
        obs = pd.read_csv(p, sep=sep)

    if col not in obs.columns:
        sys.exit(f"{label}: column {col!r} not in the object.\n"
                 f"  available: {sorted(obs.columns)[:40]}")
    ids = obs[col].dropna().astype(str).unique()
    print(f"  {label:20s} {len(ids):5d} donors   (column {col!r})")
    return set(ids)


def normalize(s):
    """Strip cohort prefixes, separators and case.

    'ROS:12345' / 'R12345' / 'ros_12345' / '12345' all collapse to '12345'.
    Deliberately aggressive: a false positive here is investigated, a false
    negative is silently wrong.
    """
    s = s.strip().lower()
    s = re.sub(r'^(ros|map|rosmap|psychad|mathys)[\s:_\-]*', '', s)
    s = re.sub(r'[\s:_\-\.]', '', s)
    s = re.sub(r'^[a-z]+(?=\d)', '', s)      # leading letters before digits
    return s


def report(a, b, name_a, name_b, tag):
    inter = a & b
    print(f"\n  {tag}")
    print(f"    {name_a:20s} {len(a):5d}")
    print(f"    {name_b:20s} {len(b):5d}")
    print(f"    {'intersection':20s} {len(inter):5d}")
    if a and b:
        print(f"    {'% of ' + name_a:20s} {100 * len(inter) / len(a):5.1f}%")
        print(f"    {'% of ' + name_b:20s} {100 * len(inter) / len(b):5.1f}%")
    if inter:
        shown = sorted(inter)[:20]
        print(f"    shared: {', '.join(shown)}"
              + (f" … (+{len(inter) - 20} more)" if len(inter) > 20 else ""))
    return inter


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--a", required=True)
    ap.add_argument("--a-col", required=True)
    ap.add_argument("--a-name", default="cohort A")
    ap.add_argument("--b", required=True)
    ap.add_argument("--b-col", required=True)
    ap.add_argument("--b-name", default="cohort B")
    ap.add_argument("--out", help="write the shared IDs to this file")
    args = ap.parse_args()

    print("=" * 72)
    print("DONOR OVERLAP CHECK")
    print("=" * 72)
    print("\n  Loading")
    A = load_ids(args.a, args.a_col, args.a_name)
    B = load_ids(args.b, args.b_col, args.b_name)

    raw = report(A, B, args.a_name, args.b_name, "RAW IDs, as stored")

    An = {normalize(x) for x in A}
    Bn = {normalize(x) for x in B}
    norm = report(An, Bn, args.a_name, args.b_name,
                  "NORMALIZED (prefixes, separators and case stripped)")

    print("\n" + "=" * 72)
    print("VERDICT")
    print("=" * 72)
    if not norm:
        print("  No overlap under either comparison.")
        print("  Random-effects pooling across these two cohorts is fine as it stands.")
    elif not raw and norm:
        print(f"  {len(norm)} donors overlap ONLY after normalization.")
        print("  The IDs are formatted differently in the two objects, so a raw")
        print("  comparison would have reported independence incorrectly.")
        print("  Confirm the mapping by hand before acting on it - the normalizer")
        print("  is deliberately aggressive and can collapse distinct IDs.")
    else:
        frac = max(len(norm) / len(An), len(norm) / len(Bn))
        print(f"  {len(norm)} donors are shared ({frac * 100:.1f}% of the smaller cohort).")
        print("  These cohorts are NOT independent. Options, in order of preference:")
        print("    1. drop the shared donors from one arm and refit that cohort")
        print("    2. report the pooled estimate with the overlap stated, and treat")
        print("       the CI as a lower bound on the true width")
        print("    3. abandon pooling for this arm and report the cohorts separately")
        print("  Do not report the current pooled CI without a caveat.")

    if args.out and norm:
        Path(args.out).write_text("\n".join(sorted(norm)) + "\n")
        print(f"\n  shared IDs -> {args.out}")


if __name__ == "__main__":
    main()

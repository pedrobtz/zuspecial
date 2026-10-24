"""Write SciPy's values for zuspecial's functions, as Parquet tables in xsref's
layout, for tools/xsref-extract --kind scipy.

Run with the SciPy release zuspecial's xsf pin comes from, for example:

    uv run --no-project --python 3.12 --with scipy==1.18.1 --with pyarrow \\
        tools/scipy-values.py --xsref <xsref>/tables/scipy_special_tests \\
        --functions tools/xsref/functions.tsv --out <dir>

Inputs per function and signature: the xsref inputs, sampled as
tools/xsref-extract samples them (cap 250), plus 200 random inputs from a
fixed seed. Each Out_ table's metadata records the SciPy version.
"""

import argparse
import csv
import pathlib

import numpy as np
import pyarrow as pa
import pyarrow.parquet as pq
import scipy
import scipy.special as sc

CAP = 250
N_RANDOM = 200
SEED = 20261024
DTYPES = {"d": np.float64, "cd": np.complex128, "p": np.int64}


def sample_rows(n):
    if n <= CAP:
        return np.arange(n)
    # R's round() is round-half-even, like numpy's rint; seq(1, n, length.out)
    # is 1-based.
    return np.unique(np.rint(np.linspace(1, n, CAP)).astype(np.int64)) - 1


def read_inputs(path, types):
    table = pq.read_table(path)

    def col(name):
        return table.column(name).to_numpy()

    cols = []
    for k, t in enumerate(types):
        if t == "cd":
            cols.append(col(f"in{k}_real") + 1j * col(f"in{k}_imag"))
        else:
            cols.append(col(f"in{k}").astype(DTYPES[t]))
    return cols


def random_inputs(rng, types):
    def real(n):
        return rng.choice([-1.0, 1.0], n) * 10.0 ** rng.uniform(-3, 3, n)

    cols = []
    for t in types:
        if t == "d":
            cols.append(real(N_RANDOM))
        elif t == "cd":
            cols.append(real(N_RANDOM) + 1j * real(N_RANDOM))
        else:
            cols.append(rng.integers(0, 31, N_RANDOM, dtype=np.int64))
    return cols


def columns(prefix, values):
    out = {}
    for k, v in enumerate(values):
        if np.iscomplexobj(v):
            out[f"{prefix}{k}_real"] = np.real(v).astype(np.float64)
            out[f"{prefix}{k}_imag"] = np.imag(v).astype(np.float64)
        else:
            out[f"{prefix}{k}"] = v
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--xsref", required=True)
    ap.add_argument("--functions", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    sc.seterr(all="ignore")
    rng = np.random.default_rng(SEED)
    xsref = pathlib.Path(a.xsref)
    out = pathlib.Path(a.out)

    with open(a.functions, newline="") as f:
        rows = list(csv.DictReader(f, delimiter="\t"))
    for row in rows:
        table = row["table"]
        fn = getattr(sc, table)
        for sig in row["sigs"].split(","):
            types = sig.split("-")[0].split("_")
            ins = read_inputs(xsref / table / f"In_{sig}.parquet", types)
            keep = sample_rows(len(ins[0]))
            ins = [np.concatenate([x[keep], r]) for x, r in zip(ins, random_inputs(rng, types))]
            with np.errstate(all="ignore"):
                values = fn(*ins)
            meta = {"scipy_version": scipy.__version__, "function": table}
            dest = out / table
            dest.mkdir(parents=True, exist_ok=True)
            pq.write_table(pa.table(columns("in", ins)), dest / f"In_{sig}.parquet")
            o = columns("out", [values])
            o["fallback"] = np.zeros(len(values), dtype=bool)
            t = pa.table(o).replace_schema_metadata(meta)
            pq.write_table(t, dest / f"Out_{sig}.parquet")
            print(f"{table} {sig}: {len(values)} rows")


if __name__ == "__main__":
    main()

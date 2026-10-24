"""Write SciPy's values for zuspecial's functions, as Parquet tables in xsref's
layout, for tools/xsref-extract --kind scipy.

Run with the SciPy release zuspecial's xsf pin comes from, for example:

    uv run --no-project --python 3.12 --with scipy==1.18.1 --with pyarrow \\
        tools/scipy-values.py --xsref <xsref>/tables/scipy_special_tests \\
        --functions tools/xsref/functions.tsv --out <dir>

Inputs per function and signature: the xsref inputs, sampled as
tools/xsref-extract samples them (--cap, default 250; 0 keeps every row),
plus --random seeded random inputs (default 200), drawn per argument from the
domain tools/xsref/functions.tsv gives it. The tables shipped in
tests/testthat/scipy use --random 0: random inputs have no recorded error to
bound cross-platform differences, so they are only compared with SciPy run
on the same platform, in CI (xsref.yaml). A function xsref has no table for
(table "-") always gets NO_XSREF_RANDOM random inputs, its only SciPy check. Each Out_ table's metadata records the SciPy version; its
columns record, for rows taken from xsref, the xsref row (1-based, 0 for a
random input) and xsref's recorded error on every platform (NaN for random
inputs), from which the R test builds each row's tolerance.
"""

import argparse
import csv
import pathlib

import numpy as np
import pyarrow as pa
import pyarrow.parquet as pq
import scipy
import scipy.special as sc

SEED = 20261024
NO_XSREF_RANDOM = 200
DTYPES = {"d": np.float64, "cd": np.complex128, "p": np.int64}


def sample_rows(n, cap):
    if cap == 0 or n <= cap:
        return np.arange(n)
    # R's round() is round-half-even, like numpy's rint; seq(1, n, length.out)
    # is 1-based.
    return np.unique(np.rint(np.linspace(1, n, cap)).astype(np.int64)) - 1


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


def random_inputs(rng, domains, n):
    def real(n):
        return rng.choice([-1.0, 1.0], n) * 10.0 ** rng.uniform(-3, 3, n)

    gen = {
        "real": real,
        "pos": lambda n: 10.0 ** rng.uniform(-3, 3, n),
        "unit": lambda n: rng.uniform(0, 1, n),
        "unitpm": lambda n: rng.uniform(-1, 1, n),
        "neg": lambda n: -(10.0 ** rng.uniform(-3, 4, n)),
        "complex": lambda n: real(n) + 1j * real(n),
        "int": lambda n: rng.integers(0, 31, n, dtype=np.int64),
    }
    return [gen[d](n) for d in domains]


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
    ap.add_argument("--cap", type=int, default=250)
    ap.add_argument("--random", type=int, default=200)
    a = ap.parse_args()

    sc.seterr(all="ignore")
    rng = np.random.default_rng(SEED)
    xsref = pathlib.Path(a.xsref)
    out = pathlib.Path(a.out)

    with open(a.functions, newline="") as f:
        rows = list(csv.DictReader(f, delimiter="\t"))
    for row in rows:
        table = row["table"]
        name = row["r_name"][len("sc_"):]
        fn = getattr(sc, name)
        has_xsref = table != "-"
        for sig, doms in zip(row["sigs"].split(","), row["domains"].split(",")):
            types = sig.split("-")[0].split("_")
            n_random = a.random if has_xsref else NO_XSREF_RANDOM
            rand = random_inputs(rng, doms.split(" "), n_random)
            if has_xsref:
                ins = read_inputs(xsref / table / f"In_{sig}.parquet", types)
                keep = sample_rows(len(ins[0]), a.cap)
            else:
                ins = [np.zeros(0, dtype=r.dtype) for r in rand]
                keep = np.zeros(0, dtype=np.int64)
            ins = [np.concatenate([x[keep], r]) for x, r in zip(ins, rand)]
            pad = np.full(n_random, np.nan)
            errs = {}
            if has_xsref:
                for path in sorted((xsref / table).glob(f"Err_{sig}_*.parquet")):
                    platform = path.stem[len(f"Err_{sig}_"):]
                    err = pq.read_table(path).column("err0").to_numpy()
                    errs[f"err_{platform}"] = np.concatenate([err[keep], pad])
            with np.errstate(all="ignore"):
                values = fn(*ins)
            meta = {
                "scipy_version": scipy.__version__,
                "function": name,
                "xsref": table if has_xsref else "none",
            }
            dest = out / (table if has_xsref else name)
            dest.mkdir(parents=True, exist_ok=True)
            pq.write_table(pa.table(columns("in", ins)), dest / f"In_{sig}.parquet")
            o = columns("out", [values])
            o["fallback"] = np.zeros(len(values), dtype=bool)
            o["xsref_row"] = np.concatenate([keep + 1, np.zeros(n_random, dtype=np.int64)])
            # Stable identity of a random input: its position in this table's
            # seeded stream (1-based; 0 for an xsref row).
            o["random_id"] = np.concatenate([np.zeros(len(keep), dtype=np.int64), np.arange(1, n_random + 1)])
            o.update(errs)
            t = pa.table(o).replace_schema_metadata(meta)
            pq.write_table(t, dest / f"Out_{sig}.parquet")
            print(f"{name} {sig}: {len(values)} rows")


if __name__ == "__main__":
    main()

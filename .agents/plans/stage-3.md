# Stage 3 — Test oracles: xsref and SciPy values: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stage 2's 21 functions pass xsref's mpmath reference cases under
xsf's own tolerance rule, and agree with SciPy 1.18.1, on every CI leg.

**Architecture:** Two oracles, one format. `tools/xsref-extract` (R, uses
`arrow` as a tool, not a package dependency) reads Parquet tables in xsref's
layout and writes one `.rds` per function and signature. The source is
either xsref at its pin or the Parquet tables `tools/scipy-values.py` writes
from SciPy 1.18.1. A capped sample ships in `tests/testthat/`; CI runs the
full xsref set.

**Tech Stack:** R (tests: base R `readRDS` only), `arrow` in tools, Python
3.12 + SciPy 1.18.1 + pyarrow through `uv` in tools, GitHub Actions.

**Spec:** `.agents/design.md` §10; roadmap Stage 3.

## Global Constraints

- xsref pin: the commit xsf's `pixi.toml` clones at the vendored xsf commit
  (`4e9b2343813136e355f0262754a3929d98bc5bff` for `f7b85f5`), not the
  RFC's `b511621`, which belongs to SciPy `main`'s xsf.
- Tolerance: `extended_relative_error(got, want) <= 4 * max(eps, recorded)`,
  ported exactly from xsf's `fp_error_metrics.h` and `testing_utils.h`.
- Platform for the `Err_` table: `clang-darwin-aarch64` (clang, macOS,
  arm64), `gcc-linux-x86_64` (gcc, Linux, x86_64), else `other`; Rtools' GCC
  on Windows is `other` (design §10).
- No values pass through text: R's parser loses subnormals in hex and is not
  guaranteed exact for 17-digit decimals. Tables stay binary (Parquet, then
  `.rds`).
- The shipped sample is at most 2 MB; the suite stays under 15 s.
- `fallback` rows (SciPy's old values, not mpmath's) are tested like the
  others and counted separately in the report.
- `sc_expn` is tested on xsref's `p_d-d` (integer `n`) only: its `d_d-d`
  table has non-whole `n`, which zuspecial refuses by design.

## Review Focus

- An xsref row whose expected value is `NaN` or `Inf`: the ported metric
  must give 0 for NaN/NaN and Inf/Inf, and a finite error for early
  overflow, exactly as xsf does. Unit tests in Task 1.
- A complex expected value with a zero or infinite part: the per-part
  rescaling in xsf's complex metric. Unit tests in Task 1.
- A table that grows upstream past the sample cap: the sample is evenly
  spaced, deterministic, and keeps the first and last rows. Task 2 test.
- A platform with no `Err_` file of its own: falls back to `other`. Task 1.
- The full-xsref job silently testing nothing (wrong directory): the test
  fails when the directory has no tables. Task 3.

---

### Task 1: The tolerance rule and platform, as test helpers

**Files:**

- Create: `tests/testthat/helper-oracle.R`
- Test: `tests/testthat/test-oracle-helpers.R`

**Interfaces:**

- Produces: `xsf_rel_err(actual, desired)` for double or complex vectors,
  vectorised, a port of `xsf::extended_relative_error`;
  `xsf_tol(recorded)` = `4 * pmax(.Machine$double.eps, recorded)`;
  `xsf_platform()` → one of the four platform strings, from
  `zuspecial_info()$compiler`, `Sys.info()[["sysname"]]` and
  `R.version$arch`.

- [ ] **Step 1: Failing tests:** `xsf_rel_err(1, 1) == 0`;
  `xsf_rel_err(NaN, NaN) == 0`; `xsf_rel_err(1, NaN) == Inf`;
  `xsf_rel_err(Inf, Inf) == 0`; `xsf_rel_err(Inf, 1e308)` is finite;
  `xsf_rel_err(1e-300, 0)` is `1e-300 / 4.9406564584124654e-324`;
  `xsf_rel_err(1 + 1e-16, 1) == 1e-16` within 1 ulp; complex
  `xsf_rel_err(1+0i, 1+0i) == 0`; `xsf_rel_err(complex(real = 1, imaginary
  = 1e-20), 1+0i)` equals `1e-20 / 1` (the imaginary zero rescaled by
  denorm_min only in the denominator's part, so check against the formula
  directly); `xsf_platform()` is one of the four strings.
- [ ] **Step 2:** FAIL. **Step 3:** Implement. **Step 4:** PASS. Commit:
  `Port xsf's tolerance rule to the test helpers`.

### Task 2: `tools/xsref-extract`

**Files:**

- Create: `tools/xsref-extract` (Rscript), `tools/xsref/functions.tsv`

**Interfaces:**

- `tools/xsref/functions.tsv`: columns `r_name`, `table` (xsref directory),
  `sigs` (comma-separated, e.g. `d-d,cd-cd`). `sc_psi` is `digamma`;
  `sc_expn` is `p_d-d` only.
- `tools/xsref-extract --source <tables-dir> --kind xsref|scipy --out <dir>
  [--cap N]` writes `<out>/<r_name>__<sig>.rds`, a list: `r_name`, `sig`,
  `kind`, `commit` (xsref commit or SciPy version), `n_total`, `rows`
  (sampled 1-based row numbers), `inputs` (list of double or complex
  vectors, complex rebuilt from `_real`/`_imag`), `out` (double or complex),
  `fallback` (logical), `err` (named list by platform; xsref only).
  `--cap` defaults to 250; `--cap 0` keeps every row. Sampling:
  `unique(round(seq(1, n, length.out = cap)))`.

- [ ] **Step 1:** Write `functions.tsv` for the 21 Stage 2 functions; check
  every table and signature exists in the xsref tree at the pin.
- [ ] **Step 2:** Write the extractor. Run it on a sparse checkout of xsref
  at the pin into `tests/testthat/xsref/`.
- [ ] **Step 3:** Check: `du -sh tests/testthat/xsref` is under 1.5 MB
  (leaving room for SciPy tables); each file's `rows` includes 1 and
  `n_total`; re-running gives byte-identical files.
- [ ] **Step 4:** Commit: `Extract xsref reference tables for testing`.

### Task 3: The xsref test

**Files:**

- Create: `tests/testthat/test-xsref.R`

- [ ] **Step 1:** For each `.rds` in `Sys.getenv("ZUSPECIAL_XSREF_DIR",
  test_path("xsref"))`: call `get(r_name, asNamespace("zuspecial"))` on the
  inputs (integer-signature inputs passed as double), under
  `sc_errstate(..., all = "ignore")`; compute `xsf_rel_err`; expect every
  row within `xsf_tol(err[[xsf_platform()]] %||% err$other)`. On failure,
  the message lists the first five offending rows (inputs, got, want,
  error, tolerance) and the fallback count. The test fails if the
  directory holds no tables.
- [ ] **Step 2:** Run. Expect PASS on this machine (`other`). Any failure
  is investigated, not loosened (systematic-debugging); a real
  disagreement stops the stage.
- [ ] **Step 3:** Commit: `Test every function against xsref`.

### Task 4: SciPy-value tables

**Files:**

- Create: `tools/scipy-values.py`, `tests/testthat/scipy/*.rds`
- Modify: `tests/testthat/test-xsref.R` (or new `test-scipy.R`)

**Interfaces:**

- `uv run --no-project --python 3.12 --with scipy==1.18.1 --with pyarrow
  tools/scipy-values.py --xsref <tables-dir> --functions
  tools/xsref/functions.tsv --out <dir>` writes, per function and
  signature, `In_<sig>.parquet` and `Out_<sig>.parquet` under
  `<dir>/<table>/` in xsref's layout: the xsref inputs (sampled by the same
  rule, cap 250) plus 200 random inputs from `numpy.random.default_rng(
  20261024)`, magnitudes log-uniform on `[1e-3, 1e3]` with random sign (each
  part for complex), integers `0..30` for `p`. Values from
  `scipy.special.<scipy_name>` called on float64 / complex128 / int64
  arrays so SciPy picks the same loop. `scipy.special.seterr(all="ignore")`.
  File metadata records `scipy_version`.
- Then `tools/xsref-extract --kind scipy --cap 0` packs them into
  `tests/testthat/scipy/`.
- Tolerance: `xsf_tol(max(err$other))` of that function and signature's
  xsref table, the same rule applied to the table's worst recorded error.

- [ ] **Step 1:** Write the script; generate; pack.
- [ ] **Step 2:** Test: every function agrees with SciPy within that
  tolerance. Run; PASS or investigate.
- [ ] **Step 3:** `du -sh tests/testthat/xsref tests/testthat/scipy` totals
  under 2 MB. Commit: `Test every function against SciPy 1.18.1`.

### Task 5: The xsref pin in `zuspecial_info()` and the full-xsref CI job

**Files:**

- Modify: `tools/vendor/vendor-xsf` (read xsref's commit from xsf's
  `pixi.toml` at the pinned xsf commit; write `ZSP_XSREF_COMMIT` into
  `src/zsp_xsf_version.h`; add an `xsref` row to `manifest.tsv`),
  `src/zsp_info.c`, `R/info.R`, `tests/testthat/test-info.R`
- Create: `.github/workflows/xsref.yaml`

- [ ] **Step 1: Failing test:** `zuspecial_info()$xsref_commit` is
  `"4e9b2343813136e355f0262754a3929d98bc5bff"`, and each shipped `.rds` of
  kind `xsref` has that `commit`.
- [ ] **Step 2:** Implement; re-vendor (vendored files unchanged;
  `tools/vendor/verify` passes).
- [ ] **Step 3:** `xsref.yaml`: on pull_request and push to main; matrix
  ubuntu-latest, macos-latest (arm64, so the `clang-darwin-aarch64` table),
  windows-latest; clone xsref at the commit from `manifest.tsv`; install
  `arrow` and `testthat`; `tools/xsref-extract --kind xsref --cap 0 --out
  $RUNNER_TEMP/xsref`; `R CMD INSTALL .`; run `test-xsref.R` with
  `ZUSPECIAL_XSREF_DIR` set. Write the pass and fallback counts to the job
  summary.
- [ ] **Step 4:** Commit: `Run the full xsref set in CI`.

### Task 6: Docs, roadmap, PR

- [ ] design.md §10: the xsref pin correction, `arrow` chosen for the
  extractor, the SciPy-table tolerance rule, `expn`'s `d_d-d` table skipped.
- [ ] CLAUDE.md: Testing conventions (xsref, SciPy tables, helpers,
  runtime), Commands (`tools/xsref-extract`, `tools/scipy-values.py`).
- [ ] `devtools::check()` 0/0/0; suite under 15 s; roadmap Done.
- [ ] PR `Stage 3 — Test oracles: xsref and SciPy values`, `Closes #5`,
  quick profile; merge when green.

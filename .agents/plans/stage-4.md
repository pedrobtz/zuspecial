# Stage 4 — Incomplete gamma and beta, Boost backend, normal functions: Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 14 functions statistics code depends on, including the five SciPy
evaluates with Boost.Math, each checked against xsref where it exists and
SciPy 1.18.1 everywhere.

**Architecture:** xsf kernels go in `src/zsp_shim_gamma.h` and
`src/zsp_shim_error.h` (the one xsf unit). The Boost wrappers are a second
translation unit, `src/zsp_boost.cpp`, which includes Boost.Math and
`xsf/error.h` only (no xsf kernels, so no ODR clash), ported from SciPy
1.18.1's `boost_special_functions.h`. `ndtri_exp` is ported from SciPy's
Cython `_ndtri_exp.pxd` into the gamma/error shim.

**Spec:** design §2, §10, §12.1; roadmap Stage 4.

## Global Constraints

- SciPy 1.18.1 pins Boost.Math 1.91.0; CRAN's `BH` is 1.90.0-1. Use
  `LinkingTo: BH` with `BOOST_MATH_STANDALONE` defined (as SciPy builds it);
  §12.1's decision is BH unless CI's same-platform SciPy parity disagrees.
- Boost wrappers call Boost exactly as SciPy does: `SpecialPolicy` for
  `ibeta`, `ibeta_inv`, `ibetac_inv`, `erf_inv`; the default policy for
  `ibetac`; the same NaN, domain and limit cases first; exceptions mapped to
  sf_error codes (domain → DOMAIN/NaN, overflow → OVERFLOW/Inf, underflow →
  UNDERFLOW/0, anything else → OTHER/NaN) through `xsf::set_error`.
- Exported, SciPy names and arguments: `sc_gammainc(a, x)`,
  `sc_gammaincc(a, x)`, `sc_gammaincinv(a, y)`, `sc_gammainccinv(a, y)`,
  `sc_betainc(a, b, x)`, `sc_betaincc(a, b, x)`, `sc_betaincinv(a, b, y)`,
  `sc_betainccinv(a, b, y)`, `sc_erfinv(y)`, `sc_ndtr(x)` (complex),
  `sc_log_ndtr(x)` (complex), `sc_ndtri(p)`, `sc_ndtri_exp(y)`,
  `sc_owens_t(h, a)`.
- Kernels: `xsf::gammainc/gammaincc/gammaincinv/gammainccinv`,
  `xsf::ndtr`, `xsf::log_ndtr` (real and complex), `xsf::ndtri`,
  `xsf::owens_t`; `ndtri_exp` built on `xsf::cephes::ndtri`.
- `zuspecial_info()`: backend `"boost"` for the five; `boost_version` from
  `BOOST_VERSION`.

## Review Focus

- A Boost exception escaping the shim: every wrapper is `noexcept` with a
  `catch (...)`; test that an evaluation error surfaces as an sf_error code.
- `betainc` limit cases (a = 0, b = 0, infinite a or b): SciPy's pointwise
  limits, tested directly.
- Restricted domains: random inputs need per-argument domains, or most
  rows are NaN and test nothing.
- `ibetac` uses the default policy, the others `SpecialPolicy`.

---

### Task 1: xsf-backed functions

- [ ] Tests (red): spot values against base R: `sc_gammainc(a, x)` vs
  `pgamma(x, a)`, `sc_gammaincc` vs `pgamma(x, a, lower = FALSE)`,
  `sc_gammaincinv(a, y)` vs `qgamma(y, a)`, `sc_gammainccinv` vs
  `qgamma(y, a, lower = FALSE)`, `sc_ndtr` vs `pnorm`, `sc_log_ndtr` vs
  `pnorm(log.p = TRUE)`, `sc_ndtri(p)` vs `qnorm(p)`, `sc_ndtri_exp(y)` vs
  `qnorm(y, log.p = TRUE)`, `sc_owens_t(h, 0) == 0` and
  `sc_owens_t(0, a) == atan(a) / (2 * pi)`; complex `sc_ndtr` on the real axis.
- [ ] Shim entries, glue table rows, R wrappers, roxygen (topic
  `normal-functions`, gamma ones join `gamma-functions`). Commit.

### Task 2: The Boost unit

- [ ] `DESCRIPTION`: `LinkingTo: BH`. `src/zsp_boost.cpp`: the five
  wrappers; `src/zsp_shim.h` declarations; glue rows (`ddd`, `d`).
- [ ] Tests (red first): base R `pbeta(x, a, b)`, `pbeta(lower = FALSE)`,
  `qbeta`, `qbeta(lower = FALSE)`; `sc_erfinv(sc_erf(x)) == x`; SciPy's
  limit cases; `sc_betainc(1, 1, 2)` raises `domain` under "raise";
  `sc_erfinv(c(-1, 1))` is `c(-Inf, Inf)`.
- [ ] Local check 0/0/0, `tools/check-symbols` passes (extend the state
  check to `zsp_boost.o`). Commit.

### Task 3: Oracles

- [ ] `tools/xsref/functions.tsv`: add the 14, with a `domains` column
  (per-argument generator for random inputs: `real`, `pos`, `unit`,
  `unitpm`, `neg`, `int`); `table` is `-` where xsref has none.
- [ ] `tools/scipy-values.py`: random inputs by domain; functions with no
  xsref table get random rows only.
- [ ] Shipped check for random rows of functions with no xsref table:
  relative 1e-12, a cross-platform smoke check documented as such; CI keeps
  64 ulps on the same platform.
- [ ] Regenerate shipped tables; run CI; the Windows known list rebuilt
  with `tools/known-windows` if needed. Commit.

### Task 4: §12.1, info, docs, PR

- [ ] `zuspecial_info()` backends and `boost_version`; design §12.1 records
  BH 1.90 vs SciPy's 1.91 and the parity result; NEWS; CLAUDE.md; roadmap.
- [ ] PR `Stage 4 — …`, quick profile; merge on green.

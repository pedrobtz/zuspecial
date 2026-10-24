# Stage 5 — Bessel, Hankel, spherical Bessel, Airy: Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 30 Bessel-family functions, real and complex, with SciPy's
argument order, checked against xsref and SciPy.

**Spec:** design §2, §5, §6.2, §16 Q6 (D16: named list); roadmap Stage 5.

## Global Constraints

- SciPy 1.18.1 kernels (from `_special_ufuncs.cpp`): `jv yv iv kv jve yve
  ive kve` → `xsf::cyl_bessel_{j,y,i,k}{,e}` for `(double v, double x)` and
  `(double v, complex z)`; `hankel1 hankel2 hankel1e hankel2e` →
  `xsf::cyl_hankel_{1,2}{,e}`, complex `z` only (real input promoted, as
  wofz); `j0 j1 y0 y1 i0 i0e i1 i1e k0 k0e k1 k1e` →
  `xsf::cyl_bessel_{..}`, real only; `spherical_{j,y,i,k}n(n, z,
  derivative = FALSE)` → `xsf::sph_bessel_{j,y,i,k}` and `*_jac`, `(long
  n, double)` and `(long n, complex)`; `airy`, `airye` → `xsf::airy`,
  `xsf::airye`, four outputs, real or complex.
- R signatures: `sc_jv(v, z)` etc.; `sc_j0(x)` etc.; `sc_spherical_jn(n, z,
  derivative = FALSE)`; `sc_airy(z)` → `list(ai, aip, bi, bip)`, each
  element shaped like `z`.
- Only the argument named `z` may be complex; `v` stays real. No
  promotion except Hankel.
- `derivative` must be `TRUE` or `FALSE` (length one, not `NA`), else
  `zuspecial_invalid_argument`.

## Tasks

1. **Glue.** New loops: `zsp_call_dc(name, v, z)` (complex out),
   `zsp_call_ic(name, n, z)`, `zsp_call_d4(name, x)` and `zsp_call_c4(name,
   z)` returning a list of four vectors with the `zsp_err` report on the
   list. `zsp_eval()` picks the routine from the argument types
   (`d`, `c`, `i`) and an `outputs` count. Tests through `.Call` for NA in
   either argument and the four-output report.
2. **Shim** `src/zsp_shim_bessel.h` (included by `zsp_shim.cpp`): all
   kernels; glue table rows.
3. **R** `R/bessel.R` (topics `bessel-functions`, `spherical-bessel`,
   `airy-functions`), `zsp_functions` rows. Tests: base R `besselJ`,
   `besselY`, `besselI`, `besselK` and the `expon.scaled` forms on real
   input (note the argument order); `sc_jv(0.5, -1)` is NaN and
   `sc_jv(0.5, -1+0i)` complex; Wronskian `j1*y0 - j0*y1 = 2/(pi x)`;
   `hankel1 = jv + i yv`; spherical `j0(x) = sin(x)/x`, derivatives by the
   recurrence `f_n' = f_{n-1} - (n+1)/z f_n`; `airy` Wronskian
   `ai*bip - aip*bi = 1/pi`, `airye` against `airy` scaling.
4. **Oracles.** `functions.tsv` rows (xsref tables named after xsf:
   `cyl_bessel_j`…; spherical `-` with domains `int real`/`int complex`);
   multi-output support in `tools/xsref-extract` (all `out*` columns,
   `err*`), `tools/scipy-values.py` (tuple results) and `oracle_check`
   (each output checked, report names the output).
5. **Docs, NEWS, roadmap, design** (D16 used), PR quick, merge on green.

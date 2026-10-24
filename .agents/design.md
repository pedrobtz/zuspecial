# RFC 0027: `zuspecial`, special functions for R from SciPy's xsf

Adopted from [RFC 0027](https://github.com/pedrobtz/packages/blob/main/rfcs/started/0027-zuspecial-special-functions.md)
on 2026-10-23. From here on this file is authoritative; the RFC is history.

- **Status:** Proposed. Merging this file adopts the design as the starting
  point for the package's own `.agents/design.md`; each decision in section
  15 stays the maintainer's until the package repository records it.
  Section 12.1 (the Boost.Math backend) and section 12.2 (licences) are
  settled in the first stage.
- **Date:** 2026-10-09.
- **Packages:** `zuspecial` (not yet created; name unchecked against
  crandb, which was not reachable from the drafting session; the CRAN
  GitHub mirror has no repository of that name); vendors xsf (BSD-3-Clause,
  with bundled Cephes, Faddeeva, qd, AMOS and specfun code, §12.2);
  `LinkingTo: BH` for six Boost.Math functions (§12.1); zuspecial takes
  MIT.
- **Source:** the xsf repository (`scipy/xsf`) at `471c1b5` (2026-10-07;
  `git describe` gives `v0.2.2-165-g471c1b5`, so 165 commits after the
  latest tag `v0.2.2` of 2026-04-09), which is the commit SciPy's
  `subprojects/xsf` submodule pins at SciPy `main` `ecee36d`
  (2026-10-08). From xsf: `README.md` (two sentences: "Header-only
  special function implementations extracted from SciPy"), `LICENSE`,
  `LICENSES_bundled.txt`, `CMakeLists.txt` (an `INTERFACE` target with
  `cxx_std_17`), `meson.build` (version `0.2.2`), `include/xsf/config.h`
  (the `__CUDACC__`/`__HIPCC__` switches, `XSF_HOST_DEVICE`, the
  `xsf::cxx` shims over `std::`), `include/xsf/error.h` (`sf_error_t`, the
  `SP_SPECFUN_ERROR` hook, `set_error_and_nan`), `include/xsf/stats.h`,
  `include/xsf/numpy.h` (includes `Python.h` and the vendored `mdspan`),
  the licence headers of `cpu/amos/amos.h`, `cpu/specfun/specfun.h`,
  `cephes/psi.h` and `cephes/scipy_iv.h`, `cpu/specfun.h` and
  `cpu/hyperu.h` (which kernels call specfun), and `tests/testing_utils.h`
  with `tests/scipy_special_tests/test_cyl_bessel_j.cpp` (the tolerance
  rule, §10). From SciPy at `ecee36d`: `scipy/special/_special_ufuncs.cpp`
  (286 ufunc registrations, from which the function inventory in §2 and
  the backend split in §12.1 were read), `boost_special_functions.h`,
  `sf_error.h`, `sf_error.cc` (default actions), `functions.json`,
  `scipy/special/meson.build`, and `subprojects/boost_math/meson.build`
  (Boost.Math 1.92.0, submodule at `7ff2d2b`, 2026-08-13). The xsref
  repository (`scipy/xsref`) at `b511621` (2026-08-11, the revision
  xsf's `pixi.toml` pins): `README.md`, `LICENSE` (BSD-3-Clause) and the
  table tree (173 function directories, 1 352 Parquet files, 127 MB).
  CRAN facts come from DESCRIPTION files on the CRAN GitHub mirror
  (`BH` 1.90.0-1, `Bessel` 0.7-1, `gsl` 2.1-9, `expint` 0.2-1,
  `hypergeo` 1.2-15, `elliptic` 1.5-1, `lamW` 2.2.7, `Rmpfr` 1.1-3,
  `RcppFaddeeva` 0.2.2, `pracma` 2.4.6) and `sf` 1.1-3's `NAMESPACE`. In
  the drafting session every xsf header except `numpy.h` compiled in one
  translation unit with GCC 13.3 and Clang 18.1 under `-std=c++17 -Wall
  -pedantic` with no warnings when `SP_SPECFUN_ERROR` is defined (§8);
  SciPy's Boost wrappers' calls compiled against Boost.Math at `7ff2d2b`
  with `BOOST_MATH_STANDALONE`. No R was available, so nothing was built
  as a package.

## 1. What zuspecial is

`zuspecial` evaluates the special functions of mathematical physics and
statistics (gamma and beta families, incomplete gamma and beta and their
inverses, error functions and Faddeeva, Bessel, Hankel, Airy, spherical
Bessel, hypergeometric, elliptic integrals in Legendre and Carlson forms,
zeta, Lambert W, Struve and more) through xsf: the header-only C++17
library that SciPy split out of `scipy.special`, holding modernised
Cephes, C++ translations of AMOS and of Zhang and Jin's specfun, the MIT
Faddeeva package, and SciPy's own newer kernels.

R's coverage is scattered. Base R has real-argument Bessel functions,
`gamma()`, `beta()`, `digamma()` and the distribution functions; complex
arguments, hypergeometric functions, elliptic integrals and the rest live
in single-purpose packages (`Bessel`, `hypergeo`, `elliptic`, `expint`,
`lamW`, `RcppFaddeeva`) or in `gsl`, which needs GNU GSL installed as a
system library and is GPL-3.

The honest caveat: Boost.Math, through `BH`, already gives R packages
much of this without a system library, for real arguments. zuspecial's
case rests on three things Boost through `BH` does not give:

1. **SciPy parity.** The same kernels, at the same commit, as
   `scipy.special`. When a model is implemented in Python and in R (a
   pricing library and its independent validation, say), the two must
   agree, and a special function from a different library is a needless
   source of disagreement in the last digits or at the edges of the
   domain.
2. **Complex arguments**, for Bessel, Hankel, Airy, gamma, error,
   Faddeeva, exponential-integral, hypergeometric and zeta functions.
3. **One coherent R API**: vectorised, recycled, `NA`-aware, with
   SciPy's names and argument order, so that translation from Python is
   mechanical.

Users: quantitative developers who validate a model across Python and R;
statisticians and physicists who need complex Bessel or hypergeometric
functions; and package authors who need a special function in C (a
distributions package wanting inverse incomplete beta, say) through the
C table (§7).

The one-line statement that governs every decision below:

> **`scipy.special`'s values in R, under `scipy.special`'s names, for real
> and complex arguments.**

## 2. Scope

**In v0.1.0** (each R function named `sc_` plus the SciPy name, §16
question 1; "c" marks complex-argument support, as SciPy registers it):

- Gamma and beta: `gamma` c, `gammaln`, `loggamma` c, `rgamma` c,
  `gammasgn`, `psi` c, `beta`, `betaln`, `binom`, `poch`.
- Incomplete gamma: `gammainc`, `gammaincc`, `gammaincinv`,
  `gammainccinv`.
- Incomplete beta: `betainc`, `betaincc`, `betaincinv`, `betainccinv`
  (Boost.Math in SciPy, §12.1).
- Error and related: `erf` c, `erfc` c, `erfcx` c, `erfi` c, `erfinv`
  (Boost.Math in SciPy), `erfcinv`, `dawsn` c, `wofz` c,
  `voigt_profile`, `ndtr` c, `log_ndtr` c, `ndtri`, `ndtri_exp`,
  `owens_t`.
- Exponential integrals: `exp1` c, `expi` c, `expn`.
- Bessel of real order: `jv`, `yv`, `iv`, `kv` c (all four), their
  exponentially scaled forms `jve`, `yve`, `ive`, `kve` c; `hankel1`,
  `hankel2`, `hankel1e`, `hankel2e` (complex only, as in SciPy); the
  fixed-order `j0`, `j1`, `y0`, `y1`, `i0`, `i0e`, `i1`, `i1e`, `k0`,
  `k0e`, `k1`, `k1e`.
- Spherical Bessel: `spherical_jn`, `spherical_yn`, `spherical_in`,
  `spherical_kn` c, each with `derivative = FALSE`.
- Airy: `airy` c and `airye` c (four outputs each).
- Hypergeometric: `hyp0f1` c, `hyp1f1` c (the real path is Boost.Math in
  SciPy), `hyp2f1` c, `hyperu`.
- Elliptic: `ellipk`, `ellipkm1`, `ellipkinc`, `ellipe`, `ellipeinc`,
  `ellipj` (four outputs); Carlson `elliprc` c, `elliprd`, `elliprf`,
  `elliprg`, `elliprj`. The Carlson forms wait for a SciPy release whose
  xsf has them (D12, 2026-10-23).
- Zeta and friends: `zeta` (Riemann c, and Hurwitz), `zetac`,
  `lambertw` c, `wrightomega` c, `spence` c.
- Struve: `struve`, `modstruve`.
- Error-state control mirroring SciPy's `geterr()`, `seterr()` and
  `errstate` (§6.4).
- A registered C table (§7).

**Later, when asked:**

- The remaining xsf kernels SciPy exposes: Kelvin (`ber`, `bei`, `ker`,
  `kei` and derivatives), Mathieu, prolate and oblate spheroidal wave
  functions, parabolic cylinder (`pbdv`, `pbvv`, `pbwa`), Fresnel and
  modified Fresnel, integrals of Bessel and Struve functions (`itj0y0`,
  `it2struve0` …), `wright_bessel`, Legendre (`lpmv`, `legendre_p`,
  `assoc_legendre_p`, `sph_harm_y`), the orthogonal-polynomial `eval_*`
  family, `agm`, `besselpoly`, the degree-argument trigonometric
  functions, `xlogy` and its siblings, and the information-theory
  helpers (`entr`, `rel_entr`, `kl_div`).
- The other Boost.Math functions SciPy uses (`log_gammainc`, `powm1`,
  and the `*dtr*` inverses), under the same backend rule (§12.1).
- Derivatives through xsf's `dual` type, which SciPy uses for the
  Legendre and spherical-harmonic families.
- Parallel evaluation of long vectors.

**Never:**

- Arbitrary precision: `Rmpfr` and `Bessel`'s `mpfr` methods do this,
  and zuspecial uses them only as test oracles.
- Distributions as d/p/q/r families: base R's `stats` and distribution
  packages do this. zuspecial ships the special functions such a package
  needs (incomplete gamma and beta and their inverses, `ndtri`,
  `log_ndtr`, `owens_t`), not the families, and not SciPy's private
  `_ncf_*`, `_nct_*`, `_landau_*` distribution kernels.
- Single precision. R has no `float`; xsf's `float` overloads are not
  instantiated.
- GPU execution, although xsf supports CUDA and HIP.

## 3. Position in the `zu*` family

| | zuspecial |
| --- | --- |
| Role | provider (C table); R API |
| R prefix | `sc_` (SciPy's own documentation alias, §16 question 1) |
| Info function | `zuspecial_info()` |
| Root condition class | `zuspecial_error` |
| Public C prefix | `zuspecial_` for the registered table; internal `zsp_` |
| From C | `R_GetCCallable("zuspecial", "zuspecial_api_v1")` |
| Hides symbols | yes (R3) |
| Vendored code | xsf `include/xsf`, without `numpy.h` and `third_party/` |
| `LinkingTo` | `BH`, for the Boost.Math backend (§12.1) |
| `Depends: R` | 4.1 (R2) |
| Language | en-GB (R2) |

**Relationships, as decided rather than as hoped:**

- **A distributions package** in the family is the intended first
  consumer of the C table, for inverse incomplete gamma and beta,
  `ndtri` and `owens_t`. No RFC for it exists yet; zuspecial does not
  wait for one, and a fixture package stands in (§14).
- **`zuxad`** (RFC 0017) differentiates through code it can see; xsf's
  kernels are opaque compiled code to it. Derivatives of special
  functions are a later zuspecial feature (§2), not a zuxad
  responsibility.
- **`zuexact`** (RFC 0023) is unrelated in code.
- No family package is required to adopt zuspecial.

**What exists elsewhere.**

- Base R: `besselJ()`, `besselY()`, `besselI()`, `besselK()` (real `x`,
  real order, argument order `(x, nu)`), `gamma()`, `lgamma()`,
  `beta()`, `lbeta()`, `digamma()`, `trigamma()`, `psigamma()`,
  `choose()`, and the incomplete gamma and beta functions as `pgamma()`,
  `qgamma()`, `pbeta()`, `qbeta()`.
- `gsl` 2.1-9 (GPL-3): wide coverage, real arguments for most functions;
  needs GSL >= 2.5 as a system library.
- `Bessel` 0.7-1 (GPL (>= 2), Maechler): complex Bessel functions
  through TOMS 644 (AMOS), the same algorithms as xsf's AMOS translation,
  plus `mpfr` methods.
- `hypergeo` 1.2-15 (GPL-2), `elliptic` 1.5-1 (GPL-2; needs `pari/gp`),
  `expint` 0.2-1 (GPL (>= 2)), `lamW` 2.2.7 (BSD-2-Clause),
  `RcppFaddeeva` 0.2.2 (GPL (>= 2)), `pracma` 2.4.6 (GPL (>= 3)).
- `BH` 1.90.0-1 (BSL-1.0): Boost.Math as headers, which a package can
  wrap itself.
- A Rust crate named `xsf` wraps the library (docs.rs lists
  `0.5.1+0.2.1`); not inspected further.
- No R binding of xsf was found.

## 4. Architecture

```text
R vectors (double / integer / complex), recycled
   |
   v
R layer: argument checks, recycling to a common length, real-or-complex
         dispatch, attribute transfer, error-state lookup
   |
   v
C glue (src/zsp_*.c): one loop per function signature; NA handled before
         any kernel is called; per-call error accumulator read afterwards
   |
   v
C++ shim (src/zsp_shim_*.cpp): extern "C", noexcept, one entry per
         function; defines xsf::set_error (thread-local accumulator);
         catches Boost.Math exceptions into sf_error codes
   |
   +--> xsf (vendored headers, C++17)
   +--> Boost.Math (from BH, BOOST_MATH_STANDALONE), six functions
   |
   v
R result: double or complex vector, or a named list for multi-output
          functions; conditions signalled once per call (§6.4)
```

- zuspecial's own code is C, except the shim. No C++ type or exception
  crosses into C or R; R's API is never called from the shim, so no
  `longjmp` passes through C++ frames.
- The shim is split into one translation unit per family (gamma and
  beta, error, Bessel, hypergeometric, elliptic, zeta and miscellaneous,
  Boost) so that `make -j` compiles them in parallel (§12.3).
  **As built (2026-10-24, Stage 2):** one translation unit,
  `src/zsp_shim.cpp`, including one header per family. xsf defines 42
  non-inline, non-template functions in its headers (it is built as one
  unit in SciPy), so a second unit including them fails to link. Splitting
  would need patches, which §8 rules out. The Boost wrappers (Stage 4)
  include no xsf kernels and may still be a unit of their own.
- `std::complex<double>` and R's `Rcomplex` never alias; the shim takes
  and returns a `{double re, im}` struct and converts by member.
- Multi-output functions (`airy`, `airye`, `ellipj`) fill several output
  arrays in one kernel call, as xsf's signatures do.

## 5. Public R API (complete v0.1.0 surface)

Every function in §2's v0.1.0 list is exported as `sc_<scipy name>`,
with SciPy's argument names and order. A representative sample:

```r
# gamma, beta and incomplete forms
sc_gamma(z)                       # real or complex
sc_loggamma(z)                    # principal branch, real or complex
sc_gammainc(a, x)                 # regularised lower P(a, x)
sc_gammaincinv(a, y)
sc_betainc(a, b, x)               # regularised I_x(a, b)
sc_betaincinv(a, b, y)

# error functions and the normal
sc_erf(z); sc_erfcx(z); sc_wofz(z)
sc_ndtr(x); sc_log_ndtr(x); sc_ndtri(y); sc_owens_t(h, a)

# Bessel, note SciPy's order: order first, argument second
sc_jv(v, z); sc_kve(v, z); sc_hankel1(v, z)
sc_spherical_jn(n, z, derivative = FALSE)
sc_airy(z)                        # list(ai, aip, bi, bip)

# hypergeometric, elliptic, zeta
sc_hyp2f1(a, b, c, z)
sc_ellipj(u, m)                   # list(sn, cn, dn, ph)
sc_elliprj(x, y, z, p)
sc_zeta(x, q = NULL)              # Riemann when q is NULL, else Hurwitz
sc_lambertw(z, k = 0L, tol = 1e-8)   # always complex, as in SciPy

# error state, after scipy.special.geterr / seterr / errstate
sc_geterr()                       # named character vector of actions
sc_seterr(all = NULL, singular = NULL, underflow = NULL, overflow = NULL,
          slow = NULL, loss = NULL, no_result = NULL, domain = NULL,
          arg = NULL, other = NULL, memory = NULL)   # previous state
sc_errstate(expr, ...)            # evaluate expr under temporary actions

zuspecial_info()                  # versions, backends, function table
```

`zuspecial_info()` returns the xsf commit, the xsref commit the tests
were generated from, the Boost version seen at build time
(`BOOST_VERSION` from `BH`), the compiler, and a data frame with one row
per exported function: R name, SciPy name, backend (`"xsf"` or
`"boost"`), and whether complex arguments are accepted.

## 6. Semantics

### 6.1 Vectorisation and recycling

- Every argument is recycled to the common length. Length-one arguments
  recycle silently; any other length that is not the common length is an
  error (`zuspecial_recycle_error`), not a warning, because a silently
  recycled parameter vector is a model bug. Zero-length input gives
  zero-length output.
- The result takes `dim`, `dimnames` and `names` from the first argument
  whose length equals the result's, as base R's arithmetic does.
  **As built (2026-10-24):** as base R does it: `dim` and `dimnames` from
  the first full-length argument that has them, else `names` from the
  first that has them; a zero-length input keeps its `dim`. Classed
  numbers (dates, difftimes) are refused with `zuspecial_invalid_argument`
  rather than stripped.
- Integer and logical input is converted to double; character, factor
  and list input is refused with `zuspecial_invalid_argument`.

### 6.2 Real and complex

- A function registered by SciPy with a complex signature takes the
  complex path when its complex-capable argument is of type `complex`,
  and returns `complex`. Real input stays on the real path and returns
  `double`.
- No automatic promotion: `sc_jv(0.5, -1)` is `NaN`, as in SciPy (xsf
  returned `NaN` in the drafting session), not the complex value.
  `sc_jv(0.5, -1+0i)` is the complex value.
- Integer-order arguments (`n` in `sc_spherical_jn()` and `sc_expn()`,
  `k` in `sc_lambertw()`) must be whole numbers within `int` range;
  others are refused with `zuspecial_invalid_argument`, matching
  NumPy's refusal to cast a float to an integer loop.
  **Corrected 2026-10-24 (Stage 2):** for `expn` SciPy 1.18.1 also
  registers a `dd->d` loop that truncates a non-whole `n` with a
  RuntimeWarning and returns `NaN` for a `NaN` `n`. zuspecial returns
  `NaN` for `NaN` but keeps refusing a non-whole `n`, a deliberate
  difference from SciPy, documented on `sc_expn()`.
- Branch cuts and principal values are xsf's, documented per function
  from SciPy's documentation.

### 6.3 Missing values

- `NA` in any argument gives `NA` in that element of the result,
  decided in the C glue before the kernel is called: xsf's arithmetic
  does not promise to carry R's `NA` payload, so `NA` and `NaN` would
  otherwise blur. `NaN` input is passed to the kernel and gives what
  SciPy gives (normally `NaN`).
- A complex element is `NA` when either part is `NA`.
- Multi-output functions return `NA` in every output for that element.

### 6.4 Floating-point conditions

xsf reports conditions through `xsf::set_error(name, code, fmt, …)` with
SciPy's ten codes (`singular`, `underflow`, `overflow`, `slow`, `loss`,
`no_result`, `domain`, `arg`, `other`, `memory`). With
`SP_SPECFUN_ERROR` defined, zuspecial supplies `set_error`:

- It records the code into a thread-local accumulator (a bit per code,
  a count and the first element index). It never signals, allocates or
  calls R.
- After the loop, the glue looks up the action for each recorded code:
  `"ignore"`, `"warn"` (a warning of class `zuspecial_warning` and
  `zuspecial_<code>`) or `"raise"` (an error, §9). Each code is
  signalled once per call, with the count and the first index, not once
  per element.
- Defaults are SciPy's (`sf_error.cc`): every code `"ignore"` except
  `memory`, which is `"raise"`.
- The R function's name is reported, not xsf's. The drafting session
  showed why: `gammaincinv(-1, 0.5)` reached `set_error` from the inner
  `Gamma`, not from `gammaincinv`.
- The action state lives in R options (`zuspecial.errstate`), so
  `sc_errstate()` is an `on.exit()` restore, and parallel R workers
  inherit nothing implicitly.

### 6.5 Names and argument order

SciPy's names and order are kept even where base R differs:
`sc_jv(v, z)` against base `besselJ(x, nu)`, `sc_gammainc(a, x)` against
`pgamma(x, a)`. The documentation of each function names its base R and
`gsl` counterparts. Two functions add R conventions SciPy expresses
otherwise: `sc_zeta(x, q = NULL)` and `derivative = FALSE` in the
spherical Bessel functions, both as in SciPy's Python wrappers.

## 7. The C table

```c
/* registered with R_RegisterCCallable("zuspecial", "zuspecial_api_v1") */
typedef struct { double re, im; } zuspecial_complex;

typedef struct {
  uint32_t    struct_size;     /* the only version discriminator */
  const char *xsf_commit;      /* "471c1b5..." */
  /* each member returns the value and, if code is not NULL, writes the
     first sf_error code raised (0 when none) */
  double (*gamma)(double x, int *code);
  double (*gammaln)(double x, int *code);
  double (*gammainc)(double a, double x, int *code);
  double (*gammaincc)(double a, double x, int *code);
  double (*gammaincinv)(double a, double y, int *code);
  double (*gammainccinv)(double a, double y, int *code);
  double (*betainc)(double a, double b, double x, int *code);
  double (*betaincinv)(double a, double b, double y, int *code);
  double (*ndtri)(double y, int *code);
  double (*log_ndtr)(double x, int *code);
  double (*owens_t)(double h, double a, int *code);
  zuspecial_complex (*jv_c)(double v, zuspecial_complex z, int *code);
  /* … one member per exported function, appended over time … */
} zuspecial_api;
```

The table follows `zuxml`'s versioning rules: `struct_size` is the only
discriminator, members are appended and never reordered or removed, and
any layout change in another public type (here `zuspecial_complex`)
bumps the registered name. All members are reentrant, allocate nothing
through R and are safe from any thread, because the error accumulator is
thread-local; they ignore the R-level error actions, so the consumer
decides what a code means. Consumers include `inst/include/zuspecial.h`
only, never xsf or Boost headers.

## 8. The vendored library, as zuspecial uses it

**As built (2026-10-23, Stage 1).** The pin is SciPy v1.18.1's xsf gitlink,
`f7b85f5` (2026-05-20), per D12, not `471c1b5`. That commit predates both the
Carlson integrals and the `cpu/` move, so its headers sit directly under
`include/xsf/` (`specfun.h`, `amos/`, `cephes/`). The tree lives in
`src/vendor/xsf/include/xsf/`, not `src/xsf/`, because xsf's own includes
are `"xsf/..."` and the portfolio keeps vendored code under `src/vendor/`;
`tools/vendor/vendor-xsf`, `tools/vendor/manifest.tsv`,
`tools/vendor/checksums.sha256` and `tools/vendor/verify` replace
`tools/vendor-xsf` and `src/xsf/VERSION`. The build also defines `NDEBUG`:
`specfun/specfun.h` has a bare `assert`, which would link `abort`. The text
below is the RFC as drafted.

- `include/xsf/**` from xsf at the commit SciPy pins (`471c1b5` at the
  time of writing), without `numpy.h` (it includes `Python.h`) and
  without `third_party/` (the Apache-2.0 `mdspan`, reached only from
  `numpy.h`), into `src/xsf/`. `tools/vendor-xsf` takes the commit from
  a SciPy checkout's `subprojects/xsf` gitlink, copies the tree, and
  records SciPy's commit, xsf's commit and the SHA-256 of each file in
  `src/xsf/VERSION`.
- Pinning to SciPy's gitlink rather than an xsf tag is deliberate: the
  latest tag (`v0.2.2`) is 165 commits behind and predates both the
  Carlson elliptic integrals (2026-09-29) and the move of CPU-only
  headers under `cpu/` (2026-10-01), and parity means SciPy's code, not
  xsf's last release. §16 question 3 asks how this is tracked.
- Build: `-DSP_SPECFUN_ERROR`, so `set_error` is declared, not defined,
  and zuspecial defines it (§6.4). Without the define, xsf's no-op
  default triggers three `-Wunused-parameter` warnings under `-Wextra`;
  with it, the drafting build had none under `-Wall -pedantic` with GCC
  13.3 or Clang 18.1. Under `-Wextra`, GCC reports five further
  unused-parameter warnings in `faddeeva.h`, `lambertw.h` and
  `cpu/bessel.h`; CRAN's flags do not include `-Wextra`.
- A shared object built from a translation unit including every header
  imported no stdio, `abort` or `exit` symbol; its only C++ runtime
  imports were `operator new[]`/`delete[]` with `nothrow`, and
  `__muldc3`/`__divdc3` for complex arithmetic. A grep found no mutable
  static state outside `numpy.h`. Stage 0 repeats both checks on every
  CI leg.
- Patches: none expected. **As built (2026-10-24, Stage 3):** one,
  `tools/patches/0001-float-to-int-conversion.patch`. The xsref inputs
  reach five float-to-int conversions of `NaN` or out-of-range doubles in
  `cephes/beta.h` and `faddeeva.h`, undefined behaviour that clang's UBSan
  reports and CRAN's UBSan check would. The patch guards them without
  changing results; it is reported upstream and listed in
  `src/vendor/PROVENANCE`. Stage 5 adds `0002` for three more such sites the
  Bessel inputs reach (`bessel.h`, `cephes/yv.h`, one of ten in
  `amos/amos.h`; the other nine are reached by no test and left alone).
- Re-vendoring follows SciPy releases rather than xsf commits, after the
  full suite including the SciPy-parity tables (§10).

## 9. Errors

Every condition inherits `zuspecial_error`: `zuspecial_invalid_argument`
(with argument name and element index), `zuspecial_recycle_error` (with
the lengths), `zuspecial_<code>_error` for each sf_error code raised
under `"raise"` (`zuspecial_domain_error`, `zuspecial_overflow_error`
and so on, with `fn`, `count` and `first_index`),
`zuspecial_internal_error`. Warnings inherit `zuspecial_warning` and
carry the same fields.

## 10. Testing

**As built (2026-10-24, Stage 3).**

- The xsref pin is the commit xsf's own `pixi.toml` clones at the vendored
  xsf commit: `4e9b234` for `f7b85f5`, not `b511621`, which goes with
  SciPy `main`'s xsf. `tools/vendor/vendor-xsf` records it, and
  `zuspecial_info()` reports it.
- `tools/xsref-extract` reads Parquet with `arrow`, as a tool only, and
  writes one `.rds` per function and signature. No value passes through
  text: R's parser loses subnormals in hex floats. The shipped sample is
  250 evenly spaced rows per table: 208 KB of xsref and 284 KB of SciPy
  values for the 21 Stage 2 functions.
- Agreement with SciPy is checked two ways, because it is not bit for bit
  across platforms. On macOS arm64, with FMA contraction, ill-conditioned
  inputs such as `beta(0.76, 897)` differ from SciPy's macOS x86_64 values
  by up to 3e-11, while both are within xsref's tolerance of mpmath.
  - Shipped tables, generated once on macOS x86_64 from xsref inputs only:
    a row may differ by the sum of the two platforms' xsref tolerances,
    since each result is within its own of mpmath.
  - CI (`xsref.yaml`): SciPy 1.18.1 runs on each OS over every xsref row
    and 200 seeded random inputs, and zuspecial must agree with it within
    64 ulps on the same platform.
  A table's worst recorded error is no use as a tolerance: it is `Inf` for
  12 of the 32 tables. On macOS x86_64 agreement is bit for bit.
- **Platform tables (2026-10-24, Stage 5).** The xsref check uses xsref's
  `other` table on every platform, not the one for the platform. Those
  tables describe xsf's own CI toolchains; zuspecial is built with R's
  compilers and flags, the case `other` is for. On Linux one complex
  `iv(36.27, -2.237)` row of 1 005 413 was 1.6e-14 from mpmath against the
  `gcc-linux-x86_64` table's 6.5e-15, while agreeing with SciPy's Linux
  build within 64 ulps; on no row is a platform table above `other`.
  Precision is held by the same-platform SciPy check.
- **Ports from SciPy (2026-10-24, Stage 6).** xsf at the 1.18.1 pin lacks
  five functions SciPy implements itself: `hyp0f1`, `hyperu` and complex
  `spence` (Cython, ported to C++ line for line), `wrightomega` (`wright.cc`
  with `_round.h`, Piers Lawrence, BSD-3, ported with its Python and
  `sf_error` calls removed), and real `hyp1f1`, which SciPy evaluates with
  Boost.Math (in `src/zsp_boost.cpp`). Ported Cython uses NumPy's `csqrt`
  and `cpow` (`src/zsp_ccomplex.c`) where SciPy's does: `std::complex`
  rounds differently, by up to 256 ulps in `hyp0f1` at large order. As in
  SciPy, the Hurwitz zeta takes complex `x` only on the real axis.
- **Fallback rows (2026-10-24, Stage 6).** xsref's `fallback` rows store
  an earlier SciPy's value where mpmath gave none; the xsref check skips
  them (the report still counts them), since agreement with SciPy 1.18.1 is
  the SciPy check's job. `hyp2f1(-1, 1, -10, -10)` is `NaN` in its fallback
  row but 0 in SciPy 1.18.1, the terminating polynomial's value.
- **Independent oracles (2026-10-24, Stage 7).** `test-oracle-packages.R`
  checks against `gsl` (real arguments, with its modulus `k` where SciPy
  takes `m = k^2`), `Bessel` (complex Bessel, Hankel, Airy), `hypergeo`
  (complex 2F1), `lamW` and `expint`; `test-mpfr.R` sweeps a few hundred
  points per family against 200-bit `Rmpfr` values, judging oscillating
  functions against their envelope, with absolute checks at zeros. All
  agree; the explained disagreements are recorded in the tests: `gsl`'s
  `dilog()` returns the real part of a complex value where SciPy's real
  `spence()` is `NaN`; `gammaln` near 1 and `psi` beside its poles are less
  accurate in xsf, and so in SciPy, than MPFR (identical values to SciPy
  1.18.1). All six are Suggests; the suite passes without them.
- **Windows (2026-10-24).** Rtools45 uses mingw-w64 v11, whose `sin` and
  `cos` lose accuracy from |x| ~ 1e5 (about 18 ulps at 1e5, 400 at 1e8)
  and are wrong in value and sign beyond ~1e15, as base R's `sin()` is on
  Windows. Complex `exp`, `sin` and `cos`, and GCC's fused sin/cos (lowered
  to `cexp`), inherit it. 14 085 xsref and SciPy rows with an argument of at
  least 1e5 fail on Windows only; `tests/testthat/known-windows.tsv.gz` lists
  them, and the tests apply it on Windows only, check that every listed row
  has such an argument, and in CI fail when a listed row starts passing.
  R core's post on mingw-w64 v12 (2025-04-24) explains why Rtools stayed on
  v11; v12 takes `sin` and `cos` from UCRT, which reduces large arguments
  accurately, so the list is re-checked when Rtools moves. Shipping an own
  trig on Windows was considered and declined (2026-10-24). SciPy's Windows
  wheels use UCRT, so on Windows the SciPy comparison is not same-platform:
  xsref rows take the summed rule with SciPy's `msvc-windows-x86_64` table,
  and random rows are compared on Linux and macOS only.
- `sc_expn` is tested on xsref's integer-`n` table only; its float-`n`
  table holds non-whole orders, which zuspecial refuses (§6.2).

- **xsref**, the primary oracle: mpmath reference values for the cases
  that were in `scipy.special`'s own tests, stored as Parquet under
  `src/xsref/tables/scipy_special_tests/<xsf kernel>/` with `In_`,
  `Out_` and per-platform `Err_` files. xsf's own rule is that the
  extended relative error must not exceed `4 * max(eps, recorded)`,
  with the recorded error taken from the platform's file
  (`gcc-linux-x86_64`, `clang-darwin-aarch64`, `msvc-windows-x86_64`,
  else `other`). zuspecial applies the same rule, with Rtools' GCC on
  Windows mapped to `other`. Out rows whose `fallback` column is true
  hold SciPy's earlier values, not mpmath's; the report counts them
  separately.
- **Size.** The tables are 127 MB, too large for a CRAN tarball.
  `tools/xsref-extract` converts them once per pin to compact binary
  files: a sample capped at 2 MB ships in `tests/testthat/`, and the
  full set runs in a CI job that fetches xsref at the pinned revision.
  How the extractor reads Parquet (`nanoparquet` or `arrow` in a tools
  environment) is unverified.
- **SciPy itself**, for parity, and the only oracle for the Boost-backed
  functions, which have no xsref tables: `tools/scipy-values.py` runs
  the pinned SciPy on the xsref inputs plus random inputs per function,
  and writes the results with SciPy's version. Agreement is within the
  same tolerance, not bit for bit, because xsf calls the platform's
  `libm` (`std::exp`, `std::log` …) and compilers may contract
  expressions into FMA differently.
- **Independent oracles** (Suggests): base R (`besselJ()` and siblings
  on real input, `gamma()`, `lgamma()`, `beta()`, `digamma()`,
  `pgamma()`/`qgamma()` against `sc_gammainc()`/`sc_gammaincinv()`,
  `pbeta()`/`qbeta()` against the incomplete beta, `pnorm()`/`qnorm()`
  against `ndtr`, `log_ndtr` and `ndtri`), `gsl`, `Bessel` (complex
  Bessel), `hypergeo`, `lamW`, `expint`. A disagreement is investigated,
  not failed automatically, because each is a different algorithm.
- **mpfr spot checks** (`Rmpfr`, Suggests): a few hundred points per
  family at 200 bits, chosen near zeros, poles, branch cuts and
  overflow thresholds, skipped when `Rmpfr` is absent.
- **Semantics**: recycling, attributes, `NA` against `NaN`, complex
  dispatch, the error-state actions and their once-per-call signalling,
  and `sc_errstate()` restoring state after an error.
- `zufuzz` targets for the glue (recycling and dispatch), not for xsf's
  kernels. CRAN suite under 15 s.

## 11. Performance targets

Measured by `tools/run-benchmarks`, recorded in the design: the R and
C layers add no more than 10 % to kernel time for vectors of 10 000
elements or more; `sc_gamma()`, `sc_gammaln()` and `sc_jv()` on real
input are within 2× of base `gamma()`, `lgamma()` and `besselJ()` (a
different algorithm, so not a promise of speed, only a guard against
glue overhead); `sc_jv()` on complex input is no slower than `Bessel`'s
`BesselJ()`. A missed target is reported, not hidden by relaxing it.

## 12. Build, portability and CRAN

### 12.1 The Boost.Math backend

SciPy does not evaluate every `scipy.special` function with xsf. Of the
286 ufunc registrations in `_special_ufuncs.cpp`, the public functions
in zuspecial's v0.1.0 list that SciPy evaluates with Boost.Math are
`betainc`, `betaincc`, `betaincinv`, `betainccinv`, `erfinv`, and the
real path of `hyp1f1`. xsf carries Cephes' `incbet` and `incbi`, but
SciPy's public `betainc` does not use them. Parity therefore needs
Boost.Math, called as SciPy calls it: the same policy
(`promote_float<false>`, `promote_double<false>`,
`max_root_iterations<400>`), the same special-casing before the call,
and exceptions caught into the same sf_error codes. Those wrappers are
ported from SciPy's `boost_special_functions.h` (BSD-3-Clause).

SciPy pins Boost.Math 1.92.0 (`7ff2d2b`); `BH` on CRAN is 1.90.0-1.
Stage 0 decides between:

1. `LinkingTo: BH`, accepting the version gap if the SciPy-value
   tables agree within tolerance on every CI leg; or
2. vendoring Boost.Math's headers at SciPy's pin with
   `BOOST_MATH_STANDALONE` (11 MB of headers at `7ff2d2b`, most of it
   unused, so a trimmed copy).

The recommendation is the first, with the second as the fallback if any
table disagrees. Either way `zuspecial_info()` reports the Boost version.

**As built (2026-10-24, Stage 4).** SciPy 1.18.1 pins Boost.Math 1.91.0
(`subprojects/boost_math`), not 1.92.0; CRAN's `BH` is 1.90.0-1. zuspecial
uses `LinkingTo: BH` with `BOOST_MATH_STANDALONE`, in its own translation
unit (`src/zsp_boost.cpp`, which includes no xsf kernels, so the §4
single-unit rule does not apply). On macOS x86_64 all five functions agree
with SciPy 1.18.1 within 64 ulps on 200 random inputs each; CI repeats this
on every OS against SciPy run there. That is the §16 question 4 evidence
for `BH`. `ndtri_exp` is not in xsf at the 1.18.1 pin; it is ported from
SciPy's Cython `_ndtri_exp.pxd` (Albert Steppi, SciPy's licence) on xsf's
`cephes::ndtri`.
In the drafting session, four of the wrappers' calls (`ibeta`,
`ibeta_inv`, `erf_inv`, `hypergeometric_1F1`) compiled at `7ff2d2b`
without warnings under `-Wall -pedantic` and imported `__cxa_throw`,
which is why the shim catches.

### 12.2 Licences

zuspecial is MIT. `inst/COPYRIGHTS` records every bundled licence:

- xsf: BSD-3-Clause (SciPy).
- `LICENSES_bundled.txt`: Cephes (BSD-3-Clause, by permission of
  Stephen Moshier), Faddeeva (MIT), qd's `dd_real.h` (BSD-3-Clause-LBNL),
  Genz's multivariate normal routines (BSD-3-Clause); `mdspan`
  (Apache-2.0 with LLVM exception) is not vendored.
- Notices not listed there: `cephes/psi.h` and `cephes/scipy_iv.h`
  contain Boost-derived code under BSL-1.0; `lambertw.h`,
  `wright_bessel.h` and `ndtri_exp.h` are "distributed under the same
  license as SciPy"; `wright.h` is BSD by its author's relicensing.
- AMOS: Sandia's notice, "approved for unlimited release".
- specfun (Zhang and Jin): "Copyrighted but permission granted to use
  code in programs." This is a permission statement, not a named
  licence. SciPy ships it under its BSD licence, and Stage 0 records
  whether that is enough for CRAN's licence field, before anything else
  depends on the specfun-backed code (in v0.1.0's list, `hyperu` and
  complex `hyp1f1`, through `cpu/specfun.h`; `cpu/bessel.h` also calls
  specfun's `msta1` and `msta2` helpers). If it is not, the two functions
  move to Later and the helpers need a replacement, which would be a
  patch (§8).

  **Decided 2026-10-23 (D13):** accepted as SciPy ships it, recorded in
  `inst/COPYRIGHTS`. If a CRAN reviewer objects, the specfun-backed
  functions move to Later then.

### 12.3 Everywhere

- C++17 for the vendored code and the shim (`CXX_STD = CXX17`; xsf's
  CMake target requires it and `-std=c++14` fails), C99 for the glue;
  hidden visibility; `R_init_zuspecial` the only export; the C table
  registered.
- No SIMD, no intrinsics, no system libraries, no Fortran: AMOS and
  specfun are already C++ translations in xsf.
- xsf's CUDA and HIP branches are inert without `__CUDACC__` and
  `__HIPCC__`; nothing defines them.
- Compile time: one translation unit with 104 wrapper functions took
  12.5 s at `-O2` with GCC 13.3 (shared object about 450 KB stripped);
  the Boost unit alone took 8 s. Stage 0 measures the whole package on
  every CI leg, and splits the shim further if any unit dominates.

## 13. Roadmap

| Stage | Title | Size |
| --- | --- | --- |
| 0 | Identity; vendor; build matrix; §12.1 backend and §12.2 licences | M |
| 1 | Glue: recycling, dispatch, `NA`, error state; gamma and error | M |
| 2 | Incomplete gamma and beta, the Boost backend, normal functions | M |
| 3 | Bessel, Hankel, spherical Bessel, Airy | M |
| 4 | Hypergeometric, elliptic, zeta, Lambert W, Struve | M |
| 5 | xsref extraction, SciPy-value tables, oracles, mpfr checks | M |
| 6 | The C table and a consumer fixture | S |
| 7 | Benchmarks, documentation and release 0.1.0 | S |

## 14. Acceptance criteria for v0.1.0

1. `R CMD check --as-cran` clean on every CI leg, with §12.1's and
   §12.2's outcomes recorded.
2. Every exported function passes its xsref cases under xsf's tolerance
   rule, and its SciPy-value table at the pinned SciPy, on every CI leg.
3. The documented base R, `gsl` and `Bessel` comparisons pass or carry a
   written explanation.
4. A fixture package consumes the C table, including a complex member
   and the error code.

## 15. Decisions

| # | Question | Decision |
| --- | --- | --- |
| D1 | Home | standalone |
| D2 | Library | xsf headers at SciPy's submodule pin |
| D3 | Boost-backed functions | Boost.Math as SciPy calls it (§12.1) |
| D4 | Glue | C, through a `noexcept` C++ shim per family |
| D5 | Names | `sc_` plus SciPy's name; SciPy's argument order |
| D6 | Complex | dispatch on input type; no automatic promotion |
| D7 | `NA` | decided in the glue, before any kernel |
| D8 | Conditions | SciPy's codes and default actions; once per call |
| D9 | Recycling | length one or the common length; otherwise an error |
| D10 | Provider | a versioned C table of scalar functions |
| D11 | Info function | `zuspecial_info()`, the package name (R1) |
| D12 | xsf pin | the gitlink of the latest SciPy release (v1.18.1: `f7b85f5`); Carlson integrals wait for a release that has them (2026-10-23) |
| D13 | specfun licence | accepted as SciPy ships it (§12.2; 2026-10-23) |
| D14 | Prefix | `sc_` (§16 question 1; 2026-10-23) |
| D15 | Error-state storage | R options (§16 question 5; 2026-10-23) |
| D16 | Multi-output shape | a named list (§16 question 6; 2026-10-23) |

## 16. Open questions

Questions 1, 3, 5 and 6 were decided on 2026-10-23 as recommended (D14,
D12, D15, D16). Question 2 is settled by the repository's name. Question 4
is decided in roadmap Stage 4, from the SciPy-value tables.

1. **The prefix.** `sf_` is taken by association: `sf` exports seven
   `sf_` functions (`sf_project()`, `sf_use_s2()` …) and is attached in
   most spatial sessions. `sp_` reads as the `sp` package, also on CRAN.
   Bare SciPy names collide with base R (`gamma`, `beta`, `round`,
   `log1p`, `expm1`). Descriptive names (`bessel_j()`, `airy()`) read
   well but break mechanical translation, and offering both doubles the
   surface. Recommended: `sc_`, after `import scipy.special as sc`, the
   alias SciPy's own docstrings use (41 times in
   `_special_ufuncs_docs.cpp`); descriptive aliases only if users ask.
2. **The name.** `zuspecial` or `zuxsf`? Recommended: `zuspecial`; it
   names the job, and the library may change behind it.
3. **Tracking SciPy.** Re-vendor on each SciPy release (stable, but up to
   six months behind `main`), or follow SciPy `main`'s gitlink?
   Recommended: SciPy releases, recorded in `zuspecial_info()`, because
   the parity claim is against a SciPy users can install.
4. **Boost backend.** `BH` or vendored Boost.Math at SciPy's pin
   (§12.1)? Recommended: `BH`, unless the Stage 0 tables disagree.
5. **Error-state storage.** R options, or a C-level thread-local copy as
   SciPy keeps? Recommended: options; the C table already ignores the
   actions, and R evaluates the glue on one thread.
6. **Multi-output shape.** A named list (as above) or a data frame?
   Recommended: a named list, mirroring SciPy's tuple; a data frame
   would force recycling semantics on outputs.

## 17. What this RFC does not decide

- Whether `gsl`, `Bessel`, `hypergeo` or other packages' users should
  switch. zuspecial's claim is parity with SciPy and a single API; it
  does not claim better accuracy than any of them.
- The distributions package that would consume the C table; it needs
  its own RFC.

Review prepared with assistance from generative AI.

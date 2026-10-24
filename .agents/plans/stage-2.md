# Stage 2 — Glue, error state, gamma and error functions: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The R and C layers every function goes through, exercised by 21
exported gamma, beta, error-function and exponential-integral functions.

**Architecture:** R validates, recycles, coerces and dispatches real or
complex; one C loop per signature looks the kernel up by name, handles `NA`
before calling it, and returns an error report as an attribute; R then
signals each raised code once under the action in `zuspecial.errstate`.

**Tech Stack:** base R only (no Imports), C99 glue, C++17 shim over xsf.

**Spec:** `.agents/design.md` §2, §4, §5, §6, §9; roadmap Stage 2.

## Global Constraints

- Zero hard runtime dependencies: base R conditions, no rlang or cli.
- Exported names are `sc_` plus SciPy's name with SciPy's argument names and
  order (D5, D14). `psi` calls `xsf::digamma`; `poch`, `erfcinv` and `expn`
  call `xsf::cephes::`.
- Recycling: length one or the common length, else `zuspecial_recycle_error`;
  any zero-length argument gives zero-length output (D9).
- Integer and logical input becomes double; character, factor, list and
  complex-where-unsupported input is `zuspecial_invalid_argument`.
- No automatic promotion (D6): real input takes the real loop. Exception:
  `wofz` has only a complex loop in SciPy, so real input is promoted, as
  NumPy's safe cast does.
- `NA` in any argument gives `NA` (or `NA_complex_`) without calling the
  kernel; `NaN` is passed through. Complex is `NA` if either part is.
- Error codes, in `sf_error_t` order 1..10: `singular`, `underflow`,
  `overflow`, `slow`, `loss`, `no_result`, `domain`, `arg`, `other`,
  `memory`. Defaults: all `"ignore"`, `memory` `"raise"` (D8).
- Error state lives in `getOption("zuspecial.errstate")`, a named character
  vector over those ten codes; unset means the defaults (D15).
- Warning classes: `c("zuspecial_<code>", "zuspecial_warning", "warning",
  "condition")`; error classes: `c("zuspecial_<code>_error",
  "zuspecial_error", "error", "condition")`. Both carry `fn`, `code`,
  `count`, `first_index`.
- The shim never calls R; no PROTECT imbalance (gctorture runs at step 20).

## Review Focus

- A length-0 argument recycled with a length-3 one: result is length 0, no
  error (base R arithmetic does the same). Test in Task 2.
- `NA_integer_` and `NA` (logical) arguments: they become `NA_real_` and
  give `NA`, not `NaN`. Test in Task 2.
- A complex `NaN` (`complex(real = NaN, imaginary = 0)`) is not `NA` and
  reaches the kernel. Test in Task 3.
- An error inside `sc_errstate(expr)` restores the previous state. Test in
  Task 1.
- An element whose kernel raises two codes: both are reported, each once.
  Test in Task 3 through the report attribute.

---

### Task 1: Conditions and error state (pure R)

**Files:**

- Create: `R/conditions.R`, `R/errstate.R`
- Test: `tests/testthat/test-errstate.R`

**Interfaces:**

- Produces: `zsp_codes` (character, the ten codes in order);
  `zsp_abort(class, message, ..., call)` and `zsp_warn(class, message, ...,
  call)` building conditions with extra fields;
  `zsp_signal_report(report, fn, call)` taking the C report (below) and
  signalling per the current actions.
- Produces (exported): `sc_geterr()` → named character vector over
  `zsp_codes`; `sc_seterr(all = NULL, singular = NULL, underflow = NULL,
  overflow = NULL, slow = NULL, loss = NULL, no_result = NULL, domain = NULL,
  arg = NULL, other = NULL)` → previous state, invisibly; `sc_errstate(expr,
  ...)` → value of `expr`, `...` passed to `sc_seterr()`.

- [ ] **Step 1: Write the failing tests:**

```r
test_that("defaults are SciPy's", {
  withr::local_options(zuspecial.errstate = NULL)
  expect_identical(
    sc_geterr(),
    c(singular = "ignore", underflow = "ignore", overflow = "ignore",
      slow = "ignore", loss = "ignore", no_result = "ignore",
      domain = "ignore", arg = "ignore", other = "ignore", memory = "raise")
  )
})

test_that("seterr returns the previous state and `all` sets every code", {
  withr::local_options(zuspecial.errstate = NULL)
  old <- sc_seterr(all = "warn", domain = "raise")
  expect_identical(old[["memory"]], "raise")
  expect_identical(sc_geterr()[["domain"]], "raise")
  expect_identical(sc_geterr()[["singular"]], "warn")
})

test_that("seterr refuses unknown actions", {
  expect_error(sc_seterr(domain = "loud"), class = "zuspecial_invalid_argument")
})

test_that("errstate restores state after an error", {
  withr::local_options(zuspecial.errstate = NULL)
  expect_error(sc_errstate(stop("boom"), all = "raise"))
  expect_identical(sc_geterr()[["singular"]], "ignore")
})
```

- [ ] **Step 2:** Run `Rscript -e 'devtools::test(filter = "errstate")'`;
  expect FAIL (functions not found).
- [ ] **Step 3:** Implement. `all` applies first, then the named codes.
  Valid actions are `"ignore"`, `"warn"`, `"raise"`. Add `withr` to
  Suggests.
- [ ] **Step 4:** Tests pass. Commit: `Add error-state control after SciPy`.

### Task 2: Argument preparation (pure R)

**Files:**

- Create: `R/args.R`
- Test: `tests/testthat/test-args.R`

**Interfaces:**

- Produces: `zsp_prep(args, complex_ok, call)` where `args` is a named list
  of the user's arguments and `complex_ok` the names that may be complex.
  Returns `list(args = <recycled doubles or complexes>, n = <length>,
  complex = <TRUE if any complex_ok argument is complex>, template =
  <argument whose attributes the result takes, or NULL>)`.
  `zsp_whole(x, name, call)` checks an integer-order argument and returns an
  integer vector.
- Produces: `zsp_finish(value, template)` copies `dim`, `dimnames` and
  `names` from `template`.

- [ ] **Step 1: Write the failing tests**, through `zsp_prep()` directly:
  recycling `1` with length 3 is fine; lengths 2 and 3 give
  `zuspecial_recycle_error`; a length-0 argument gives `n == 0`;
  `"a"`, `factor("a")`, `list(1)` give `zuspecial_invalid_argument`;
  complex in a non-`complex_ok` argument gives `zuspecial_invalid_argument`;
  `NA` (logical) and `NA_integer_` come back as `NA_real_`;
  `zsp_whole(c(1, 2.5), "n")` and `zsp_whole(2^31, "n")` give
  `zuspecial_invalid_argument`, `zsp_whole(c(1, NA), "n")` gives
  `c(1L, NA)`; the template is the first argument whose length equals `n`,
  so a 2x2 matrix keeps its `dim`.
- [ ] **Step 2:** Run; expect FAIL.
- [ ] **Step 3:** Implement. When any `complex_ok` argument is complex,
  every `complex_ok` argument is coerced to complex.
- [ ] **Step 4:** Tests pass. Commit: `Prepare arguments: recycling, types, attributes`.

### Task 3: C glue loops and the shim units

**Files:**

- Create: `src/zsp_glue.c`, `src/zsp_shim_error.cpp`
- Modify: `src/zsp_shim.h`, `src/zsp_shim_gamma.cpp`, `src/zuspecial.c`
- Delete: `src/zsp_spike.c`, `tests/testthat/test-shim.R` (moved into
  `test-glue.R`)
- Test: `tests/testthat/test-glue.R`

**Interfaces:**

- Produces (shim, C linkage, `noexcept`), one per kernel and signature:
  `double zsp_<name>(double)`, `zsp_complex zsp_<name>_c(zsp_complex)`,
  `double zsp_<name>(double, double)`, `double zsp_<name>(double, double,
  double)`, `double zsp_expn(int, double)`. Gamma family in
  `zsp_shim_gamma.cpp`; error functions and exponential integrals in
  `zsp_shim_error.cpp`.
- Produces (`.Call`, registered): `zsp_call_d(name, x)`, `zsp_call_c(name,
  z)`, `zsp_call_dd(name, a, b)`, `zsp_call_ddd(name, a, b, c)`,
  `zsp_call_id(name, n, x)`. `name` is a length-1 character vector looked up
  in a static table for that signature (unknown name is an R error raised
  before the loop). Inputs are already recycled to equal length. Returns
  the result vector; when any code was raised, it carries attribute
  `"zsp_err"`: an integer vector of length 20, `count[k]` at `k` and
  `first_index[k]` (1-based) at `10 + k`, for codes `k = 1..10`.

- [ ] **Step 1: Write the failing tests**, calling the routines directly:
  `zsp_call_d("gamma", c(5, NA, NaN))` is `c(24, NA, NaN)` with `NA`
  identical to `NA_real_`; `zsp_call_d("gamma", c(1, -1, -2))` has
  `attr(, "zsp_err")[1] == 2` and `[11] == 2`; `zsp_call_c("gamma",
  complex(real = c(NA, NaN), imaginary = 0))` gives `NA_complex_` then a
  non-`NA` value; `zsp_call_id("expn", c(1L, NA), c(1, 1))` gives a value
  then `NA`; `zsp_call_d("nosuch", 1)` errors.
- [ ] **Step 2:** Run; expect FAIL.
- [ ] **Step 3:** Implement the shim entries and tables. The kernel is
  called only when no input element is `NA` (`R_IsNA` on each real, on each
  part of a complex, `NA_INTEGER` for `n`).
- [ ] **Step 4:** Tests pass; `R CMD INSTALL . && tools/check-symbols src`
  passes. Commit: `C glue: one loop per signature, NA before the kernel`.

### Task 4: The exported functions

**Files:**

- Create: `R/eval.R` (the shared path), `R/gamma.R`, `R/erf.R`,
  `R/expint.R`
- Test: `tests/testthat/test-gamma.R`, `test-erf.R`, `test-expint.R`,
  `test-semantics.R`

**Interfaces:**

- Consumes: `zsp_prep()`, `zsp_finish()`, `zsp_whole()` (Task 2), the
  `.Call` routines (Task 3), `zsp_signal_report()` (Task 1).
- Produces: `zsp_eval(name, args, complex_ok = character(), call)`
  choosing `zsp_call_c` or the real routine by `prep$complex` and argument
  count, then finishing and signalling. Every exported function is one line
  over it. Exported, with the design's argument names: `sc_gamma(z)`,
  `sc_gammaln(x)`, `sc_loggamma(z)`, `sc_rgamma(z)`, `sc_gammasgn(x)`,
  `sc_psi(z)`, `sc_beta(a, b)`, `sc_betaln(a, b)`, `sc_binom(x, y)`,
  `sc_poch(z, m)`, `sc_erf(z)`, `sc_erfc(x)`, `sc_erfcx(x)`, `sc_erfi(z)`,
  `sc_erfcinv(y)`, `sc_dawsn(x)`, `sc_wofz(z)`, `sc_voigt_profile(x, sigma,
  gamma)`, `sc_exp1(z)`, `sc_expi(x)`, `sc_expn(n, x)`. Complex-capable:
  gamma, loggamma, rgamma, psi, erf, erfc, erfcx, erfi, dawsn, wofz, exp1,
  expi.

- [ ] **Step 1: Write the failing tests.** Spot values against base R:
  `sc_gamma(x)` vs `gamma(x)`, `sc_gammaln(x)` vs `lgamma(x)`,
  `sc_beta(a, b)` vs `beta(a, b)`, `sc_psi(x)` vs `digamma(x)`,
  `sc_binom(x, y)` vs `choose(x, y)` for integer `x, y`, tolerance `1e-14`
  relative on ordinary inputs; `sc_erf(x)` vs `2 * pnorm(x * sqrt(2)) - 1`
  at `1e-14`. Semantics, in `test-semantics.R`: `sc_gamma(1+0i)` is complex
  1; `sc_gamma(-1)` warns with class `zuspecial_singular` under
  `sc_errstate(sc_gamma(c(-1, -2)), singular = "warn")`, exactly once, with
  `count == 2` and `first_index == 1`; under `"raise"` it errors with class
  `zuspecial_singular_error`; `sc_wofz(1)` is complex; `sc_erfcinv(1i)` is
  `zuspecial_invalid_argument`; `sc_expn(1.5, 1)` is
  `zuspecial_invalid_argument`; a named vector and a matrix keep their
  names and dim.
- [ ] **Step 2:** Run; expect FAIL.
- [ ] **Step 3:** Implement. Roxygen: one topic per family (`@rdname
  gamma-functions`, `error-functions`, `exponential-integrals`), each
  naming its base R counterparts and SciPy's documentation URL; the error
  state gets its own topic.
- [ ] **Step 4:** `devtools::document()`; all tests pass with
  `devtools::test(shuffle = TRUE)`. Commit: `Export gamma, error and
  exponential-integral functions`.

### Task 5: `zuspecial_info()`

**Files:**

- Create: `R/info.R`, `src/zsp_info.cpp`
- Modify: `tools/vendor/vendor-xsf` (write `src/zsp_xsf_version.h` with
  `#define ZSP_XSF_COMMIT` and `ZSP_SCIPY_TAG`), `src/zuspecial.c`
- Test: `tests/testthat/test-info.R`

**Interfaces:**

- Produces: `zuspecial_info()` → list with `xsf_commit`, `scipy_version`
  (the tag without `v`), `compiler` (from `__VERSION__` or
  `__clang_version__`), and `functions`, a data frame with columns
  `r_name`, `scipy_name`, `backend` (`"xsf"`), `complex` (logical), one row
  per exported `sc_` function. `zsp_functions` in `R/info.R` is that table
  and the single registry other code reads.

- [ ] **Step 1: Write the failing test:** `xsf_commit` is the 40-hex string
  `f7b85f505a94fd398024478d2e747b01dd2d7a6d`; `functions$r_name` equals the
  sorted set of exported `sc_` functions other than the error-state ones
  (`setdiff(grep("^sc_", getNamespaceExports("zuspecial"), value = TRUE),
  c("sc_geterr", "sc_seterr", "sc_errstate"))`).
- [ ] **Step 2:** Run; FAIL. **Step 3:** Implement, re-running
  `tools/vendor/vendor-xsf v1.18.1` to generate the header (no vendored
  file changes; `tools/vendor/verify` still passes).
- [ ] **Step 4:** Pass. Commit: `Add zuspecial_info()`.

### Task 6: Docs, NEWS, roadmap, and the full check

- [ ] `NEWS.md` bullets for the functions and the error state; CLAUDE.md
  Architecture (`R/eval.R` path, `src/zsp_glue.c`), Current state.
- [ ] `devtools::check()` 0/0/0; `tools/check-symbols src` passes;
  roadmap Stage 2 Done date.
- [ ] PR `Stage 2 — Glue, error state, gamma and error functions`,
  `Closes #4`, `full-ci` label; merge on a green full run.

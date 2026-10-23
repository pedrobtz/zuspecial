# zuspecial: roadmap

Status: draft 2026-10-23. Implements [design.md](design.md).
Target: v0.1.0, the first CRAN release.
Tracking: [v0.1.0 (#1)](https://github.com/pedrobtz/zuspecial/issues/1), with
one sub-issue per stage;
[CRAN-submission (#14)](https://github.com/pedrobtz/zuspecial/issues/14).

The stages follow design §13, with two changes. Test oracles (design Stage 5)
move up to Stage 3, so that every function family is checked against xsref
and SciPy as it lands rather than at the end. The Boost.Math backend decision
(§12.1) moves from Stage 0 to Stage 4, because it needs the SciPy-value
tables built in Stage 3.

## Stages

| Stage | Title | CI | Issue | Pull request | Done |
| --- | --- | --- | --- | --- | --- |
| 0 | [Package identity](#stage-0--package-identity) | quick | [#2](https://github.com/pedrobtz/zuspecial/issues/2) | [#16](https://github.com/pedrobtz/zuspecial/pull/16) | 2026-10-23 |
| 1 | [Vendored xsf and the build](#stage-1--vendored-xsf-and-the-build) | full | [#3](https://github.com/pedrobtz/zuspecial/issues/3) | [#17](https://github.com/pedrobtz/zuspecial/pull/17) | 2026-10-23 |
| 2 | [Glue, error state, gamma and error functions](#stage-2--glue-error-state-gamma-and-error-functions) | full | [#4](https://github.com/pedrobtz/zuspecial/issues/4) | | |
| 3 | [Test oracles: xsref and SciPy values](#stage-3--test-oracles-xsref-and-scipy-values) | quick | [#5](https://github.com/pedrobtz/zuspecial/issues/5) | | |
| 4 | [Incomplete gamma and beta, Boost backend, normal functions](#stage-4--incomplete-gamma-and-beta-boost-backend-normal-functions) | quick | [#6](https://github.com/pedrobtz/zuspecial/issues/6) | | |
| 5 | [Bessel, Hankel, spherical Bessel, Airy](#stage-5--bessel-hankel-spherical-bessel-airy) | quick | [#7](https://github.com/pedrobtz/zuspecial/issues/7) | | |
| 6 | [Hypergeometric, elliptic, zeta, Lambert W, Struve](#stage-6--hypergeometric-elliptic-zeta-lambert-w-struve) | quick | [#8](https://github.com/pedrobtz/zuspecial/issues/8) | | |
| 7 | [Independent oracles and mpfr checks](#stage-7--independent-oracles-and-mpfr-checks) | quick | [#9](https://github.com/pedrobtz/zuspecial/issues/9) | | |
| 8 | [The C table and a consumer fixture](#stage-8--the-c-table-and-a-consumer-fixture) | quick | [#10](https://github.com/pedrobtz/zuspecial/issues/10) | | |
| 9 | [Benchmarks and documentation](#stage-9--benchmarks-and-documentation) | quick | [#11](https://github.com/pedrobtz/zuspecial/issues/11) | | |
| 10 | [Full CI](#stage-10--full-ci) | full | [#12](https://github.com/pedrobtz/zuspecial/issues/12) | | |
| 11 | [v0.1.0 readiness](#stage-11--v010-readiness) | full | [#13](https://github.com/pedrobtz/zuspecial/issues/13) | | |

## Stage 0 — Package identity

**Issue.** [#2](https://github.com/pedrobtz/zuspecial/issues/2), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuspecial/issues/1).

**CI.** `quick`.

**Goal.** The package has its real identity and the portfolio's CI, and a
quick pull request run finishes in under five minutes.

**Work.**

- `DESCRIPTION`: real Title, Description and `Authors@R` (`aut`, `cre`,
  `cph`), `Depends: R (>= 4.1)`, `Language: en-GB`, MIT licence kept,
  `Version: 0.0.0.9000`, `URL` and `BugReports`.
- `.Rbuildignore` has every entry the `CLAUDE.md` "Working with skills"
  section lists (done in `pkg-init`; check it).
- `R-CMD-check` caller from r-actions' `examples/`, still calling
  `r-cmd-check.yml@v1`, with `{"os": "windows-latest", "r": "devel"}` added
  to `runners`.
- `coverage` caller pinned to an r-actions commit with the `v1` tag in a
  comment, since it holds a write token.
- `CLAUDE.md` from the template (done in `pkg-init`; update Current state).

**Exit criteria.**

- `DESCRIPTION` has no scaffold placeholder text.
- The `R-CMD-check` caller lists the Windows R-devel runner row.
- `coverage.yaml` pins a commit SHA, not `@v1`.
- The pull request's quick-profile run is green and every check finishes in
  under five minutes.

**Design.** §3 (identity table).

**Deviation (2026-10-23).** The quick profile's package work is well under
five minutes: on [#16](https://github.com/pedrobtz/zuspecial/pull/16)'s
rerun, clang23 took 128 s and the Ubuntu leg's dependencies and check took
54 s. The Ubuntu leg still took 336 s because `r-lib/actions/setup-r`
spent 269 s installing R itself (the first attempt stalled there for 17
minutes and was cancelled), and pkgdown's 693 s was 247 s of `setup-r` plus
427 s of cold-cache dependency installs. Neither is something `quick-step`
or `quick-containers` can tune. Merged on green; Stage 1 re-times the quick
profile and, if `setup-r` is still the bottleneck, raises it upstream.

## Stage 1 — Vendored xsf and the build

**Issue.** [#3](https://github.com/pedrobtz/zuspecial/issues/3), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuspecial/issues/1).

**CI.** `full — first compiled C++ and a vendored library: sanitizers,
valgrind, rchk and every platform leg`.

**Goal.** xsf is vendored reproducibly, compiles on every CI leg under
CRAN's flags, and links no forbidden symbol; one kernel is callable from R
to prove the C-to-C++ path.

**Work.**

- `tools/vendor-xsf`: takes the xsf commit from a SciPy release's
  `subprojects/xsf` gitlink, copies `include/xsf/**` without `numpy.h` and
  `third_party/` into `src/xsf/`, and writes SciPy's commit, xsf's commit
  and each file's SHA-256 to `src/xsf/VERSION`.
- A verify script that checks the tree against `VERSION`.
- `src/Makevars` and `src/Makevars.win`: `CXX_STD = CXX17`,
  `-DSP_SPECFUN_ERROR`, hidden visibility, `R_init_zuspecial` the only
  export.
- A first shim translation unit (gamma family) with an `extern "C"`,
  `noexcept` entry for `gamma`, and a minimal `xsf::set_error`
  (thread-local accumulator, §6.4), called from a C routine. Not exported
  to users yet.
- `inst/COPYRIGHTS` and `DESCRIPTION` `Copyright:` covering every bundled
  licence in §12.2.
- §12.2's specfun question decided and recorded in design.md: whether
  "permission granted to use code in programs" is acceptable for CRAN. If
  not, `hyperu` and complex `hyp1f1` move to After 0.1.0 and the `msta1`
  and `msta2` helpers get a replacement patch.
- The vendor workflow (`vendor.yml`) and native-checks workflow from
  r-actions, plus an `nm -u` check that fails on stdio, `abort`, `exit`
  and system RNG symbols.
- Compile time per CI leg recorded in this roadmap.

**Exit criteria.**

- `tools/vendor/manifest.tsv` names the SciPy release and xsf commit, and
  `tools/vendor/verify` passes in CI.
- The full-profile r-actions run is green on the pull request, including
  sanitizers, valgrind and rchk.
- The `nm -u` check passes on every leg.
- design.md records the specfun licence decision.
- The quick profile still finishes in under five minutes.

**Design.** §4, §8, §12.2, §12.3.

**Deviation (2026-10-23).** The tree is vendored to
`src/vendor/xsf/include/xsf/`, with the manifest and checksums in
`tools/vendor/`, instead of `src/xsf/` and `src/xsf/VERSION`: xsf's includes
are `"xsf/..."`, and r-actions' `vendor.yml` and the portfolio template
expect `src/vendor/` and `tools/vendor/`. The build adds `-DNDEBUG` for a
bare `assert` in `specfun.h`. Recorded in design §8.

## Stage 2 — Glue, error state, gamma and error functions

**Issue.** [#4](https://github.com/pedrobtz/zuspecial/issues/4), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuspecial/issues/1).

**CI.** `full — the C glue every later family reuses (PROTECT, attribute
transfer, condition signalling): gctorture and valgrind`.

**Goal.** The R and C layers that every function goes through are built and
tested, on the gamma, beta and error-function families.

**Work.**

- R layer: argument checks, recycling (length one or the common length,
  else `zuspecial_recycle_error`), integer and logical to double,
  real-or-complex dispatch with no promotion, attribute transfer (§6.1,
  §6.2).
- C glue, one loop per signature: `NA` handled before the kernel, complex
  `NA` when either part is `NA`, the `{double re, im}` conversion (§6.3,
  §4).
- Error state: `sc_geterr()`, `sc_seterr()`, `sc_errstate()`, stored as
  §16 question 5 decides; once-per-call signalling with count and first
  index; the condition classes of §9.
- Exported: `sc_gamma`, `sc_gammaln`, `sc_loggamma`, `sc_rgamma`,
  `sc_gammasgn`, `sc_psi`, `sc_beta`, `sc_betaln`, `sc_binom`, `sc_poch`,
  `sc_erf`, `sc_erfc`, `sc_erfcx`, `sc_erfi`, `sc_erfcinv`, `sc_dawsn`,
  `sc_wofz`, `sc_voigt_profile`, `sc_exp1`, `sc_expi`, `sc_expn`, with
  complex paths where §2 marks them.
- `zuspecial_info()` with the xsf commit, compiler and the function table.
- Semantics tests (§10): recycling, attributes, `NA` against `NaN`,
  dispatch, error actions, `sc_errstate()` restoring after an error.

**Exit criteria.**

- `devtools::test(shuffle = TRUE)` passes, including every semantics test
  listed above.
- Every error is asserted by condition class.
- The full-profile run is green on the pull request, including gctorture.
- Spot values for each exported function match base R where base R has the
  function (`gamma()`, `lgamma()`, `beta()`, `digamma()`, `choose()`).

**Design.** §5, §6, §9; §2 (gamma, beta, error, exponential integrals).

## Stage 3 — Test oracles: xsref and SciPy values

**Issue.** [#5](https://github.com/pedrobtz/zuspecial/issues/5), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuspecial/issues/1).

**CI.** `quick`.

**Goal.** The reference tables exist in a form R tests can read, and Stage
2's functions pass them under xsf's tolerance rule.

**Work.**

- `tools/xsref-extract`: reads the xsref Parquet tables at the pinned
  revision (settling `nanoparquet` against `arrow`) and writes compact
  binary files; `fallback` rows counted separately.
- A sample capped at 2 MB in `tests/testthat/`, and a CI job that fetches
  xsref at the pin and runs the full set.
- `tools/scipy-values.py`: runs the pinned SciPy on the xsref inputs plus
  random inputs per function and writes the values with SciPy's version.
- A helper implementing `4 * max(eps, recorded)` with the platform mapping
  of §10 (Rtools GCC to `other`).
- `zuspecial_info()` reports the xsref commit.

**Exit criteria.**

- The shipped sample is at most 2 MB.
- Every Stage 2 function passes its xsref cases and its SciPy-value table
  on the quick profile.
- The full-xsref CI job is green.
- The test suite stays under 15 s locally.

**Design.** §10.

## Stage 4 — Incomplete gamma and beta, Boost backend, normal functions

**Issue.** [#6](https://github.com/pedrobtz/zuspecial/issues/6), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuspecial/issues/1).

**CI.** `quick`.

**Goal.** The functions statistics code depends on are in, including the
ones SciPy evaluates with Boost.Math.

**Work.**

- `LinkingTo: BH`, or vendored Boost.Math at SciPy's pin, decided by
  comparing SciPy-value tables on every CI leg (§12.1, §16 question 4);
  the outcome recorded in design.md.
- A Boost shim unit porting SciPy's `boost_special_functions.h` wrappers:
  same policy, same special-casing, exceptions caught into sf_error codes.
- Exported: `sc_gammainc`, `sc_gammaincc`, `sc_gammaincinv`,
  `sc_gammainccinv`, `sc_betainc`, `sc_betaincc`, `sc_betaincinv`,
  `sc_betainccinv`, `sc_erfinv`, `sc_ndtr`, `sc_log_ndtr`, `sc_ndtri`,
  `sc_ndtri_exp`, `sc_owens_t`.
- `zuspecial_info()` reports the Boost version and each function's backend.

**Exit criteria.**

- Each function passes its xsref cases (where they exist) and its
  SciPy-value table on the quick profile.
- design.md records the §12.1 decision.
- A test shows a Boost exception surfacing as the matching sf_error code,
  not as a crash.

**Design.** §2 (incomplete gamma and beta, normal), §12.1.

## Stage 5 — Bessel, Hankel, spherical Bessel, Airy

**Issue.** [#7](https://github.com/pedrobtz/zuspecial/issues/7), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuspecial/issues/1).

**CI.** `quick`.

**Goal.** The Bessel families are in, real and complex, with SciPy's
argument order.

**Work.**

- Exported: `sc_jv`, `sc_yv`, `sc_iv`, `sc_kv` and their `e` forms;
  `sc_hankel1`, `sc_hankel2`, `sc_hankel1e`, `sc_hankel2e`; the fixed-order
  `j0` … `k1e`; `sc_spherical_jn`, `sc_spherical_yn`, `sc_spherical_in`,
  `sc_spherical_kn` with `derivative = FALSE`; `sc_airy`, `sc_airye`.
- Multi-output results shaped as §16 question 6 decides.
- Integer-order arguments refused unless whole and in `int` range.

**Exit criteria.**

- Each function passes its xsref cases and SciPy-value table on the quick
  profile.
- `sc_jv(0.5, -1)` is `NaN` and `sc_jv(0.5, -1+0i)` is complex, in a test.
- Real-input results agree with base `besselJ()` and siblings in a test.

**Design.** §2 (Bessel, spherical Bessel, Airy), §6.2.

## Stage 6 — Hypergeometric, elliptic, zeta, Lambert W, Struve

**Issue.** [#8](https://github.com/pedrobtz/zuspecial/issues/8), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuspecial/issues/1).

**CI.** `quick`.

**Goal.** The rest of the v0.1.0 function list is in.

**Work.**

- Exported: `sc_hyp0f1`, `sc_hyp1f1` (real path through the Boost backend),
  `sc_hyp2f1`, `sc_hyperu`; `sc_ellipk`, `sc_ellipkm1`, `sc_ellipkinc`,
  `sc_ellipe`, `sc_ellipeinc`, `sc_ellipj`; `sc_zeta(x, q = NULL)`,
  `sc_zetac`, `sc_lambertw`, `sc_wrightomega`, `sc_spence`; `sc_struve`,
  `sc_modstruve`.
- The Carlson integrals are not in this stage: the SciPy 1.18.1 pin's xsf
  predates them (2026-10-23, design D12).

**Exit criteria.**

- Each function passes its xsref cases and SciPy-value table on the quick
  profile.
- `zuspecial_info()`'s function table lists every function in design §2's
  v0.1.0 list, less the Carlson integrals (design D12).

**Design.** §2 (hypergeometric, elliptic, zeta, Struve).

## Stage 7 — Independent oracles and mpfr checks

**Issue.** [#9](https://github.com/pedrobtz/zuspecial/issues/9), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuspecial/issues/1).

**CI.** `quick`.

**Goal.** Results are compared with libraries that use different
algorithms, and disagreements are explained.

**Work.**

- Suggests-guarded comparisons against `gsl`, `Bessel`, `hypergeo`,
  `lamW`, `expint`, and base `pgamma()`/`qgamma()`, `pbeta()`/`qbeta()`,
  `pnorm()`/`qnorm()`.
- `Rmpfr` spot checks at 200 bits near zeros, poles, branch cuts and
  overflow thresholds, skipped when `Rmpfr` is absent.
- A written note for each disagreement, kept in the tests or in design.md.

**Exit criteria.**

- Every comparison passes or carries a written explanation.
- The suite passes with every Suggests package absent (`skip_if_not_installed`
  on each).

**Design.** §10 (independent oracles, mpfr); §14 criterion 3.

## Stage 8 — The C table and a consumer fixture

**Issue.** [#10](https://github.com/pedrobtz/zuspecial/issues/10), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuspecial/issues/1).

**CI.** `quick`.

**Goal.** Other packages can call zuspecial's functions from C.

**Work.**

- `inst/include/zuspecial.h` with `zuspecial_complex` and `zuspecial_api`,
  registered as `zuspecial_api_v1` with `R_RegisterCCallable`.
- A fixture package under `tests/` that `LinkingTo`s zuspecial and calls a
  real member, a complex member and reads the error code.

**Exit criteria.**

- The header compiles standalone, with no xsf or Boost include.
- The fixture package builds and its tests pass in CI.

**Design.** §7; §14 criterion 4.

## Stage 9 — Benchmarks and documentation

**Issue.** [#11](https://github.com/pedrobtz/zuspecial/issues/11), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuspecial/issues/1).

**CI.** `quick`.

**Goal.** Performance is measured against the design's targets, and the
package is documented for users.

**Work.**

- `tools/run-benchmarks` and its results recorded in design.md §11.
- Roxygen for every exported function, naming its base R and `gsl`
  counterparts and SciPy's branch cuts (§6.5).
- `README.Rmd` (with `pkg-readme`), a pkgdown reference index grouped by
  family, and an article on translating from `scipy.special`.

**Exit criteria.**

- design.md §11 records measured numbers, with any missed target reported.
- `devtools::check()` has no documentation warnings.
- The pkgdown site builds in CI.

**Design.** §11, §6.5.

## Stage 10 — Full CI

**Issue.** [#12](https://github.com/pedrobtz/zuspecial/issues/12), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuspecial/issues/1).

**CI.** `full`.

**Goal.** No new features. The full r-actions profile runs on the default
branch's code and everything it finds is fixed.

**Work.**

- Run with the `full-ci` label: gctorture at the sensitive step, valgrind,
  ASan, every platform leg including Windows R-devel, `nosuggests`, `nold`,
  cran-special.
- Fix every failure, including those recorded on this issue by earlier
  merges.

**Exit criteria.**

- A full-profile run is green on the pull request and on the merge commit.

**Design.** §14 criterion 1.

## Stage 11 — v0.1.0 readiness

**Issue.** [#13](https://github.com/pedrobtz/zuspecial/issues/13), sub-issue of
[v0.1.0](https://github.com/pedrobtz/zuspecial/issues/1).

**CI.** `full`.

**Goal.** Only the submission itself is left.

**Work.**

- `Version: 0.1.0` and the matching `NEWS.md` heading.
- `cran-comments.md` listing the r-actions CI legs as test environments.
- `pkg-critical-review` run, blocking and required findings fixed; then
  `pkg-cran-review` run, every finding resolved.
- `urlchecker::url_check()` and `spelling::spell_check_package()` clean.

**Exit criteria.**

- A full-profile r-actions run is green on the release commit.
- `urlchecker::url_check()` and `spelling::spell_check_package()` report
  nothing.
- Every `pkg-cran-review` finding is resolved.

**Design.** §14.

## After 0.1.0

- The remaining xsf kernels SciPy exposes (Kelvin, Mathieu, spheroidal,
  parabolic cylinder, Fresnel, Bessel and Struve integrals,
  `wright_bessel`, Legendre, the `eval_*` polynomials, `agm`,
  `besselpoly`, degree trigonometric functions, `xlogy` and siblings,
  information-theory helpers): design §2 "Later, when asked".
- The other Boost.Math functions SciPy uses (`log_gammainc`, `powm1`, the
  `*dtr*` inverses).
- Derivatives through xsf's `dual` type.
- Parallel evaluation of long vectors.
- The Carlson elliptic integrals (`sc_elliprc`, `sc_elliprd`, `sc_elliprf`,
  `sc_elliprg`, `sc_elliprj`), with the re-vendor for the first SciPy
  release whose xsf has them. Moved here 2026-10-23 when the pin was set to
  SciPy 1.18.1 (design D12).

## Open questions

- **§16 question 4, `BH` or vendored Boost.Math.** Decided in Stage 4 from
  the tables.

Resolved 2026-10-23 (design §15): the `sc_` prefix (D14), the xsf pin
follows SciPy releases (D12), error state in R options (D15), multi-output
results as named lists (D16), the specfun licence accepted (D13), and the
name `zuspecial`.

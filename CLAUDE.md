# CLAUDE.md

<!-- markdownlint-disable-next-line MD013 -->
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

zuspecial gives R `scipy.special`'s special functions, for real and complex
arguments, under SciPy's names (`sc_` plus the SciPy name) and argument order.
It wraps xsf, the header-only C++17 library SciPy split out of
`scipy.special`, vendored at the commit SciPy pins, plus the six Boost.Math
functions SciPy evaluates with Boost instead (`LinkingTo: BH`). Users are
people who need Python and R to agree to the last digit, people who need
complex Bessel or hypergeometric functions, and package authors who call
special functions from C through a registered C table. It has zero hard
runtime dependencies. It does not do arbitrary precision, d/p/q/r
distribution families, single precision or GPU execution.

The specification is [`.agents/design.md`](.agents/design.md), adopted from
[RFC 0027](https://github.com/pedrobtz/packages/blob/main/rfcs/started/0027-zuspecial-special-functions.md).
It outranks this file: `CLAUDE.md` orients, the design doc decides. Its open
questions (§16) and the Stage 0 decisions on the Boost backend (§12.1) and
licences (§12.2) are still open.

## Current state

Scaffolded 2026-10-23 with `create-pkg.sh`; package identity and CI set up
in Stage 0 (2026-10-23). Stage 2 (2026-10-24) added the R and C glue, the
error state, and 21 gamma, error and exponential-integral functions; Stage 3
the xsref and SciPy oracles; Stage 4 the incomplete gamma and beta, normal
and Boost-backed functions; Stage 5 the Bessel, Hankel, spherical Bessel and
Airy functions; Stage 6 the hypergeometric, elliptic, zeta, Lambert W,
Wright omega, Spence and Struve functions (82 in all); Stage 7 the
independent package and `Rmpfr` oracles; Stage 8 the C table
`zuspecial_api_v1`; Stage 9 the benchmarks (design §11), the README, the
pkgdown reference index and the article `vignettes/articles/scipy.Rmd`
(a pkgdown article, not an installed vignette). The
roadmap in `.agents/roadmap.md` takes it to v0.1.0, tracked in
[#1](https://github.com/pedrobtz/zuspecial/issues/1).

## Stage tracking

Progress toward the next version is tracked as GitHub sub-issues, so the
parent issue shows a progress bar such as "6 of 7".

- **One parent issue per target version**, titled with the bare version, for
  example `v0.1.0`. `v0.1.0` issue: created by `pkg-roadmap`.
- **One sub-issue per roadmap stage**, titled as the roadmap titles it, for
  example `Stage 3 — R interface`, and linking to that section. The number of
  stages is whatever the roadmap has; there is no fixed scale.
- **Every tracking issue carries the `stage` label**, so it can be told apart
  from bug and feature issues and left out of open-issue counts.
- **Close a stage by merging its pull request.** Put `Closes #<n>` in the
  body of the stage's pull request. Never close a stage whose exit criteria
  are not met; record a deviation in the roadmap first.
- **The roadmap stays authoritative.** The issues record which stages are
  done, not what a stage requires. Adding, removing or renaming a stage
  means editing the roadmap and the sub-issues in the same change.
- **Each stage has a CI tier, `quick` or `full`.** The roadmap sets it, and
  `quick` is the default. See Continuous integration for what each means.
  The second-to-last stage, `Full CI`, runs the full set and fixes what it
  finds before `v0.1.0 readiness`.
- Close the parent issue when CRAN accepts the version and it is tagged.
  Opening a parent issue implies at least one stage sub-issue; a parent with
  no sub-issues shows no progress on the board.

## Versioning

A new package develops at `0.0.0.9000` and targets `0.1.0` for its first CRAN
release. Set `Version: 0.1.0` and the matching `NEWS.md` heading when the
package enters `Pre-flight`. Bump to `0.1.0.9000` only after CRAN accepts it,
never before: a `.9000` version above an unreleased `0.1.0` heading is wrong.

Until the first release the R API may change freely. Sibling packages can
still depend on this one before CRAN does, through `Remotes:` or `LinkingTo:`.
None does yet. The intended first consumer of the C table is a family
distributions package that has no RFC yet. A package that others wait on
should reach CRAN first.

## Commands

Run from the package root.

```sh
Rscript -e 'devtools::load_all()'                # compile src/ and load
Rscript -e 'devtools::document()'                # roxygen -> NAMESPACE, man/
Rscript -e 'devtools::test()'                    # full testthat suite
Rscript -e 'devtools::test(filter = "<name>")'   # one test file
Rscript -e 'devtools::test(shuffle = TRUE)'      # order independence
Rscript -e 'devtools::check()'                   # R CMD check
air format .                                     # format R sources
```

Occasional, for vendoring and the native build:

```sh
tools/vendor/vendor-xsf v1.18.1   # re-vendor xsf at a SciPy release's pin
tools/vendor/verify               # vendored tree matches the checksums
R CMD INSTALL . && tools/check-symbols src   # forbidden imports, shim state
```

Regenerating the test tables, after a function is added or the pin moves
(xsref sparse-checked out at the commit in `tools/vendor/manifest.tsv`):

```sh
tools/xsref-extract --source <xsref>/tables/scipy_special_tests --kind xsref \
  --commit <xsref-commit> --out tests/testthat/xsref
uv run --no-project --python 3.12 --with scipy==1.18.1 --with pyarrow \
  python tools/scipy-values.py --xsref <xsref>/tables/scipy_special_tests \
  --functions tools/xsref/functions.tsv --random 0 --out <tmp>
tools/xsref-extract --source <tmp> --kind scipy --cap 0 --out tests/testthat/scipy
```

`devtools::load_all()` builds with `-UNDEBUG`, so run `tools/check-symbols`
on objects from `R CMD INSTALL`, never from `load_all()`.

## Architecture

The full picture is `.agents/design.md` §4. Every exported function is one
line over [R/eval.R](R/eval.R)'s `zsp_eval()`, which runs:

1. [R/args.R](R/args.R) `zsp_prep()`: type checks, recycling, coercion,
   real-or-complex choice, and the template whose attributes the result
   takes.
2. [src/zsp_glue.c](src/zsp_glue.c): one `.Call` loop per signature
   (`zsp_call_d`, `_c`, `_dd`, `_ddd`, `_id`, `_dc`, `_ic`, and `_d4`,
   `_c4` for four outputs), which looks the kernel up by SciPy name, sets
   `NA` without calling it, and attaches the error report as attribute
   `zsp_err`. `zsp_eval()` names the signature from the argument types
   (`i` whole, `c` complex, `d` double) and the output count.
3. [R/conditions.R](R/conditions.R) `zsp_signal_report()`: one condition per
   raised code, under the action [R/errstate.R](R/errstate.R) keeps in the
   `zuspecial.errstate` option.

The C++ side:

- [src/zsp_shim.h](src/zsp_shim.h): the C/C++ boundary. Plain C types only;
  every function is `extern "C"` and `noexcept`.
- [src/zsp_shim.cpp](src/zsp_shim.cpp): the only translation unit that
  includes xsf kernels. It includes one `src/zsp_shim_<family>.h` per
  family, which must never be included anywhere else.
- [src/zsp_wright.h](src/zsp_wright.h), and in
  [src/zsp_shim_hyper.h](src/zsp_shim_hyper.h) `hyp0f1`, `hyperu`, complex
  `spence`: code ported from SciPy where xsf lacks it, with NumPy's complex
  `csqrt`/`cpow` from [src/zsp_ccomplex.c](src/zsp_ccomplex.c) where the
  original used them. Keep ports line for line; parity depends on it.
- [inst/include/zuspecial.h](inst/include/zuspecial.h) and
  [src/zsp_api.c](src/zsp_api.c): the public C table `zuspecial_api_v1`,
  registered in `R_init_zuspecial`; `tests/testthat/fixtures/zsconsumer` is a
  consumer package the tests build.
- [src/zsp_boost.cpp](src/zsp_boost.cpp): the six functions SciPy
  evaluates with Boost.Math (`LinkingTo: BH`), ported from SciPy's
  `boost_special_functions.h`. A unit of its own: it includes no xsf
  kernels, only `xsf/error.h`.
- [src/zsp_error.cpp](src/zsp_error.cpp): defines `xsf::set_error`
  (declared because the build sets `SP_SPECFUN_ERROR`) and `zsp_err_take()`.
  It holds the only mutable state: a thread-local bitmask, bit `1 << code`
  per `sf_error_t`.
- `src/vendor/xsf/include/`: the include root (`-Ivendor/xsf/include` in
  `src/Makevars`), since xsf includes itself as `"xsf/..."`.

Adding a function means a shim entry in its family header, a row in the
glue's table for its signature, an `sc_` wrapper, a row in
[R/info.R](R/info.R)'s `zsp_functions`, and a row in
`tools/xsref/functions.tsv` with regenerated test tables.

## Invariants that are easy to break

These come from the design and from Stages 1 and 2, and all are now in code.

- **No C++ crosses into C or R.** The shim is `extern "C"` and `noexcept`,
  catches Boost.Math exceptions into sf_error codes, and never calls R's API.
  An R error raised under a C++ frame longjmps past destructors.
- **`std::complex<double>` and `Rcomplex` never alias.** The shim converts
  through a `{double re, im}` struct, member by member.
- **`NA` is decided in the C glue, before any kernel runs.** xsf does not
  promise to keep R's `NA` payload, so `NA` and `NaN` would blur.
- **`xsf::set_error` only records.** It writes a thread-local accumulator and
  never signals, allocates or calls R. Conditions are signalled once per
  call, after the loop, under the R function's name.
- **The C table is append-only.** `struct_size` is the only version
  discriminator. Never reorder or remove members. A layout change in
  `zuspecial_complex` bumps the registered name `zuspecial_api_v1`.
  Consumers include only `inst/include/zuspecial.h`, never xsf or Boost.
- **Only `src/zsp_shim.cpp` includes xsf kernel headers.** xsf defines
  non-inline functions in headers (`cephes::chbevl`, the `erfcx` in
  `faddeeva.h`, ...), as SciPy builds it in one unit. A second translation
  unit that includes them fails to link with duplicate symbols.
- **`src/Makevars` and `src/Makevars.win` keep `-DNDEBUG`.** Without it the
  bare `assert` in xsf's `specfun/specfun.h` links `abort`, which CRAN's
  compiled-code check rejects. `tools/check-symbols` catches it.
- **The C table is append-only, and its header is plain C99.** Never
  reorder or remove a member of `zuspecial_api`; append, and
  `struct_size` tells consumers. A layout change in `zuspecial_complex`
  means a new registered name (`zuspecial_api_v2`). The header includes no
  xsf, Boost or C++; `test-c-api.R` compiles it under `-std=c99 -pedantic`.
- **No automatic complex promotion.** Real input stays on the real path, so
  `sc_jv(0.5, -1)` is `NaN`, as in SciPy.

## Testing conventions

- **Self-sufficient.** Every test builds its own inputs inside the
  `test_that()` block. No file-scope objects.
- **Self-contained.** Global state goes through `withr::local_*()`, randomised
  input through `withr::local_seed()`. Tests write only under `tempdir()`.
- **Assert on condition classes, never message text.** Use
  `expect_error(..., class = "<pkg>_<kind>_error")`. Wording belongs in
  snapshot tests.
- **Order independence.** `devtools::test(shuffle = TRUE)` is part of the
  definition of done.
- **Borrow a conformance suite before writing one.** Mainstream
  implementations in Python, Java, Go or Node usually ship a test corpus.
  Use it as an oracle rather than inventing cases by hand. zuspecial's is
  xsref: mpmath reference values, checked under xsf's `4 * max(eps,
  recorded)` rule against the `Err_` table for this platform. A second
  oracle is SciPy 1.18.1 itself: the shipped tables (xsref inputs, made on
  macOS x86_64) allow the sum of both platforms' xsref tolerances, and CI
  runs SciPy on each OS and requires 64 ulps on xsref and seeded random
  inputs. Both live as `.rds` samples in
  `tests/testthat/xsref/` and `tests/testthat/scipy/`, listed in
  `tools/xsref/functions.tsv`; the full xsref set runs in `xsref.yaml`.
  On Windows only, rows in `tests/testthat/known-windows.tsv.gz` are
  excused: Rtools' mingw-w64 v11 `sin`/`cos` are wrong for large arguments
  (design §10). Regenerate it with `tools/known-windows` from the
  workflow's Windows `oracle-report` artifact, never by hand; the script
  refuses any failing row without an argument of at least 1e5.
  xsref has no tables for the Boost-backed functions (Stage 4), which only
  the SciPy tables cover.
- **Independent oracles are Suggests**: `gsl`, `Bessel`, `hypergeo`,
  `lamW`, `expint` (`test-oracle-packages.R`) and `Rmpfr` (`test-mpfr.R`),
  each behind `skip_if_not_installed()`. A disagreement is explained in the
  test, never silenced by a looser tolerance.
- **Helpers live in `tests/testthat/helper-*.R`.**
  [helper-oracle.R](tests/testthat/helper-oracle.R) ports xsf's
  `extended_relative_error` (`xsf_rel_err()`), its tolerance
  (`xsf_tol()`) and its platform choice (`xsf_platform()`). Change them
  only to follow xsf.
- **Keep the suite inside the CRAN time budget.** About 5 s locally with
  every Suggests installed (2026-10-24); the design's limit is 15 s.

## Definition of done

`devtools::document()` and `devtools::check()` clean, meaning 0 errors, 0
warnings and 0 notes. The one allowed note is "New submission" before the first
release. `devtools::test(shuffle = TRUE)` green. CI green at the change's
tier: the quick profile for a `quick` roadmap stage or an ordinary pull
request, the full profile for a `full` stage, `Full CI`, and every release.
A user-facing change also needs a test, roxygen documentation and a `NEWS.md`
entry.

## Releasing to CRAN

- **CI is the pre-submission check.** The `pedrobtz/r-actions` R CMD check runs
  `--as-cran` on the CRAN-like runners and containers, and it replaces
  win-builder, the macOS builder and R-hub. None of them is a release step,
  and `cran-comments.md` lists the CI legs as its test environments.
- **Entering `Pre-flight`.** The roadmap's feature stages are done, the
  version is set as in Versioning, `NEWS.md` and `cran-comments.md` are
  written, and CI is green. Only submission work remains.
- **Before submitting,** run `pkg-critical-review` once the roadmap is
  implemented and fix what it files, then `pkg-cran-review`, and resolve
  every finding. Both skills are in `pedrobtz/r-skills`.
- **The pretest is automated and does not read `cran-comments.md`.** A NOTE
  that is explained but not fixed gets the upload archived. Fix the NOTE, as
  under Vendored native code, instead of justifying it.
- **After acceptance,** `pkg-post-cran` tags the submitted commit with the
  bare version, `0.1.0` (no `v`), publishes the GitHub release, bumps to
  `0.1.0.9000`, closes the version's parent issue and moves the board card.

## Editing rules

- roxygen comments are the source. Never edit `man/` or `NAMESPACE` by hand.
- Edit `README.Rmd`, not the generated `README.md`.
- Keep prose simple and short. One idea per sentence.
- Wrap roxygen text at 80 characters and run `air format .` on R sources.
- Use `lower_snake_case`, and prefix internal native symbols with `<pkg>_`.
- Keep hard runtime dependencies at zero unless a recorded design decision
  says otherwise.
- Export and document public functions. Do not create roxygen topics for
  internal ones.

## Continuous integration

Workflows come from `pedrobtz/r-actions`. Call those reusable workflows instead
of writing bespoke ones, and pin a released tag rather than `main`. Pin a
workflow that holds a write token, such as `coverage.yml`, to a commit, with
the tag in a comment. The `R-CMD-check` workflow must call `r-cmd-check.yml`,
because a hand-rolled one does not count as the pre-submission check. This
package calls `r-cmd-check.yml` (from `R-CMD-check.yaml`) and `coverage.yml`
(from `coverage.yaml`); `pkgdown.yaml` builds the site with `r-lib/actions`.

Small edits get a small run. The shared workflows look at the files a pull
request changes, compared with its merge base:

- **Markdown only**, such as `README.md`, `NEWS.md` or `cran-comments.md`,
  skips every check. Only coverage and the pkgdown site run.
- **`DESCRIPTION` or `README.Rmd` as well**, and nothing else, adds one R CMD
  check on Ubuntu R-release.
- **Any other file** runs everything.

So put a README or `DESCRIPTION` touch-up in its own pull request. Once a pull
request changes code, every later push to it runs every workflow.

### Quick by default, full by exception

The full profile is slow. gctorture at step 20 alone has taken 36 to 107
minutes on sibling packages. Waiting on it between roadmap stages was the
main thing slowing roadmaps down, so:

- **Pull requests run the quick profile.** It should finish in under five
  minutes. If it doesn't, raise gctorture's `quick-step` or trim
  `quick-containers` in the caller workflows; never cut the full profile.
- **A `full` roadmap stage takes the `full-ci` label** and merges only on a
  green full run. The roadmap gives the reason in the stage's `**CI.**`
  line, for example first compiled code, a `PROTECT` or finalizer change, a
  vendored library, or a Windows-only path.
- **Don't wait on the full run a merge starts** on the default branch, and
  cancel older full runs it supersedes. A failure that only the full set
  shows goes on the `Full CI` stage issue as a comment with the run link,
  and is fixed there. A failure the quick profile also shows is fixed now.
- **`Full CI` and `v0.1.0 readiness` wait** for a green full run on their
  merge commit, and the release commit always needs one.
- Locally, run `gctorture(TRUE)` on the code a C change touches when it is
  cheap; the full run is the authority.

## Vendored native code

xsf (BSD-3-Clause, with bundled Cephes, Faddeeva, qd, AMOS and specfun
code; `inst/COPYRIGHTS` lists every notice) is vendored in
`src/vendor/xsf/` at `f7b85f5`, the commit SciPy v1.18.1's `subprojects/xsf`
gitlink names, without `numpy.h` and `third_party/`. The pin follows SciPy
releases, not xsf tags (design D12), so this one exception to "pin a stable
upstream release" is deliberate: the release pinned is SciPy's.
`tools/vendor/manifest.tsv` and `tools/vendor/checksums.sha256` record it,
`src/vendor/PROVENANCE` gives the update procedure, and
`vendor-upstream.yml` opens an issue when SciPy releases. Local patches live
in `tools/patches/`, which `tools/vendor/vendor-xsf` applies in order; each
is listed in `src/vendor/PROVENANCE` with its reason. There is one: `0001`
guards float-to-int conversions UBSan flags (2026-10-24). The build also
defines `NDEBUG`, because of a bare `assert` in `specfun/specfun.h`.

- Pin a stable upstream release, never `master` or a release candidate.
- Record the tag, the commit and the checksums, and write down the update
  procedure so the next bump is mechanical.
- Keep upstream `LICENSE` and `NOTICE` under `src/vendor/<lib>/`, declare the
  vendored code in `DESCRIPTION` and `inst/COPYRIGHTS`.
- Keep the vendor tree clearly separated from first-party source, and record
  every local patch and why it exists.
- **CRAN's compiled-code check applies to vendored code too.** No `stdout` or
  `stderr`, no `printf`, `abort`, `exit` or system RNG may be linked, even
  behind a debug switch that never runs. Remove them with a patch in
  `tools/patches/`, list it in `src/vendor/PROVENANCE`, and make the
  vendor-verify script check "upstream plus exactly these patches". Avoid
  diagnostic-suppressing pragmas too, because they draw their own NOTE. zuhtml
  is the reference: `tools/patches/0002-no-stdio.patch` and
  `tools/verify-vendor`. zuxml's first upload was archived because it
  justified such a symbol instead of patching it.
- Guard against regressions in CI: run `nm -u` on the built objects and fail
  on any of those symbols, so an upstream bump cannot bring them back.

## Commits and pull requests

Short, imperative, sentence-case commit subjects, optionally scoped. Keep each
commit focused and do not sweep in unrelated files. A pull request explains the
user-visible outcome and the rationale, links related issues, lists the checks
that were run and the tests that were skipped, and flags platform-sensitive or
vendored changes. Performance claims need evidence.

Never commit or push to the default branch. Work on a branch, open a pull
request, and leave it for review. Do not merge a pull request unless you are
told to.

When you find a defect, in this package or in an upstream tool, open an issue
for it rather than only working around it.

## Working with skills

The portfolio's workflow skills live in `pedrobtz/r-skills` (`pkg-init`,
`pkg-roadmap`, `pkg-implement`, `pkg-critical-review`, `pkg-cran-review`,
`pkg-post-cran`, `pkg-readme`); the general process skills are
[Superpowers](https://github.com/obra/superpowers). `building-a-package.md`
in `pedrobtz/packages` walks through them in order. Both sets defer to this
file where they overlap, so the settlements are recorded here.

- **One design.** The specification is `.agents/design.md`, adopted from the
  package's RFC in `pedrobtz/packages/rfcs`. A package with an adopted design
  is past `brainstorming`; a design change goes through the RFC, not a new
  spec. Superpowers' default `docs/superpowers/specs/` is not used.
- **Plans at two levels.** `.agents/roadmap.md` holds the stages, one
  mergeable pull request each, with exit criteria and a CI tier
  (`pkg-roadmap`). Inside a stage, `writing-plans` breaks the work into
  tasks of one test cycle each, saved as `.agents/plans/stage-<n>.md`. The
  roadmap stays authoritative; a plan is scratch and is not kept in sync.
- **Build and merge.** `pkg-implement` runs the stage loop: branch
  `stage-<n>-<slug>` from the stage issue, implement the plan with
  `test-driven-development` (`Rscript -e 'devtools::test(filter = "<name>")'`
  is the red/green command), open the pull request, merge on green at the
  stage's CI tier. The confirmation the user gives at the start of that
  loop is the "told to merge" that Commits and pull requests requires, so
  the `finishing-a-development-branch` menu is not presented for stage
  pull requests. Any other pull request still waits for review.
- **Failures and claims.** A failing check or test goes through
  `systematic-debugging` before a fix. "Green", "done" and "ready for CRAN"
  are claimed only after `verification-before-completion`: run the command,
  read the output.
- **Review.** `requesting-code-review` gates tasks inside a stage.
  `pkg-critical-review` reviews the whole package once the roadmap is
  implemented, with Posit's reviewers, and files issues. CRAN's reviewer
  email and GitHub review threads go through `receiving-code-review`.
- **Keep scratch out of the tarball.** `R CMD build` reads `.Rbuildignore`,
  not `.gitignore`. It must list `^\.agents$`, `^\.superpowers$` (the
  Superpowers task ledger), `^\.worktrees$` (if git worktrees are kept in
  the package directory; a sibling directory avoids the question),
  `^\.claude$`, `^CLAUDE\.md$`, `^AGENTS\.md$`, `^CRAN-SUBMISSION$` and
  `^cran-comments\.md$`. A stray top-level file is a NOTE, and the pretest
  archives on NOTEs.

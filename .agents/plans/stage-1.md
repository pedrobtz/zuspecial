# Stage 1 — Vendored xsf and the build: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** xsf is vendored reproducibly at SciPy 1.18.1's pin, compiles under
CRAN's flags on every CI leg with no forbidden symbol, and one kernel
(`gamma`) is reachable from R through the C-to-C++ shim.

**Architecture:** xsf's `include/xsf/**` (minus `numpy.h` and
`third_party/`) lives in `src/vendor/xsf/include/xsf/`, because xsf's own
includes are `"xsf/..."`. A C++17 shim translation unit per family exposes
`extern "C"`, `noexcept` entries; `xsf::set_error` is defined once and only
sets bits in a thread-local mask. C glue calls the shim. Nothing exported to
users yet.

**Tech Stack:** R (>= 4.1), C99, C++17, POSIX sh for tools, GitHub Actions
from `pedrobtz/r-actions@v1`.

**Spec:** `.agents/design.md` §4, §6.4, §8, §12.2, §12.3; roadmap Stage 1.

## Global Constraints

- Pin: SciPy `v1.18.1`, whose `subprojects/xsf` gitlink is
  `f7b85f505a94fd398024478d2e747b01dd2d7a6d` (decided 2026-10-23, §16 Q3).
- `CXX_STD = CXX17`; `-DSP_SPECFUN_ERROR`; `-DNDEBUG` (xsf's
  `specfun/specfun.h:5531` has a bare `assert`, which links `abort`).
- Hidden visibility; `R_init_zuspecial` is the only exported symbol.
- No C++ type or exception crosses into C or R; the shim never calls R's API.
- Internal native symbols are prefixed `zsp_`.
- Forbidden in the built objects: `printf` family, `puts`, `putchar`,
  `stdout`, `stderr`, `std::cout`/`std::cerr`, `abort`, `exit`, `_exit`,
  `__assert_fail`, `__assert_rtn`, `rand`, `srand`, `random`.
- Vendored files are never edited; no patches are expected.

## Review Focus

- A vendored file edited by hand but with its checksum re-recorded: the
  `vendor.yml` PR guard must catch it (Task 4 wires it; Task 1's verifier
  catches the unrecorded case).
- A header added upstream that includes `numpy.h` or `third_party/`: the
  build must fail loudly, not silently pick up a system header. Task 1's
  vendor script fails if any copied file includes either.
- `set_error` reached from two threads: each thread sees only its own bits
  (Task 2 test uses one thread; the `thread_local` storage is reviewed).
- `-DNDEBUG` missing on Windows: `Makevars.win` must carry the same flags
  (Task 3's symbol check runs on Windows too).
- A shim function throwing (none in this stage, Boost comes in Stage 4):
  every shim entry is `noexcept`, so a throw terminates rather than
  unwinding into C; reviewed, not tested.

---

### Task 1: Vendoring tool, manifest and the vendored tree

**Files:**

- Create: `tools/vendor/vendor-xsf` (POSIX sh, executable)
- Create: `tools/vendor/verify` (POSIX sh, executable)
- Create: `tools/vendor/manifest.tsv`, `tools/vendor/checksums.sha256`
- Create: `src/vendor/xsf/include/xsf/**`, `src/vendor/xsf/LICENSE`,
  `src/vendor/xsf/LICENSES_bundled.txt`, `src/vendor/PROVENANCE`

**Interfaces:**

- Produces: include root `src/vendor/xsf/include` (so `#include
  "xsf/gamma.h"` works); `tools/vendor/manifest.tsv` with header
  `name<TAB>upstream<TAB>commit<TAB>scipy_tag<TAB>scipy_commit` and one
  `xsf` row; `tools/vendor/verify` exits 0 when every file under
  `src/vendor/xsf` matches `checksums.sha256` and no unlisted file exists.

- [ ] **Step 1:** Write `tools/vendor/vendor-xsf [<scipy-tag>]` (default
  `v1.18.1`): resolve the xsf gitlink with
  `gh api repos/scipy/scipy/contents/subprojects/xsf?ref=<tag> --jq .sha`,
  fetch that xsf commit shallowly into a temp dir, copy `include/xsf/**`
  without `numpy.h` and `third_party/`, plus `LICENSE` and
  `LICENSES_bundled.txt`, into `src/vendor/xsf/`; fail if any copied file
  contains `numpy.h`, `Python.h` or `third_party` in an `#include`; write
  `manifest.tsv` and `checksums.sha256` (`shasum -a 256`, sorted paths).
- [ ] **Step 2:** Run `tools/vendor/vendor-xsf v1.18.1`. Expected: 110 files
  (112 under `include/xsf` less `numpy.h` and the one `third_party` file),
  about 1.5 MB, manifest commit `f7b85f5…`.
- [ ] **Step 3:** Write `tools/vendor/verify`. Run it: exit 0. Append a
  space to one vendored header, run again: non-zero naming that file.
  Restore with `git checkout`.
- [ ] **Step 4:** Write `src/vendor/PROVENANCE`: upstream, SciPy tag and
  commit, xsf commit, what is excluded and why, "Patches: none", and the
  update procedure (`tools/vendor/vendor-xsf <new-tag>`, then the full
  test suite).
- [ ] **Step 5:** Commit: `Vendor xsf at SciPy 1.18.1's pin`.

### Task 2: Build flags, error accumulator, gamma shim, and the spike call

**Files:**

- Create: `src/Makevars`, `src/Makevars.win` (identical content)
- Create: `src/zsp_shim.h` (C header shared by C and C++)
- Create: `src/zsp_error.cpp`, `src/zsp_shim_gamma.cpp`
- Modify: `src/zuspecial.c` (register the spike routine; mark
  `R_init_zuspecial` with `attribute_visible`)
- Create: `src/zsp_spike.c`
- Test: `tests/testthat/test-shim.R`
- Modify: `.gitignore` / `src/.gitignore` if needed for build products

**Interfaces:**

- Produces (in `src/zsp_shim.h`, `extern "C"` under C++):
  - `typedef struct { double re, im; } zsp_complex;`
  - `double zsp_gamma(double x);`
  - `unsigned int zsp_err_take(void);` returns and clears this thread's
    bitmask, bit `1u << code` for each `sf_error_t` code raised since the
    last call.
- Produces: `.Call` routine `zsp_spike_gamma(SEXP x)` returning
  `list(value = <double>, codes = <integer bitmask per element>)`; for
  Stage 2 to replace, not to export.

- [ ] **Step 1: Write the failing test** in `tests/testthat/test-shim.R`:

```r
test_that("gamma is reachable through the shim", {
  res <- .Call(zsp_spike_gamma, c(5, 0.5))
  expect_equal(res$value, c(24, sqrt(pi)), tolerance = 1e-15)
  expect_identical(res$codes, c(0L, 0L))
})

test_that("a pole sets SF_ERROR_SINGULAR and nothing else", {
  res <- .Call(zsp_spike_gamma, -1)
  expect_false(is.finite(res$value))
  expect_identical(res$codes, bitwShiftL(1L, 1L))  # SF_ERROR_SINGULAR = 1
})

test_that("the error mask is cleared between elements", {
  res <- .Call(zsp_spike_gamma, c(-1, 2))
  expect_identical(res$codes[2], 0L)
})
```

- [ ] **Step 2:** Run `Rscript -e 'devtools::test(filter = "shim")'`.
  Expected: FAIL, `zsp_spike_gamma` not found.
- [ ] **Step 3:** `src/Makevars`:
  `CXX_STD = CXX17`,
  `PKG_CPPFLAGS = -Ivendor/xsf/include -DSP_SPECFUN_ERROR -DNDEBUG`,
  `PKG_CFLAGS = $(C_VISIBILITY)`, `PKG_CXXFLAGS = $(CXX_VISIBILITY)`.
  Copy to `Makevars.win`.
- [ ] **Step 4:** `src/zsp_error.cpp` defines
  `void xsf::set_error(const char *, sf_error_t, const char *, ...)` setting
  `zsp_err_bits |= 1u << code` on a `static thread_local unsigned int`, and
  `zsp_err_take()`. No allocation, no R, no I/O.
- [ ] **Step 5:** `src/zsp_shim_gamma.cpp`: `double zsp_gamma(double x)
  noexcept { return xsf::gamma(x); }` including `xsf/gamma.h`.
- [ ] **Step 6:** `src/zsp_spike.c`: loop over a REALSXP, call
  `zsp_err_take()` before the loop and after each element; register it in
  `src/zuspecial.c`'s `call_methods`.
- [ ] **Step 7:** Run the test. Expected: PASS. Then
  `Rscript -e 'devtools::check()'`: 0 errors, 0 warnings, 0 notes.
- [ ] **Step 8:** Commit: `Build xsf with a gamma shim and error mask`.

### Task 3: Symbol and static-state guard

**Files:**

- Create: `tools/check-symbols` (POSIX sh, executable)
- Create: `.github/workflows/symbols.yaml`

**Interfaces:**

- Consumes: the objects `R CMD INSTALL` leaves in `src/` (`*.o`) and the
  shared object.
- Produces: `tools/check-symbols <dir>` exits non-zero and lists offenders
  when an undefined symbol in any object matches the forbidden list in
  Global Constraints, or when a `zsp_shim_*.o` object defines a writable
  data symbol (`nm` types `B`, `b`, `D`, `d`), since only `zsp_error.o` may
  hold state.

- [ ] **Step 1:** Write the script; handle macOS's leading underscore and
  Windows' `nm` from Rtools.
- [ ] **Step 2:** Build in place (`R CMD INSTALL --preclean --no-test-load .`
  with `--no-clean-on-error`, or `pkgbuild::compile_dll()`), run
  `tools/check-symbols src`. Expected: exit 0.
- [ ] **Step 3:** Prove it bites: temporarily add `abort();` to the spike
  routine, rebuild, run: non-zero naming `abort`. Revert.
- [ ] **Step 4:** `symbols.yaml`: on push and pull_request, matrix
  `ubuntu-latest`, `macos-latest`, `windows-latest` (R release, via
  `r-lib/actions/setup-r@v2`), build and run the script; print each
  object's compile time (`time` around `R CMD INSTALL`) to the job summary.
- [ ] **Step 5:** Commit: `Guard against forbidden symbols and shim state`.

### Task 4: CI callers for native checks and the vendor guard

**Files:**

- Create: `.github/workflows/native-checks.yml` (copy of r-actions
  `examples/native-checks.yml`, unchanged)
- Create: `.github/workflows/vendor.yml` calling `vendor.yml@v1` with
  `vendor-dir: src/vendor` and the default `verify` and `must-update`
- Create: `.github/workflows/vendor-upstream.yml` calling
  `vendor-upstream.yml@v1` weekly, `upstream-repo: scipy/scipy`,
  `current-version: awk -F'\t' 'NR > 1 { print $4 }' tools/vendor/manifest.tsv`,
  `tag-pattern: '^v[0-9]+\.[0-9]+\.[0-9]+$'`, permissions
  `contents: read`, `issues: write`

- [ ] **Step 1:** Write the three callers.
- [ ] **Step 2:** `actionlint` if installed; otherwise parse each with
  `python3 -c 'import yaml,sys; yaml.safe_load(open(sys.argv[1]))'`.
- [ ] **Step 3:** Commit: `Add native-check and vendor workflows`.

### Task 5: Licences, identity and recorded decisions

**Files:**

- Create: `inst/COPYRIGHTS`
- Modify: `DESCRIPTION` (`Authors@R` `cph` entries, `Copyright:` field)
- Modify: `.agents/design.md` (§8 path, §12.2 outcome, §16 decisions)
- Modify: `.agents/roadmap.md` (Stage 6 and After 0.1.0: Carlson moves out)
- Modify: `CLAUDE.md` (Architecture, Vendored native code, Commands)

- [ ] **Step 1:** `inst/COPYRIGHTS`: xsf (BSD-3-Clause, SciPy developers);
  Cephes (BSD-3-Clause, Stephen L. Moshier); Faddeeva (MIT, MIT);
  qd `dd_real.h` (BSD-3-Clause-LBNL, The Regents of the University of
  California); AMOS (Sandia, "approved for unlimited release"); specfun
  (Shanjie Zhang and Jianming Jin, "Copyrighted but permission granted to
  use code in programs", accepted on 2026-10-23 as SciPy ships it); the
  Boost-derived code in `cephes/psi.h`, `cephes/scipy_iv.h`,
  `cephes/lanczos.h`, `cephes/igami.h`, `cephes/owens_t.h` (BSL-1.0); the
  "same license as SciPy" files. Take every name from the headers
  themselves, not from this list.
- [ ] **Step 2:** `DESCRIPTION`: `Copyright: See inst/COPYRIGHTS and
  src/vendor/PROVENANCE.`; `cph` persons for SciPy developers, Stephen L.
  Moshier, Massachusetts Institute of Technology, The Regents of the
  University of California, Shanjie Zhang, Jianming Jin, each with a
  `comment` naming the bundled component.
- [ ] **Step 3:** design.md: in §8 the path is `src/vendor/xsf/include/xsf/`
  and the pin is SciPy 1.18.1, whose xsf predates `cpu/` and the Carlson
  integrals; §12.2 specfun accepted; §16 Q1 `sc_`, Q3 SciPy releases, Q5 R
  options, Q6 named list, all decided 2026-10-23; `-DNDEBUG` and why.
- [ ] **Step 4:** roadmap: remove `sc_elliprc` … `sc_elliprj` from Stage 6,
  add them to After 0.1.0 ("with the re-vendor for the first SciPy release
  whose xsf has them"), resolve the Open questions entries, dated
  2026-10-23.
- [ ] **Step 5:** `CLAUDE.md`: Architecture names `src/zsp_shim_*.cpp`,
  `src/zsp_error.cpp`, the include root; Vendored native code gets the pin,
  commit and update procedure; Commands gains `tools/vendor/vendor-xsf`,
  `tools/vendor/verify`, `tools/check-symbols src` (occasional).
- [ ] **Step 6:** `devtools::check()` clean; commit:
  `Record licences and Stage 1 decisions`.

### Task 6: Pull request at the full profile

- [ ] **Step 1:** Open `Stage 1 — Vendored xsf and the build` with
  `Closes #3`, add the `full-ci` label.
- [ ] **Step 2:** Green on every check, including sanitizers, valgrind,
  rchk, `symbols`, `vendor`. Quick profile timed under five minutes on a
  run without the label (the first push, before labelling).
- [ ] **Step 3:** Record per-leg compile times from the `symbols` job
  summary in the roadmap's Stage 1 section.

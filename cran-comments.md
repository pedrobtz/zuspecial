## Submission

This is a new submission.

zuspecial gives R the special functions of SciPy's `scipy.special`. It
bundles xsf (<https://github.com/scipy/xsf>), the header-only C++17 library
those functions are built from, in `src/vendor/xsf/`. It is pinned at commit
`f7b85f5`, the one SciPy 1.18.1 uses, so that values match a SciPy release
users can install. Boost.Math is not bundled; it comes from BH through
`LinkingTo`.

## Test environments

* local macOS 15.7 (x86_64), R 4.5.2
* GitHub Actions: ubuntu-latest (R release, oldrel-1), macOS-latest
  (R release), windows-latest (R release, R-devel)
* R-hub containers, R-devel: `clang23`, `ubuntu-clang`, `ubuntu-gcc16`,
  `nosuggests`, `nold`
* UBSan (gcc, clang), ASan (gcc, clang), valgrind, gctorture, rchk, LTO,
  `-fanalyzer`, and the `rcnst`, `rlibro` and `vnu` checks

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

## Bundled code

xsf is BSD-3-Clause and zuspecial's own code is MIT. xsf contains code from
Cephes (Stephen L. Moshier, BSD-3-Clause by permission to SciPy), AMOS
(approved for unlimited release), specfun (Zhang and Jin, "permission
granted to use code in programs", distributed by SciPy under its licence),
the Faddeeva package (MIT), qd (BSD-3-Clause-LBNL) and Boost-derived files
(Boost Software License 1.0). `inst/COPYRIGHTS` lists every notice,
`inst/licenses/` installs the licence texts. Every copyright holder is in
`Authors@R` as `cph`, and every other author named in the bundled sources
as `ctb`.

The vendored tree carries two small patches, listed in
`src/vendor/PROVENANCE`. They guard float-to-int conversions of NaN and
out-of-range doubles, which UBSan reports. They were reported upstream as
scipy/xsf#338. Everything else is byte-identical to upstream, and a
checksum test in CI verifies this.

## Method references

The functions are those of 'SciPy', cited in `Description` (Virtanen et
al. 2020, <doi:10.1038/s41592-019-0686-2>); each help page links to the
'SciPy' documentation of its functions.

## Network use

Tests, examples and the README do not use the network.

# Every function against xsref's mpmath reference values, under xsf's own
# rule (helper-oracle.R). The sample in tests/testthat/xsref ships with the
# package; the full set runs in CI with ZUSPECIAL_XSREF_DIR (xsref.yaml).

test_that("every function matches xsref within xsf's tolerance", {
  dir <- oracle_dir("ZUSPECIAL_XSREF_DIR", "xsref")
  files <- list.files(dir, pattern = "\\.rds$", full.names = TRUE)
  expect_gt(length(files), 0)
  for (file in files) {
    whole <- readRDS(file)
    for (part in oracle_outputs(whole, oracle_eval(whole))) {
      entry <- part$entry
      # xsref's "other" table, on every platform: its platform tables
      # describe xsf's own CI toolchains, and zuspecial is built with R's
      # (design 10). Precision is held by the same-platform SciPy check.
      tol <- xsf_tol(entry$err[["other"]])
      # Fallback rows hold an earlier SciPy's value where mpmath had none,
      # so they are not truth: hyp2f1(-1, 1, -10, -10) is NaN there but 0 in
      # SciPy 1.18.1 (and zuspecial). Agreement with SciPy covers them.
      tol[entry$fallback] <- Inf
      oracle_check(entry, part$got, tol)
    }
  }
})

test_that("every function agrees with SciPy 1.18.1", {
  same_platform <- nzchar(Sys.getenv("ZUSPECIAL_SCIPY_DIR"))
  dir <- oracle_dir("ZUSPECIAL_SCIPY_DIR", "scipy")
  files <- list.files(dir, pattern = "\\.rds$", full.names = TRUE)
  expect_gt(length(files), 0)
  for (file in files) {
    whole <- readRDS(file)
    if (!same_platform && !isTRUE(whole$no_xsref)) {
      expect_true(all(whole$xsref_row > 0))
    }
    for (part in oracle_outputs(whole, oracle_eval(whole))) {
      oracle_check(
        part$entry,
        part$got,
        scipy_row_tol(part$entry, same_platform)
      )
    }
  }
})

# Every function against xsref's mpmath reference values, under xsf's own
# rule (helper-oracle.R). The sample in tests/testthat/xsref ships with the
# package; the full set runs in CI with ZUSPECIAL_XSREF_DIR (xsref.yaml).

test_that("every function matches xsref within xsf's tolerance", {
  dir <- oracle_dir("ZUSPECIAL_XSREF_DIR", "xsref")
  files <- list.files(dir, pattern = "\\.rds$", full.names = TRUE)
  expect_gt(length(files), 0)
  platform <- xsf_platform()
  for (file in files) {
    entry <- readRDS(file)
    got <- oracle_eval(entry)
    recorded <- entry$err[[platform]] %||% entry$err[["other"]]
    oracle_check(entry, got, xsf_tol(recorded))
  }
})

test_that("every function agrees with SciPy 1.18.1", {
  same_platform <- nzchar(Sys.getenv("ZUSPECIAL_SCIPY_DIR"))
  dir <- oracle_dir("ZUSPECIAL_SCIPY_DIR", "scipy")
  files <- list.files(dir, pattern = "\\.rds$", full.names = TRUE)
  expect_gt(length(files), 0)
  for (file in files) {
    entry <- readRDS(file)
    got <- oracle_eval(entry)
    if (!same_platform && !isTRUE(entry$no_xsref)) {
      expect_true(all(entry$xsref_row > 0))
    }
    oracle_check(entry, got, scipy_row_tol(entry, same_platform))
  }
})

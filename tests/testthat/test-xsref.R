# Every function against xsref's mpmath reference values, under xsf's own
# rule (helper-oracle.R). The sample in tests/testthat/xsref ships with the
# package; the full set runs in CI with ZUSPECIAL_XSREF_DIR (xsref.yaml).

oracle_dir <- function(var, default) {
  dir <- Sys.getenv(var, "")
  if (nzchar(dir)) dir else test_path(default)
}

oracle_eval <- function(entry) {
  fn <- get(entry$r_name, envir = asNamespace("zuspecial"))
  sc_errstate(do.call(fn, unname(entry$inputs)), all = "ignore")
}

oracle_report <- function(entry, got, err, tol, n = 5) {
  bad <- which(!(err <= tol))
  shown <- utils::head(bad, n)
  rows <- vapply(shown, function(i) {
    ins <- vapply(entry$inputs, function(x) format(x[[i]], digits = 17), "")
    sprintf(
      "  row %d: in = (%s) got = %s want = %s err = %.3g tol = %.3g%s",
      entry$rows[[i]], paste(ins, collapse = ", "),
      format(got[[i]], digits = 17), format(entry$out[[i]], digits = 17),
      err[[i]], tol[[i]], if (entry$fallback[[i]]) " [fallback]" else ""
    )
  }, "")
  random <- if (is.null(entry$xsref_row)) 0L else sum(entry$xsref_row[bad] == 0)
  sprintf(
    "%s %s: %d of %d rows outside tolerance (%d random; %d fallback rows in table)\n%s",
    entry$r_name, entry$sig, length(bad), length(err), random,
    sum(entry$fallback), paste(rows, collapse = "\n")
  )
}

test_that("every function matches xsref within xsf's tolerance", {
  dir <- oracle_dir("ZUSPECIAL_XSREF_DIR", "xsref")
  files <- list.files(dir, pattern = "\\.rds$", full.names = TRUE)
  expect_gt(length(files), 0)
  platform <- xsf_platform()
  for (file in files) {
    entry <- readRDS(file)
    got <- oracle_eval(entry)
    err <- xsf_rel_err(got, entry$out)
    recorded <- entry$err[[platform]] %||% entry$err[["other"]]
    tol <- xsf_tol(recorded)
    ok <- all(err <= tol)
    expect(ok, if (ok) "" else oracle_report(entry, got, err, tol))
  }
})

# Agreement with SciPy is not bit for bit across platforms, because xsf
# calls the platform's libm and compilers contract into FMA differently
# (design 10). For a row taken from xsref, both results are within their
# platform's xsref tolerance of mpmath, so they are within the sum of the
# two of each other: this platform's table for zuspecial, "other" for the
# SciPy values, generated on macOS x86_64. Random inputs have no recorded
# error and must agree within 64 ulps. On macOS x86_64 agreement is exact.
scipy_tol <- 64 * .Machine$double.eps

scipy_row_tol <- function(entry) {
  mine <- entry$err[[xsf_platform()]] %||% entry$err[["other"]]
  theirs <- entry$err[["other"]]
  bound <- xsf_tol(mine) + xsf_tol(theirs)
  bound[is.na(bound)] <- 0
  pmax(scipy_tol, bound)
}

test_that("every function agrees with SciPy 1.18.1", {
  files <- list.files(test_path("scipy"), pattern = "\\.rds$", full.names = TRUE)
  expect_gt(length(files), 0)
  for (file in files) {
    entry <- readRDS(file)
    got <- oracle_eval(entry)
    err <- xsf_rel_err(got, entry$out)
    tol <- scipy_row_tol(entry)
    ok <- all(err <= tol)
    expect(ok, if (ok) "" else oracle_report(entry, got, err, tol))
  }
})

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
# (design 10). Two cases:
#
# - The shipped tables were generated on macOS x86_64 and hold xsref inputs
#   only. Both results are within their platform's xsref tolerance of
#   mpmath, so a row may differ by the sum: this platform's table for
#   zuspecial, "other" for SciPy's machine.
# - With ZUSPECIAL_SCIPY_DIR, the tables come from SciPy run on this same
#   platform (xsref.yaml), xsref and random inputs, and every row must agree
#   within 64 ulps.
scipy_tol <- 64 * .Machine$double.eps

scipy_row_tol <- function(entry, same_platform) {
  if (same_platform) {
    return(rep_len(scipy_tol, length(entry$out)))
  }
  mine <- entry$err[[xsf_platform()]] %||% entry$err[["other"]]
  theirs <- entry$err[["other"]]
  bound <- xsf_tol(mine) + xsf_tol(theirs)
  bound[is.na(bound)] <- 0
  pmax(scipy_tol, bound)
}

test_that("every function agrees with SciPy 1.18.1", {
  same_platform <- nzchar(Sys.getenv("ZUSPECIAL_SCIPY_DIR"))
  dir <- oracle_dir("ZUSPECIAL_SCIPY_DIR", "scipy")
  files <- list.files(dir, pattern = "\\.rds$", full.names = TRUE)
  expect_gt(length(files), 0)
  for (file in files) {
    entry <- readRDS(file)
    got <- oracle_eval(entry)
    err <- xsf_rel_err(got, entry$out)
    if (!same_platform) {
      expect_true(all(entry$xsref_row > 0))
    }
    tol <- scipy_row_tol(entry, same_platform)
    ok <- all(err <= tol)
    expect(ok, if (ok) "" else oracle_report(entry, got, err, tol))
  }
})

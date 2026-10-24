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

# The identity of each row: its xsref row number, or for a random SciPy
# input its position in the seeded stream.
oracle_ids <- function(entry) {
  if (entry$kind == "xsref") {
    data.frame(xsref_row = as.integer(entry$rows), random_id = 0L)
  } else {
    data.frame(
      xsref_row = as.integer(entry$xsref_row),
      random_id = as.integer(entry$random_id %||% 0L)
    )
  }
}

# Rows listed in known-windows.tsv.gz: on Windows, Rtools' mingw-w64 v11 sin
# and cos lose accuracy from |x| ~ 1e5 and are wrong beyond ~1e15, which these
# rows' large arguments reach (design 10). The list applies on Windows only,
# so elsewhere the same rows are checked like any other; and on every
# platform each listed row must have an argument of at least 1e5, so the list
# can only ever hold large-argument rows.
known_windows <- utils::read.delim(
  test_path("known-windows.tsv.gz"),
  comment.char = "#"
)

oracle_known <- function(entry, ids) {
  known <- known_windows[
    known_windows$r_name == entry$r_name & known_windows$sig == entry$sig &
      known_windows$kind == entry$kind,
  ]
  listed <- paste(ids$xsref_row, ids$random_id) %in%
    paste(known$xsref_row, known$random_id)
  if (any(listed)) {
    mag <- function(x) if (is.complex(x)) pmax(abs(Re(x)), abs(Im(x))) else abs(x)
    biggest <- do.call(pmax, lapply(entry$inputs, function(x) mag(x)[listed]))
    expect(
      all(biggest >= 1e5),
      sprintf("%s %s: known-windows.tsv.gz lists rows with no argument >= 1e5",
        entry$r_name, entry$sig)
    )
  }
  if (.Platform$OS.type == "windows") listed else logical(nrow(ids))
}

oracle_check <- function(entry, got, tol) {
  err <- xsf_rel_err(got, entry$out)
  ids <- oracle_ids(entry)
  known <- oracle_known(entry, ids)
  outside <- !(err <= tol)

  report <- Sys.getenv("ZUSPECIAL_ORACLE_REPORT")
  if (nzchar(report) && any(outside)) {
    rows <- data.frame(
      r_name = entry$r_name, sig = entry$sig, kind = entry$kind,
      ids[outside, ], err = err[outside], tol = tol[outside],
      known = known[outside]
    )
    utils::write.table(
      rows, report, sep = "\t", quote = FALSE, row.names = FALSE,
      append = file.exists(report), col.names = !file.exists(report)
    )
  }

  ok <- all(!outside | known)
  expect(ok, if (ok) "" else oracle_report(entry, got, err, tol, outside & !known))
  if (any(known) && identical(Sys.getenv("ZUSPECIAL_KNOWN_STRICT"), "true")) {
    stale <- known & !outside
    expect(
      !any(stale),
      sprintf(
        "%s %s: %d rows listed in known-windows.tsv now pass; remove them.",
        entry$r_name, entry$sig, sum(stale)
      )
    )
  }
}

oracle_report <- function(entry, got, err, tol, bad, n = 5) {
  bad <- which(bad)
  shown <- utils::head(bad, n)
  rows <- vapply(shown, function(i) {
    ins <- vapply(entry$inputs, function(x) format(x[[i]], digits = 17), "")
    sprintf(
      "  row %d: in = (%s) got = %s want = %s err = %.3g tol = %.3g%s",
      i, paste(ins, collapse = ", "),
      format(got[[i]], digits = 17), format(entry$out[[i]], digits = 17),
      err[[i]], tol[[i]], if (entry$fallback[[i]]) " [fallback]" else ""
    )
  }, "")
  random <- if (is.null(entry$random_id)) 0L else sum(entry$random_id[bad] > 0)
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
    recorded <- entry$err[[platform]] %||% entry$err[["other"]]
    oracle_check(entry, got, xsf_tol(recorded))
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
#   within 64 ulps. Except on Windows: SciPy's wheels there are built with
#   MSVC on UCRT's libm, zuspecial with Rtools on mingw-w64's, so the
#   platform is not the same; xsref rows take the summed rule with SciPy's
#   msvc-windows-x86_64 table, and random rows, which nothing bounds, are
#   left to Linux and macOS.
scipy_tol <- 64 * .Machine$double.eps

scipy_row_tol <- function(entry, same_platform) {
  windows <- .Platform$OS.type == "windows"
  if (same_platform && !windows) {
    return(rep_len(scipy_tol, length(entry$out)))
  }
  mine <- entry$err[[xsf_platform()]] %||% entry$err[["other"]]
  theirs <- entry$err[[if (same_platform) "msvc-windows-x86_64" else "other"]]
  bound <- xsf_tol(mine) + xsf_tol(theirs)
  bound[is.na(bound)] <- if (same_platform) Inf else 0
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
    if (!same_platform) {
      expect_true(all(entry$xsref_row > 0))
    }
    oracle_check(entry, got, scipy_row_tol(entry, same_platform))
  }
})

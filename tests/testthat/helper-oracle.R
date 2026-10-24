# The tolerance rule of xsf's own tests, ported from
# src/vendor/xsf/include/xsf/fp_error_metrics.h and xsf's
# tests/testing_utils.h, so that the R tests judge results exactly as xsf
# judges them against the same xsref tables.

xsf_dmax <- .Machine$double.xmax
xsf_tiny <- 4.9406564584124654e-324 # denorm_min
xsf_ulp_max <- 2^-53 * xsf_dmax # ulp(max_float)

xsf_copysign <- function(x, s) {
  abs(x) * ifelse(s < 0 | (s == 0 & 1 / s < 0), -1, 1)
}

xsf_abs_err_real <- function(actual, desired) {
  n <- max(length(actual), length(desired))
  actual <- rep_len(actual, n)
  desired <- rep_len(desired, n)
  err <- abs(actual - desired)
  both_nan <- is.nan(actual) & is.nan(desired)
  equal <- !is.nan(actual) & !is.nan(desired) & actual == desired
  one_nan <- !both_nan & (is.nan(actual) | is.nan(desired))
  rest <- !(equal | both_nan | one_nan)
  inf_a <- rest & is.infinite(actual)
  inf_d <- rest & !inf_a & is.infinite(desired)
  err[equal | both_nan] <- 0
  err[one_nan] <- Inf
  sa <- sign(actual[inf_a])
  err[inf_a] <- abs((sa * xsf_dmax - desired[inf_a]) + sa * xsf_ulp_max)
  sd <- sign(desired[inf_d])
  err[inf_d] <- abs((sd * xsf_dmax - actual[inf_d]) + sd * xsf_ulp_max)
  err
}

xsf_hypot <- function(x, y) {
  m <- pmax(abs(x), abs(y))
  r <- pmin(abs(x), abs(y)) / m
  out <- m * sqrt(1 + r * r)
  out[m == 0] <- 0
  out[is.infinite(m)] <- Inf
  out
}

xsf_rel_err <- function(actual, desired) {
  if (is.complex(actual) || is.complex(desired)) {
    actual <- as.complex(actual)
    desired <- as.complex(desired)
    err <- xsf_hypot(
      xsf_abs_err_real(Re(actual), Re(desired)),
      xsf_abs_err_real(Im(actual), Im(desired))
    )
    adjust <- function(p) {
      out <- p
      out[!is.nan(p) & p == 0] <- xsf_copysign(xsf_tiny, p[!is.nan(p) & p == 0])
      out[is.infinite(p)] <- xsf_copysign(xsf_dmax, p[is.infinite(p)])
      out[is.nan(p)] <- 1
      out
    }
    re <- adjust(Re(desired))
    im <- adjust(Im(desired))
    mod <- xsf_hypot(re, im)
    big <- is.infinite(mod)
    out <- err / mod
    out[big] <- (err[big] / 2) / xsf_hypot(re[big] / 2, im[big] / 2)
    return(out)
  }
  err <- xsf_abs_err_real(actual, desired)
  ad <- abs(rep_len(desired, length(err)))
  d <- rep_len(desired, length(err))
  ad[!is.nan(d) & d == 0] <- xsf_tiny
  ad[is.infinite(d)] <- xsf_dmax
  ad[is.nan(d)] <- 1
  err / ad
}

xsf_tol <- function(recorded) 4 * pmax(.Machine$double.eps, recorded)

# The Err_ table xsf's tests would read on this build (testing_utils.h). R on
# Windows builds with Rtools' GCC, which xsf calls "other" (design 10).
xsf_platform <- function() {
  compiler <- zuspecial_info()$compiler
  os <- Sys.info()[["sysname"]]
  arch <- R.version$arch
  if (
    startsWith(compiler, "clang") &&
      os == "Darwin" &&
      arch %in% c("aarch64", "arm64")
  ) {
    "clang-darwin-aarch64"
  } else if (startsWith(compiler, "gcc") && os == "Linux" && arch == "x86_64") {
    "gcc-linux-x86_64"
  } else {
    "other"
  }
}

# Base R has %||% only from 4.4; the package supports 4.1.
`%||%` <- function(x, y) if (is.null(x)) y else x

# Shared by test-xsref.R: reading, evaluating and judging oracle tables.

oracle_dir <- function(var, default) {
  dir <- Sys.getenv(var, "")
  if (nzchar(dir)) dir else test_path(default)
}

oracle_eval <- function(entry) {
  fn <- get(entry$r_name, envir = asNamespace("zuspecial"))
  sc_errstate(do.call(fn, unname(entry$inputs)), all = "ignore")
}

# One entry per output. A multi-output function (airy) has a list of outputs
# and of per-platform errors; each output is checked on its own, as
# "<sig>#<k>", which is also how known-windows.tsv.gz names it.
oracle_outputs <- function(entry, got) {
  if (!is.list(entry$out)) {
    return(list(list(entry = entry, got = got)))
  }
  lapply(seq_along(entry$out), function(k) {
    part <- entry
    part$out <- entry$out[[k]]
    part$err <- lapply(entry$err, `[[`, k)
    part$sig <- paste0(entry$sig, "#", k)
    list(entry = part, got = got[[k]])
  })
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
# The header lines start with "#"; the data may contain "#" too, in the
# signatures of multi-output functions ("d_d-d_d_d_d#2"), so comments are
# dropped by line rather than by read.delim's comment.char.
known_windows <- local({
  lines <- readLines(test_path("known-windows.tsv.gz"))
  utils::read.delim(
    text = lines[!startsWith(lines, "#")],
    comment.char = "",
    colClasses = c("character", "character", "character", "integer", "integer")
  )
})

oracle_known <- function(entry, ids) {
  known <- known_windows[
    known_windows$r_name == entry$r_name &
      known_windows$sig == entry$sig &
      known_windows$kind == entry$kind,
  ]
  listed <- paste(ids$xsref_row, ids$random_id) %in%
    paste(known$xsref_row, known$random_id)
  if (any(listed)) {
    mag <- function(x) {
      if (is.complex(x)) pmax(abs(Re(x)), abs(Im(x))) else abs(x)
    }
    # The rows the defect can reach, as tools/known-windows decides them: an
    # argument of at least 1e5, or ellipj with m = 0 (sin and cos directly).
    biggest <- do.call(pmax, lapply(entry$inputs, function(x) mag(x)[listed]))
    direct_trig <- if (entry$r_name == "sc_ellipj") {
      entry$inputs[[2]][listed] == 0
    } else {
      FALSE
    }
    expect(
      all(biggest >= 1e5 | direct_trig),
      sprintf(
        "%s %s: known-windows.tsv.gz lists rows the defect cannot reach",
        entry$r_name,
        entry$sig
      )
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
      r_name = entry$r_name,
      sig = entry$sig,
      kind = entry$kind,
      ids[outside, ],
      err = err[outside],
      tol = tol[outside],
      known = known[outside]
    )
    utils::write.table(
      rows,
      report,
      sep = "\t",
      quote = FALSE,
      row.names = FALSE,
      append = file.exists(report),
      col.names = !file.exists(report)
    )
  }

  ok <- all(!outside | known)
  expect(
    ok,
    if (ok) "" else oracle_report(entry, got, err, tol, outside & !known)
  )
  if (any(known) && identical(Sys.getenv("ZUSPECIAL_KNOWN_STRICT"), "true")) {
    stale <- known & !outside
    expect(
      !any(stale),
      sprintf(
        "%s %s: %d rows listed in known-windows.tsv now pass; remove them.",
        entry$r_name,
        entry$sig,
        sum(stale)
      )
    )
  }
}

oracle_report <- function(entry, got, err, tol, bad, n = 5) {
  bad <- which(bad)
  shown <- utils::head(bad, n)
  rows <- vapply(
    shown,
    function(i) {
      ins <- vapply(entry$inputs, function(x) format(x[[i]], digits = 17), "")
      sprintf(
        "  row %d: in = (%s) got = %s want = %s err = %.3g tol = %.3g%s",
        i,
        paste(ins, collapse = ", "),
        format(got[[i]], digits = 17),
        format(entry$out[[i]], digits = 17),
        err[[i]],
        tol[[i]],
        if (entry$fallback[[i]]) " [fallback]" else ""
      )
    },
    ""
  )
  random <- if (is.null(entry$random_id)) 0L else sum(entry$random_id[bad] > 0)
  sprintf(
    "%s %s: %d of %d rows outside tolerance (%d random; %d fallback rows in table)\n%s",
    entry$r_name,
    entry$sig,
    length(bad),
    length(err),
    random,
    sum(entry$fallback),
    paste(rows, collapse = "\n")
  )
}

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

# Functions xsref has no table for (the Boost-backed ones, log_ndtr,
# ndtri_exp) ship random rows only. Nothing records their error, so across
# platforms they get a smoke check that catches a wrong kernel or broken glue
# (errors of order 1), at a relative 1e-6; their precision is held by CI, at
# 64 ulps against SciPy on the same platform. 1e-12 was too strict: complex
# log_ndtr(5.47 - 0.119i) is about 2.3e-8 computed as log(1 + w), and its
# imaginary part differs between macOS arm64 and x86_64 by 1e-16 absolute,
# 4.9e-9 relative, with zuspecial and SciPy agreeing on each platform.
scipy_smoke_tol <- 1e-6

scipy_row_tol <- function(entry, same_platform) {
  windows <- .Platform$OS.type == "windows"
  if (same_platform && !windows) {
    return(rep_len(scipy_tol, length(entry$out)))
  }
  if (isTRUE(entry$no_xsref)) {
    return(rep_len(
      if (same_platform) Inf else scipy_smoke_tol,
      length(entry$out)
    ))
  }
  mine <- entry$err[["other"]]
  theirs <- entry$err[[if (same_platform) "msvc-windows-x86_64" else "other"]]
  bound <- xsf_tol(mine) + xsf_tol(theirs)
  bound[is.na(bound)] <- if (same_platform) Inf else 0
  # Where the bound reaches 1, xsref allows either result to be wrong by
  # 100% or more: near the zeros of airy at large negative x, say, where
  # SciPy's MSVC build returns 0, zuspecial 1e-17 and mpmath 4e-15. Such a row
  # has no correct digits to compare, so it is not compared.
  bound[bound >= 1] <- Inf
  pmax(scipy_tol, bound)
}

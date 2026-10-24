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

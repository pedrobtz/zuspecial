# One row per exported kernel function: its SciPy name, the library that
# evaluates it (as SciPy 1.18.1 does), and whether it takes complex arguments.
zsp_functions <- local({
  rows <- strsplit(
    c(
      "gamma,xsf,TRUE",
      "gammaln,xsf,FALSE",
      "loggamma,xsf,TRUE",
      "rgamma,xsf,TRUE",
      "gammasgn,xsf,FALSE",
      "psi,xsf,TRUE",
      "beta,xsf,FALSE",
      "betaln,xsf,FALSE",
      "binom,xsf,FALSE",
      "poch,xsf,FALSE",
      "gammainc,xsf,FALSE",
      "gammaincc,xsf,FALSE",
      "gammaincinv,xsf,FALSE",
      "gammainccinv,xsf,FALSE",
      "erf,xsf,TRUE",
      "erfc,xsf,TRUE",
      "erfcx,xsf,TRUE",
      "erfi,xsf,TRUE",
      "erfcinv,xsf,FALSE",
      "dawsn,xsf,TRUE",
      "wofz,xsf,TRUE",
      "voigt_profile,xsf,FALSE",
      "exp1,xsf,TRUE",
      "expi,xsf,TRUE",
      "expn,xsf,FALSE",
      "ndtr,xsf,TRUE",
      "log_ndtr,xsf,TRUE",
      "ndtri,xsf,FALSE",
      "ndtri_exp,xsf,FALSE",
      "owens_t,xsf,FALSE"
    ),
    ",",
    fixed = TRUE
  )
  data.frame(
    scipy_name = vapply(rows, `[[`, "", 1L),
    backend = vapply(rows, `[[`, "", 2L),
    complex = as.logical(vapply(rows, `[[`, "", 3L))
  )
})
zsp_functions <- cbind(
  r_name = paste0("sc_", zsp_functions$scipy_name),
  zsp_functions
)

#' Versions and functions
#'
#' Reports what this build of zuspecial evaluates with: the vendored xsf
#' commit, the SciPy release whose `subprojects/xsf` pin it is, the xsref
#' commit whose mpmath reference tables the tests use, the compiler, and the
#' table of exported functions.
#'
#' @returns A list with `xsf_commit`, `scipy_version`, `xsref_commit`,
#'   `compiler` and `functions`, a data frame with one row per exported function: `r_name`,
#'   `scipy_name`, `backend` (the library that evaluates it) and `complex`
#'   (whether it takes complex arguments).
#' @examples
#' info <- zuspecial_info()
#' info$scipy_version
#' head(info$functions)
#' @export
zuspecial_info <- function() {
  native <- .Call(zsp_info)
  list(
    xsf_commit = native[[1]],
    scipy_version = sub("^v", "", native[[2]]),
    xsref_commit = native[[4]],
    compiler = native[[3]],
    functions = zsp_functions
  )
}

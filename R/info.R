# One row per exported kernel function: its SciPy name, the library that
# evaluates it, and whether it takes complex arguments.
zsp_functions <- data.frame(
  scipy_name = c(
    "gamma", "gammaln", "loggamma", "rgamma", "gammasgn", "psi", "beta",
    "betaln", "binom", "poch", "erf", "erfc", "erfcx", "erfi", "erfcinv",
    "dawsn", "wofz", "voigt_profile", "exp1", "expi", "expn"
  ),
  backend = "xsf",
  complex = c(
    TRUE, FALSE, TRUE, TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE, TRUE,
    TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE, TRUE, TRUE, FALSE
  )
)
zsp_functions <- cbind(
  r_name = paste0("sc_", zsp_functions$scipy_name),
  zsp_functions
)

#' Versions and functions
#'
#' Reports what this build of zuspecial evaluates with: the vendored xsf
#' commit, the SciPy release whose `subprojects/xsf` pin it is, the compiler,
#' and the table of exported functions.
#'
#' @returns A list with `xsf_commit`, `scipy_version`, `compiler` and
#'   `functions`, a data frame with one row per exported function: `r_name`,
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
    compiler = native[[3]],
    functions = zsp_functions
  )
}

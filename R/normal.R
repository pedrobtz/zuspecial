#' Normal distribution functions
#'
#' The standard normal distribution's functions as `scipy.special` computes
#' them, for code that needs SciPy's values rather than a distribution
#' family.
#'
#' - `sc_ndtr()`: the cumulative distribution function \eqn{\Phi(x)},
#'   complex. Base R: [stats::pnorm()].
#' - `sc_log_ndtr()`: \eqn{\log \Phi(x)}, accurate far into the lower
#'   tail, complex. Base R: `pnorm(x, log.p = TRUE)`.
#' - `sc_ndtri()`: the quantile function, the inverse of `sc_ndtr()`. Base R:
#'   [stats::qnorm()].
#' - `sc_ndtri_exp()`: the inverse of `sc_log_ndtr()`, for log probabilities
#'   too small for `exp()`. Base R: `qnorm(y, log.p = TRUE)`.
#' - `sc_owens_t()`: Owen's T function \eqn{T(h, a)}, which gives bivariate
#'   and skew-normal probabilities.
#'
#' @template args-results
#'
#' @param x Numeric or complex vector.
#' @param y Numeric vector: probabilities for `sc_ndtri()`, log
#'   probabilities (at most 0) for `sc_ndtri_exp()`.
#' @param h,a Numeric vectors.
#' @returns A double vector, or a complex vector for complex input.
#' @section Other packages:
#' In `gsl`: `erf_Q(x)`, the upper tail, which is `sc_ndtr(-x)`.
#'
#' @seealso <https://docs.scipy.org/doc/scipy/reference/special.html#gaussian-normal-distribution>
#' @examples
#' sc_ndtr(c(-1, 0, 1))
#' sc_log_ndtr(-40)
#' sc_ndtri(0.975)
#' sc_ndtri_exp(-1000)
#' sc_owens_t(0.5, 2)
#' @name normal-functions
NULL

#' @rdname normal-functions
#' @export
sc_ndtr <- function(x) zsp_eval("ndtr", list(x = x), "x")

#' @rdname normal-functions
#' @export
sc_log_ndtr <- function(x) zsp_eval("log_ndtr", list(x = x), "x")

#' @rdname normal-functions
#' @export
sc_ndtri <- function(y) zsp_eval("ndtri", list(y = y))

#' @rdname normal-functions
#' @export
sc_ndtri_exp <- function(y) zsp_eval("ndtri_exp", list(y = y))

#' @rdname normal-functions
#' @export
sc_owens_t <- function(h, a) zsp_eval("owens_t", list(h = h, a = a))

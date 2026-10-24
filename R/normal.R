#' Normal distribution functions
#'
#' The standard normal distribution's functions as `scipy.special` computes
#' them, for code that needs SciPy's values rather than a distribution
#' family.
#'
#' - `sc_ndtr()`: the cumulative distribution function \eqn{\Phi(x)},
#'   complex. Base R: [pnorm()].
#' - `sc_log_ndtr()`: \eqn{\log \Phi(x)}, accurate far into the lower
#'   tail, complex. Base R: `pnorm(x, log.p = TRUE)`.
#' - `sc_ndtri()`: the quantile function, the inverse of `sc_ndtr()`. Base R:
#'   [qnorm()].
#' - `sc_ndtri_exp()`: the inverse of `sc_log_ndtr()`, for log probabilities
#'   too small for `exp()`. Base R: `qnorm(y, log.p = TRUE)`.
#' - `sc_owens_t()`: Owen's T function \eqn{T(h, a)}, which gives bivariate
#'   and skew-normal probabilities.
#'
#' Arguments are recycled, `NA` gives `NA`, and the result takes its
#' dimensions, or else its names, from the arguments as base R arithmetic
#' does; see [sc_seterr()] for the conditions the kernels raise.
#'
#' @param x Numeric or complex vector.
#' @param p Numeric vector of probabilities.
#' @param y Numeric vector of log probabilities (at most 0).
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
sc_ndtri <- function(p) zsp_eval("ndtri", list(p = p))

#' @rdname normal-functions
#' @export
sc_ndtri_exp <- function(y) zsp_eval("ndtri_exp", list(y = y))

#' @rdname normal-functions
#' @export
sc_owens_t <- function(h, a) zsp_eval("owens_t", list(h = h, a = a))

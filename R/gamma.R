#' Gamma and beta functions
#'
#' The gamma function and its relatives, evaluated with the same kernels as
#' `scipy.special`, under SciPy's names and argument order. Functions marked
#' "complex" take the complex path when given a complex argument and return
#' complex; real input always stays real (`sc_gamma(-1)` is `NaN`).
#'
#' - `sc_gamma()`: \eqn{\Gamma(z)}, complex. Base R: [gamma()].
#' - `sc_gammaln()`: \eqn{\log|\Gamma(x)|}. Base R: [lgamma()].
#' - `sc_loggamma()`: the principal branch of \eqn{\log \Gamma(z)}, complex,
#'   with a branch cut on the negative real axis. For real `z < 0` it is
#'   `NaN`, unlike `sc_gammaln()`.
#' - `sc_rgamma()`: \eqn{1 / \Gamma(z)}, complex; zero at the poles.
#' - `sc_gammasgn()`: the sign of \eqn{\Gamma(x)}.
#' - `sc_psi()`: the digamma function \eqn{\psi(z)}, complex. Base R:
#'   [digamma()].
#' - `sc_beta()`, `sc_betaln()`: \eqn{B(a, b)} and \eqn{\log|B(a, b)|}. Base
#'   R: [beta()], [lbeta()].
#' - `sc_binom()`: the binomial coefficient for real `x` and `y`. Base R:
#'   [choose()].
#' - `sc_poch()`: the Pochhammer symbol \eqn{\Gamma(z + m) / \Gamma(z)}.
#'
#' Arguments are recycled: each must have length one or the common length.
#' `NA` gives `NA`; `NaN` is evaluated as SciPy does. The result takes its
#' dimensions, or else its names, from the arguments as base R arithmetic
#' does. Conditions the kernels raise, such as a pole, are handled as
#' [sc_seterr()] says.
#'
#' @param z,x Numeric vector; for `z`, also complex.
#' @param a,b,y,m Numeric vectors.
#' @returns A double vector, or a complex vector for complex input.
#' @seealso <https://docs.scipy.org/doc/scipy/reference/special.html#gamma-and-related-functions>
#' @examples
#' sc_gamma(c(0.5, 5))
#' sc_gamma(1 + 1i)
#' sc_loggamma(-2.5 + 0i)
#' sc_beta(2, 3)
#' sc_errstate(sc_gamma(-1), singular = "warn")
#' @name gamma-functions
NULL

#' @rdname gamma-functions
#' @export
sc_gamma <- function(z) zsp_eval("gamma", list(z = z), "z")

#' @rdname gamma-functions
#' @export
sc_gammaln <- function(x) zsp_eval("gammaln", list(x = x))

#' @rdname gamma-functions
#' @export
sc_loggamma <- function(z) zsp_eval("loggamma", list(z = z), "z")

#' @rdname gamma-functions
#' @export
sc_rgamma <- function(z) zsp_eval("rgamma", list(z = z), "z")

#' @rdname gamma-functions
#' @export
sc_gammasgn <- function(x) zsp_eval("gammasgn", list(x = x))

#' @rdname gamma-functions
#' @export
sc_psi <- function(z) zsp_eval("psi", list(z = z), "z")

#' @rdname gamma-functions
#' @export
sc_beta <- function(a, b) zsp_eval("beta", list(a = a, b = b))

#' @rdname gamma-functions
#' @export
sc_betaln <- function(a, b) zsp_eval("betaln", list(a = a, b = b))

#' @rdname gamma-functions
#' @export
sc_binom <- function(x, y) zsp_eval("binom", list(x = x, y = y))

#' @rdname gamma-functions
#' @export
sc_poch <- function(z, m) zsp_eval("poch", list(z = z, m = m))

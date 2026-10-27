#' Exponential integrals
#'
#' - `sc_exp1()`: \eqn{E_1(z) = \int_1^\infty e^{-zt} / t \, dt}, complex,
#'   with a branch cut on the negative real axis.
#' - `sc_expi()`: \eqn{\mathrm{Ei}(x)}, complex.
#' - `sc_expn()`: the generalised \eqn{E_n(x)} for whole `n`.
#'
#' @template args-results
#'
#' @param z Numeric or complex vector.
#' @param x Numeric vector; in `sc_expi()`, also complex.
#' @param n Whole numbers within integer range. `NaN` gives `NaN`, as in
#'   SciPy. A non-whole `n` is an error: SciPy truncates it with a warning,
#'   and zuspecial refuses it so that a fractional order cannot slip
#'   through.
#' @returns A double vector, or a complex vector for complex input.
#' @template windows-trig
#'
#' @section Other packages:
#' In `gsl`, for real arguments: `expint_E1()`, `expint_Ei()` and
#' `expint_En(n, x)`. In `expint`: `expint_E1()`, `expint_Ei()` and
#' `expint_En()`.
#'
#' @seealso <https://docs.scipy.org/doc/scipy/reference/special.html#other-special-functions>
#' @examples
#' sc_exp1(c(0.5, 1, 2))
#' sc_expi(-1 + 0i)
#' sc_expn(2, 1)
#' @name exponential-integrals
NULL

#' @rdname exponential-integrals
#' @export
sc_exp1 <- function(z) zsp_eval("exp1", list(z = z), "z")

#' @rdname exponential-integrals
#' @export
sc_expi <- function(x) zsp_eval("expi", list(x = x), "x")

#' @rdname exponential-integrals
#' @export
sc_expn <- function(n, x) zsp_eval("expn", list(n = n, x = x), whole = "n")

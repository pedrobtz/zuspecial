#' Hypergeometric functions
#'
#' The confluent and Gauss hypergeometric functions, with the kernels
#' `scipy.special` uses (Boost.Math for real `hyp1f1`, as in SciPy).
#'
#' - `sc_hyp0f1()`: \eqn{{}_0F_1(;v;z)}, complex.
#' - `sc_hyp1f1()`: Kummer's \eqn{{}_1F_1(a;b;x)}, complex `x`.
#' - `sc_hyp2f1()`: the Gauss \eqn{{}_2F_1(a,b;c;z)}, complex `z`.
#' - `sc_hyperu()`: Tricomi's \eqn{U(a, b, x)} for real `x >= 0`.
#'
#' Only the last argument may be complex; the parameters are real. Arguments
#' are recycled, `NA` gives `NA`, and the result takes its dimensions, or else
#' its names, from the arguments as base R arithmetic does; see
#' [sc_seterr()] for the conditions the kernels raise.
#'
#' @param v,a,b,c Numeric vectors of parameters.
#' @param z,x Numeric vector; complex too, except for `sc_hyperu()`.
#' @returns A double vector, or a complex vector for complex input.
#' @seealso <https://docs.scipy.org/doc/scipy/reference/special.html#hypergeometric-functions>
#' @examples
#' sc_hyp0f1(0.5, 1)
#' sc_hyp1f1(1, 2, c(0.5, 1 + 1i))
#' sc_hyp2f1(1, 1, 2, 0.5)
#' sc_hyperu(1, 2, 3)
#' @name hypergeometric-functions
NULL

#' @rdname hypergeometric-functions
#' @export
sc_hyp0f1 <- function(v, z) zsp_eval("hyp0f1", list(v = v, z = z), "z")

#' @rdname hypergeometric-functions
#' @export
sc_hyp1f1 <- function(a, b, x) {
  zsp_eval("hyp1f1", list(a = a, b = b, x = x), "x")
}

#' @rdname hypergeometric-functions
#' @export
sc_hyp2f1 <- function(a, b, c, z) {
  zsp_eval("hyp2f1", list(a = a, b = b, c = c, z = z), "z")
}

#' @rdname hypergeometric-functions
#' @export
sc_hyperu <- function(a, b, x) {
  zsp_eval("hyperu", list(a = a, b = b, x = x))
}

#' Elliptic integrals and Jacobi elliptic functions
#'
#' Complete and incomplete elliptic integrals in Legendre form, with the
#' parameter `m` (\eqn{m = k^2}) as `scipy.special` takes it, and the Jacobi
#' elliptic functions.
#'
#' - `sc_ellipk()`, `sc_ellipe()`: complete integrals \eqn{K(m)}, \eqn{E(m)}.
#' - `sc_ellipkm1()`: \eqn{K(1 - p)}, accurate near \eqn{m = 1}.
#' - `sc_ellipkinc()`, `sc_ellipeinc()`: incomplete \eqn{F(\phi | m)} and
#'   \eqn{E(\phi | m)}.
#' - `sc_ellipj()`: \eqn{sn}, \eqn{cn}, \eqn{dn} and the amplitude
#'   \eqn{\phi}, as a named list, as SciPy returns a tuple.
#'
#' Arguments are recycled, `NA` gives `NA`, and results take their
#' dimensions, or else their names, from the arguments as base R arithmetic
#' does; see [sc_seterr()] for the conditions the kernels raise.
#'
#' @param m Numeric vector of parameters.
#' @param p Numeric vector, \eqn{1 - m}.
#' @param phi Numeric vector of amplitudes.
#' @param u Numeric vector.
#' @returns A double vector; for `sc_ellipj()`, a list with `sn`, `cn`, `dn`
#'   and `ph`.
#' @seealso <https://docs.scipy.org/doc/scipy/reference/special.html#elliptic-functions-and-integrals>
#' @examples
#' sc_ellipk(c(0, 0.5, 0.9))
#' sc_ellipkinc(pi / 4, 0.5)
#' sc_ellipj(1, 0.5)
#' @name elliptic-functions
NULL

#' @rdname elliptic-functions
#' @export
sc_ellipk <- function(m) zsp_eval("ellipk", list(m = m))

#' @rdname elliptic-functions
#' @export
sc_ellipkm1 <- function(p) zsp_eval("ellipkm1", list(p = p))

#' @rdname elliptic-functions
#' @export
sc_ellipkinc <- function(phi, m) zsp_eval("ellipkinc", list(phi = phi, m = m))

#' @rdname elliptic-functions
#' @export
sc_ellipe <- function(m) zsp_eval("ellipe", list(m = m))

#' @rdname elliptic-functions
#' @export
sc_ellipeinc <- function(phi, m) zsp_eval("ellipeinc", list(phi = phi, m = m))

#' @rdname elliptic-functions
#' @export
sc_ellipj <- function(u, m) {
  zsp_eval("ellipj", list(u = u, m = m), outputs = c("sn", "cn", "dn", "ph"))
}

#' Zeta, Lambert W, Wright omega, Spence and Struve functions
#'
#' - `sc_zeta()`: the Riemann zeta function \eqn{\zeta(x)} when `q` is
#'   `NULL`, else the Hurwitz zeta function \eqn{\zeta(x, q)}. The Riemann
#'   form takes complex `x`; the Hurwitz form, as in SciPy, only complex `x`
#'   on the real axis, and is `NaN` (a `domain` condition) elsewhere.
#' - `sc_zetac()`: \eqn{\zeta(x) - 1}, accurate for large `x`.
#' - `sc_lambertw()`: branch `k` of the Lambert W function, the solution of
#'   \eqn{w e^w = z}. As in SciPy, the result is always complex.
#' - `sc_wrightomega()`: the Wright omega function, the solution of
#'   \eqn{\omega + \log \omega = z}, complex.
#' - `sc_spence()`: Spence's function (the dilogarithm
#'   \eqn{\mathrm{Li}_2(1 - z)}), complex.
#' - `sc_struve()`, `sc_modstruve()`: the Struve functions \eqn{H_v(x)} and
#'   \eqn{L_v(x)}.
#'
#' Arguments are recycled, `NA` gives `NA`, and the result takes its
#' dimensions, or else its names, from the arguments as base R arithmetic
#' does; see [sc_seterr()] for the conditions the kernels raise.
#'
#' @param x Numeric vector; for `sc_zeta()`, also complex.
#' @param q `NULL`, or a numeric vector of Hurwitz parameters.
#' @param z Numeric or complex vector.
#' @param k Whole numbers within integer range, the branch.
#' @param tol Numeric vector, the tolerance of the iteration.
#' @param v Numeric vector of orders.
#' @returns A double vector, or a complex vector for complex input (always
#'   for `sc_lambertw()`).
#' @seealso <https://docs.scipy.org/doc/scipy/reference/special.html#other-special-functions>
#' @examples
#' sc_zeta(c(2, 4))
#' sc_zeta(2, 2)
#' sc_lambertw(1)
#' sc_lambertw(-0.2, k = -1)
#' sc_wrightomega(1 + 2i)
#' sc_spence(0.5)
#' sc_struve(0.5, 2)
#' @name zeta-functions
NULL

#' @rdname zeta-functions
#' @export
sc_zeta <- function(x, q = NULL) {
  if (is.null(q)) {
    zsp_eval("zeta", list(x = x), "x")
  } else {
    zsp_eval("zeta_q", list(x = x, q = q), "x", fn = "sc_zeta")
  }
}

#' @rdname zeta-functions
#' @export
sc_zetac <- function(x) zsp_eval("zetac", list(x = x))

#' @rdname zeta-functions
#' @export
sc_lambertw <- function(z, k = 0L, tol = 1e-8) {
  zsp_eval(
    "lambertw",
    list(z = z, k = k, tol = tol),
    "z",
    whole = "k",
    complex_only = TRUE
  )
}

#' @rdname zeta-functions
#' @export
sc_wrightomega <- function(z) zsp_eval("wrightomega", list(z = z), "z")

#' @rdname zeta-functions
#' @export
sc_spence <- function(z) zsp_eval("spence", list(z = z), "z")

#' @rdname zeta-functions
#' @export
sc_struve <- function(v, x) zsp_eval("struve", list(v = v, x = x))

#' @rdname zeta-functions
#' @export
sc_modstruve <- function(v, x) zsp_eval("modstruve", list(v = v, x = x))

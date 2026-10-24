#' Bessel and Hankel functions
#'
#' Cylindrical Bessel functions of real order and real or complex argument,
#' with `scipy.special`'s names and argument order: order first, argument
#' second. Base R's [besselJ()] and siblings take them the other way round
#' and accept only real arguments.
#'
#' - `sc_jv()`, `sc_yv()`, `sc_iv()`, `sc_kv()`: \eqn{J_v(z)}, \eqn{Y_v(z)},
#'   \eqn{I_v(z)}, \eqn{K_v(z)}. Base R: `besselJ(z, v)` and so on.
#' - `sc_jve()`, `sc_yve()`, `sc_ive()`, `sc_kve()`: the exponentially scaled
#'   forms, \eqn{J_v(z) e^{-|\Im z|}}, \eqn{Y_v(z) e^{-|\Im z|}},
#'   \eqn{I_v(z) e^{-|\Re z|}} and \eqn{K_v(z) e^z}. Base R: the
#'   `expon.scaled = TRUE` forms of [besselI()] and [besselK()].
#' - `sc_hankel1()`, `sc_hankel2()`: \eqn{H^{(1)}_v(z) = J_v(z) + i Y_v(z)}
#'   and \eqn{H^{(2)}_v(z)}; `sc_hankel1e()`, `sc_hankel2e()` scale them by
#'   \eqn{e^{\mp iz}}. SciPy defines them for complex `z` only, so real input
#'   is treated as complex and the result is always complex.
#' - `sc_j0()`, `sc_j1()`, `sc_y0()`, `sc_y1()`, `sc_i0()`, `sc_i0e()`,
#'   `sc_i1()`, `sc_i1e()`, `sc_k0()`, `sc_k0e()`, `sc_k1()`, `sc_k1e()`: orders
#'   0 and 1 for real `x`, faster than the general functions.
#'
#' A complex `z` takes the complex path and returns complex; a real `z` stays
#' real, so `sc_jv(0.5, -1)` is `NaN` while `sc_jv(0.5, -1+0i)` is complex,
#' as in SciPy. The order `v` must be real. Arguments are recycled, `NA`
#' gives `NA`, and the result takes its dimensions, or else its names, from
#' the arguments as base R arithmetic does; see [sc_seterr()] for the
#' conditions the kernels raise.
#'
#' @param v Numeric vector of orders.
#' @param z Numeric or complex vector of arguments.
#' @param x Numeric vector.
#' @returns A double vector, or a complex vector for complex `z` (always for
#'   the Hankel functions).
#' @section Windows:
#' R on Windows is built with Rtools, whose C library (mingw-w64 v11)
#' evaluates `sin()` and `cos()` inaccurately for arguments beyond about
#' `1e5`, as base R's own `sin()` shows there. Arguments that large are
#' correspondingly inaccurate on Windows only.
#' @section Branch cuts:
#' For complex `z`, as in SciPy: \eqn{J_v} and \eqn{I_v} are entire in `z`
#' for a whole order `v`, and otherwise have a branch cut on the negative
#' real axis; \eqn{Y_v}, \eqn{K_v} and the Hankel functions have that cut
#' for every order.
#'
#' @section Other packages:
#' In `gsl`, for real arguments, in SciPy's order: `bessel_Jnu(nu, x)`,
#' `bessel_Ynu()`, `bessel_Inu()`, `bessel_Knu()`, the scaled
#' `bessel_Inu_scaled()` and `bessel_Knu_scaled()`, and `bessel_J0()` to
#' `bessel_K1_scaled()`. In `Bessel`, for complex arguments, in base R's
#' order: `BesselJ(z, nu)`, `BesselY()`, `BesselI()`, `BesselK()` and
#' `BesselH(m, z, nu)`.
#'
#' @seealso <https://docs.scipy.org/doc/scipy/reference/special.html#bessel-functions>
#' @examples
#' sc_jv(c(0, 1, 2.5), 3)
#' sc_jv(0.5, -1)
#' sc_jv(0.5, -1 + 0i)
#' sc_kve(1, 50)
#' sc_hankel1(0, 2)
#' sc_j0(c(0, 2.405))
#' @name bessel-functions
NULL

#' @rdname bessel-functions
#' @export
sc_jv <- function(v, z) zsp_eval("jv", list(v = v, z = z), "z")

#' @rdname bessel-functions
#' @export
sc_yv <- function(v, z) zsp_eval("yv", list(v = v, z = z), "z")

#' @rdname bessel-functions
#' @export
sc_iv <- function(v, z) zsp_eval("iv", list(v = v, z = z), "z")

#' @rdname bessel-functions
#' @export
sc_kv <- function(v, z) zsp_eval("kv", list(v = v, z = z), "z")

#' @rdname bessel-functions
#' @export
sc_jve <- function(v, z) zsp_eval("jve", list(v = v, z = z), "z")

#' @rdname bessel-functions
#' @export
sc_yve <- function(v, z) zsp_eval("yve", list(v = v, z = z), "z")

#' @rdname bessel-functions
#' @export
sc_ive <- function(v, z) zsp_eval("ive", list(v = v, z = z), "z")

#' @rdname bessel-functions
#' @export
sc_kve <- function(v, z) zsp_eval("kve", list(v = v, z = z), "z")

#' @rdname bessel-functions
#' @export
sc_hankel1 <- function(v, z) {
  zsp_eval("hankel1", list(v = v, z = z), "z", complex_only = TRUE)
}

#' @rdname bessel-functions
#' @export
sc_hankel2 <- function(v, z) {
  zsp_eval("hankel2", list(v = v, z = z), "z", complex_only = TRUE)
}

#' @rdname bessel-functions
#' @export
sc_hankel1e <- function(v, z) {
  zsp_eval("hankel1e", list(v = v, z = z), "z", complex_only = TRUE)
}

#' @rdname bessel-functions
#' @export
sc_hankel2e <- function(v, z) {
  zsp_eval("hankel2e", list(v = v, z = z), "z", complex_only = TRUE)
}

#' @rdname bessel-functions
#' @export
sc_j0 <- function(x) zsp_eval("j0", list(x = x))

#' @rdname bessel-functions
#' @export
sc_j1 <- function(x) zsp_eval("j1", list(x = x))

#' @rdname bessel-functions
#' @export
sc_y0 <- function(x) zsp_eval("y0", list(x = x))

#' @rdname bessel-functions
#' @export
sc_y1 <- function(x) zsp_eval("y1", list(x = x))

#' @rdname bessel-functions
#' @export
sc_i0 <- function(x) zsp_eval("i0", list(x = x))

#' @rdname bessel-functions
#' @export
sc_i0e <- function(x) zsp_eval("i0e", list(x = x))

#' @rdname bessel-functions
#' @export
sc_i1 <- function(x) zsp_eval("i1", list(x = x))

#' @rdname bessel-functions
#' @export
sc_i1e <- function(x) zsp_eval("i1e", list(x = x))

#' @rdname bessel-functions
#' @export
sc_k0 <- function(x) zsp_eval("k0", list(x = x))

#' @rdname bessel-functions
#' @export
sc_k0e <- function(x) zsp_eval("k0e", list(x = x))

#' @rdname bessel-functions
#' @export
sc_k1 <- function(x) zsp_eval("k1", list(x = x))

#' @rdname bessel-functions
#' @export
sc_k1e <- function(x) zsp_eval("k1e", list(x = x))

#' Spherical Bessel functions
#'
#' The spherical Bessel functions of integer order, or their derivatives,
#' for real or complex argument, as `scipy.special`'s `spherical_jn()` and
#' siblings compute them.
#'
#' - `sc_spherical_jn()`, `sc_spherical_yn()`: \eqn{j_n(z)} and \eqn{y_n(z)}.
#' - `sc_spherical_in()`, `sc_spherical_kn()`: the modified functions
#'   \eqn{i_n(z)} and \eqn{k_n(z)}.
#'
#' Arguments are recycled, `NA` gives `NA`, and the result takes its
#' dimensions, or else its names, from the arguments as base R arithmetic
#' does; see [sc_seterr()] for the conditions the kernels raise.
#'
#' @param n Whole numbers within integer range, the orders.
#' @param z Numeric or complex vector of arguments.
#' @param derivative `TRUE` for the derivative with respect to `z`, `FALSE`
#'   (the default) for the function itself.
#' @returns A double vector, or a complex vector for complex `z`.
#' @section Other packages:
#' In `gsl`, for real `x`: `bessel_jl(l, x)` and `bessel_yl()`, and the
#' scaled `bessel_il_scaled()` and `bessel_kl_scaled()`, which are
#' `sc_spherical_in(n, x) * exp(-abs(x))` and
#' `sc_spherical_kn(n, x) * exp(x)`.
#'
#' @seealso <https://docs.scipy.org/doc/scipy/reference/generated/scipy.special.spherical_jn.html>
#' @examples
#' sc_spherical_jn(0:3, 1.5)
#' sc_spherical_jn(1, 1.5, derivative = TRUE)
#' sc_spherical_kn(2, 1 + 1i)
#' @name spherical-bessel
NULL

#' @rdname spherical-bessel
#' @export
sc_spherical_jn <- function(n, z, derivative = FALSE) {
  zsp_check_flag(derivative, "derivative", sys.call())
  zsp_eval(
    if (derivative) "spherical_jn_d" else "spherical_jn",
    list(n = n, z = z),
    "z",
    whole = "n",
    fn = "sc_spherical_jn"
  )
}

#' @rdname spherical-bessel
#' @export
sc_spherical_yn <- function(n, z, derivative = FALSE) {
  zsp_check_flag(derivative, "derivative", sys.call())
  zsp_eval(
    if (derivative) "spherical_yn_d" else "spherical_yn",
    list(n = n, z = z),
    "z",
    whole = "n",
    fn = "sc_spherical_yn"
  )
}

#' @rdname spherical-bessel
#' @export
sc_spherical_in <- function(n, z, derivative = FALSE) {
  zsp_check_flag(derivative, "derivative", sys.call())
  zsp_eval(
    if (derivative) "spherical_in_d" else "spherical_in",
    list(n = n, z = z),
    "z",
    whole = "n",
    fn = "sc_spherical_in"
  )
}

#' @rdname spherical-bessel
#' @export
sc_spherical_kn <- function(n, z, derivative = FALSE) {
  zsp_check_flag(derivative, "derivative", sys.call())
  zsp_eval(
    if (derivative) "spherical_kn_d" else "spherical_kn",
    list(n = n, z = z),
    "z",
    whole = "n",
    fn = "sc_spherical_kn"
  )
}

#' Airy functions
#'
#' The Airy functions \eqn{Ai(z)}, \eqn{Bi(z)} and their derivatives, for
#' real or complex `z`, as `scipy.special.airy()` and `airye()` compute
#' them. Each call returns all four, as a named list, as SciPy returns a
#' tuple.
#'
#' - `sc_airy()`: \eqn{Ai}, \eqn{Ai'}, \eqn{Bi}, \eqn{Bi'}.
#' - `sc_airye()`: the exponentially scaled forms, \eqn{Ai(z) e^{\zeta}},
#'   \eqn{Ai'(z) e^{\zeta}}, \eqn{Bi(z) e^{-|\Re \zeta|}} and
#'   \eqn{Bi'(z) e^{-|\Re \zeta|}}, with \eqn{\zeta = \frac23 z^{3/2}}.
#'
#' @param z Numeric or complex vector.
#' @returns A list with elements `ai`, `aip`, `bi` and `bip`, each a double
#'   vector, or a complex vector for complex `z`, with `z`'s dimensions or
#'   names. `NA` in `z` gives `NA` in every element.
#' @section Other packages:
#' In `gsl`, for real arguments: `airy_Ai()`, `airy_Bi()`,
#' `airy_Ai_deriv()`, `airy_Bi_deriv()` and their `_scaled` forms. In
#' `Bessel`, for complex arguments: `AiryA(z, deriv)` and `AiryB()`.
#'
#' @seealso <https://docs.scipy.org/doc/scipy/reference/generated/scipy.special.airy.html>
#' @examples
#' sc_airy(c(-1, 0, 1))
#' sc_airye(10)$ai
#' sc_airy(1 + 1i)
#' @name airy-functions
NULL

#' @rdname airy-functions
#' @export
sc_airy <- function(z) {
  zsp_eval("airy", list(z = z), "z", outputs = c("ai", "aip", "bi", "bip"))
}

#' @rdname airy-functions
#' @export
sc_airye <- function(z) {
  zsp_eval("airye", list(z = z), "z", outputs = c("ai", "aip", "bi", "bip"))
}

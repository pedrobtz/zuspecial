#' Error functions and the Faddeeva function
#'
#' The error function and its relatives, with the kernels `scipy.special`
#' uses (the MIT Faddeeva package for complex arguments). Functions marked
#' "complex" take the complex path for complex input.
#'
#' - `sc_erf()`, `sc_erfc()`: \eqn{\mathrm{erf}(z)} and
#'   \eqn{1 - \mathrm{erf}(x)}, complex. Base R equivalents:
#'   `2 * pnorm(x * sqrt(2)) - 1` and `2 * pnorm(-x * sqrt(2))`.
#' - `sc_erfcx()`: the scaled complementary error function
#'   \eqn{e^{x^2} \mathrm{erfc}(x)}, complex.
#' - `sc_erfi()`: the imaginary error function \eqn{-i\,\mathrm{erf}(iz)},
#'   complex.
#' - `sc_erfcinv()`: the inverse of `sc_erfc()` on \eqn{(0, 2)}.
#' - `sc_erfinv()`: the inverse of `sc_erf()` on \eqn{[-1, 1]}, evaluated
#'   with Boost.Math (from the BH package), as SciPy does.
#' - `sc_dawsn()`: Dawson's integral, complex.
#' - `sc_wofz()`: the Faddeeva function \eqn{w(z) = e^{-z^2}
#'   \mathrm{erfc}(-iz)}. SciPy defines it for complex input only, so real
#'   input is treated as complex and the result is always complex.
#' - `sc_voigt_profile()`: the Voigt profile, the convolution of a normal
#'   density with standard deviation `sigma` and a Cauchy density with half
#'   width `gamma`.
#'
#' Arguments are recycled, `NA` gives `NA`, and the result takes its
#' dimensions, or else its names, from the arguments as base R arithmetic
#' does; see [sc_seterr()] for the conditions the kernels raise.
#'
#' @param z,x Numeric vector; for `z`, and for `x` in `sc_erfc()`,
#'   `sc_erfcx()` and `sc_dawsn()`, also complex.
#' @param y Numeric vector: in \eqn{[0, 2]} for `sc_erfcinv()`, in
#'   \eqn{[-1, 1]} for `sc_erfinv()`.
#' @param sigma,gamma Numeric vectors, the Voigt profile's parameters.
#' @returns A double vector, or a complex vector for complex input (always
#'   complex for `sc_wofz()`).
#' @section Windows:
#' R on Windows is built with Rtools, whose C library (mingw-w64 v11)
#' evaluates `sin()` and `cos()` inaccurately for arguments beyond about
#' `1e5`, as base R's own `sin()` shows there. Complex arguments with a part
#' that large, and real ones where the kernel takes a sine of such a value,
#' are correspondingly inaccurate on Windows only.
#'
#' @section Other packages:
#' In `gsl`, for real arguments only: `erf()`, `erfc()`, `log_erfc()` and
#' `dawson()`.
#'
#' @seealso <https://docs.scipy.org/doc/scipy/reference/special.html#error-function-and-fresnel-integrals>
#' @examples
#' sc_erf(c(-1, 0, 1))
#' sc_erf(1 + 1i)
#' sc_erfcx(30)
#' sc_wofz(1 + 2i)
#' sc_voigt_profile(0, sigma = 1, gamma = 0.5)
#' @name error-functions
NULL

#' @rdname error-functions
#' @export
sc_erf <- function(z) zsp_eval("erf", list(z = z), "z")

#' @rdname error-functions
#' @export
sc_erfc <- function(x) zsp_eval("erfc", list(x = x), "x")

#' @rdname error-functions
#' @export
sc_erfcx <- function(x) zsp_eval("erfcx", list(x = x), "x")

#' @rdname error-functions
#' @export
sc_erfi <- function(z) zsp_eval("erfi", list(z = z), "z")

#' @rdname error-functions
#' @export
sc_erfcinv <- function(y) zsp_eval("erfcinv", list(y = y))

#' @rdname error-functions
#' @export
sc_dawsn <- function(x) zsp_eval("dawsn", list(x = x), "x")

#' @rdname error-functions
#' @export
sc_wofz <- function(z) zsp_eval("wofz", list(z = z), "z", complex_only = TRUE)

#' @rdname error-functions
#' @export
sc_voigt_profile <- function(x, sigma, gamma) {
  zsp_eval("voigt_profile", list(x = x, sigma = sigma, gamma = gamma))
}

#' @rdname error-functions
#' @export
sc_erfinv <- function(y) zsp_eval("erfinv", list(y = y))

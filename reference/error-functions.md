# Error functions and the Faddeeva function

The error function and its relatives, with the kernels `scipy.special`
uses (the MIT Faddeeva package for complex arguments). Functions marked
"complex" take the complex path for complex input.

## Usage

``` r
sc_erf(z)

sc_erfc(x)

sc_erfcx(x)

sc_erfi(z)

sc_erfcinv(y)

sc_dawsn(x)

sc_wofz(z)

sc_voigt_profile(x, sigma, gamma)

sc_erfinv(y)
```

## Arguments

- z, x:

  Numeric vector; for `z`, and for `x` in `sc_erfc()`, `sc_erfcx()` and
  `sc_dawsn()`, also complex.

- y:

  Numeric vector: in \\\[0, 2\]\\ for `sc_erfcinv()`, in \\\[-1, 1\]\\
  for `sc_erfinv()`.

- sigma, gamma:

  Numeric vectors, the Voigt profile's parameters.

## Value

A double vector, or a complex vector for complex input (always complex
for `sc_wofz()`).

## Details

- `sc_erf()`, `sc_erfc()`: \\\mathrm{erf}(z)\\ and \\1 -
  \mathrm{erf}(x)\\, complex. Base R equivalents:
  `2 * pnorm(x * sqrt(2)) - 1` and `2 * pnorm(-x * sqrt(2))`.

- `sc_erfcx()`: the scaled complementary error function \\e^{x^2}
  \mathrm{erfc}(x)\\, complex.

- `sc_erfi()`: the imaginary error function \\-i\\\mathrm{erf}(iz)\\,
  complex.

- `sc_erfcinv()`: the inverse of `sc_erfc()` on \\(0, 2)\\.

- `sc_erfinv()`: the inverse of `sc_erf()` on \\\[-1, 1\]\\, evaluated
  with Boost.Math (from the BH package), as SciPy does.

- `sc_dawsn()`: Dawson's integral, complex.

- `sc_wofz()`: the Faddeeva function \\w(z) = e^{-z^2}
  \mathrm{erfc}(-iz)\\. SciPy defines it for complex input only, so real
  input is treated as complex and the result is always complex.

- `sc_voigt_profile()`: the Voigt profile, the convolution of a normal
  density with standard deviation `sigma` and a Cauchy density with half
  width `gamma`.

Arguments are recycled, `NA` gives `NA`, and the result takes its
dimensions, or else its names, from the arguments as base R arithmetic
does; see
[`sc_seterr()`](https://pedrobtz.github.io/zuspecial/reference/errstate.md)
for the conditions the kernels raise.

## Windows

R on Windows is built with Rtools, whose C library (mingw-w64 v11)
evaluates [`sin()`](https://rdrr.io/r/base/Trig.html) and
[`cos()`](https://rdrr.io/r/base/Trig.html) inaccurately for arguments
beyond about `1e5`, as base R's own
[`sin()`](https://rdrr.io/r/base/Trig.html) shows there. Complex
arguments with a part that large, and real ones where the kernel takes a
sine of such a value, are correspondingly inaccurate on Windows only.

## Other packages

In `gsl`, for real arguments only: `erf()`, `erfc()`, `log_erfc()` and
`dawson()`.

## See also

<https://docs.scipy.org/doc/scipy/reference/special.html#error-function-and-fresnel-integrals>

## Examples

``` r
sc_erf(c(-1, 0, 1))
#> [1] -0.8427008  0.0000000  0.8427008
sc_erf(1 + 1i)
#> [1] 1.316151+0.1904535i
sc_erfcx(30)
#> [1] 0.01879589
sc_wofz(1 + 2i)
#> [1] 0.2184926+0.09299781i
sc_voigt_profile(0, sigma = 1, gamma = 0.5)
#> [1] 0.2789555
```

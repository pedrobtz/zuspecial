# Exponential integrals

- `sc_exp1()`: \\E_1(z) = \int_1^\infty e^{-zt} / t \\ dt\\, complex,
  with a branch cut on the negative real axis.

- `sc_expi()`: \\\mathrm{Ei}(x)\\, complex.

- `sc_expn()`: the generalised \\E_n(x)\\ for whole `n`.

## Usage

``` r
sc_exp1(z)

sc_expi(x)

sc_expn(n, x)
```

## Arguments

- z:

  Numeric or complex vector.

- x:

  Numeric vector; in `sc_expi()`, also complex.

- n:

  Whole numbers within integer range. `NaN` gives `NaN`, as in SciPy. A
  non-whole `n` is an error: SciPy truncates it with a warning, and
  zuspecial refuses it so that a fractional order cannot slip through.

## Value

A double vector, or a complex vector for complex input.

## Details

Arguments are recycled: each must have length one or the common length.
`NA` gives `NA`; `NaN` is evaluated as SciPy does. The result takes its
dimensions, or else its names, from the arguments as base R arithmetic
does, and so does each element of a list result. Conditions the kernels
raise, such as a pole, are handled as
[`sc_seterr()`](https://pedrobtz.github.io/zuspecial/reference/errstate.md)
says.

## Windows

R on Windows is built with Rtools, whose C library (mingw-w64 v11)
evaluates [`sin()`](https://rdrr.io/r/base/Trig.html) and
[`cos()`](https://rdrr.io/r/base/Trig.html) inaccurately for arguments
beyond about `1e5`, as base R's own
[`sin()`](https://rdrr.io/r/base/Trig.html) shows there. Complex
arguments with a part that large, and real ones where the kernel takes a
sine of such a value, are correspondingly inaccurate on Windows only.

## Other packages

In `gsl`, for real arguments: `expint_E1()`, `expint_Ei()` and
`expint_En(n, x)`. In `expint`: `expint_E1()`, `expint_Ei()` and
`expint_En()`.

## See also

<https://docs.scipy.org/doc/scipy/reference/special.html#other-special-functions>

## Examples

``` r
sc_exp1(c(0.5, 1, 2))
#> [1] 0.55977359 0.21938393 0.04890051
sc_expi(-1 + 0i)
#> [1] -0.2193839+0i
sc_expn(2, 1)
#> [1] 0.1484955
```

# Zeta, Lambert W, Wright omega, Spence and Struve functions

- `sc_zeta()`: the Riemann zeta function \\\zeta(x)\\ when `q` is
  `NULL`, else the Hurwitz zeta function \\\zeta(x, q)\\. The Riemann
  form takes complex `x`; the Hurwitz form, as in SciPy, only complex
  `x` on the real axis, and is `NaN` (a `domain` condition) elsewhere.

- `sc_zetac()`: \\\zeta(x) - 1\\, accurate for large `x`.

- `sc_lambertw()`: branch `k` of the Lambert W function, the solution of
  \\w e^w = z\\. As in SciPy, the result is always complex.

- `sc_wrightomega()`: the Wright omega function, the solution of
  \\\omega + \log \omega = z\\, complex.

- `sc_spence()`: Spence's function (the dilogarithm \\\mathrm{Li}\_2(1 -
  z)\\), complex.

- `sc_struve()`, `sc_modstruve()`: the Struve functions \\H_v(x)\\ and
  \\L_v(x)\\.

## Usage

``` r
sc_zeta(x, q = NULL)

sc_zetac(x)

sc_lambertw(z, k = 0L, tol = 1e-08)

sc_wrightomega(z)

sc_spence(z)

sc_struve(v, x)

sc_modstruve(v, x)
```

## Arguments

- x:

  Numeric vector; for `sc_zeta()`, also complex.

- q:

  `NULL`, or a numeric vector of Hurwitz parameters.

- z:

  Numeric or complex vector.

- k:

  Whole numbers within integer range, the branch.

- tol:

  Numeric vector, the tolerance of the iteration.

- v:

  Numeric vector of orders.

## Value

A double vector, or a complex vector for complex input (always for
`sc_lambertw()`).

## Details

Arguments are recycled: each must have length one or the common length.
`NA` gives `NA`; `NaN` is evaluated as SciPy does. The result takes its
dimensions, or else its names, from the arguments as base R arithmetic
does, and so does each element of a list result. Conditions the kernels
raise, such as a pole, are handled as
[`sc_seterr()`](https://pedrobtz.github.io/zuspecial/reference/errstate.md)
says.

## Branch cuts

As in SciPy: the principal branch of `sc_lambertw()` (`k = 0`) has a
branch cut on the real axis from \\-\infty\\ to \\-1/e\\, and every
other branch one from \\-\infty\\ to 0; `sc_spence()` has a branch cut
on the negative real axis.

## Other packages

In `gsl`, for real arguments: `zeta()`, `hzeta(s, q)`, `zetam1()` (the
`sc_zetac()` of SciPy), `lambert_W0()` and `lambert_Wm1()` (branches 0
and -1), and `dilog(x)`, which is `sc_spence(1 - x)`. In `lamW`:
`lambertW0()` and `lambertWm1()`.

## See also

<https://docs.scipy.org/doc/scipy/reference/special.html#other-special-functions>

## Examples

``` r
sc_zeta(c(2, 4))
#> [1] 1.644934 1.082323
sc_zeta(2, 2)
#> [1] 0.6449341
sc_lambertw(1)
#> [1] 0.5671433+0i
sc_lambertw(-0.2, k = -1)
#> [1] -2.542641+0i
sc_wrightomega(1 + 2i)
#> [1] 0.7472911+1.048444i
sc_spence(0.5)
#> [1] 0.5822405
sc_struve(0.5, 2)
#> [1] 0.7989753
```

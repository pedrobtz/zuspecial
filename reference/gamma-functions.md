# Gamma and beta functions

The gamma function and its relatives, evaluated with the same kernels as
`scipy.special`, under SciPy's names and argument order. Functions
marked "complex" take the complex path when given a complex argument and
return complex; real input always stays real (`sc_gamma(-1)` is `NaN`).

## Usage

``` r
sc_gamma(z)

sc_gammaln(x)

sc_loggamma(z)

sc_rgamma(z)

sc_gammasgn(x)

sc_psi(z)

sc_beta(a, b)

sc_betaln(a, b)

sc_binom(x, y)

sc_poch(z, m)
```

## Arguments

- z, x:

  Numeric vector; for `z`, also complex.

- a, b, y, m:

  Numeric vectors.

## Value

A double vector, or a complex vector for complex input.

## Details

- `sc_gamma()`: \\\Gamma(z)\\, complex. Base R:
  [`gamma()`](https://rdrr.io/r/base/Special.html).

- `sc_gammaln()`: \\\log\|\Gamma(x)\|\\. Base R:
  [`lgamma()`](https://rdrr.io/r/base/Special.html).

- `sc_loggamma()`: the principal branch of \\\log \Gamma(z)\\, complex,
  with a branch cut on the negative real axis. For real `z < 0` it is
  `NaN`, unlike `sc_gammaln()`.

- `sc_rgamma()`: \\1 / \Gamma(z)\\, complex; zero at the poles.

- `sc_gammasgn()`: the sign of \\\Gamma(x)\\.

- `sc_psi()`: the digamma function \\\psi(z)\\, complex. Base R:
  [`digamma()`](https://rdrr.io/r/base/Special.html).

- `sc_beta()`, `sc_betaln()`: \\B(a, b)\\ and \\\log\|B(a, b)\|\\. Base
  R: [`beta()`](https://rdrr.io/r/base/Special.html),
  [`lbeta()`](https://rdrr.io/r/base/Special.html).

- `sc_binom()`: the binomial coefficient for real `x` and `y`. Base R:
  [`choose()`](https://rdrr.io/r/base/Special.html).

- `sc_poch()`: the Pochhammer symbol \\\Gamma(z + m) / \Gamma(z)\\.

Arguments are recycled: each must have length one or the common length.
`NA` gives `NA`; `NaN` is evaluated as SciPy does. The result takes its
dimensions, or else its names, from the arguments as base R arithmetic
does. Conditions the kernels raise, such as a pole, are handled as
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

## See also

<https://docs.scipy.org/doc/scipy/reference/special.html#gamma-and-related-functions>

## Examples

``` r
sc_gamma(c(0.5, 5))
#> [1]  1.772454 24.000000
sc_gamma(1 + 1i)
#> [1] 0.4980157-0.1549498i
sc_loggamma(-2.5 + 0i)
#> [1] -0.05624372-9.424778i
sc_beta(2, 3)
#> [1] 0.08333333
sc_errstate(sc_gamma(-1), singular = "warn")
#> Warning: sc_gamma: singular in 1 element, first at index 1.
#> [1] NaN
```

# Normal distribution functions

The standard normal distribution's functions as `scipy.special` computes
them, for code that needs SciPy's values rather than a distribution
family.

## Usage

``` r
sc_ndtr(x)

sc_log_ndtr(x)

sc_ndtri(p)

sc_ndtri_exp(y)

sc_owens_t(h, a)
```

## Arguments

- x:

  Numeric or complex vector.

- p:

  Numeric vector of probabilities.

- y:

  Numeric vector of log probabilities (at most 0).

- h, a:

  Numeric vectors.

## Value

A double vector, or a complex vector for complex input.

## Details

- `sc_ndtr()`: the cumulative distribution function \\\Phi(x)\\,
  complex. Base R: [`pnorm()`](https://rdrr.io/r/stats/Normal.html).

- `sc_log_ndtr()`: \\\log \Phi(x)\\, accurate far into the lower tail,
  complex. Base R: `pnorm(x, log.p = TRUE)`.

- `sc_ndtri()`: the quantile function, the inverse of `sc_ndtr()`. Base
  R: [`qnorm()`](https://rdrr.io/r/stats/Normal.html).

- `sc_ndtri_exp()`: the inverse of `sc_log_ndtr()`, for log
  probabilities too small for
  [`exp()`](https://rdrr.io/r/base/Log.html). Base R:
  `qnorm(y, log.p = TRUE)`.

- `sc_owens_t()`: Owen's T function \\T(h, a)\\, which gives bivariate
  and skew-normal probabilities.

Arguments are recycled, `NA` gives `NA`, and the result takes its
dimensions, or else its names, from the arguments as base R arithmetic
does; see
[`sc_seterr()`](https://pedrobtz.github.io/zuspecial/reference/errstate.md)
for the conditions the kernels raise.

## See also

<https://docs.scipy.org/doc/scipy/reference/special.html#gaussian-normal-distribution>

## Examples

``` r
sc_ndtr(c(-1, 0, 1))
#> [1] 0.1586553 0.5000000 0.8413447
sc_log_ndtr(-40)
#> [1] -804.6084
sc_ndtri(0.975)
#> [1] 1.959964
sc_ndtri_exp(-1000)
#> [1] -44.61575
sc_owens_t(0.5, 2)
#> [1] 0.1415806
```

# Elliptic integrals and Jacobi elliptic functions

Complete and incomplete elliptic integrals in Legendre form, with the
parameter `m` (\\m = k^2\\) as `scipy.special` takes it, and the Jacobi
elliptic functions.

## Usage

``` r
sc_ellipk(m)

sc_ellipkm1(p)

sc_ellipkinc(phi, m)

sc_ellipe(m)

sc_ellipeinc(phi, m)

sc_ellipj(u, m)
```

## Arguments

- m:

  Numeric vector of parameters.

- p:

  Numeric vector, \\1 - m\\.

- phi:

  Numeric vector of amplitudes.

- u:

  Numeric vector.

## Value

A double vector; for `sc_ellipj()`, a list with `sn`, `cn`, `dn` and
`ph`.

## Details

- `sc_ellipk()`, `sc_ellipe()`: complete integrals \\K(m)\\, \\E(m)\\.

- `sc_ellipkm1()`: \\K(1 - p)\\, accurate near \\m = 1\\.

- `sc_ellipkinc()`, `sc_ellipeinc()`: incomplete \\F(\phi \| m)\\ and
  \\E(\phi \| m)\\.

- `sc_ellipj()`: \\sn\\, \\cn\\, \\dn\\ and the amplitude \\\phi\\, as a
  named list, as SciPy returns a tuple.

Arguments are recycled, `NA` gives `NA`, and results take their
dimensions, or else their names, from the arguments as base R arithmetic
does; see
[`sc_seterr()`](https://pedrobtz.github.io/zuspecial/reference/errstate.md)
for the conditions the kernels raise.

## Windows

R on Windows is built with Rtools, whose C library (mingw-w64 v11)
computes [`sin()`](https://rdrr.io/r/base/Trig.html) and
[`cos()`](https://rdrr.io/r/base/Trig.html) with x87 argument reduction.
Near a zero of the cosine it loses relative accuracy, and
`sc_ellipj(u, 0)`, which is `cos(u)` exactly, inherits that for `u` near
`pi / 2` on Windows only.

## See also

<https://docs.scipy.org/doc/scipy/reference/special.html#elliptic-functions-and-integrals>

## Examples

``` r
sc_ellipk(c(0, 0.5, 0.9))
#> [1] 1.570796 1.854075 2.578092
sc_ellipkinc(pi / 4, 0.5)
#> [1] 0.8260179
sc_ellipj(1, 0.5)
#> $sn
#> [1] 0.8030018
#> 
#> $cn
#> [1] 0.5959766
#> 
#> $dn
#> [1] 0.823161
#> 
#> $ph
#> [1] 0.9323151
#> 
```

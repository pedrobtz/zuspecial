# Spherical Bessel functions

The spherical Bessel functions of integer order, or their derivatives,
for real or complex argument, as `scipy.special`'s `spherical_jn()` and
siblings compute them.

## Usage

``` r
sc_spherical_jn(n, z, derivative = FALSE)

sc_spherical_yn(n, z, derivative = FALSE)

sc_spherical_in(n, z, derivative = FALSE)

sc_spherical_kn(n, z, derivative = FALSE)
```

## Arguments

- n:

  Whole numbers within integer range, the orders.

- z:

  Numeric or complex vector of arguments.

- derivative:

  `TRUE` for the derivative with respect to `z`, `FALSE` (the default)
  for the function itself.

## Value

A double vector, or a complex vector for complex `z`.

## Details

- `sc_spherical_jn()`, `sc_spherical_yn()`: \\j_n(z)\\ and \\y_n(z)\\.

- `sc_spherical_in()`, `sc_spherical_kn()`: the modified functions
  \\i_n(z)\\ and \\k_n(z)\\.

Arguments are recycled, `NA` gives `NA`, and the result takes its
dimensions, or else its names, from the arguments as base R arithmetic
does; see
[`sc_seterr()`](https://pedrobtz.github.io/zuspecial/reference/errstate.md)
for the conditions the kernels raise.

## See also

<https://docs.scipy.org/doc/scipy/reference/generated/scipy.special.spherical_jn.html>

## Examples

``` r
sc_spherical_jn(0:3, 1.5)
#> [1] 0.66499666 0.39617297 0.12734928 0.02832464
sc_spherical_jn(1, 1.5, derivative = TRUE)
#> [1] 0.136766
sc_spherical_kn(2, 1 + 1i)
#> [1] -1.415258-0.7370441i
```

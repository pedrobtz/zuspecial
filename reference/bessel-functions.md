# Bessel and Hankel functions

Cylindrical Bessel functions of real order and real or complex argument,
with `scipy.special`'s names and argument order: order first, argument
second. Base R's [`besselJ()`](https://rdrr.io/r/base/Bessel.html) and
siblings take them the other way round and accept only real arguments.

## Usage

``` r
sc_jv(v, z)

sc_yv(v, z)

sc_iv(v, z)

sc_kv(v, z)

sc_jve(v, z)

sc_yve(v, z)

sc_ive(v, z)

sc_kve(v, z)

sc_hankel1(v, z)

sc_hankel2(v, z)

sc_hankel1e(v, z)

sc_hankel2e(v, z)

sc_j0(x)

sc_j1(x)

sc_y0(x)

sc_y1(x)

sc_i0(x)

sc_i0e(x)

sc_i1(x)

sc_i1e(x)

sc_k0(x)

sc_k0e(x)

sc_k1(x)

sc_k1e(x)
```

## Arguments

- v:

  Numeric vector of orders.

- z:

  Numeric or complex vector of arguments.

- x:

  Numeric vector.

## Value

A double vector, or a complex vector for complex `z` (always for the
Hankel functions).

## Details

- `sc_jv()`, `sc_yv()`, `sc_iv()`, `sc_kv()`: \\J_v(z)\\, \\Y_v(z)\\,
  \\I_v(z)\\, \\K_v(z)\\. Base R: `besselJ(z, v)` and so on.

- `sc_jve()`, `sc_yve()`, `sc_ive()`, `sc_kve()`: the exponentially
  scaled forms, \\J_v(z) e^{-\|\Im z\|}\\, \\Y_v(z) e^{-\|\Im z\|}\\,
  \\I_v(z) e^{-\|\Re z\|}\\ and \\K_v(z) e^z\\. Base R: the
  `expon.scaled = TRUE` forms of
  [`besselI()`](https://rdrr.io/r/base/Bessel.html) and
  [`besselK()`](https://rdrr.io/r/base/Bessel.html).

- `sc_hankel1()`, `sc_hankel2()`: \\H^{(1)}\_v(z) = J_v(z) + i Y_v(z)\\
  and \\H^{(2)}\_v(z)\\; `sc_hankel1e()`, `sc_hankel2e()` scale them by
  \\e^{\mp iz}\\. SciPy defines them for complex `z` only, so real input
  is treated as complex and the result is always complex.

- `sc_j0()`, `sc_j1()`, `sc_y0()`, `sc_y1()`, `sc_i0()`, `sc_i0e()`,
  `sc_i1()`, `sc_i1e()`, `sc_k0()`, `sc_k0e()`, `sc_k1()`, `sc_k1e()`:
  orders 0 and 1 for real `x`, faster than the general functions.

A complex `z` takes the complex path and returns complex; a real `z`
stays real, so `sc_jv(0.5, -1)` is `NaN` while `sc_jv(0.5, -1+0i)` is
complex, as in SciPy. The order `v` must be real. Arguments are
recycled, `NA` gives `NA`, and the result takes its dimensions, or else
its names, from the arguments as base R arithmetic does; see
[`sc_seterr()`](https://pedrobtz.github.io/zuspecial/reference/errstate.md)
for the conditions the kernels raise.

## Windows

R on Windows is built with Rtools, whose C library (mingw-w64 v11)
evaluates [`sin()`](https://rdrr.io/r/base/Trig.html) and
[`cos()`](https://rdrr.io/r/base/Trig.html) inaccurately for arguments
beyond about `1e5`, as base R's own
[`sin()`](https://rdrr.io/r/base/Trig.html) shows there. Arguments that
large are correspondingly inaccurate on Windows only.

## See also

<https://docs.scipy.org/doc/scipy/reference/special.html#bessel-functions>

## Examples

``` r
sc_jv(c(0, 1, 2.5), 3)
#> [1] -0.260052  0.339059  0.412710
sc_jv(0.5, -1)
#> [1] NaN
sc_jv(0.5, -1 + 0i)
#> [1] 5.551115e-17+0.6713967i
sc_kve(1, 50)
#> [1] 0.1785666
sc_hankel1(0, 2)
#> [1] 0.2238908+0.5103757i
sc_j0(c(0, 2.405))
#> [1]  1.0000e+00 -9.0558e-05
```

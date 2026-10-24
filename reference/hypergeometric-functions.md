# Hypergeometric functions

The confluent and Gauss hypergeometric functions, with the kernels
`scipy.special` uses (Boost.Math for real `hyp1f1`, as in SciPy).

## Usage

``` r
sc_hyp0f1(v, z)

sc_hyp1f1(a, b, x)

sc_hyp2f1(a, b, c, z)

sc_hyperu(a, b, x)
```

## Arguments

- v, a, b, c:

  Numeric vectors of parameters.

- z, x:

  Numeric vector; complex too, except for `sc_hyperu()`.

## Value

A double vector, or a complex vector for complex input.

## Details

- `sc_hyp0f1()`: \\{}\_0F_1(;v;z)\\, complex.

- `sc_hyp1f1()`: Kummer's \\{}\_1F_1(a;b;x)\\, complex `x`.

- `sc_hyp2f1()`: the Gauss \\{}\_2F_1(a,b;c;z)\\, complex `z`.

- `sc_hyperu()`: Tricomi's \\U(a, b, x)\\ for real `x >= 0`.

Only the last argument may be complex; the parameters are real.
Arguments are recycled, `NA` gives `NA`, and the result takes its
dimensions, or else its names, from the arguments as base R arithmetic
does; see
[`sc_seterr()`](https://pedrobtz.github.io/zuspecial/reference/errstate.md)
for the conditions the kernels raise.

## Branch cuts

`sc_hyp2f1()` has a branch cut on the real axis from 1 to infinity, as
in SciPy. `sc_hyp0f1()` and `sc_hyp1f1()` are entire in `z`.

## Other packages

In `gsl`, for real arguments: `hyperg_0F1()`, `hyperg_1F1()`,
`hyperg_2F1()` and `hyperg_U()`. In `hypergeo`: `hypergeo(A, B, C, z)`,
the Gauss function for complex `z`.

## See also

<https://docs.scipy.org/doc/scipy/reference/special.html#hypergeometric-functions>

## Examples

``` r
sc_hyp0f1(0.5, 1)
#> [1] 3.762196
sc_hyp1f1(1, 2, c(0.5, 1 + 1i))
#> [1] 1.297443+0.0000000i 1.378025+0.9093307i
sc_hyp2f1(1, 1, 2, 0.5)
#> [1] 1.386294
sc_hyperu(1, 2, 3)
#> [1] 0.3333333
```

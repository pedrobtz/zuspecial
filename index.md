# zuspecial

## Overview

R’s special functions are scattered. Base R has the gamma function and
Bessel functions of real argument; complex Bessel functions,
hypergeometric functions, elliptic integrals and the Lambert W function
each live in their own package, or in `gsl`, which needs the GNU
Scientific Library installed. And when a model is written in Python and
checked in R, or the other way round, two libraries that disagree in the
last digits are a needless source of doubt.

zuspecial gives R the special functions of
[`scipy.special`](https://docs.scipy.org/doc/scipy/reference/special.html),
computed by the same C++ kernels: [xsf](https://github.com/scipy/xsf),
the library SciPy’s special functions are built from, at the commit
SciPy 1.18.1 uses.

- **SciPy’s values.** Each function is tested against
  [xsref](https://github.com/scipy/xsref)’s mpmath reference tables,
  under xsf’s own tolerances, and against SciPy 1.18.1 itself, on Linux,
  macOS and Windows.
- **Real and complex arguments.** Bessel, Hankel, Airy, gamma, error,
  exponential-integral, hypergeometric and zeta functions take complex
  arguments where SciPy does.
- **SciPy’s names and argument order.** `sc_jv(v, z)` is
  `scipy.special.jv(v, z)`, so code translates line by line.
- **Ordinary R functions.** Vectorised and recycled, `NA`-aware, keeping
  names and dimensions; floating-point conditions follow SciPy’s
  `seterr()`, as warnings or errors when asked for.
- **A C interface.** Other packages can call the functions from compiled
  code through `LinkingTo: zuspecial`.

Nothing is needed at run time; Boost.Math headers, from the BH package,
are needed to build it.

## Installation

Install zuspecial from CRAN with:

``` r

install.packages("zuspecial")
```

or the development version from GitHub with:

``` r

# install.packages("pak")
pak::pak("pedrobtz/zuspecial")
```

## Usage

``` r

library(zuspecial)
```

Functions are vectorised, and take complex arguments where SciPy does:

``` r

sc_gamma(c(0.5, 5))
#> [1]  1.772454 24.000000
sc_gamma(1 + 1i)
#> [1] 0.4980157-0.1549498i
```

Arguments come in SciPy’s order, the order first for the Bessel
functions, where base R’s
[`besselJ()`](https://rdrr.io/r/base/Bessel.html) puts it second:

``` r

sc_jv(2.5, 3)
#> [1] 0.41271
besselJ(3, 2.5)
#> [1] 0.41271
```

As in SciPy, the type of the argument picks the result: the Bessel
function of order 0.5 at -1 is `NaN` for a real `-1`, and a complex
number for `-1+0i`:

``` r

sc_jv(0.5, -1)
#> [1] NaN
sc_jv(0.5, -1 + 0i)
#> [1] 5.551115e-17+0.6713967i
```

Poles, overflow and loss of precision are silent by default, as in
SciPy, and can be turned into warnings or errors:

``` r

sc_gamma(-1)
#> [1] NaN
sc_errstate(sc_gamma(-1), singular = "warn")
#> Warning in sc_gamma(-1): sc_gamma: singular in 1 element, first at index 1.
#> [1] NaN
```

Functions that return several values in SciPy return a named list:

``` r

str(sc_airy(1))
#> List of 4
#>  $ ai : num 0.135
#>  $ aip: num -0.159
#>  $ bi : num 1.21
#>  $ bip: num 0.932
```

Every function is `sc_` followed by its name in `scipy.special`, the
alias SciPy’s own documentation uses (`import scipy.special as sc`).

## Learn more

- [Translating from
  scipy.special](https://pedrobtz.github.io/zuspecial/articles/scipy.html):
  names, argument types, error handling, multi-output functions, the C
  interface, and the few places zuspecial differs.
- The [reference
  index](https://pedrobtz.github.io/zuspecial/reference/), by family.
- [`zuspecial_info()`](https://pedrobtz.github.io/zuspecial/reference/zuspecial_info.md)
  for the versions and the table of functions.

## Acknowledgements

The kernels are SciPy’s [xsf](https://github.com/scipy/xsf), with its
bundled Cephes, AMOS, specfun, Faddeeva and qd code, and Boost.Math for
the functions SciPy evaluates with it. The reference values come from
[xsref](https://github.com/scipy/xsref). zuspecial is also checked
against the `gsl`, `Bessel`, `hypergeo`, `lamW`, `expint` and `Rmpfr`
packages.

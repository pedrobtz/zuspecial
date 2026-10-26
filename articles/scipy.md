# Translating from scipy.special

zuspecial evaluates `scipy.special`’s functions with the C++ kernels
SciPy itself uses: [xsf](https://github.com/scipy/xsf) at the commit
SciPy 1.18.1 vendors, and Boost.Math for the six functions SciPy
evaluates with it. This article is for readers who know `scipy.special`
and want to move code between the two: what carries over unchanged, what
R does differently, and the few places zuspecial departs from SciPy on
purpose.

``` r

library(zuspecial)
```

## Names and arguments

Every function is `sc_` followed by its SciPy name, and takes SciPy’s
arguments in SciPy’s order. A line of Python

``` python
import scipy.special as sc
sc.gammainc(2, 3)
```

becomes

``` r

sc_gammainc(2, 3)
#> [1] 0.8008517
```

Base R often puts the same arguments the other way round.
[`pgamma()`](https://rdrr.io/r/stats/GammaDist.html) is the regularised
lower incomplete gamma function too, with the argument first and the
shape second:

``` r

pgamma(3, 2)
#> [1] 0.8008517
```

The same holds for the Bessel functions: `sc_jv(v, z)` against
`besselJ(x, nu)`. Each help page names the base R and `gsl`
counterparts.

Two functions take an argument SciPy spells as a separate keyword or
function, both as in SciPy’s Python wrappers: `sc_zeta(x, q = NULL)` is
the Riemann zeta function without `q` and the Hurwitz zeta function with
it, and the spherical Bessel functions take `derivative = FALSE`.

``` r

sc_zeta(2)
#> [1] 1.644934
sc_zeta(2, q = 2)
#> [1] 0.6449341
sc_spherical_jn(1, 2, derivative = TRUE)
#> [1] 0.01925094
```

`zuspecial_info()$functions` lists the 82 functions with their backend
and whether they take complex arguments.

## Real and complex arguments

A function SciPy registers for complex input takes the complex path when
its argument is of type `complex`, and returns `complex`. A real
argument stays on the real path and returns `double`, so, as in SciPy,
there is no automatic promotion when the real result is undefined:

``` r

sc_jv(0.5, -1)
#> [1] NaN
sc_jv(0.5, -1 + 0i)
#> [1] 5.551115e-17+0.6713967i
```

R’s [`c()`](https://rdrr.io/r/base/c.html) makes a whole vector complex
once one element is, so mixing the two in one vector sends every element
down the complex path. Keep real and complex inputs in separate vectors
when the distinction matters.

Integer arguments (`n` in
[`sc_expn()`](https://pedrobtz.github.io/zuspecial/reference/exponential-integrals.md)
and the spherical Bessel functions, `k` in
[`sc_lambertw()`](https://pedrobtz.github.io/zuspecial/reference/zeta-functions.md))
must hold whole numbers within R’s integer range. Integer and logical
vectors are converted to double; character, factor, list and classed
input (dates, difftimes) is refused.

## Vectorisation

zuspecial’s functions are vectorised like R’s arithmetic, not broadcast
like NumPy’s ufuncs:

- Length-one arguments recycle against the others. Any other mismatch in
  length is an error of class `zuspecial_recycle_error`, never a
  warning: a silently recycled parameter vector is a bug.

- Arrays are not broadcast. Where NumPy turns a `(2, 1)` array and a
  `(3,)` array into a `(2, 3)` result, R needs
  [`outer()`](https://rdrr.io/r/base/outer.html):

  ``` r

  outer(0:1, 1:3, sc_jv)
  #>           [,1]      [,2]      [,3]
  #> [1,] 0.7651977 0.2238908 -0.260052
  #> [2,] 0.4400506 0.5767248  0.339059
  ```

- The result keeps `dim` and `dimnames` from the first full-length
  argument that has them, otherwise `names`, as base R does:

  ``` r

  sc_gamma(c(a = 0.5, b = 5))
  #>         a         b 
  #>  1.772454 24.000000
  ```

## Missing values

R has `NA` as well as `NaN`, and keeps them apart. `NA` in any argument
gives `NA` in that element, decided before the kernel is called; `NaN`
goes to the kernel and gives what SciPy gives, normally `NaN`:

``` r

sc_gamma(c(NA, NaN, 3))
#> [1]  NA NaN   2
```

A complex element is `NA` when either part is. A multi-output function
returns `NA` in every output for that element.

## Floating-point conditions

xsf reports a pole, an overflow or a loss of precision through SciPy’s
ten error codes: `singular`, `underflow`, `overflow`, `slow`, `loss`,
`no_result`, `domain`, `arg`, `other` and `memory`. As in SciPy, every
code is ignored by default except `memory`:

``` r

sc_geterr()
#>  singular underflow  overflow      slow      loss no_result    domain       arg 
#>  "ignore"  "ignore"  "ignore"  "ignore"  "ignore"  "ignore"  "ignore"  "ignore" 
#>     other    memory 
#>  "ignore"   "raise"
```

[`sc_seterr()`](https://pedrobtz.github.io/zuspecial/reference/errstate.md)
and
[`sc_errstate()`](https://pedrobtz.github.io/zuspecial/reference/errstate.md)
are `scipy.special.seterr()` and `scipy.special.errstate()`.
[`sc_errstate()`](https://pedrobtz.github.io/zuspecial/reference/errstate.md)
takes the expression first, where Python uses a `with` block:

``` python
with sc.errstate(singular="raise"):
    sc.gamma(-1)
```

``` r

tryCatch(
  sc_errstate(sc_gamma(-1), singular = "raise"),
  zuspecial_singular_error = function(e) conditionMessage(e)
)
#> [1] "sc_gamma: singular in 1 element, first at index 1."
```

Three things differ from SciPy:

- A code is signalled once per call, with the number of elements that
  raised it and the index of the first, not once per element.
- Only the codes the kernels report are signalled. SciPy also turns the
  processor’s floating-point flags into codes, so it raises a few that
  zuspecial does not, such as `overflow` for `exp1(800)`. The values are
  the same.
- Warnings and errors are R conditions with classes
  (`zuspecial_warning`, `zuspecial_<code>`, `zuspecial_error`,
  `zuspecial_<code>_error`), for
  [`tryCatch()`](https://rdrr.io/r/base/conditions.html) and
  [`withCallingHandlers()`](https://rdrr.io/r/base/conditions.html).

The state is stored in the option `zuspecial.errstate`, so parallel R
workers start from the defaults rather than inheriting the parent’s.

## Functions with several outputs

Where SciPy returns a tuple, zuspecial returns a named list, with the
names SciPy’s documentation uses:

``` python
ai, aip, bi, bip = sc.airy(1)
```

``` r

airy <- sc_airy(1)
airy$bi
#> [1] 1.207424
names(sc_ellipj(0.5, 0.3))
#> [1] "sn" "cn" "dn" "ph"
```

## From compiled code

Packages that need these functions from C or C++ can call 32 of them,
the complex `jv` among them, through a registered table, without linking
to xsf or Boost. Add zuspecial to `Imports` and `LinkingTo` in
`DESCRIPTION`, import something from it in `NAMESPACE` so that its
namespace loads (for example `importFrom(zuspecial, zuspecial_info)`),
and then:

``` c
#include <R.h>
#include <R_ext/Rdynload.h>
#define ZUSPECIAL_DEFINE_API_GET
#include <zuspecial.h>

double gamma_or_nan(double x) {
  const zuspecial_api *api = zuspecial_api_get();
  int code;
  double value = api->gamma(x, &code);
  return code == 0 ? value : R_NaN;
}
```

Each member evaluates one element, exactly as the R function does, and
reports the lowest-numbered error code the evaluation raised in `code`
(0 when none).
[`sc_seterr()`](https://pedrobtz.github.io/zuspecial/reference/errstate.md)
does not apply: the caller decides what a code means. The members are
reentrant and safe from any thread. The header,
`inst/include/zuspecial.h`, documents the members and how the table is
versioned.

## Where zuspecial differs from SciPy

- **[`sc_expn()`](https://pedrobtz.github.io/zuspecial/reference/exponential-integrals.md)
  with a non-whole `n`.** SciPy truncates it with a `RuntimeWarning`;
  zuspecial refuses it. A `NaN` `n` gives `NaN` in both.
- **Arguments beyond about 1e5 on Windows.** R on Windows is built with
  Rtools, whose C library (mingw-w64 v11) evaluates
  [`sin()`](https://rdrr.io/r/base/Trig.html) and
  [`cos()`](https://rdrr.io/r/base/Trig.html) inaccurately for large
  arguments, as base R’s own [`sin()`](https://rdrr.io/r/base/Trig.html)
  shows. Kernels that take the sine or cosine of such a value are less
  accurate there than on Linux and macOS. The affected help pages have a
  “Windows” section.
- **Functions not yet included.** Version 0.1.0 covers the gamma, beta,
  error, exponential-integral, Bessel, Airy, hypergeometric, elliptic,
  zeta and Struve families. The Carlson elliptic integrals wait for a
  SciPy release whose xsf has them; Kelvin, Mathieu, spheroidal,
  parabolic-cylinder, Fresnel, Legendre and the orthogonal polynomials
  come later. Single precision, arbitrary precision and the distribution
  families of `scipy.stats` are out of scope.

## How the values are checked

Every function with a table in [xsref](https://github.com/scipy/xsref),
SciPy’s mpmath reference collection, is checked against it on Linux,
macOS and Windows, with xsf’s own error metric and tolerances. The
functions are also compared with values computed by SciPy 1.18.1 on each
platform, and with the `gsl`, `Bessel`, `hypergeo`, `lamW`, `expint` and
`Rmpfr` packages.
[`zuspecial_info()`](https://pedrobtz.github.io/zuspecial/reference/zuspecial_info.md)
reports the xsf, SciPy, xsref and Boost versions the installed package
was built from.

## Speed

The R layer adds about 10 % to the kernel’s time on 10 000 elements and
nothing measurable beyond 100 000. Against base R on real input,
[`sc_gamma()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md)
and
[`sc_gammaln()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md)
are at least as fast as [`gamma()`](https://rdrr.io/r/base/Special.html)
and [`lgamma()`](https://rdrr.io/r/base/Special.html), and
[`sc_jv()`](https://pedrobtz.github.io/zuspecial/reference/bessel-functions.md)
takes about 2.7 times as long as
[`besselJ()`](https://rdrr.io/r/base/Bessel.html): the time is xsf’s
kernel, which is also SciPy’s. On complex input
[`sc_jv()`](https://pedrobtz.github.io/zuspecial/reference/bessel-functions.md)
is several times faster than
[`Bessel::BesselJ()`](https://rdrr.io/pkg/Bessel/man/Bessel.html).
`tools/run-benchmarks` in the source repository reproduces these
figures.

# Versions and functions

Reports what this build of zuspecial evaluates with: the vendored xsf
commit, the SciPy release whose `subprojects/xsf` pin it is, the xsref
commit whose mpmath reference tables the tests use, the compiler, and
the table of exported functions.

## Usage

``` r
zuspecial_info()
```

## Value

A list with `xsf_commit`, `scipy_version`, `xsref_commit`, `compiler`
and `functions`, a data frame with one row per exported function:
`r_name`, `scipy_name`, `backend` (the library that evaluates it) and
`complex` (whether it takes complex arguments).

## Examples

``` r
info <- zuspecial_info()
info$scipy_version
#> [1] "1.18.1"
head(info$functions)
#>        r_name scipy_name backend complex
#> 1    sc_gamma      gamma     xsf    TRUE
#> 2  sc_gammaln    gammaln     xsf   FALSE
#> 3 sc_loggamma   loggamma     xsf    TRUE
#> 4   sc_rgamma     rgamma     xsf    TRUE
#> 5 sc_gammasgn   gammasgn     xsf   FALSE
#> 6      sc_psi        psi     xsf    TRUE
```

# zuspecial 0.0.0.9000

* Gamma and beta functions: `sc_gamma()`, `sc_gammaln()`, `sc_loggamma()`,
  `sc_rgamma()`, `sc_gammasgn()`, `sc_psi()`, `sc_beta()`, `sc_betaln()`,
  `sc_binom()` and `sc_poch()`, with complex arguments where SciPy has them.

* Error functions: `sc_erf()`, `sc_erfc()`, `sc_erfcx()`, `sc_erfi()`,
  `sc_erfcinv()`, `sc_dawsn()`, the Faddeeva function `sc_wofz()` and
  `sc_voigt_profile()`.

* Exponential integrals: `sc_exp1()`, `sc_expi()` and `sc_expn()`.

* Incomplete gamma and beta functions and their inverses: `sc_gammainc()`,
  `sc_gammaincc()`, `sc_gammaincinv()`, `sc_gammainccinv()`, `sc_betainc()`,
  `sc_betaincc()`, `sc_betaincinv()` and `sc_betainccinv()`. The incomplete
  beta functions use Boost.Math, from the BH package, as SciPy does.

* Normal distribution functions: `sc_ndtr()`, `sc_log_ndtr()`, `sc_ndtri()`,
  `sc_ndtri_exp()`, `sc_owens_t()`, and `sc_erfinv()`.

* `sc_geterr()`, `sc_seterr()` and `sc_errstate()` choose whether each kind
  of floating-point condition is ignored, warns or raises, after
  `scipy.special`.

* `zuspecial_info()` reports the vendored xsf commit, the SciPy release it
  matches, the compiler and the function table.

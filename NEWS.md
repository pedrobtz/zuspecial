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

* Bessel functions: `sc_jv()`, `sc_yv()`, `sc_iv()`, `sc_kv()` and their
  exponentially scaled forms `sc_jve()`, `sc_yve()`, `sc_ive()`, `sc_kve()`,
  for real or complex arguments; the Hankel functions `sc_hankel1()`,
  `sc_hankel2()`, `sc_hankel1e()`, `sc_hankel2e()`; and the fixed-order
  `sc_j0()` to `sc_k1e()`.

* Spherical Bessel functions `sc_spherical_jn()`, `sc_spherical_yn()`,
  `sc_spherical_in()`, `sc_spherical_kn()`, with `derivative`.

* Airy functions `sc_airy()` and `sc_airye()`, returning `ai`, `aip`, `bi`
  and `bip` as a named list.

* Hypergeometric functions `sc_hyp0f1()`, `sc_hyp1f1()`, `sc_hyp2f1()` and
  `sc_hyperu()`; elliptic integrals `sc_ellipk()`, `sc_ellipkm1()`,
  `sc_ellipkinc()`, `sc_ellipe()`, `sc_ellipeinc()` and the Jacobi functions
  `sc_ellipj()`; `sc_zeta()` (Riemann and Hurwitz), `sc_zetac()`,
  `sc_lambertw()`, `sc_wrightomega()`, `sc_spence()`, `sc_struve()` and
  `sc_modstruve()`. The Carlson elliptic integrals wait for a SciPy release
  whose xsf has them.

* Normal distribution functions: `sc_ndtr()`, `sc_log_ndtr()`, `sc_ndtri()`,
  `sc_ndtri_exp()`, `sc_owens_t()`, and `sc_erfinv()`. `sc_ndtri()`'s argument is `y`,
  as in SciPy's `ndtri(y)`.

* `sc_geterr()`, `sc_seterr()` and `sc_errstate()` choose whether each kind
  of floating-point condition is ignored, warns or raises, after
  `scipy.special`.

* A registered C interface, `zuspecial_api_v1` (`inst/include/zuspecial.h`),
  lets other packages call 32 of the functions from C through `LinkingTo:`,
  each returning its value and the error code it raised.

* `zuspecial_info()` reports the vendored xsf commit, the SciPy release it
  matches, the compiler and the function table.

* Each help page names the counterparts in base R and in `gsl`, `Bessel`,
  `hypergeo`, `lamW` and `expint`, and the branch cuts SciPy documents. A
  new article, "Translating from scipy.special", covers names, argument
  types, error handling, multi-output functions, the C interface and where
  zuspecial differs from SciPy.

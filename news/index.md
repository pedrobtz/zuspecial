# Changelog

## zuspecial 0.0.0.9000

- Gamma and beta functions:
  [`sc_gamma()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md),
  [`sc_gammaln()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md),
  [`sc_loggamma()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md),
  [`sc_rgamma()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md),
  [`sc_gammasgn()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md),
  [`sc_psi()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md),
  [`sc_beta()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md),
  [`sc_betaln()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md),
  [`sc_binom()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md)
  and
  [`sc_poch()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md),
  with complex arguments where SciPy has them.

- Error functions:
  [`sc_erf()`](https://pedrobtz.github.io/zuspecial/reference/error-functions.md),
  [`sc_erfc()`](https://pedrobtz.github.io/zuspecial/reference/error-functions.md),
  [`sc_erfcx()`](https://pedrobtz.github.io/zuspecial/reference/error-functions.md),
  [`sc_erfi()`](https://pedrobtz.github.io/zuspecial/reference/error-functions.md),
  [`sc_erfcinv()`](https://pedrobtz.github.io/zuspecial/reference/error-functions.md),
  [`sc_dawsn()`](https://pedrobtz.github.io/zuspecial/reference/error-functions.md),
  the Faddeeva function
  [`sc_wofz()`](https://pedrobtz.github.io/zuspecial/reference/error-functions.md)
  and
  [`sc_voigt_profile()`](https://pedrobtz.github.io/zuspecial/reference/error-functions.md).

- Exponential integrals:
  [`sc_exp1()`](https://pedrobtz.github.io/zuspecial/reference/exponential-integrals.md),
  [`sc_expi()`](https://pedrobtz.github.io/zuspecial/reference/exponential-integrals.md)
  and
  [`sc_expn()`](https://pedrobtz.github.io/zuspecial/reference/exponential-integrals.md).

- Incomplete gamma and beta functions and their inverses:
  [`sc_gammainc()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md),
  [`sc_gammaincc()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md),
  [`sc_gammaincinv()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md),
  [`sc_gammainccinv()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md),
  [`sc_betainc()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md),
  [`sc_betaincc()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md),
  [`sc_betaincinv()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md)
  and
  [`sc_betainccinv()`](https://pedrobtz.github.io/zuspecial/reference/gamma-functions.md).
  The incomplete beta functions use Boost.Math, from the BH package, as
  SciPy does.

- Bessel functions:
  [`sc_jv()`](https://pedrobtz.github.io/zuspecial/reference/bessel-functions.md),
  [`sc_yv()`](https://pedrobtz.github.io/zuspecial/reference/bessel-functions.md),
  [`sc_iv()`](https://pedrobtz.github.io/zuspecial/reference/bessel-functions.md),
  [`sc_kv()`](https://pedrobtz.github.io/zuspecial/reference/bessel-functions.md)
  and their exponentially scaled forms
  [`sc_jve()`](https://pedrobtz.github.io/zuspecial/reference/bessel-functions.md),
  [`sc_yve()`](https://pedrobtz.github.io/zuspecial/reference/bessel-functions.md),
  [`sc_ive()`](https://pedrobtz.github.io/zuspecial/reference/bessel-functions.md),
  [`sc_kve()`](https://pedrobtz.github.io/zuspecial/reference/bessel-functions.md),
  for real or complex arguments; the Hankel functions
  [`sc_hankel1()`](https://pedrobtz.github.io/zuspecial/reference/bessel-functions.md),
  [`sc_hankel2()`](https://pedrobtz.github.io/zuspecial/reference/bessel-functions.md),
  [`sc_hankel1e()`](https://pedrobtz.github.io/zuspecial/reference/bessel-functions.md),
  [`sc_hankel2e()`](https://pedrobtz.github.io/zuspecial/reference/bessel-functions.md);
  and the fixed-order
  [`sc_j0()`](https://pedrobtz.github.io/zuspecial/reference/bessel-functions.md)
  to
  [`sc_k1e()`](https://pedrobtz.github.io/zuspecial/reference/bessel-functions.md).

- Spherical Bessel functions
  [`sc_spherical_jn()`](https://pedrobtz.github.io/zuspecial/reference/spherical-bessel.md),
  [`sc_spherical_yn()`](https://pedrobtz.github.io/zuspecial/reference/spherical-bessel.md),
  [`sc_spherical_in()`](https://pedrobtz.github.io/zuspecial/reference/spherical-bessel.md),
  [`sc_spherical_kn()`](https://pedrobtz.github.io/zuspecial/reference/spherical-bessel.md),
  with `derivative`.

- Airy functions
  [`sc_airy()`](https://pedrobtz.github.io/zuspecial/reference/airy-functions.md)
  and
  [`sc_airye()`](https://pedrobtz.github.io/zuspecial/reference/airy-functions.md),
  returning `ai`, `aip`, `bi` and `bip` as a named list.

- Hypergeometric functions
  [`sc_hyp0f1()`](https://pedrobtz.github.io/zuspecial/reference/hypergeometric-functions.md),
  [`sc_hyp1f1()`](https://pedrobtz.github.io/zuspecial/reference/hypergeometric-functions.md),
  [`sc_hyp2f1()`](https://pedrobtz.github.io/zuspecial/reference/hypergeometric-functions.md)
  and
  [`sc_hyperu()`](https://pedrobtz.github.io/zuspecial/reference/hypergeometric-functions.md);
  elliptic integrals
  [`sc_ellipk()`](https://pedrobtz.github.io/zuspecial/reference/elliptic-functions.md),
  [`sc_ellipkm1()`](https://pedrobtz.github.io/zuspecial/reference/elliptic-functions.md),
  [`sc_ellipkinc()`](https://pedrobtz.github.io/zuspecial/reference/elliptic-functions.md),
  [`sc_ellipe()`](https://pedrobtz.github.io/zuspecial/reference/elliptic-functions.md),
  [`sc_ellipeinc()`](https://pedrobtz.github.io/zuspecial/reference/elliptic-functions.md)
  and the Jacobi functions
  [`sc_ellipj()`](https://pedrobtz.github.io/zuspecial/reference/elliptic-functions.md);
  [`sc_zeta()`](https://pedrobtz.github.io/zuspecial/reference/zeta-functions.md)
  (Riemann and Hurwitz),
  [`sc_zetac()`](https://pedrobtz.github.io/zuspecial/reference/zeta-functions.md),
  [`sc_lambertw()`](https://pedrobtz.github.io/zuspecial/reference/zeta-functions.md),
  [`sc_wrightomega()`](https://pedrobtz.github.io/zuspecial/reference/zeta-functions.md),
  [`sc_spence()`](https://pedrobtz.github.io/zuspecial/reference/zeta-functions.md),
  [`sc_struve()`](https://pedrobtz.github.io/zuspecial/reference/zeta-functions.md)
  and
  [`sc_modstruve()`](https://pedrobtz.github.io/zuspecial/reference/zeta-functions.md).
  The Carlson elliptic integrals wait for a SciPy release whose xsf has
  them.

- Normal distribution functions:
  [`sc_ndtr()`](https://pedrobtz.github.io/zuspecial/reference/normal-functions.md),
  [`sc_log_ndtr()`](https://pedrobtz.github.io/zuspecial/reference/normal-functions.md),
  [`sc_ndtri()`](https://pedrobtz.github.io/zuspecial/reference/normal-functions.md),
  [`sc_ndtri_exp()`](https://pedrobtz.github.io/zuspecial/reference/normal-functions.md),
  [`sc_owens_t()`](https://pedrobtz.github.io/zuspecial/reference/normal-functions.md),
  and
  [`sc_erfinv()`](https://pedrobtz.github.io/zuspecial/reference/error-functions.md).

- [`sc_geterr()`](https://pedrobtz.github.io/zuspecial/reference/errstate.md),
  [`sc_seterr()`](https://pedrobtz.github.io/zuspecial/reference/errstate.md)
  and
  [`sc_errstate()`](https://pedrobtz.github.io/zuspecial/reference/errstate.md)
  choose whether each kind of floating-point condition is ignored, warns
  or raises, after `scipy.special`.

- [`zuspecial_info()`](https://pedrobtz.github.io/zuspecial/reference/zuspecial_info.md)
  reports the vendored xsf commit, the SciPy release it matches, the
  compiler and the function table.

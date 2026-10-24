// Shim for the error functions and exponential integrals. Included only
// by zsp_shim.cpp.

#include <cmath>
#include <limits>

#include "xsf/cephes/erfinv.h"
#include "xsf/cephes/expn.h"
#include "xsf/cephes/ndtri.h"
#include "xsf/cephes/polevl.h"
#include "xsf/erf.h"
#include "xsf/expint.h"
#include "xsf/stats.h"

#include "zsp_complex.h"

extern "C" {

double zsp_erf_d(double x) noexcept { return xsf::erf(x); }
double zsp_erfc_d(double x) noexcept { return xsf::erfc(x); }
double zsp_erfcx_d(double x) noexcept { return xsf::erfcx(x); }
double zsp_erfi_d(double x) noexcept { return xsf::erfi(x); }
double zsp_erfcinv_d(double y) noexcept { return xsf::cephes::erfcinv(y); }
double zsp_dawsn_d(double x) noexcept { return xsf::dawsn(x); }
double zsp_exp1_d(double x) noexcept { return xsf::exp1(x); }
double zsp_expi_d(double x) noexcept { return xsf::expi(x); }

zsp_complex zsp_erf_c(zsp_complex z) noexcept {
  return zsp_from_std(xsf::erf(zsp_to_std(z)));
}
zsp_complex zsp_erfc_c(zsp_complex z) noexcept {
  return zsp_from_std(xsf::erfc(zsp_to_std(z)));
}
zsp_complex zsp_erfcx_c(zsp_complex z) noexcept {
  return zsp_from_std(xsf::erfcx(zsp_to_std(z)));
}
zsp_complex zsp_erfi_c(zsp_complex z) noexcept {
  return zsp_from_std(xsf::erfi(zsp_to_std(z)));
}
zsp_complex zsp_dawsn_c(zsp_complex z) noexcept {
  return zsp_from_std(xsf::dawsn(zsp_to_std(z)));
}
zsp_complex zsp_wofz_c(zsp_complex z) noexcept {
  return zsp_from_std(xsf::wofz(zsp_to_std(z)));
}
zsp_complex zsp_exp1_c(zsp_complex z) noexcept {
  return zsp_from_std(xsf::exp1(zsp_to_std(z)));
}
zsp_complex zsp_expi_c(zsp_complex z) noexcept {
  return zsp_from_std(xsf::expi(zsp_to_std(z)));
}

double zsp_voigt_profile_ddd(double x, double sigma, double gamma) noexcept {
  return xsf::voigt_profile(x, sigma, gamma);
}
double zsp_expn_id(int n, double x) noexcept { return xsf::cephes::expn(n, x); }

double zsp_ndtr_d(double x) noexcept { return xsf::ndtr(x); }
double zsp_log_ndtr_d(double x) noexcept { return xsf::log_ndtr(x); }
zsp_complex zsp_ndtr_c(zsp_complex z) noexcept {
  return zsp_from_std(xsf::ndtr(zsp_to_std(z)));
}
zsp_complex zsp_log_ndtr_c(zsp_complex z) noexcept {
  return zsp_from_std(xsf::log_ndtr(zsp_to_std(z)));
}
double zsp_ndtri_d(double p) noexcept { return xsf::ndtri(p); }
double zsp_owens_t_dd(double h, double a) noexcept {
  return xsf::owens_t(h, a);
}

// ndtri_exp: the inverse of log_ndtr. Not in xsf at the pinned commit; SciPy
// 1.18.1 implements it in Cython (scipy/special/_ndtri_exp.pxd, by Albert
// Steppi, distributed under the same licence as SciPy). Ported line for
// line, on xsf's cephes::ndtri, polevl and p1evl as SciPy calls them.
static double zsp_ndtri_exp_small_y(double y) {
  static const double P1[] = {
      4.05544892305962419923,      3.15251094599893866154e1,
      5.71628192246421288162e1,    4.40805073893200834700e1,
      1.46849561928858024014e1,    2.18663306850790267539,
      -1.40256079171354495875e-1,  -3.50424626827848203418e-2,
      -8.57456785154685413611e-4};
  static const double Q1[] = {
      1.57799883256466749731e1,    4.53907635128879210584e1,
      4.13172038254672030440e1,    1.50425385692907503408e1,
      2.50464946208309415979,      -1.42182922854787788574e-1,
      -3.80806407691578277194e-2,  -9.33259480895457427372e-4};
  static const double P2[] = {
      3.23774891776946035970,      6.91522889068984211695,
      3.93881025292474443415,      1.33303460815807542389,
      2.01485389549179081538e-1,   1.23716634817820021358e-2,
      3.01581553508235416007e-4,   2.65806974686737550832e-6,
      6.23974539184983293730e-9};
  static const double Q2[] = {
      6.02427039364742014255,      3.67983563856160859403,
      1.37702099489081330271,      2.16236993594496635890e-1,
      1.34204006088543189037e-2,   3.28014464682127739104e-4,
      2.89247864745380683936e-6,   6.79019408009981274425e-9};
  // sqrt(-2 * y) is faster and more precise but overflows when
  // y < -DBL_MAX * 0.5.
  double x = y >= -std::numeric_limits<double>::max() * 0.5
                 ? std::sqrt(-2 * y)
                 : 1.41421356237309504880 * std::sqrt(-y); // sqrt(2)
  double x0 = x - std::log(x) / x;
  double z = 1 / x;
  double x1 = x < 8.0
                  ? z * xsf::cephes::polevl(z, P1, 8) / xsf::cephes::p1evl(z, Q1, 8)
                  : z * xsf::cephes::polevl(z, P2, 8) / xsf::cephes::p1evl(z, Q2, 8);
  return x1 - x0;
}

double zsp_ndtri_exp_d(double y) noexcept {
  if (y < -std::numeric_limits<double>::max()) {
    return -std::numeric_limits<double>::infinity();
  } else if (y < -2.0) {
    return zsp_ndtri_exp_small_y(y);
  } else if (y > -0.14541345786885906) { // log1p(-exp(-2))
    return -xsf::cephes::ndtri(-std::expm1(y));
  } else {
    return xsf::cephes::ndtri(std::exp(y));
  }
}

} // extern "C"

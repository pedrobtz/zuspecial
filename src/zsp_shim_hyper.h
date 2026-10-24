// Shim for the hypergeometric, elliptic, zeta, Lambert W, Wright omega,
// Spence and Struve functions. Included only by zsp_shim.cpp.
//
// hyp0f1, hyperu and complex spence are ported from SciPy 1.18.1's Cython
// (scipy/special/_hyp0f1.pxd, _hypergeometric.pxd, _spence.pxd; (C) SciPy
// developers, BSD-3-Clause), which xsf at the pin lacks: line for line, on
// the same xsf kernels SciPy's wrappers call.

#include <cfloat>
#include <cmath>
#include <complex>
#include <limits>

#include "xsf/bessel.h"
#include "xsf/cephes/poch.h"
#include "xsf/cephes/spence.h"
#include "xsf/ellip.h"
#include "xsf/gamma.h"
#include "xsf/hyp2f1.h"
#include "xsf/lambertw.h"
#include "xsf/log.h"
#include "xsf/specfun.h"
#include "xsf/struve.h"
#include "xsf/trig.h"
#include "xsf/zeta.h"
#include "xsf/zlog1.h"

#include "zsp_complex.h"
#include "zsp_wright.h"

namespace {

const double zsp_nan = std::numeric_limits<double>::quiet_NaN();
const double zsp_inf = std::numeric_limits<double>::infinity();

// _hyp0f1.pxd: _hyp0f1_asy, for real z > 0 and large v (DLMF 10.41).
double hyp0f1_asy(double v, double z) {
  double arg = std::sqrt(z);
  double v1 = std::fabs(v - 1);
  double x = 2.0 * arg / v1;
  double p1 = std::sqrt(1.0 + x * x);
  double eta = p1 + std::log(x) - std::log1p(p1);
  double arg_exp_i = -0.5 * std::log(p1);
  arg_exp_i -= 0.5 * std::log(2.0 * M_PI * v1);
  arg_exp_i += xsf::gammaln(v);
  double gs = xsf::gammasgn(v);
  double arg_exp_k = arg_exp_i;
  arg_exp_i += v1 * eta;
  arg_exp_k -= v1 * eta;
  double pp = 1.0 / p1;
  double p2 = pp * pp;
  double p4 = p2 * p2;
  double p6 = p4 * p2;
  double u1 = (3.0 - 5.0 * p2) * pp / 24.0;
  double u2 = (81.0 - 462.0 * p2 + 385.0 * p4) * p2 / 1152.0;
  double u3 = (30375.0 - 369603.0 * p2 + 765765.0 * p4 - 425425.0 * p6) * pp *
              p2 / 414720.0;
  double u_corr_i = 1.0 + u1 / v1 + u2 / (v1 * v1) + u3 / (v1 * v1 * v1);
  double result =
      std::exp(arg_exp_i - xsf::xlogy(v1, arg)) * gs * u_corr_i;
  if (v - 1 < 0) {
    // DLMF 10.27.2: I_{-v} = I_{v} + (2/pi) sin(pi*v) K_v
    double u_corr_k = 1.0 - u1 / v1 + u2 / (v1 * v1) - u3 / (v1 * v1 * v1);
    result += std::exp(arg_exp_k + xsf::xlogy(v1, arg)) * gs * 2.0 *
              xsf::sinpi(v1) * u_corr_k;
  }
  return result;
}

// _hyp0f1.pxd: _hyp0f1_real.
double hyp0f1_real(double v, double z) {
  if (v <= 0.0 && v == std::floor(v)) {
    return zsp_nan;
  }
  if (z == 0.0 && v != 0.0) {
    return 1.0;
  }
  if (std::fabs(z) < 1e-6 * (1.0 + std::fabs(v))) {
    return 1.0 + z / v + z * z / (2.0 * v * (v + 1.0));
  }
  if (z > 0) {
    double arg = std::sqrt(z);
    double arg_exp = xsf::xlogy(1.0 - v, arg) + xsf::gammaln(v);
    double bess_val = xsf::cyl_bessel_i(v - 1, 2.0 * arg);
    if (arg_exp > std::log(DBL_MAX) || bess_val == 0 ||
        arg_exp < std::log(DBL_MIN) || std::isinf(bess_val)) {
      return hyp0f1_asy(v, z);
    }
    return std::exp(arg_exp) * xsf::gammasgn(v) * bess_val;
  }
  double arg = std::sqrt(-z);
  return std::pow(arg, 1.0 - v) * xsf::gamma(v) *
         xsf::cephes::jv(v - 1, 2 * arg);
}

// SciPy's zsqrt and zpow are NumPy's npy_csqrt and npy_cpow: see
// src/zsp_ccomplex.c.
std::complex<double> zsqrt(std::complex<double> z) {
  return zsp_to_std(zsp_csqrt(zsp_from_std(z)));
}
std::complex<double> zpow(std::complex<double> a, double b) {
  return zsp_to_std(zsp_cpow(zsp_from_std(a), zsp_from_std(b)));
}

// _hyp0f1.pxd: _hyp0f1_cmplx.
std::complex<double> hyp0f1_cmplx(double v, std::complex<double> z) {
  if (v <= 0.0 && v == std::floor(v)) {
    return std::complex<double>(zsp_nan, 0.0);
  }
  if (z.real() == 0.0 && z.imag() == 0.0 && v != 0.0) {
    return 1.0;
  }
  if (std::abs(z) < 1e-6 * (1.0 + std::fabs(v))) {
    // In this order, or it loses precision for v ~ -z << 1 (SciPy gh-6365).
    std::complex<double> t1 = 1.0 + z / v;
    std::complex<double> t2 = z * z / (2.0 * v * (v + 1.0));
    return t1 + t2;
  }
  std::complex<double> arg, r;
  if (z.real() > 0) {
    arg = zsqrt(z);
    r = xsf::cyl_bessel_i(v - 1.0, 2.0 * arg);
  } else {
    arg = zsqrt(-z);
    r = xsf::cyl_bessel_j(v - 1.0, 2.0 * arg);
  }
  return r * xsf::gamma(v) * zpow(arg, 1.0 - v);
}

// _hypergeometric.pxd: hyperu.
double hyperu(double a, double b, double x) {
  if (std::isnan(a) || std::isnan(b) || std::isnan(x)) {
    return zsp_nan;
  }
  if (x < 0.0) {
    xsf::set_error("hyperu", SF_ERROR_DOMAIN, nullptr);
    return zsp_nan;
  }
  if (x == 0.0) {
    if (b > 1.0) { // DLMF 13.2.16-18
      xsf::set_error("hyperu", SF_ERROR_SINGULAR, nullptr);
      return zsp_inf;
    }
    return xsf::cephes::poch(1.0 - b + a, -a); // DLMF 13.2.14-15, 13.2.19-21
  }
  if (b == 1 && x < 1 && -0.25 < a && a < 0.3) { // DLMF 13.3.7; SciPy gh-15650
    return (x + 1 + 2 * a) * xsf::hypu(a + 1, 1, x) -
           (a + 1) * (a + 1) * xsf::hypu(a + 2, 1, x);
  }
  return xsf::hypu(a, b, x);
}

// _spence.pxd: cspence and its two series.
const double spence_tol = 2.220446092504131e-16;
const double pisq_6 = 1.6449340668482264365;

std::complex<double> cspence_series0(std::complex<double> z) {
  if (z == 0.0) {
    return pisq_6;
  }
  std::complex<double> zfac = 1, sum1 = 0, sum2 = 0;
  for (int n = 1; n < 500; n++) {
    zfac *= z;
    std::complex<double> term1 = zfac / static_cast<double>(n * n);
    sum1 += term1;
    std::complex<double> term2 = zfac / static_cast<double>(n);
    sum2 += term2;
    if (std::abs(term1) <= spence_tol * std::abs(sum1) &&
        std::abs(term2) <= spence_tol * std::abs(sum2)) {
      break;
    }
  }
  return pisq_6 - sum1 + xsf::detail::zlog1(z) * sum2;
}

std::complex<double> cspence_series1(std::complex<double> z) {
  if (z == 1.0) {
    return 0;
  }
  z = 1.0 - z;
  std::complex<double> zz = z * z, zfac = 1, res = 0;
  for (int n = 1; n < 500; n++) {
    zfac *= z;
    // One division at a time, against overflow.
    std::complex<double> term =
        ((zfac / static_cast<double>(n * n)) / static_cast<double>((n + 1) * (n + 1))) /
        static_cast<double>((n + 2) * (n + 2));
    res += term;
    if (std::abs(term) <= spence_tol * std::abs(res)) {
      break;
    }
  }
  res *= 4.0 * zz;
  res += 4.0 * z + 5.75 * zz + 3.0 * (1.0 - zz) * xsf::detail::zlog1(1.0 - z);
  res /= 1.0 + 4.0 * z + zz;
  return res;
}

std::complex<double> cspence(std::complex<double> z) {
  if (std::abs(z) < 0.5) {
    return cspence_series0(z);
  } else if (std::abs(1.0 - z) > 1) {
    std::complex<double> l = xsf::detail::zlog1(z - 1.0);
    return -cspence_series1(z / (z - 1.0)) - pisq_6 - 0.5 * l * l;
  }
  return cspence_series1(z);
}

} // namespace

extern "C" {

double zsp_hyp0f1_dd(double v, double z) noexcept { return hyp0f1_real(v, z); }
zsp_complex zsp_hyp0f1_dc(double v, zsp_complex z) noexcept {
  return zsp_from_std(hyp0f1_cmplx(v, zsp_to_std(z)));
}
zsp_complex zsp_hyp1f1_ddc(double a, double b, zsp_complex z) noexcept {
  return zsp_from_std(xsf::hyp1f1(a, b, zsp_to_std(z)));
}
double zsp_hyp2f1_dddd(double a, double b, double c, double x) noexcept {
  return xsf::hyp2f1(a, b, c, x);
}
zsp_complex zsp_hyp2f1_dddc(double a, double b, double c, zsp_complex z) noexcept {
  return zsp_from_std(xsf::hyp2f1(a, b, c, zsp_to_std(z)));
}
double zsp_hyperu_ddd(double a, double b, double x) noexcept {
  return hyperu(a, b, x);
}

double zsp_ellipk_d(double m) noexcept { return xsf::ellipk(m); }
double zsp_ellipkm1_d(double p) noexcept { return xsf::ellipkm1(p); }
double zsp_ellipkinc_dd(double phi, double m) noexcept {
  return xsf::ellipkinc(phi, m);
}
double zsp_ellipe_d(double m) noexcept { return xsf::ellipe(m); }
double zsp_ellipeinc_dd(double phi, double m) noexcept {
  return xsf::ellipeinc(phi, m);
}
void zsp_ellipj_dd4(double u, double m, double *out) noexcept {
  xsf::ellipj(u, m, out[0], out[1], out[2], out[3]);
}

double zsp_zeta_d(double x) noexcept { return xsf::riemann_zeta(x); }
zsp_complex zsp_zeta_c(zsp_complex z) noexcept {
  return zsp_from_std(xsf::riemann_zeta(zsp_to_std(z)));
}
double zsp_zeta_q_dd(double x, double q) noexcept { return xsf::zeta(x, q); }
zsp_complex zsp_zeta_q_cd(zsp_complex z, double q) noexcept {
  return zsp_from_std(xsf::zeta(zsp_to_std(z), q));
}
double zsp_zetac_d(double x) noexcept { return xsf::zetac(x); }

zsp_complex zsp_lambertw_cid(zsp_complex z, int k, double tol) noexcept {
  return zsp_from_std(xsf::lambertw(zsp_to_std(z), static_cast<long>(k), tol));
}
double zsp_wrightomega_d(double x) noexcept {
  return zsp_port::wright::wrightomega_real(x);
}
zsp_complex zsp_wrightomega_c(zsp_complex z) noexcept {
  return zsp_from_std(zsp_port::wright::wrightomega(zsp_to_std(z)));
}
double zsp_spence_d(double x) noexcept { return xsf::cephes::spence(x); }
zsp_complex zsp_spence_c(zsp_complex z) noexcept {
  return zsp_from_std(cspence(zsp_to_std(z)));
}
double zsp_struve_dd(double v, double x) noexcept { return xsf::struve_h(v, x); }
double zsp_modstruve_dd(double v, double x) noexcept {
  return xsf::struve_l(v, x);
}

} // extern "C"

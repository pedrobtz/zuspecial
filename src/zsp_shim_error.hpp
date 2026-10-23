// Shim for the error functions and exponential integrals. Included only
// by zsp_shim.cpp.

#include "xsf/cephes/erfinv.h"
#include "xsf/cephes/expn.h"
#include "xsf/erf.h"
#include "xsf/expint.h"

#include "zsp_complex.hpp"

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

} // extern "C"

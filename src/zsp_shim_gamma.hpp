// Shim for the gamma and beta family. Included only by zsp_shim.cpp.

#include "xsf/beta.h"
#include "xsf/binom.h"
#include "xsf/cephes/poch.h"
#include "xsf/digamma.h"
#include "xsf/gamma.h"
#include "xsf/loggamma.h"

#include "zsp_complex.hpp"

extern "C" {

double zsp_gamma_d(double x) noexcept { return xsf::gamma(x); }
double zsp_gammaln_d(double x) noexcept { return xsf::gammaln(x); }
double zsp_loggamma_d(double x) noexcept { return xsf::loggamma(x); }
double zsp_rgamma_d(double x) noexcept { return xsf::rgamma(x); }
double zsp_gammasgn_d(double x) noexcept { return xsf::gammasgn(x); }
double zsp_psi_d(double x) noexcept { return xsf::digamma(x); }

zsp_complex zsp_gamma_c(zsp_complex z) noexcept {
  return zsp_from_std(xsf::gamma(zsp_to_std(z)));
}
zsp_complex zsp_loggamma_c(zsp_complex z) noexcept {
  return zsp_from_std(xsf::loggamma(zsp_to_std(z)));
}
zsp_complex zsp_rgamma_c(zsp_complex z) noexcept {
  return zsp_from_std(xsf::rgamma(zsp_to_std(z)));
}
zsp_complex zsp_psi_c(zsp_complex z) noexcept {
  return zsp_from_std(xsf::digamma(zsp_to_std(z)));
}

double zsp_beta_dd(double a, double b) noexcept { return xsf::beta(a, b); }
double zsp_betaln_dd(double a, double b) noexcept { return xsf::betaln(a, b); }
double zsp_binom_dd(double x, double y) noexcept { return xsf::binom(x, y); }
double zsp_poch_dd(double z, double m) noexcept {
  return xsf::cephes::poch(z, m);
}

} // extern "C"

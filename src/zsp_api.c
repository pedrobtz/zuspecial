/* The public C table, inst/include/zuspecial.h, registered as
   zuspecial_api_v1 (design section 7). Each member clears this thread's
   sf_error mask, calls the same kernel the R function does, and reports the
   lowest-numbered code raised. */

#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

#include "../inst/include/zuspecial.h"
#include "zsp_shim.h"
#include "zsp_xsf_version.h"

static void zsp_api_code(int *code) {
  unsigned int bits = zsp_err_take();
  if (code == NULL) {
    return;
  }
  *code = 0;
  for (int k = 1; k <= 10; k++) {
    if (bits & (1u << k)) {
      *code = k;
      return;
    }
  }
}

static double api_gamma(double x, int *code) {
  zsp_err_take();
  double value = zsp_gamma_d(x);
  zsp_api_code(code);
  return value;
}
static double api_gammaln(double x, int *code) {
  zsp_err_take();
  double value = zsp_gammaln_d(x);
  zsp_api_code(code);
  return value;
}
static double api_gammasgn(double x, int *code) {
  zsp_err_take();
  double value = zsp_gammasgn_d(x);
  zsp_api_code(code);
  return value;
}
static double api_rgamma(double x, int *code) {
  zsp_err_take();
  double value = zsp_rgamma_d(x);
  zsp_api_code(code);
  return value;
}
static double api_psi(double x, int *code) {
  zsp_err_take();
  double value = zsp_psi_d(x);
  zsp_api_code(code);
  return value;
}
static double api_beta(double a, double b, int *code) {
  zsp_err_take();
  double value = zsp_beta_dd(a, b);
  zsp_api_code(code);
  return value;
}
static double api_betaln(double a, double b, int *code) {
  zsp_err_take();
  double value = zsp_betaln_dd(a, b);
  zsp_api_code(code);
  return value;
}
static double api_binom(double x, double y, int *code) {
  zsp_err_take();
  double value = zsp_binom_dd(x, y);
  zsp_api_code(code);
  return value;
}
static double api_gammainc(double a, double x, int *code) {
  zsp_err_take();
  double value = zsp_gammainc_dd(a, x);
  zsp_api_code(code);
  return value;
}
static double api_gammaincc(double a, double x, int *code) {
  zsp_err_take();
  double value = zsp_gammaincc_dd(a, x);
  zsp_api_code(code);
  return value;
}
static double api_gammaincinv(double a, double y, int *code) {
  zsp_err_take();
  double value = zsp_gammaincinv_dd(a, y);
  zsp_api_code(code);
  return value;
}
static double api_gammainccinv(double a, double y, int *code) {
  zsp_err_take();
  double value = zsp_gammainccinv_dd(a, y);
  zsp_api_code(code);
  return value;
}
static double api_betainc(double a, double b, double x, int *code) {
  zsp_err_take();
  double value = zsp_betainc_ddd(a, b, x);
  zsp_api_code(code);
  return value;
}
static double api_betaincc(double a, double b, double x, int *code) {
  zsp_err_take();
  double value = zsp_betaincc_ddd(a, b, x);
  zsp_api_code(code);
  return value;
}
static double api_betaincinv(double a, double b, double y, int *code) {
  zsp_err_take();
  double value = zsp_betaincinv_ddd(a, b, y);
  zsp_api_code(code);
  return value;
}
static double api_betainccinv(double a, double b, double y, int *code) {
  zsp_err_take();
  double value = zsp_betainccinv_ddd(a, b, y);
  zsp_api_code(code);
  return value;
}
static double api_erf(double x, int *code) {
  zsp_err_take();
  double value = zsp_erf_d(x);
  zsp_api_code(code);
  return value;
}
static double api_erfc(double x, int *code) {
  zsp_err_take();
  double value = zsp_erfc_d(x);
  zsp_api_code(code);
  return value;
}
static double api_erfcx(double x, int *code) {
  zsp_err_take();
  double value = zsp_erfcx_d(x);
  zsp_api_code(code);
  return value;
}
static double api_erfinv(double y, int *code) {
  zsp_err_take();
  double value = zsp_erfinv_d(y);
  zsp_api_code(code);
  return value;
}
static double api_erfcinv(double y, int *code) {
  zsp_err_take();
  double value = zsp_erfcinv_d(y);
  zsp_api_code(code);
  return value;
}
static double api_ndtr(double x, int *code) {
  zsp_err_take();
  double value = zsp_ndtr_d(x);
  zsp_api_code(code);
  return value;
}
static double api_log_ndtr(double x, int *code) {
  zsp_err_take();
  double value = zsp_log_ndtr_d(x);
  zsp_api_code(code);
  return value;
}
static double api_ndtri(double y, int *code) {
  zsp_err_take();
  double value = zsp_ndtri_d(y);
  zsp_api_code(code);
  return value;
}
static double api_ndtri_exp(double y, int *code) {
  zsp_err_take();
  double value = zsp_ndtri_exp_d(y);
  zsp_api_code(code);
  return value;
}
static double api_owens_t(double h, double a, int *code) {
  zsp_err_take();
  double value = zsp_owens_t_dd(h, a);
  zsp_api_code(code);
  return value;
}
static double api_jv(double v, double x, int *code) {
  zsp_err_take();
  double value = zsp_jv_dd(v, x);
  zsp_api_code(code);
  return value;
}
static double api_yv(double v, double x, int *code) {
  zsp_err_take();
  double value = zsp_yv_dd(v, x);
  zsp_api_code(code);
  return value;
}
static double api_iv(double v, double x, int *code) {
  zsp_err_take();
  double value = zsp_iv_dd(v, x);
  zsp_api_code(code);
  return value;
}
static double api_kv(double v, double x, int *code) {
  zsp_err_take();
  double value = zsp_kv_dd(v, x);
  zsp_api_code(code);
  return value;
}
static double api_zeta(double x, int *code) {
  zsp_err_take();
  double value = zsp_zeta_d(x);
  zsp_api_code(code);
  return value;
}

static zuspecial_complex api_jv_c(double v, zuspecial_complex z, int *code) {
  zsp_complex arg;
  arg.re = z.re;
  arg.im = z.im;
  zsp_err_take();
  zsp_complex res = zsp_jv_dc(v, arg);
  zsp_api_code(code);
  zuspecial_complex out;
  out.re = res.re;
  out.im = res.im;
  return out;
}

static const zuspecial_api zuspecial_api_table = {
    (uint32_t) sizeof(zuspecial_api),
    ZSP_XSF_COMMIT,
    api_gamma,
    api_gammaln,
    api_gammasgn,
    api_rgamma,
    api_psi,
    api_beta,
    api_betaln,
    api_binom,
    api_gammainc,
    api_gammaincc,
    api_gammaincinv,
    api_gammainccinv,
    api_betainc,
    api_betaincc,
    api_betaincinv,
    api_betainccinv,
    api_erf,
    api_erfc,
    api_erfcx,
    api_erfinv,
    api_erfcinv,
    api_ndtr,
    api_log_ndtr,
    api_ndtri,
    api_ndtri_exp,
    api_owens_t,
    api_jv,
    api_yv,
    api_iv,
    api_kv,
    api_zeta,
    api_jv_c};

const zuspecial_api *zuspecial_api_v1(void) {
  return &zuspecial_api_table;
}

void zsp_register_api(void) {
  /* Keyed on the package name, not the DllInfo. */
  R_RegisterCCallable("zuspecial", "zuspecial_api_v1",
                      (DL_FUNC) zuspecial_api_v1);
}

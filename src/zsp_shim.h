#ifndef ZSP_SHIM_H
#define ZSP_SHIM_H

/* The boundary between the C glue and the C++ shim. Plain C types only:
   no C++ type or exception crosses it, and the shim never calls R. */

#ifdef __cplusplus
#define ZSP_NOEXCEPT noexcept
extern "C" {
#else
#define ZSP_NOEXCEPT
#endif

typedef struct {
  double re, im;
} zsp_complex;

/* Returns and clears this thread's sf_error mask: bit (1u << code) for each
   sf_error_t code xsf raised since the last call. */
unsigned int zsp_err_take(void) ZSP_NOEXCEPT;

/* Gamma and beta family: src/zsp_shim_gamma.cpp. */
double zsp_gamma_d(double x) ZSP_NOEXCEPT;
double zsp_gammaln_d(double x) ZSP_NOEXCEPT;
double zsp_loggamma_d(double x) ZSP_NOEXCEPT;
double zsp_rgamma_d(double x) ZSP_NOEXCEPT;
double zsp_gammasgn_d(double x) ZSP_NOEXCEPT;
double zsp_psi_d(double x) ZSP_NOEXCEPT;
zsp_complex zsp_gamma_c(zsp_complex z) ZSP_NOEXCEPT;
zsp_complex zsp_loggamma_c(zsp_complex z) ZSP_NOEXCEPT;
zsp_complex zsp_rgamma_c(zsp_complex z) ZSP_NOEXCEPT;
zsp_complex zsp_psi_c(zsp_complex z) ZSP_NOEXCEPT;
double zsp_beta_dd(double a, double b) ZSP_NOEXCEPT;
double zsp_betaln_dd(double a, double b) ZSP_NOEXCEPT;
double zsp_binom_dd(double x, double y) ZSP_NOEXCEPT;
double zsp_poch_dd(double z, double m) ZSP_NOEXCEPT;

/* Error functions and exponential integrals: src/zsp_shim_error.cpp. */
double zsp_erf_d(double x) ZSP_NOEXCEPT;
double zsp_erfc_d(double x) ZSP_NOEXCEPT;
double zsp_erfcx_d(double x) ZSP_NOEXCEPT;
double zsp_erfi_d(double x) ZSP_NOEXCEPT;
double zsp_erfcinv_d(double y) ZSP_NOEXCEPT;
double zsp_dawsn_d(double x) ZSP_NOEXCEPT;
double zsp_exp1_d(double x) ZSP_NOEXCEPT;
double zsp_expi_d(double x) ZSP_NOEXCEPT;
zsp_complex zsp_erf_c(zsp_complex z) ZSP_NOEXCEPT;
zsp_complex zsp_erfc_c(zsp_complex z) ZSP_NOEXCEPT;
zsp_complex zsp_erfcx_c(zsp_complex z) ZSP_NOEXCEPT;
zsp_complex zsp_erfi_c(zsp_complex z) ZSP_NOEXCEPT;
zsp_complex zsp_dawsn_c(zsp_complex z) ZSP_NOEXCEPT;
zsp_complex zsp_wofz_c(zsp_complex z) ZSP_NOEXCEPT;
zsp_complex zsp_exp1_c(zsp_complex z) ZSP_NOEXCEPT;
zsp_complex zsp_expi_c(zsp_complex z) ZSP_NOEXCEPT;
double zsp_voigt_profile_ddd(double x, double sigma, double gamma) ZSP_NOEXCEPT;
double zsp_expn_id(int n, double x) ZSP_NOEXCEPT;

#ifdef __cplusplus
}
#endif

#endif

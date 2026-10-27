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

/* Gamma and beta family: src/zsp_shim_gamma.h. */
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
double zsp_gammainc_dd(double a, double x) ZSP_NOEXCEPT;
double zsp_gammaincc_dd(double a, double x) ZSP_NOEXCEPT;
double zsp_gammaincinv_dd(double a, double y) ZSP_NOEXCEPT;
double zsp_gammainccinv_dd(double a, double y) ZSP_NOEXCEPT;

/* Error functions and exponential integrals: src/zsp_shim_error.h. */
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
double zsp_ndtr_d(double x) ZSP_NOEXCEPT;
double zsp_log_ndtr_d(double x) ZSP_NOEXCEPT;
zsp_complex zsp_ndtr_c(zsp_complex z) ZSP_NOEXCEPT;
zsp_complex zsp_log_ndtr_c(zsp_complex z) ZSP_NOEXCEPT;
double zsp_ndtri_d(double p) ZSP_NOEXCEPT;
double zsp_ndtri_exp_d(double y) ZSP_NOEXCEPT;
double zsp_owens_t_dd(double h, double a) ZSP_NOEXCEPT;

/* Bessel family: src/zsp_shim_bessel.h. */
double zsp_jv_dd(double v, double x) ZSP_NOEXCEPT;
zsp_complex zsp_jv_dc(double v, zsp_complex z) ZSP_NOEXCEPT;
double zsp_yv_dd(double v, double x) ZSP_NOEXCEPT;
zsp_complex zsp_yv_dc(double v, zsp_complex z) ZSP_NOEXCEPT;
double zsp_iv_dd(double v, double x) ZSP_NOEXCEPT;
zsp_complex zsp_iv_dc(double v, zsp_complex z) ZSP_NOEXCEPT;
double zsp_kv_dd(double v, double x) ZSP_NOEXCEPT;
zsp_complex zsp_kv_dc(double v, zsp_complex z) ZSP_NOEXCEPT;
double zsp_jve_dd(double v, double x) ZSP_NOEXCEPT;
zsp_complex zsp_jve_dc(double v, zsp_complex z) ZSP_NOEXCEPT;
double zsp_yve_dd(double v, double x) ZSP_NOEXCEPT;
zsp_complex zsp_yve_dc(double v, zsp_complex z) ZSP_NOEXCEPT;
double zsp_ive_dd(double v, double x) ZSP_NOEXCEPT;
zsp_complex zsp_ive_dc(double v, zsp_complex z) ZSP_NOEXCEPT;
double zsp_kve_dd(double v, double x) ZSP_NOEXCEPT;
zsp_complex zsp_kve_dc(double v, zsp_complex z) ZSP_NOEXCEPT;
zsp_complex zsp_hankel1_dc(double v, zsp_complex z) ZSP_NOEXCEPT;
zsp_complex zsp_hankel2_dc(double v, zsp_complex z) ZSP_NOEXCEPT;
zsp_complex zsp_hankel1e_dc(double v, zsp_complex z) ZSP_NOEXCEPT;
zsp_complex zsp_hankel2e_dc(double v, zsp_complex z) ZSP_NOEXCEPT;
double zsp_j0_d(double x) ZSP_NOEXCEPT;
double zsp_j1_d(double x) ZSP_NOEXCEPT;
double zsp_y0_d(double x) ZSP_NOEXCEPT;
double zsp_y1_d(double x) ZSP_NOEXCEPT;
double zsp_i0_d(double x) ZSP_NOEXCEPT;
double zsp_i0e_d(double x) ZSP_NOEXCEPT;
double zsp_i1_d(double x) ZSP_NOEXCEPT;
double zsp_i1e_d(double x) ZSP_NOEXCEPT;
double zsp_k0_d(double x) ZSP_NOEXCEPT;
double zsp_k0e_d(double x) ZSP_NOEXCEPT;
double zsp_k1_d(double x) ZSP_NOEXCEPT;
double zsp_k1e_d(double x) ZSP_NOEXCEPT;
double zsp_spherical_jn_id(int n, double x) ZSP_NOEXCEPT;
zsp_complex zsp_spherical_jn_ic(int n, zsp_complex z) ZSP_NOEXCEPT;
double zsp_spherical_jn_d_id(int n, double x) ZSP_NOEXCEPT;
zsp_complex zsp_spherical_jn_d_ic(int n, zsp_complex z) ZSP_NOEXCEPT;
double zsp_spherical_yn_id(int n, double x) ZSP_NOEXCEPT;
zsp_complex zsp_spherical_yn_ic(int n, zsp_complex z) ZSP_NOEXCEPT;
double zsp_spherical_yn_d_id(int n, double x) ZSP_NOEXCEPT;
zsp_complex zsp_spherical_yn_d_ic(int n, zsp_complex z) ZSP_NOEXCEPT;
double zsp_spherical_in_id(int n, double x) ZSP_NOEXCEPT;
zsp_complex zsp_spherical_in_ic(int n, zsp_complex z) ZSP_NOEXCEPT;
double zsp_spherical_in_d_id(int n, double x) ZSP_NOEXCEPT;
zsp_complex zsp_spherical_in_d_ic(int n, zsp_complex z) ZSP_NOEXCEPT;
double zsp_spherical_kn_id(int n, double x) ZSP_NOEXCEPT;
zsp_complex zsp_spherical_kn_ic(int n, zsp_complex z) ZSP_NOEXCEPT;
double zsp_spherical_kn_d_id(int n, double x) ZSP_NOEXCEPT;
zsp_complex zsp_spherical_kn_d_ic(int n, zsp_complex z) ZSP_NOEXCEPT;
void zsp_airy_d4(double x, double *out) ZSP_NOEXCEPT;
void zsp_airy_c4(zsp_complex z, zsp_complex *out) ZSP_NOEXCEPT;
void zsp_airye_d4(double x, double *out) ZSP_NOEXCEPT;
void zsp_airye_c4(zsp_complex z, zsp_complex *out) ZSP_NOEXCEPT;

/* Hypergeometric, elliptic, zeta, Lambert W, Wright omega, Spence, Struve:
   src/zsp_shim_hyper.h (and the Boost unit for real hyp1f1). */
double zsp_hyp0f1_dd(double v, double z) ZSP_NOEXCEPT;
zsp_complex zsp_hyp0f1_dc(double v, zsp_complex z) ZSP_NOEXCEPT;
double zsp_hyp1f1_ddd(double a, double b, double x) ZSP_NOEXCEPT;
zsp_complex zsp_hyp1f1_ddc(double a, double b, zsp_complex z) ZSP_NOEXCEPT;
double zsp_hyp2f1_dddd(double a, double b, double c, double x) ZSP_NOEXCEPT;
zsp_complex zsp_hyp2f1_dddc(double a, double b, double c, zsp_complex z) ZSP_NOEXCEPT;
double zsp_hyperu_ddd(double a, double b, double x) ZSP_NOEXCEPT;
double zsp_ellipk_d(double m) ZSP_NOEXCEPT;
double zsp_ellipkm1_d(double p) ZSP_NOEXCEPT;
double zsp_ellipkinc_dd(double phi, double m) ZSP_NOEXCEPT;
double zsp_ellipe_d(double m) ZSP_NOEXCEPT;
double zsp_ellipeinc_dd(double phi, double m) ZSP_NOEXCEPT;
void zsp_ellipj_dd4(double u, double m, double *out) ZSP_NOEXCEPT;
double zsp_zeta_d(double x) ZSP_NOEXCEPT;
zsp_complex zsp_zeta_c(zsp_complex z) ZSP_NOEXCEPT;
double zsp_zeta_q_dd(double x, double q) ZSP_NOEXCEPT;
zsp_complex zsp_zeta_q_cd(zsp_complex z, double q) ZSP_NOEXCEPT;
double zsp_zetac_d(double x) ZSP_NOEXCEPT;
zsp_complex zsp_lambertw_cid(zsp_complex z, int k, double tol) ZSP_NOEXCEPT;
double zsp_wrightomega_d(double x) ZSP_NOEXCEPT;
zsp_complex zsp_wrightomega_c(zsp_complex z) ZSP_NOEXCEPT;
double zsp_spence_d(double x) ZSP_NOEXCEPT;
zsp_complex zsp_spence_c(zsp_complex z) ZSP_NOEXCEPT;
double zsp_struve_dd(double v, double x) ZSP_NOEXCEPT;
double zsp_modstruve_dd(double v, double x) ZSP_NOEXCEPT;

/* NumPy's complex sqrt and power, for code ported from SciPy's Cython:
   src/zsp_ccomplex.c. */
zsp_complex zsp_csqrt(zsp_complex z) ZSP_NOEXCEPT;
zsp_complex zsp_cpow(zsp_complex a, zsp_complex b) ZSP_NOEXCEPT;

/* Boost.Math, as SciPy calls it: src/zsp_boost.cpp. */
double zsp_betainc_ddd(double a, double b, double x) ZSP_NOEXCEPT;
double zsp_betaincc_ddd(double a, double b, double x) ZSP_NOEXCEPT;
double zsp_betaincinv_ddd(double a, double b, double y) ZSP_NOEXCEPT;
double zsp_betainccinv_ddd(double a, double b, double y) ZSP_NOEXCEPT;
double zsp_erfinv_d(double y) ZSP_NOEXCEPT;
int zsp_boost_version(void) ZSP_NOEXCEPT;

#ifdef __cplusplus
}
#endif

#endif

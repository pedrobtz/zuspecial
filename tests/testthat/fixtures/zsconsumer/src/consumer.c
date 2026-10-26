/* A consumer of zuspecial's C table, written as a downstream package
   would: LinkingTo: zuspecial, the table fetched once with
   zuspecial_api_get(). */
#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

#define ZUSPECIAL_DEFINE_API_GET
#include <zuspecial.h>

SEXP zsc_info_c(void) {
  const zuspecial_api *api = zuspecial_api_get();
  SEXP out = PROTECT(Rf_allocVector(VECSXP, 3));
  SET_VECTOR_ELT(out, 0, Rf_ScalarInteger((int) api->struct_size));
  SET_VECTOR_ELT(out, 1, Rf_mkString(api->xsf_commit));
  SET_VECTOR_ELT(out, 2, Rf_ScalarLogical(ZUSPECIAL_API_HAS(api, jv_c)));
  UNPROTECT(1);
  return out;
}

/* value and the error code, for a scalar */
SEXP zsc_gamma_c(SEXP x) {
  const zuspecial_api *api = zuspecial_api_get();
  int code = -1;
  double value = api->gamma(REAL(x)[0], &code);
  SEXP out = PROTECT(Rf_allocVector(VECSXP, 2));
  SET_VECTOR_ELT(out, 0, Rf_ScalarReal(value));
  SET_VECTOR_ELT(out, 1, Rf_ScalarInteger(code));
  UNPROTECT(1);
  return out;
}

SEXP zsc_jv_c_c(SEXP v, SEXP z) {
  const zuspecial_api *api = zuspecial_api_get();
  zuspecial_complex arg;
  arg.re = COMPLEX(z)[0].r;
  arg.im = COMPLEX(z)[0].i;
  int code = -1;
  zuspecial_complex res = api->jv_c(REAL(v)[0], arg, &code);
  SEXP out = PROTECT(Rf_allocVector(VECSXP, 2));
  SEXP val = PROTECT(Rf_allocVector(CPLXSXP, 1));
  COMPLEX(val)[0].r = res.re;
  COMPLEX(val)[0].i = res.im;
  SET_VECTOR_ELT(out, 0, val);
  SET_VECTOR_ELT(out, 1, Rf_ScalarInteger(code));
  UNPROTECT(2);
  return out;
}

/* Every real member at fixed inputs a, b, c (ndtri_exp at -a), so the
   test can compare each with its sc_ function and catch a member wired
   to the wrong kernel. The last element calls gamma with code = NULL. */
SEXP zsc_all_c(SEXP abc) {
  const zuspecial_api *api = zuspecial_api_get();
  double a = REAL(abc)[0], b = REAL(abc)[1], c = REAL(abc)[2];
  int code;
  SEXP out = PROTECT(Rf_allocVector(REALSXP, 32));
  double *v = REAL(out);
  v[0] = api->gamma(a, &code);
  v[1] = api->gammaln(a, &code);
  v[2] = api->gammasgn(a, &code);
  v[3] = api->rgamma(a, &code);
  v[4] = api->psi(a, &code);
  v[5] = api->erf(a, &code);
  v[6] = api->erfc(a, &code);
  v[7] = api->erfcx(a, &code);
  v[8] = api->erfinv(a, &code);
  v[9] = api->erfcinv(a, &code);
  v[10] = api->ndtr(a, &code);
  v[11] = api->log_ndtr(a, &code);
  v[12] = api->ndtri(a, &code);
  v[13] = api->zeta(a, &code);
  v[14] = api->ndtri_exp(-a, &code);
  v[15] = api->beta(a, b, &code);
  v[16] = api->betaln(a, b, &code);
  v[17] = api->binom(a, b, &code);
  v[18] = api->gammainc(a, b, &code);
  v[19] = api->gammaincc(a, b, &code);
  v[20] = api->gammaincinv(a, b, &code);
  v[21] = api->gammainccinv(a, b, &code);
  v[22] = api->owens_t(a, b, &code);
  v[23] = api->jv(a, b, &code);
  v[24] = api->yv(a, b, &code);
  v[25] = api->iv(a, b, &code);
  v[26] = api->kv(a, b, &code);
  v[27] = api->betainc(a, b, c, &code);
  v[28] = api->betaincc(a, b, c, &code);
  v[29] = api->betaincinv(a, b, c, &code);
  v[30] = api->betainccinv(a, b, c, &code);
  v[31] = api->gamma(a, NULL);
  UNPROTECT(1);
  return out;
}

static const R_CallMethodDef calls[] = {
  {"zsc_info_c", (DL_FUNC) &zsc_info_c, 0},
  {"zsc_gamma_c", (DL_FUNC) &zsc_gamma_c, 1},
  {"zsc_jv_c_c", (DL_FUNC) &zsc_jv_c_c, 2},
  {"zsc_all_c", (DL_FUNC) &zsc_all_c, 1},
  {NULL, NULL, 0}
};

void R_init_zsconsumer(DllInfo *dll) {
  R_registerRoutines(dll, NULL, calls, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
}

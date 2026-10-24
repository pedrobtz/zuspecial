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

static const R_CallMethodDef calls[] = {
  {"zsc_info_c", (DL_FUNC) &zsc_info_c, 0},
  {"zsc_gamma_c", (DL_FUNC) &zsc_gamma_c, 1},
  {"zsc_jv_c_c", (DL_FUNC) &zsc_jv_c_c, 2},
  {NULL, NULL, 0}
};

void R_init_zsconsumer(DllInfo *dll) {
  R_registerRoutines(dll, NULL, calls, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
}

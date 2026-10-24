#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include <R_ext/Visibility.h>

SEXP zsp_call_d(SEXP name, SEXP x);
SEXP zsp_call_c(SEXP name, SEXP z);
SEXP zsp_call_dd(SEXP name, SEXP a, SEXP b);
SEXP zsp_call_ddd(SEXP name, SEXP a, SEXP b, SEXP c);
SEXP zsp_call_id(SEXP name, SEXP k, SEXP x);
SEXP zsp_info(void);
SEXP zsp_boost_version_r(void);

static const R_CallMethodDef call_methods[] = {
  {"zsp_call_d", (DL_FUNC) &zsp_call_d, 2},
  {"zsp_call_c", (DL_FUNC) &zsp_call_c, 2},
  {"zsp_call_dd", (DL_FUNC) &zsp_call_dd, 3},
  {"zsp_call_ddd", (DL_FUNC) &zsp_call_ddd, 4},
  {"zsp_call_id", (DL_FUNC) &zsp_call_id, 3},
  {"zsp_info", (DL_FUNC) &zsp_info, 0},
  {"zsp_boost_version_r", (DL_FUNC) &zsp_boost_version_r, 0},
  {NULL, NULL, 0}
};

void attribute_visible R_init_zuspecial(DllInfo *dll) {
  R_registerRoutines(dll, NULL, call_methods, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  R_forceSymbols(dll, TRUE);
}

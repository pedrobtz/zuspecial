#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include <R_ext/Visibility.h>

SEXP zsp_spike_gamma(SEXP x);

static const R_CallMethodDef call_methods[] = {
  {"zsp_spike_gamma", (DL_FUNC) &zsp_spike_gamma, 1},
  {NULL, NULL, 0}
};

void attribute_visible R_init_zuspecial(DllInfo *dll) {
  R_registerRoutines(dll, NULL, call_methods, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  R_forceSymbols(dll, TRUE);
}

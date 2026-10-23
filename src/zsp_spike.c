#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>

#include "zsp_shim.h"

/* Stage 1 spike: gamma through the shim, with the per-element error mask.
   Internal; Stage 2's glue replaces it. */
SEXP zsp_spike_gamma(SEXP x) {
  R_xlen_t n = XLENGTH(x);
  SEXP value = PROTECT(Rf_allocVector(REALSXP, n));
  SEXP codes = PROTECT(Rf_allocVector(INTSXP, n));
  const double *px = REAL(x);
  double *pv = REAL(value);
  int *pc = INTEGER(codes);

  zsp_err_take();
  for (R_xlen_t i = 0; i < n; i++) {
    pv[i] = zsp_gamma(px[i]);
    pc[i] = (int) zsp_err_take();
  }

  SEXP out = PROTECT(Rf_allocVector(VECSXP, 2));
  SET_VECTOR_ELT(out, 0, value);
  SET_VECTOR_ELT(out, 1, codes);
  SEXP names = PROTECT(Rf_allocVector(STRSXP, 2));
  SET_STRING_ELT(names, 0, Rf_mkChar("value"));
  SET_STRING_ELT(names, 1, Rf_mkChar("codes"));
  Rf_setAttrib(out, R_NamesSymbol, names);
  UNPROTECT(4);
  return out;
}

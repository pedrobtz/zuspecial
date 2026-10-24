#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>

#include "zsp_xsf_version.h"

#if defined(__clang__)
#define ZSP_COMPILER "clang " __clang_version__
#elif defined(__GNUC__)
#define ZSP_COMPILER "gcc " __VERSION__
#else
#define ZSP_COMPILER "unknown"
#endif

/* The vendored versions and the compiler, for zuspecial_info(). */
SEXP zsp_info(void) {
  SEXP out = PROTECT(Rf_allocVector(STRSXP, 4));
  SET_STRING_ELT(out, 0, Rf_mkChar(ZSP_XSF_COMMIT));
  SET_STRING_ELT(out, 1, Rf_mkChar(ZSP_SCIPY_TAG));
  SET_STRING_ELT(out, 2, Rf_mkChar(ZSP_COMPILER));
  SET_STRING_ELT(out, 3, Rf_mkChar(ZSP_XSREF_COMMIT));
  UNPROTECT(1);
  return out;
}

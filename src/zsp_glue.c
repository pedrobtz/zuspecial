#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <limits.h>
#include <string.h>

#include "zsp_shim.h"

/* One loop per signature (design section 4). The R layer has already
   checked, coerced and recycled the arguments, so every input is a REALSXP,
   CPLXSXP or INTSXP of the same length. NA is decided here, before any
   kernel is called (section 6.3). After the loop, the error report goes on
   the result as attribute "zsp_err": count for sf_error code k at k and the
   first 1-based index at 10 + k, k = 1..10 (section 6.4). */

#define ZSP_NCODES 10

typedef struct {
  int count[ZSP_NCODES];
  int first[ZSP_NCODES];
} zsp_report;

static void zsp_note(zsp_report *r, unsigned int bits, R_xlen_t i) {
  for (int k = 1; k <= ZSP_NCODES; k++) {
    if (bits & (1u << k)) {
      if (r->count[k - 1] == 0) {
        r->first[k - 1] = i < INT_MAX ? (int) (i + 1) : INT_MAX;
      }
      if (r->count[k - 1] < INT_MAX) {
        r->count[k - 1]++;
      }
    }
  }
}

/* Attaches the report to `out` when any code was raised; `out` must be
   protected by the caller. */
static void zsp_attach(SEXP out, const zsp_report *r) {
  int any = 0;
  for (int k = 0; k < ZSP_NCODES; k++) {
    any |= r->count[k];
  }
  if (!any) {
    return;
  }
  SEXP rep = PROTECT(Rf_allocVector(INTSXP, 2 * ZSP_NCODES));
  int *p = INTEGER(rep);
  for (int k = 0; k < ZSP_NCODES; k++) {
    p[k] = r->count[k];
    p[ZSP_NCODES + k] = r->first[k];
  }
  Rf_setAttrib(out, Rf_install("zsp_err"), rep);
  UNPROTECT(1);
}

static const char *zsp_name(SEXP name) {
  if (TYPEOF(name) != STRSXP || XLENGTH(name) != 1) {
    Rf_error("kernel name must be a string");
  }
  return CHAR(STRING_ELT(name, 0));
}

static void zsp_check(SEXP x, SEXPTYPE type, R_xlen_t n) {
  if (TYPEOF(x) != type || XLENGTH(x) != n) {
    Rf_error("internal: argument of wrong type or length");
  }
}

typedef double (*zsp_fn_d)(double);
typedef zsp_complex (*zsp_fn_c)(zsp_complex);
typedef double (*zsp_fn_dd)(double, double);
typedef double (*zsp_fn_ddd)(double, double, double);
typedef double (*zsp_fn_id)(int, double);

#define ZSP_LOOKUP(table, type, key)                                          \
  type fn = NULL;                                                             \
  for (size_t j = 0; j < sizeof(table) / sizeof(table[0]); j++) {             \
    if (strcmp(table[j].name, key) == 0) {                                    \
      fn = table[j].fn;                                                       \
      break;                                                                  \
    }                                                                         \
  }                                                                           \
  if (fn == NULL) {                                                           \
    Rf_error("unknown kernel '%s'", key);                                     \
  }

static const struct {
  const char *name;
  zsp_fn_d fn;
} zsp_table_d[] = {
  {"gamma", zsp_gamma_d},       {"gammaln", zsp_gammaln_d},
  {"loggamma", zsp_loggamma_d}, {"rgamma", zsp_rgamma_d},
  {"gammasgn", zsp_gammasgn_d}, {"psi", zsp_psi_d},
  {"erf", zsp_erf_d},           {"erfc", zsp_erfc_d},
  {"erfcx", zsp_erfcx_d},       {"erfi", zsp_erfi_d},
  {"erfcinv", zsp_erfcinv_d},   {"dawsn", zsp_dawsn_d},
  {"exp1", zsp_exp1_d},         {"expi", zsp_expi_d},
};

static const struct {
  const char *name;
  zsp_fn_c fn;
} zsp_table_c[] = {
  {"gamma", zsp_gamma_c}, {"loggamma", zsp_loggamma_c},
  {"rgamma", zsp_rgamma_c}, {"psi", zsp_psi_c},
  {"erf", zsp_erf_c},     {"erfc", zsp_erfc_c},
  {"erfcx", zsp_erfcx_c}, {"erfi", zsp_erfi_c},
  {"dawsn", zsp_dawsn_c}, {"wofz", zsp_wofz_c},
  {"exp1", zsp_exp1_c},   {"expi", zsp_expi_c},
};

static const struct {
  const char *name;
  zsp_fn_dd fn;
} zsp_table_dd[] = {
  {"beta", zsp_beta_dd},
  {"betaln", zsp_betaln_dd},
  {"binom", zsp_binom_dd},
  {"poch", zsp_poch_dd},
};

static const struct {
  const char *name;
  zsp_fn_ddd fn;
} zsp_table_ddd[] = {
  {"voigt_profile", zsp_voigt_profile_ddd},
};

static const struct {
  const char *name;
  zsp_fn_id fn;
} zsp_table_id[] = {
  {"expn", zsp_expn_id},
};

SEXP zsp_call_d(SEXP name, SEXP x) {
  const char *nm = zsp_name(name);
  ZSP_LOOKUP(zsp_table_d, zsp_fn_d, nm);
  R_xlen_t n = XLENGTH(x);
  zsp_check(x, REALSXP, n);
  SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
  const double *px = REAL(x);
  double *po = REAL(out);
  zsp_report r = {{0}, {0}};
  zsp_err_take();
  for (R_xlen_t i = 0; i < n; i++) {
    if (R_IsNA(px[i])) {
      po[i] = NA_REAL;
      continue;
    }
    po[i] = fn(px[i]);
    unsigned int bits = zsp_err_take();
    if (bits) {
      zsp_note(&r, bits, i);
    }
  }
  zsp_attach(out, &r);
  UNPROTECT(1);
  return out;
}

SEXP zsp_call_c(SEXP name, SEXP z) {
  const char *nm = zsp_name(name);
  ZSP_LOOKUP(zsp_table_c, zsp_fn_c, nm);
  R_xlen_t n = XLENGTH(z);
  zsp_check(z, CPLXSXP, n);
  SEXP out = PROTECT(Rf_allocVector(CPLXSXP, n));
  const Rcomplex *pz = COMPLEX(z);
  Rcomplex *po = COMPLEX(out);
  zsp_report r = {{0}, {0}};
  zsp_err_take();
  for (R_xlen_t i = 0; i < n; i++) {
    if (R_IsNA(pz[i].r) || R_IsNA(pz[i].i)) {
      po[i].r = NA_REAL;
      po[i].i = NA_REAL;
      continue;
    }
    zsp_complex arg;
    arg.re = pz[i].r;
    arg.im = pz[i].i;
    zsp_complex res = fn(arg);
    po[i].r = res.re;
    po[i].i = res.im;
    unsigned int bits = zsp_err_take();
    if (bits) {
      zsp_note(&r, bits, i);
    }
  }
  zsp_attach(out, &r);
  UNPROTECT(1);
  return out;
}

SEXP zsp_call_dd(SEXP name, SEXP a, SEXP b) {
  const char *nm = zsp_name(name);
  ZSP_LOOKUP(zsp_table_dd, zsp_fn_dd, nm);
  R_xlen_t n = XLENGTH(a);
  zsp_check(a, REALSXP, n);
  zsp_check(b, REALSXP, n);
  SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
  const double *pa = REAL(a), *pb = REAL(b);
  double *po = REAL(out);
  zsp_report r = {{0}, {0}};
  zsp_err_take();
  for (R_xlen_t i = 0; i < n; i++) {
    if (R_IsNA(pa[i]) || R_IsNA(pb[i])) {
      po[i] = NA_REAL;
      continue;
    }
    po[i] = fn(pa[i], pb[i]);
    unsigned int bits = zsp_err_take();
    if (bits) {
      zsp_note(&r, bits, i);
    }
  }
  zsp_attach(out, &r);
  UNPROTECT(1);
  return out;
}

SEXP zsp_call_ddd(SEXP name, SEXP a, SEXP b, SEXP c) {
  const char *nm = zsp_name(name);
  ZSP_LOOKUP(zsp_table_ddd, zsp_fn_ddd, nm);
  R_xlen_t n = XLENGTH(a);
  zsp_check(a, REALSXP, n);
  zsp_check(b, REALSXP, n);
  zsp_check(c, REALSXP, n);
  SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
  const double *pa = REAL(a), *pb = REAL(b), *pc = REAL(c);
  double *po = REAL(out);
  zsp_report r = {{0}, {0}};
  zsp_err_take();
  for (R_xlen_t i = 0; i < n; i++) {
    if (R_IsNA(pa[i]) || R_IsNA(pb[i]) || R_IsNA(pc[i])) {
      po[i] = NA_REAL;
      continue;
    }
    po[i] = fn(pa[i], pb[i], pc[i]);
    unsigned int bits = zsp_err_take();
    if (bits) {
      zsp_note(&r, bits, i);
    }
  }
  zsp_attach(out, &r);
  UNPROTECT(1);
  return out;
}

SEXP zsp_call_id(SEXP name, SEXP k, SEXP x) {
  const char *nm = zsp_name(name);
  ZSP_LOOKUP(zsp_table_id, zsp_fn_id, nm);
  R_xlen_t n = XLENGTH(x);
  zsp_check(k, INTSXP, n);
  zsp_check(x, REALSXP, n);
  SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
  const int *pk = INTEGER(k);
  const double *px = REAL(x);
  double *po = REAL(out);
  zsp_report r = {{0}, {0}};
  zsp_err_take();
  for (R_xlen_t i = 0; i < n; i++) {
    if (pk[i] == NA_INTEGER || R_IsNA(px[i])) {
      po[i] = NA_REAL;
      continue;
    }
    po[i] = fn(pk[i], px[i]);
    unsigned int bits = zsp_err_take();
    if (bits) {
      zsp_note(&r, bits, i);
    }
  }
  zsp_attach(out, &r);
  UNPROTECT(1);
  return out;
}

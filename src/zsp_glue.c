#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>
#include <string.h>

#include "zsp_shim.h"

/* One loop per signature (design section 4). The R layer has already
   checked, coerced and recycled the arguments, so every input is a REALSXP,
   CPLXSXP or INTSXP of the same length. NA is decided here, before any
   kernel is called (section 6.3). After the loop, the error report goes on
   the result as attribute "zsp_err", a double vector: count for sf_error
   code k at k and the first 1-based index at 10 + k, k = 1..10 (section
   6.4). */

#define ZSP_NCODES 10

/* Counts and indices are R_xlen_t, and go to R as doubles, so long vectors
   are reported exactly. */
typedef struct {
  R_xlen_t count[ZSP_NCODES];
  R_xlen_t first[ZSP_NCODES];
} zsp_report;

static void zsp_note(zsp_report *r, unsigned int bits, R_xlen_t i) {
  for (int k = 1; k <= ZSP_NCODES; k++) {
    if (bits & (1u << k)) {
      if (r->count[k - 1] == 0) {
        r->first[k - 1] = i + 1;
      }
      r->count[k - 1]++;
    }
  }
}

/* Attaches the report to `out` when any code was raised; `out` must be
   protected by the caller. */
static void zsp_attach(SEXP out, const zsp_report *r) {
  int any = 0;
  for (int k = 0; k < ZSP_NCODES; k++) {
    any |= r->count[k] > 0;
  }
  if (!any) {
    return;
  }
  SEXP rep = PROTECT(Rf_allocVector(REALSXP, 2 * ZSP_NCODES));
  double *p = REAL(rep);
  for (int k = 0; k < ZSP_NCODES; k++) {
    p[k] = (double) r->count[k];
    p[ZSP_NCODES + k] = (double) r->first[k];
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
  {"ndtr", zsp_ndtr_d},         {"log_ndtr", zsp_log_ndtr_d},
  {"ndtri", zsp_ndtri_d},       {"ndtri_exp", zsp_ndtri_exp_d},
  {"erfinv", zsp_erfinv_d},
  {"j0", zsp_j0_d},
  {"j1", zsp_j1_d},
  {"y0", zsp_y0_d},
  {"y1", zsp_y1_d},
  {"i0", zsp_i0_d},
  {"i0e", zsp_i0e_d},
  {"i1", zsp_i1_d},
  {"i1e", zsp_i1e_d},
  {"k0", zsp_k0_d},
  {"k0e", zsp_k0e_d},
  {"k1", zsp_k1_d},
  {"k1e", zsp_k1e_d},
  {"ellipk", zsp_ellipk_d},
  {"ellipkm1", zsp_ellipkm1_d},
  {"ellipe", zsp_ellipe_d},
  {"zeta", zsp_zeta_d},
  {"zetac", zsp_zetac_d},
  {"wrightomega", zsp_wrightomega_d},
  {"spence", zsp_spence_d},
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
  {"ndtr", zsp_ndtr_c},   {"log_ndtr", zsp_log_ndtr_c},
  {"zeta", zsp_zeta_c},
  {"wrightomega", zsp_wrightomega_c},
  {"spence", zsp_spence_c},
};

static const struct {
  const char *name;
  zsp_fn_dd fn;
} zsp_table_dd[] = {
  {"beta", zsp_beta_dd},
  {"betaln", zsp_betaln_dd},
  {"binom", zsp_binom_dd},
  {"poch", zsp_poch_dd},
  {"gammainc", zsp_gammainc_dd},
  {"gammaincc", zsp_gammaincc_dd},
  {"gammaincinv", zsp_gammaincinv_dd},
  {"gammainccinv", zsp_gammainccinv_dd},
  {"owens_t", zsp_owens_t_dd},
  {"jv", zsp_jv_dd},
  {"yv", zsp_yv_dd},
  {"iv", zsp_iv_dd},
  {"kv", zsp_kv_dd},
  {"jve", zsp_jve_dd},
  {"yve", zsp_yve_dd},
  {"ive", zsp_ive_dd},
  {"kve", zsp_kve_dd},
  {"hyp0f1", zsp_hyp0f1_dd},
  {"ellipkinc", zsp_ellipkinc_dd},
  {"ellipeinc", zsp_ellipeinc_dd},
  {"zeta_q", zsp_zeta_q_dd},
  {"struve", zsp_struve_dd},
  {"modstruve", zsp_modstruve_dd},
};

static const struct {
  const char *name;
  zsp_fn_ddd fn;
} zsp_table_ddd[] = {
  {"voigt_profile", zsp_voigt_profile_ddd},
  {"betainc", zsp_betainc_ddd},
  {"betaincc", zsp_betaincc_ddd},
  {"betaincinv", zsp_betaincinv_ddd},
  {"betainccinv", zsp_betainccinv_ddd},
  {"hyp1f1", zsp_hyp1f1_ddd},
  {"hyperu", zsp_hyperu_ddd},
};

static const struct {
  const char *name;
  zsp_fn_id fn;
} zsp_table_id[] = {
  {"expn", zsp_expn_id},
  {"spherical_jn", zsp_spherical_jn_id},
  {"spherical_jn_d", zsp_spherical_jn_d_id},
  {"spherical_yn", zsp_spherical_yn_id},
  {"spherical_yn_d", zsp_spherical_yn_d_id},
  {"spherical_in", zsp_spherical_in_id},
  {"spherical_in_d", zsp_spherical_in_d_id},
  {"spherical_kn", zsp_spherical_kn_id},
  {"spherical_kn_d", zsp_spherical_kn_d_id},
};


typedef zsp_complex (*zsp_fn_dc)(double, zsp_complex);
typedef zsp_complex (*zsp_fn_ic)(int, zsp_complex);
typedef void (*zsp_fn_d4)(double, double *);
typedef void (*zsp_fn_c4)(zsp_complex, zsp_complex *);

static const struct {
  const char *name;
  zsp_fn_dc fn;
} zsp_table_dc[] = {
  {"jv", zsp_jv_dc},
  {"yv", zsp_yv_dc},
  {"iv", zsp_iv_dc},
  {"kv", zsp_kv_dc},
  {"jve", zsp_jve_dc},
  {"yve", zsp_yve_dc},
  {"ive", zsp_ive_dc},
  {"kve", zsp_kve_dc},
  {"hankel1", zsp_hankel1_dc},
  {"hankel2", zsp_hankel2_dc},
  {"hankel1e", zsp_hankel1e_dc},
  {"hankel2e", zsp_hankel2e_dc},
  {"hyp0f1", zsp_hyp0f1_dc},
};

static const struct {
  const char *name;
  zsp_fn_ic fn;
} zsp_table_ic[] = {
  {"spherical_jn", zsp_spherical_jn_ic},
  {"spherical_jn_d", zsp_spherical_jn_d_ic},
  {"spherical_yn", zsp_spherical_yn_ic},
  {"spherical_yn_d", zsp_spherical_yn_d_ic},
  {"spherical_in", zsp_spherical_in_ic},
  {"spherical_in_d", zsp_spherical_in_d_ic},
  {"spherical_kn", zsp_spherical_kn_ic},
  {"spherical_kn_d", zsp_spherical_kn_d_ic},
};

static const struct {
  const char *name;
  zsp_fn_d4 fn;
} zsp_table_d4[] = {
  {"airy", zsp_airy_d4},
  {"airye", zsp_airye_d4},
};

static const struct {
  const char *name;
  zsp_fn_c4 fn;
} zsp_table_c4[] = {
  {"airy", zsp_airy_c4},
  {"airye", zsp_airye_c4},
};

typedef double (*zsp_fn_dddd)(double, double, double, double);

static const struct {
  const char *name;
  zsp_fn_dddd fn;
} zsp_table_dddd[] = {
  {"hyp2f1", zsp_hyp2f1_dddd},
};

typedef zsp_complex (*zsp_fn_dddc)(double, double, double, zsp_complex);

static const struct {
  const char *name;
  zsp_fn_dddc fn;
} zsp_table_dddc[] = {
  {"hyp2f1", zsp_hyp2f1_dddc},
};

typedef zsp_complex (*zsp_fn_ddc)(double, double, zsp_complex);

static const struct {
  const char *name;
  zsp_fn_ddc fn;
} zsp_table_ddc[] = {
  {"hyp1f1", zsp_hyp1f1_ddc},
};

typedef zsp_complex (*zsp_fn_cd)(zsp_complex, double);

static const struct {
  const char *name;
  zsp_fn_cd fn;
} zsp_table_cd[] = {
  {"zeta_q", zsp_zeta_q_cd},
};

typedef zsp_complex (*zsp_fn_cid)(zsp_complex, int, double);

static const struct {
  const char *name;
  zsp_fn_cid fn;
} zsp_table_cid[] = {
  {"lambertw", zsp_lambertw_cid},
};

typedef void (*zsp_fn_dd4)(double, double, double *);

static const struct {
  const char *name;
  zsp_fn_dd4 fn;
} zsp_table_dd4[] = {
  {"ellipj", zsp_ellipj_dd4},
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

SEXP zsp_call_dc(SEXP name, SEXP v, SEXP z) {
  const char *nm = zsp_name(name);
  ZSP_LOOKUP(zsp_table_dc, zsp_fn_dc, nm);
  R_xlen_t n = XLENGTH(z);
  zsp_check(v, REALSXP, n);
  zsp_check(z, CPLXSXP, n);
  SEXP out = PROTECT(Rf_allocVector(CPLXSXP, n));
  const double *pv = REAL(v);
  const Rcomplex *pz = COMPLEX(z);
  Rcomplex *po = COMPLEX(out);
  zsp_report r = {{0}, {0}};
  zsp_err_take();
  for (R_xlen_t i = 0; i < n; i++) {
    if (R_IsNA(pv[i]) || R_IsNA(pz[i].r) || R_IsNA(pz[i].i)) {
      po[i].r = NA_REAL;
      po[i].i = NA_REAL;
      continue;
    }
    zsp_complex arg;
    arg.re = pz[i].r;
    arg.im = pz[i].i;
    zsp_complex res = fn(pv[i], arg);
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

SEXP zsp_call_ic(SEXP name, SEXP k, SEXP z) {
  const char *nm = zsp_name(name);
  ZSP_LOOKUP(zsp_table_ic, zsp_fn_ic, nm);
  R_xlen_t n = XLENGTH(z);
  zsp_check(k, INTSXP, n);
  zsp_check(z, CPLXSXP, n);
  SEXP out = PROTECT(Rf_allocVector(CPLXSXP, n));
  const int *pk = INTEGER(k);
  const Rcomplex *pz = COMPLEX(z);
  Rcomplex *po = COMPLEX(out);
  zsp_report r = {{0}, {0}};
  zsp_err_take();
  for (R_xlen_t i = 0; i < n; i++) {
    if (pk[i] == NA_INTEGER || R_IsNA(pz[i].r) || R_IsNA(pz[i].i)) {
      po[i].r = NA_REAL;
      po[i].i = NA_REAL;
      continue;
    }
    zsp_complex arg;
    arg.re = pz[i].r;
    arg.im = pz[i].i;
    zsp_complex res = fn(pk[i], arg);
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

/* Four outputs (airy, airye): a list of four vectors, with the report on
   the list. */
SEXP zsp_call_d4(SEXP name, SEXP x) {
  const char *nm = zsp_name(name);
  ZSP_LOOKUP(zsp_table_d4, zsp_fn_d4, nm);
  R_xlen_t n = XLENGTH(x);
  zsp_check(x, REALSXP, n);
  SEXP out = PROTECT(Rf_allocVector(VECSXP, 4));
  double *po[4];
  for (int j = 0; j < 4; j++) {
    SET_VECTOR_ELT(out, j, Rf_allocVector(REALSXP, n));
    po[j] = REAL(VECTOR_ELT(out, j));
  }
  const double *px = REAL(x);
  zsp_report r = {{0}, {0}};
  zsp_err_take();
  for (R_xlen_t i = 0; i < n; i++) {
    if (R_IsNA(px[i])) {
      for (int j = 0; j < 4; j++) {
        po[j][i] = NA_REAL;
      }
      continue;
    }
    double res[4];
    fn(px[i], res);
    for (int j = 0; j < 4; j++) {
      po[j][i] = res[j];
    }
    unsigned int bits = zsp_err_take();
    if (bits) {
      zsp_note(&r, bits, i);
    }
  }
  zsp_attach(out, &r);
  UNPROTECT(1);
  return out;
}

SEXP zsp_call_c4(SEXP name, SEXP z) {
  const char *nm = zsp_name(name);
  ZSP_LOOKUP(zsp_table_c4, zsp_fn_c4, nm);
  R_xlen_t n = XLENGTH(z);
  zsp_check(z, CPLXSXP, n);
  SEXP out = PROTECT(Rf_allocVector(VECSXP, 4));
  Rcomplex *po[4];
  for (int j = 0; j < 4; j++) {
    SET_VECTOR_ELT(out, j, Rf_allocVector(CPLXSXP, n));
    po[j] = COMPLEX(VECTOR_ELT(out, j));
  }
  const Rcomplex *pz = COMPLEX(z);
  zsp_report r = {{0}, {0}};
  zsp_err_take();
  for (R_xlen_t i = 0; i < n; i++) {
    if (R_IsNA(pz[i].r) || R_IsNA(pz[i].i)) {
      for (int j = 0; j < 4; j++) {
        po[j][i].r = NA_REAL;
        po[j][i].i = NA_REAL;
      }
      continue;
    }
    zsp_complex arg;
    arg.re = pz[i].r;
    arg.im = pz[i].i;
    zsp_complex res[4];
    fn(arg, res);
    for (int j = 0; j < 4; j++) {
      po[j][i].r = res[j].re;
      po[j][i].i = res[j].im;
    }
    unsigned int bits = zsp_err_take();
    if (bits) {
      zsp_note(&r, bits, i);
    }
  }
  zsp_attach(out, &r);
  UNPROTECT(1);
  return out;
}

SEXP zsp_call_dddd(SEXP name, SEXP a0, SEXP a1, SEXP a2, SEXP a3) {
  const char *nm = zsp_name(name);
  ZSP_LOOKUP(zsp_table_dddd, zsp_fn_dddd, nm);
  R_xlen_t n = XLENGTH(a0);
  zsp_check(a0, REALSXP, n);
  zsp_check(a1, REALSXP, n);
  zsp_check(a2, REALSXP, n);
  zsp_check(a3, REALSXP, n);
  SEXP out = PROTECT(Rf_allocVector(REALSXP, n));
  const double *pa0 = REAL(a0);
  const double *pa1 = REAL(a1);
  const double *pa2 = REAL(a2);
  const double *pa3 = REAL(a3);
  double *po = REAL(out);
  zsp_report r = {{0}, {0}};
  zsp_err_take();
  for (R_xlen_t i = 0; i < n; i++) {
    if (R_IsNA(pa0[i]) || R_IsNA(pa1[i]) || R_IsNA(pa2[i]) || R_IsNA(pa3[i])) {
      po[i] = NA_REAL;
      continue;
    }
    po[i] = fn(pa0[i], pa1[i], pa2[i], pa3[i]);
    unsigned int bits = zsp_err_take();
    if (bits) {
      zsp_note(&r, bits, i);
    }
  }
  zsp_attach(out, &r);
  UNPROTECT(1);
  return out;
}

SEXP zsp_call_dddc(SEXP name, SEXP a0, SEXP a1, SEXP a2, SEXP a3) {
  const char *nm = zsp_name(name);
  ZSP_LOOKUP(zsp_table_dddc, zsp_fn_dddc, nm);
  R_xlen_t n = XLENGTH(a0);
  zsp_check(a0, REALSXP, n);
  zsp_check(a1, REALSXP, n);
  zsp_check(a2, REALSXP, n);
  zsp_check(a3, CPLXSXP, n);
  SEXP out = PROTECT(Rf_allocVector(CPLXSXP, n));
  const double *pa0 = REAL(a0);
  const double *pa1 = REAL(a1);
  const double *pa2 = REAL(a2);
  const Rcomplex *pa3 = COMPLEX(a3);
  Rcomplex *po = COMPLEX(out);
  zsp_report r = {{0}, {0}};
  zsp_err_take();
  for (R_xlen_t i = 0; i < n; i++) {
    if (R_IsNA(pa0[i]) || R_IsNA(pa1[i]) || R_IsNA(pa2[i]) || R_IsNA(pa3[i].r) || R_IsNA(pa3[i].i)) {
      po[i].r = NA_REAL;
      po[i].i = NA_REAL;
      continue;
    }
    zsp_complex ca3;
    ca3.re = pa3[i].r;
    ca3.im = pa3[i].i;
    zsp_complex res = fn(pa0[i], pa1[i], pa2[i], ca3);
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

SEXP zsp_call_ddc(SEXP name, SEXP a0, SEXP a1, SEXP a2) {
  const char *nm = zsp_name(name);
  ZSP_LOOKUP(zsp_table_ddc, zsp_fn_ddc, nm);
  R_xlen_t n = XLENGTH(a0);
  zsp_check(a0, REALSXP, n);
  zsp_check(a1, REALSXP, n);
  zsp_check(a2, CPLXSXP, n);
  SEXP out = PROTECT(Rf_allocVector(CPLXSXP, n));
  const double *pa0 = REAL(a0);
  const double *pa1 = REAL(a1);
  const Rcomplex *pa2 = COMPLEX(a2);
  Rcomplex *po = COMPLEX(out);
  zsp_report r = {{0}, {0}};
  zsp_err_take();
  for (R_xlen_t i = 0; i < n; i++) {
    if (R_IsNA(pa0[i]) || R_IsNA(pa1[i]) || R_IsNA(pa2[i].r) || R_IsNA(pa2[i].i)) {
      po[i].r = NA_REAL;
      po[i].i = NA_REAL;
      continue;
    }
    zsp_complex ca2;
    ca2.re = pa2[i].r;
    ca2.im = pa2[i].i;
    zsp_complex res = fn(pa0[i], pa1[i], ca2);
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

SEXP zsp_call_cd(SEXP name, SEXP a0, SEXP a1) {
  const char *nm = zsp_name(name);
  ZSP_LOOKUP(zsp_table_cd, zsp_fn_cd, nm);
  R_xlen_t n = XLENGTH(a0);
  zsp_check(a0, CPLXSXP, n);
  zsp_check(a1, REALSXP, n);
  SEXP out = PROTECT(Rf_allocVector(CPLXSXP, n));
  const Rcomplex *pa0 = COMPLEX(a0);
  const double *pa1 = REAL(a1);
  Rcomplex *po = COMPLEX(out);
  zsp_report r = {{0}, {0}};
  zsp_err_take();
  for (R_xlen_t i = 0; i < n; i++) {
    if (R_IsNA(pa0[i].r) || R_IsNA(pa0[i].i) || R_IsNA(pa1[i])) {
      po[i].r = NA_REAL;
      po[i].i = NA_REAL;
      continue;
    }
    zsp_complex ca0;
    ca0.re = pa0[i].r;
    ca0.im = pa0[i].i;
    zsp_complex res = fn(ca0, pa1[i]);
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

SEXP zsp_call_cid(SEXP name, SEXP a0, SEXP a1, SEXP a2) {
  const char *nm = zsp_name(name);
  ZSP_LOOKUP(zsp_table_cid, zsp_fn_cid, nm);
  R_xlen_t n = XLENGTH(a0);
  zsp_check(a0, CPLXSXP, n);
  zsp_check(a1, INTSXP, n);
  zsp_check(a2, REALSXP, n);
  SEXP out = PROTECT(Rf_allocVector(CPLXSXP, n));
  const Rcomplex *pa0 = COMPLEX(a0);
  const int *pa1 = INTEGER(a1);
  const double *pa2 = REAL(a2);
  Rcomplex *po = COMPLEX(out);
  zsp_report r = {{0}, {0}};
  zsp_err_take();
  for (R_xlen_t i = 0; i < n; i++) {
    if (R_IsNA(pa0[i].r) || R_IsNA(pa0[i].i) || pa1[i] == NA_INTEGER || R_IsNA(pa2[i])) {
      po[i].r = NA_REAL;
      po[i].i = NA_REAL;
      continue;
    }
    zsp_complex ca0;
    ca0.re = pa0[i].r;
    ca0.im = pa0[i].i;
    zsp_complex res = fn(ca0, pa1[i], pa2[i]);
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

SEXP zsp_call_dd4(SEXP name, SEXP u, SEXP m) {
  const char *nm = zsp_name(name);
  ZSP_LOOKUP(zsp_table_dd4, zsp_fn_dd4, nm);
  R_xlen_t n = XLENGTH(u);
  zsp_check(u, REALSXP, n);
  zsp_check(m, REALSXP, n);
  SEXP out = PROTECT(Rf_allocVector(VECSXP, 4));
  double *po[4];
  for (int j = 0; j < 4; j++) {
    SET_VECTOR_ELT(out, j, Rf_allocVector(REALSXP, n));
    po[j] = REAL(VECTOR_ELT(out, j));
  }
  const double *pu = REAL(u), *pm = REAL(m);
  zsp_report r = {{0}, {0}};
  zsp_err_take();
  for (R_xlen_t i = 0; i < n; i++) {
    if (R_IsNA(pu[i]) || R_IsNA(pm[i])) {
      for (int j = 0; j < 4; j++) {
        po[j][i] = NA_REAL;
      }
      continue;
    }
    double res[4];
    fn(pu[i], pm[i], res);
    for (int j = 0; j < 4; j++) {
      po[j][i] = res[j];
    }
    unsigned int bits = zsp_err_take();
    if (bits) {
      zsp_note(&r, bits, i);
    }
  }
  zsp_attach(out, &r);
  UNPROTECT(1);
  return out;
}

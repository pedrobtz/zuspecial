/* zuspecial public C API: scipy.special's functions from C.
 *
 * Downstream packages use this via, in DESCRIPTION:
 *
 *     Imports:    zuspecial   (guarantees only that zuspecial is INSTALLED)
 *     LinkingTo:  zuspecial   (puts this header on the include path)
 *
 * and, in NAMESPACE, an import directive such as
 *
 *     importFrom(zuspecial, zuspecial_info)
 *
 * which is REQUIRED: the table is registered when zuspecial's namespace is
 * LOADED, and Imports: alone does not load it. Then call through the table
 * -- see zuspecial_api_get() below. No xsf, Boost or C++ type appears here;
 * this header is plain C99.
 *
 * ---- members ------------------------------------------------------------
 * Each member evaluates one function for one argument set, exactly as the
 * R function sc_<name>() does element by element, and returns the value. If
 * `code` is not NULL it receives the lowest-numbered sf_error code the
 * evaluation raised (1 singular, 2 underflow, 3 overflow, 4 slow, 5 loss,
 * 6 no_result, 7 domain, 8 arg, 9 other, 10 memory), or 0 when it raised
 * none. The R-level actions of sc_seterr() do not apply: the caller decides
 * what a code means. R's NA is not special-cased; it is a NaN like any other.
 *
 * Every member is reentrant, allocates nothing through R and is safe from
 * any thread: the codes are collected in thread-local storage. Getting the
 * table is not: zuspecial_api_get() calls R and fills a static cache, so
 * call it once on R's main thread (in R_init_<pkg>, or before a parallel
 * region) and pass the pointer to the workers.
 *
 * Some members are named after C functions (erf, erfc, gamma). <tgmath.h>
 * defines those names as function-like macros, so a consumer that includes
 * it writes (api->erf)(x) rather than api->erf(x).
 *
 * ---- versioning ---------------------------------------------------------
 *   * struct_size versions THIS TABLE. Members are appended, never reordered
 *     or removed; test for one with ZUSPECIAL_API_HAS(api, member).
 *   * The registered NAME versions the other types in this header
 *     (zuspecial_complex), which struct_size cannot see: a layout change
 *     there bumps it to zuspecial_api_v2, so a stale consumer fails at
 *     R_GetCCallable() instead of reading through the wrong offsets.
 *
 *   zuspecial_api_v1 -- initial.
 * ------------------------------------------------------------------------ */

#ifndef ZUSPECIAL_H
#define ZUSPECIAL_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  double re, im;
} zuspecial_complex;

typedef struct {
  uint32_t struct_size; /* the only version discriminator */
  const char *xsf_commit; /* the vendored xsf commit */
  double (*gamma)(double x, int *code);
  double (*gammaln)(double x, int *code);
  double (*gammasgn)(double x, int *code);
  double (*rgamma)(double x, int *code);
  double (*psi)(double x, int *code);
  double (*beta)(double a, double b, int *code);
  double (*betaln)(double a, double b, int *code);
  double (*binom)(double x, double y, int *code);
  double (*gammainc)(double a, double x, int *code);
  double (*gammaincc)(double a, double x, int *code);
  double (*gammaincinv)(double a, double y, int *code);
  double (*gammainccinv)(double a, double y, int *code);
  double (*betainc)(double a, double b, double x, int *code);
  double (*betaincc)(double a, double b, double x, int *code);
  double (*betaincinv)(double a, double b, double y, int *code);
  double (*betainccinv)(double a, double b, double y, int *code);
  double (*erf)(double x, int *code);
  double (*erfc)(double x, int *code);
  double (*erfcx)(double x, int *code);
  double (*erfinv)(double y, int *code);
  double (*erfcinv)(double y, int *code);
  double (*ndtr)(double x, int *code);
  double (*log_ndtr)(double x, int *code);
  double (*ndtri)(double y, int *code);
  double (*ndtri_exp)(double y, int *code);
  double (*owens_t)(double h, double a, int *code);
  double (*jv)(double v, double x, int *code);
  double (*yv)(double v, double x, int *code);
  double (*iv)(double v, double x, int *code);
  double (*kv)(double v, double x, int *code);
  double (*zeta)(double x, int *code);
  zuspecial_complex (*jv_c)(double v, zuspecial_complex z, int *code);
} zuspecial_api;

#define ZUSPECIAL_API_HAS(api, member)                                        \
  ((api)->struct_size >= offsetof(zuspecial_api, member) + sizeof((api)->member))

#ifdef ZUSPECIAL_DEFINE_API_GET
/* Downstream: define ZUSPECIAL_DEFINE_API_GET in exactly one translation
 * unit, after including <R.h> and <R_ext/Rdynload.h>, to emit this accessor.
 *
 * R_GetCCallable() returns DL_FUNC, void *(*)(void). Casting that straight
 * to the real signature compiles, but clang rejects it under
 * -Wcast-function-type; reading the pointer back through a union avoids the
 * cast. R_GetCCallable() raises an R error itself when zuspecial's
 * namespace is not loaded or the name is unknown.
 *
 * Call it first on R's main thread (see "members" above). The cached
 * pointer stays valid while zuspecial's DLL is loaded; a consumer that
 * outlives an unload and reload of zuspecial (pkgload, during development)
 * must be reloaded too. */
static const zuspecial_api *
zuspecial_api_get(void) {
  static const zuspecial_api *api = NULL;
  if (api == NULL) {
    union {
      DL_FUNC fn;
      const zuspecial_api *(*get)(void);
    } resolve;
    resolve.fn = R_GetCCallable("zuspecial", "zuspecial_api_v1");
    if (resolve.fn != NULL)
      api = resolve.get();
  }
  return api;
}
#endif

#ifdef __cplusplus
}
#endif
#endif /* ZUSPECIAL_H */

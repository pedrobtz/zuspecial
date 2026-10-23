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

double zsp_gamma(double x) ZSP_NOEXCEPT;

#ifdef __cplusplus
}
#endif

#endif

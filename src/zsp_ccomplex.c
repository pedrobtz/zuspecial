/* Complex square root and power as NumPy computes them, for the code ported
   from SciPy's Cython (src/zsp_shim_hyper.h), whose zsqrt and zpow are
   npy_csqrt and npy_cpow. std::sqrt and std::pow on std::complex round
   differently: in hyp0f1 at large order the difference reaches 256 ulps.

   npy_csqrt is the C library's csqrt. npy_cpow (numpy/_core/src/npymath/
   npy_math_complex.c.src, BSD-3-Clause, NumPy developers) handles small
   integer exponents by repeated squaring and otherwise calls cpow; ported
   here. Values are moved through the double[2] representation C11 gives
   complex types (6.2.5), not CMPLX, which not every C library defines. */

#include <complex.h>

#include "zsp_shim.h"

static double complex zsp_pack(double re, double im) {
  double complex z;
  ((double *) &z)[0] = re;
  ((double *) &z)[1] = im;
  return z;
}

static zsp_complex zsp_unpack(double complex z) {
  zsp_complex out;
  out.re = ((double *) &z)[0];
  out.im = ((double *) &z)[1];
  return out;
}

zsp_complex zsp_csqrt(zsp_complex z) {
  return zsp_unpack(csqrt(zsp_pack(z.re, z.im)));
}

/* NumPy's cmul and cdiv, as npy_cpow uses them. */
static zsp_complex zsp_cmul(zsp_complex a, zsp_complex b) {
  zsp_complex out;
  out.re = a.re * b.re - a.im * b.im;
  out.im = a.re * b.im + a.im * b.re;
  return out;
}

static zsp_complex zsp_cdiv(zsp_complex a, zsp_complex b) {
  double abs_br = b.re < 0 ? -b.re : b.re;
  double abs_bi = b.im < 0 ? -b.im : b.im;
  zsp_complex out;
  if (abs_br >= abs_bi) {
    if (abs_br == 0 && abs_bi == 0) {
      /* Division by zero: a complex inf or nan. */
      out.re = a.re / abs_br;
      out.im = a.im / abs_bi;
    } else {
      double rat = b.im / b.re;
      double scl = 1.0 / (b.re + b.im * rat);
      out.re = (a.re + a.im * rat) * scl;
      out.im = (a.im - a.re * rat) * scl;
    }
  } else {
    double rat = b.re / b.im;
    double scl = 1.0 / (b.im + b.re * rat);
    out.re = (a.re * rat + a.im) * scl;
    out.im = (a.im * rat - a.re) * scl;
  }
  return out;
}

zsp_complex zsp_cpow(zsp_complex a, zsp_complex b) {
  zsp_complex one = {1.0, 0.0};
  if (b.re == 0.0 && b.im == 0.0) {
    return one;
  }
  if (a.re == 0.0 && a.im == 0.0) {
    zsp_complex out;
    if (b.re > 0 && b.im == 0) {
      out.re = 0.0;
      out.im = 0.0;
    } else {
      /* 0 to a negative or complex power is ill-defined. */
      volatile double zero = 0.0;
      out.re = zero / zero; /* NaN, raising invalid as NumPy does */
      out.im = out.re;
    }
    return out;
  }
  if (b.im == 0 && b.re > -100 && b.re < 100 && (double) (long) b.re == b.re) {
    long n = (long) b.re;
    if (n == 1) {
      return a;
    }
    if (n == 2) {
      return zsp_cmul(a, a);
    }
    if (n == 3) {
      return zsp_cmul(a, zsp_cmul(a, a));
    }
    zsp_complex aa = one, p = a;
    long mask = 1;
    if (n < 0) {
      n = -n;
    }
    for (;;) {
      if (n & mask) {
        aa = zsp_cmul(aa, p);
      }
      mask <<= 1;
      if (n < mask || mask <= 0) {
        break;
      }
      p = zsp_cmul(p, p);
    }
    return b.re < 0 ? zsp_cdiv(one, aa) : aa;
  }
  return zsp_unpack(cpow(zsp_pack(a.re, a.im), zsp_pack(b.re, b.im)));
}

#ifndef ZSP_COMPLEX_HPP
#define ZSP_COMPLEX_HPP

// zsp_complex and std::complex<double> never alias: convert by member
// (design section 4).

#include <complex>

#include "zsp_shim.h"

inline std::complex<double> zsp_to_std(zsp_complex z) {
  return std::complex<double>(z.re, z.im);
}

inline zsp_complex zsp_from_std(std::complex<double> z) {
  zsp_complex out;
  out.re = z.real();
  out.im = z.imag();
  return out;
}

#endif

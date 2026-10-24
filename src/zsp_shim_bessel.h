// Shim for the Bessel family: cylindrical, Hankel, spherical and Airy
// functions. Included only by zsp_shim.cpp.

#include "xsf/airy.h"
#include "xsf/bessel.h"
#include "xsf/sph_bessel.h"

#include "zsp_complex.h"

extern "C" {

double zsp_jv_dd(double v, double x) noexcept { return xsf::cyl_bessel_j(v, x); }
zsp_complex zsp_jv_dc(double v, zsp_complex z) noexcept {
  return zsp_from_std(xsf::cyl_bessel_j(v, zsp_to_std(z)));
}
double zsp_yv_dd(double v, double x) noexcept { return xsf::cyl_bessel_y(v, x); }
zsp_complex zsp_yv_dc(double v, zsp_complex z) noexcept {
  return zsp_from_std(xsf::cyl_bessel_y(v, zsp_to_std(z)));
}
double zsp_iv_dd(double v, double x) noexcept { return xsf::cyl_bessel_i(v, x); }
zsp_complex zsp_iv_dc(double v, zsp_complex z) noexcept {
  return zsp_from_std(xsf::cyl_bessel_i(v, zsp_to_std(z)));
}
double zsp_kv_dd(double v, double x) noexcept { return xsf::cyl_bessel_k(v, x); }
zsp_complex zsp_kv_dc(double v, zsp_complex z) noexcept {
  return zsp_from_std(xsf::cyl_bessel_k(v, zsp_to_std(z)));
}
double zsp_jve_dd(double v, double x) noexcept { return xsf::cyl_bessel_je(v, x); }
zsp_complex zsp_jve_dc(double v, zsp_complex z) noexcept {
  return zsp_from_std(xsf::cyl_bessel_je(v, zsp_to_std(z)));
}
double zsp_yve_dd(double v, double x) noexcept { return xsf::cyl_bessel_ye(v, x); }
zsp_complex zsp_yve_dc(double v, zsp_complex z) noexcept {
  return zsp_from_std(xsf::cyl_bessel_ye(v, zsp_to_std(z)));
}
double zsp_ive_dd(double v, double x) noexcept { return xsf::cyl_bessel_ie(v, x); }
zsp_complex zsp_ive_dc(double v, zsp_complex z) noexcept {
  return zsp_from_std(xsf::cyl_bessel_ie(v, zsp_to_std(z)));
}
double zsp_kve_dd(double v, double x) noexcept { return xsf::cyl_bessel_ke(v, x); }
zsp_complex zsp_kve_dc(double v, zsp_complex z) noexcept {
  return zsp_from_std(xsf::cyl_bessel_ke(v, zsp_to_std(z)));
}
zsp_complex zsp_hankel1_dc(double v, zsp_complex z) noexcept {
  return zsp_from_std(xsf::cyl_hankel_1(v, zsp_to_std(z)));
}
zsp_complex zsp_hankel2_dc(double v, zsp_complex z) noexcept {
  return zsp_from_std(xsf::cyl_hankel_2(v, zsp_to_std(z)));
}
zsp_complex zsp_hankel1e_dc(double v, zsp_complex z) noexcept {
  return zsp_from_std(xsf::cyl_hankel_1e(v, zsp_to_std(z)));
}
zsp_complex zsp_hankel2e_dc(double v, zsp_complex z) noexcept {
  return zsp_from_std(xsf::cyl_hankel_2e(v, zsp_to_std(z)));
}
double zsp_j0_d(double x) noexcept { return xsf::cyl_bessel_j0(x); }
double zsp_j1_d(double x) noexcept { return xsf::cyl_bessel_j1(x); }
double zsp_y0_d(double x) noexcept { return xsf::cyl_bessel_y0(x); }
double zsp_y1_d(double x) noexcept { return xsf::cyl_bessel_y1(x); }
double zsp_i0_d(double x) noexcept { return xsf::cyl_bessel_i0(x); }
double zsp_i0e_d(double x) noexcept { return xsf::cyl_bessel_i0e(x); }
double zsp_i1_d(double x) noexcept { return xsf::cyl_bessel_i1(x); }
double zsp_i1e_d(double x) noexcept { return xsf::cyl_bessel_i1e(x); }
double zsp_k0_d(double x) noexcept { return xsf::cyl_bessel_k0(x); }
double zsp_k0e_d(double x) noexcept { return xsf::cyl_bessel_k0e(x); }
double zsp_k1_d(double x) noexcept { return xsf::cyl_bessel_k1(x); }
double zsp_k1e_d(double x) noexcept { return xsf::cyl_bessel_k1e(x); }
double zsp_spherical_jn_id(int n, double x) noexcept {
  return xsf::sph_bessel_j(static_cast<long>(n), x);
}
zsp_complex zsp_spherical_jn_ic(int n, zsp_complex z) noexcept {
  return zsp_from_std(xsf::sph_bessel_j(static_cast<long>(n), zsp_to_std(z)));
}
double zsp_spherical_jn_d_id(int n, double x) noexcept {
  return xsf::sph_bessel_j_jac(static_cast<long>(n), x);
}
zsp_complex zsp_spherical_jn_d_ic(int n, zsp_complex z) noexcept {
  return zsp_from_std(xsf::sph_bessel_j_jac(static_cast<long>(n), zsp_to_std(z)));
}
double zsp_spherical_yn_id(int n, double x) noexcept {
  return xsf::sph_bessel_y(static_cast<long>(n), x);
}
zsp_complex zsp_spherical_yn_ic(int n, zsp_complex z) noexcept {
  return zsp_from_std(xsf::sph_bessel_y(static_cast<long>(n), zsp_to_std(z)));
}
double zsp_spherical_yn_d_id(int n, double x) noexcept {
  return xsf::sph_bessel_y_jac(static_cast<long>(n), x);
}
zsp_complex zsp_spherical_yn_d_ic(int n, zsp_complex z) noexcept {
  return zsp_from_std(xsf::sph_bessel_y_jac(static_cast<long>(n), zsp_to_std(z)));
}
double zsp_spherical_in_id(int n, double x) noexcept {
  return xsf::sph_bessel_i(static_cast<long>(n), x);
}
zsp_complex zsp_spherical_in_ic(int n, zsp_complex z) noexcept {
  return zsp_from_std(xsf::sph_bessel_i(static_cast<long>(n), zsp_to_std(z)));
}
double zsp_spherical_in_d_id(int n, double x) noexcept {
  return xsf::sph_bessel_i_jac(static_cast<long>(n), x);
}
zsp_complex zsp_spherical_in_d_ic(int n, zsp_complex z) noexcept {
  return zsp_from_std(xsf::sph_bessel_i_jac(static_cast<long>(n), zsp_to_std(z)));
}
double zsp_spherical_kn_id(int n, double x) noexcept {
  return xsf::sph_bessel_k(static_cast<long>(n), x);
}
zsp_complex zsp_spherical_kn_ic(int n, zsp_complex z) noexcept {
  return zsp_from_std(xsf::sph_bessel_k(static_cast<long>(n), zsp_to_std(z)));
}
double zsp_spherical_kn_d_id(int n, double x) noexcept {
  return xsf::sph_bessel_k_jac(static_cast<long>(n), x);
}
zsp_complex zsp_spherical_kn_d_ic(int n, zsp_complex z) noexcept {
  return zsp_from_std(xsf::sph_bessel_k_jac(static_cast<long>(n), zsp_to_std(z)));
}
void zsp_airy_d4(double x, double *out) noexcept {
  xsf::airy(x, out[0], out[1], out[2], out[3]);
}
void zsp_airy_c4(zsp_complex z, zsp_complex *out) noexcept {
  std::complex<double> ai, aip, bi, bip;
  xsf::airy(zsp_to_std(z), ai, aip, bi, bip);
  out[0] = zsp_from_std(ai);
  out[1] = zsp_from_std(aip);
  out[2] = zsp_from_std(bi);
  out[3] = zsp_from_std(bip);
}
void zsp_airye_d4(double x, double *out) noexcept {
  xsf::airye(x, out[0], out[1], out[2], out[3]);
}
void zsp_airye_c4(zsp_complex z, zsp_complex *out) noexcept {
  std::complex<double> ai, aip, bi, bip;
  xsf::airye(zsp_to_std(z), ai, aip, bi, bip);
  out[0] = zsp_from_std(ai);
  out[1] = zsp_from_std(aip);
  out[2] = zsp_from_std(bi);
  out[3] = zsp_from_std(bip);
}

} // extern "C"

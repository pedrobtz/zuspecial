// The functions SciPy 1.18.1 evaluates with Boost.Math rather than xsf
// (design section 12.1): betainc, betaincc, betaincinv, betainccinv and
// erfinv. Ported from scipy/special/boost_special_functions.h (BSD-3-Clause,
// SciPy developers): the same policies, the same special cases before the
// call, and Boost's exceptions caught into the same sf_error codes, through
// xsf::set_error.
//
// A translation unit of its own: it includes no xsf kernels, only
// xsf/error.h, so it cannot clash with zsp_shim.cpp (see there).

#define BOOST_MATH_STANDALONE

#include <cmath>
#include <limits>
#include <stdexcept>

#include <boost/math/special_functions/beta.hpp>
#include <boost/math/special_functions/erf.hpp>
#include <boost/version.hpp>

#include "xsf/error.h"

#include "zsp_shim.h"

namespace {

typedef boost::math::policies::policy<
    boost::math::policies::promote_float<false>,
    boost::math::policies::promote_double<false>,
    boost::math::policies::max_root_iterations<400>,
    boost::math::policies::discrete_quantile<boost::math::policies::real>>
    SpecialPolicy;

const double nan = std::numeric_limits<double>::quiet_NaN();
const double inf = std::numeric_limits<double>::infinity();

// Calls f, mapping Boost's exceptions as SciPy's wrappers do.
template <typename F>
double guarded(const char *name, F f) noexcept {
  try {
    return f();
  } catch (const std::domain_error &) {
    xsf::set_error(name, SF_ERROR_DOMAIN, nullptr);
    return nan;
  } catch (const std::overflow_error &) {
    xsf::set_error(name, SF_ERROR_OVERFLOW, nullptr);
    return inf;
  } catch (const std::underflow_error &) {
    xsf::set_error(name, SF_ERROR_UNDERFLOW, nullptr);
    return 0;
  } catch (...) {
    xsf::set_error(name, SF_ERROR_OTHER, nullptr);
    return nan;
  }
}

// In limiting cases SciPy treats betainc (and betaincc) as a two-parameter
// family of functions of x, taking the pointwise limit in x. Returns true
// and sets *out when (a, b, x) is such a case or invalid.
bool beta_limits(const char *name, double a, double b, double x, bool upper,
                 double *out) {
  if (std::isnan(a) || std::isnan(b) || std::isnan(x)) {
    *out = nan;
    return true;
  }
  if (a < 0 || b < 0 || x < 0 || x > 1) {
    xsf::set_error(name, SF_ERROR_DOMAIN, nullptr);
    *out = nan;
    return true;
  }
  if ((a == 0 && b == 0) || (std::isinf(a) && std::isinf(b))) {
    *out = nan; // indeterminate: depends on the path to the limit
    return true;
  }
  if (a == 0 || std::isinf(b)) { // point mass at x = 0
    *out = upper ? (x > 0 ? 0 : 1) : (x > 0 ? 1 : 0);
    return true;
  }
  if (b == 0 || std::isinf(a)) { // point mass at x = 1
    *out = upper ? (x < 1 ? 1 : 0) : (x < 1 ? 0 : 1);
    return true;
  }
  return false;
}

bool beta_inv_domain(const char *name, double a, double b, double p,
                     double *out) {
  if (std::isnan(a) || std::isnan(b) || std::isnan(p)) {
    *out = nan;
    return true;
  }
  if (a <= 0 || b <= 0 || p < 0 || p > 1) {
    xsf::set_error(name, SF_ERROR_DOMAIN, nullptr);
    *out = nan;
    return true;
  }
  return false;
}

} // namespace

extern "C" {

double zsp_betainc_ddd(double a, double b, double x) noexcept {
  double out;
  if (beta_limits("betainc", a, b, x, false, &out)) {
    return out;
  }
  return guarded("betainc",
                 [=] { return boost::math::ibeta(a, b, x, SpecialPolicy()); });
}

double zsp_betaincc_ddd(double a, double b, double x) noexcept {
  double out;
  if (beta_limits("betaincc", a, b, x, true, &out)) {
    return out;
  }
  // SciPy calls ibetac with Boost's default policy, not SpecialPolicy.
  return guarded("betaincc", [=] { return boost::math::ibetac(a, b, x); });
}

double zsp_betaincinv_ddd(double a, double b, double y) noexcept {
  double out;
  if (beta_inv_domain("betaincinv", a, b, y, &out)) {
    return out;
  }
  return guarded("betaincinv", [=] {
    return boost::math::ibeta_inv(a, b, y, SpecialPolicy());
  });
}

double zsp_betainccinv_ddd(double a, double b, double y) noexcept {
  double out;
  if (beta_inv_domain("betainccinv", a, b, y, &out)) {
    return out;
  }
  return guarded("betainccinv", [=] {
    return boost::math::ibetac_inv(a, b, y, SpecialPolicy());
  });
}

double zsp_erfinv_d(double y) noexcept {
  if (y == -1) {
    return -inf;
  }
  if (y == 1) {
    return inf;
  }
  return guarded("erfinv",
                 [=] { return boost::math::erf_inv(y, SpecialPolicy()); });
}

// BOOST_VERSION of the Boost.Math headers this build used, for
// zuspecial_info().
int zsp_boost_version(void) noexcept { return BOOST_VERSION; }

} // extern "C"

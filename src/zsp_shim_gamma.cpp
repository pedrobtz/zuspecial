// Shim for the gamma and beta family (design section 4).

#include "xsf/gamma.h"

#include "zsp_shim.h"

extern "C" double zsp_gamma(double x) noexcept { return xsf::gamma(x); }

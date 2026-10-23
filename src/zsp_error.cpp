#include "xsf/error.h"

#include "zsp_shim.h"

// The only mutable state in the shim. thread_local, so the C table (design
// section 7) is safe from any thread.
static thread_local unsigned int zsp_err_bits = 0;

namespace xsf {

// Declared by xsf/error.h under SP_SPECFUN_ERROR. Records the code and
// nothing else: it never signals, allocates or calls R (design section 6.4).
void set_error(const char *, sf_error_t code, const char *, ...) {
  if (code > SF_ERROR_OK && code < SF_ERROR__LAST) {
    zsp_err_bits |= 1u << code;
  }
}

} // namespace xsf

extern "C" unsigned int zsp_err_take(void) noexcept {
  unsigned int bits = zsp_err_bits;
  zsp_err_bits = 0;
  return bits;
}

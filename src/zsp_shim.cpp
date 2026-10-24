// The C++ shim over xsf, as one translation unit.
//
// xsf defines some non-inline, non-template functions in its headers
// (cephes::chbevl, cephes::rgamma, the erfcx in faddeeva.h, ...), as SciPy
// compiles it into a single unit. Including those headers from two units
// breaks the one-definition rule at link time, so every family's entries
// live in a header included here and nowhere else.

#include "zsp_shim_bessel.h"
#include "zsp_shim_error.h"
#include "zsp_shim_gamma.h"
#include "zsp_shim_hyper.h"

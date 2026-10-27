#' @section Windows:
#' R on Windows is built with Rtools, whose C library (mingw-w64 v11)
#' evaluates `sin()` and `cos()` inaccurately for arguments beyond about
#' `1e5`, as base R's own `sin()` shows there. Complex arguments with a part
#' that large, and real ones where the kernel takes a sine of such a value,
#' are correspondingly inaccurate on Windows only.

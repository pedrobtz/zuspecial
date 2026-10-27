#' @details
#' Arguments are recycled: each must have length one or the common length.
#' `NA` gives `NA`; `NaN` is evaluated as SciPy does. The result takes its
#' dimensions, or else its names, from the arguments as base R arithmetic
#' does, and so does each element of a list result. Conditions the kernels
#' raise, such as a pole, are handled as [sc_seterr()] says.

# The path every sc_ function takes: prepare the arguments, pick the loop
# for the signature and path, then give the result its attributes and signal
# any error codes under the current actions.
#
# `name` is the kernel's SciPy name. `whole` names integer-order arguments,
# which go to the C loop as integers. `complex_only` is for functions SciPy
# registers only for complex input (wofz): real input is promoted.
zsp_eval <- function(name, args, complex_ok = character(), whole = character(),
                     complex_only = FALSE) {
  call <- sys.call(-1)
  prep <- zsp_prep(args, complex_ok, call)
  if (complex_only && !prep$complex) {
    prep$args[complex_ok] <- lapply(prep$args[complex_ok], as.complex)
    prep$complex <- TRUE
  }
  for (arg in whole) {
    prep$args[[arg]] <- zsp_whole(prep$args[[arg]], arg, call)
  }

  routine <- if (prep$complex) {
    zsp_call_c
  } else if (length(whole) > 0L) {
    zsp_call_id
  } else {
    switch(length(args), zsp_call_d, zsp_call_dd, zsp_call_ddd)
  }
  value <- do.call(.Call, c(list(routine, name), unname(prep$args)))

  report <- attr(value, "zsp_err")
  attr(value, "zsp_err") <- NULL
  value <- zsp_finish(value, prep$template)
  if (!is.null(report)) {
    zsp_signal_report(report, paste0("sc_", name), call)
  }
  value
}

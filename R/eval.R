# The path every sc_ function takes: prepare the arguments, pick the loop
# for the signature and path, then give the result its attributes and signal
# any error codes under the current actions.
#
# `name` is the kernel's SciPy name and `fn` the R function conditions name.
# `whole` names integer-order arguments,
# which go to the C loop as integers. `complex_only` is for functions SciPy
# registers only for complex input (wofz): real input is promoted.
zsp_eval <- function(
  name,
  args,
  complex_ok = character(),
  whole = character(),
  complex_only = FALSE,
  outputs = NULL,
  fn = paste0("sc_", name)
) {
  call <- sys.call(-1)
  prep <- zsp_prep(args, complex_ok, call)
  if (complex_only && !prep$complex) {
    prep$args[complex_ok] <- lapply(prep$args[complex_ok], as.complex)
    prep$complex <- TRUE
  }
  nan_order <- logical(prep$n)
  for (arg in whole) {
    nan_order <- nan_order | is.nan(prep$args[[arg]])
    prep$args[[arg]] <- zsp_whole(prep$args[[arg]], arg, call)
  }

  # The loop for this signature: one letter per argument (i whole, c
  # complex, d double), then the number of outputs if more than one.
  types <- vapply(
    names(prep$args),
    function(arg) {
      if (arg %in% whole) {
        "i"
      } else if (is.complex(prep$args[[arg]])) {
        "c"
      } else {
        "d"
      }
    },
    ""
  )
  signature <- paste0(paste(types, collapse = ""), length(outputs) %|0|% "")
  routine <- switch(
    signature,
    d = zsp_call_d,
    c = zsp_call_c,
    dd = zsp_call_dd,
    ddd = zsp_call_ddd,
    id = zsp_call_id,
    dc = zsp_call_dc,
    ic = zsp_call_ic,
    d4 = zsp_call_d4,
    c4 = zsp_call_c4,
    stop("internal: no loop for signature ", signature)
  )
  value <- do.call(.Call, c(list(routine, name), unname(prep$args)))

  report <- attr(value, "zsp_err")
  attr(value, "zsp_err") <- NULL
  if (is.null(outputs)) {
    value[nan_order] <- NaN
    value <- zsp_finish(value, prep$template)
  } else {
    value <- lapply(value, zsp_finish, template = prep$template)
    names(value) <- outputs
  }
  if (!is.null(report)) {
    zsp_signal_report(report, fn, call)
  }
  value
}

# The output count in a loop's signature: none for one output.
`%|0|%` <- function(n, empty) if (n <= 1L) empty else n

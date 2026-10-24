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
  nan_order <- if (length(whole) > 0L) logical(prep$n)
  for (arg in whole) {
    nan_order <- nan_order | is.nan(prep$args[[arg]])
    prep$args[[arg]] <- zsp_whole(prep$args[[arg]], arg, call)
  }

  # The loop for this signature: one letter per argument (i whole, c
  # complex, d double), then the number of outputs if more than one.
  a <- prep$args
  types <- character(length(a))
  for (j in seq_along(a)) {
    types[[j]] <- if (names(a)[[j]] %in% whole) {
      "i"
    } else if (is.complex(a[[j]])) {
      "c"
    } else {
      "d"
    }
  }
  signature <- paste0(paste(types, collapse = ""), length(outputs) %|0|% "")
  # A direct .Call with the routine named literally, as R CMD check wants;
  # the signature fixes the argument count. do.call() costs more than the
  # loop for short vectors.
  value <- switch(
    signature,
    d = .Call(zsp_call_d, name, a[[1]]),
    c = .Call(zsp_call_c, name, a[[1]]),
    d4 = .Call(zsp_call_d4, name, a[[1]]),
    c4 = .Call(zsp_call_c4, name, a[[1]]),
    dd = .Call(zsp_call_dd, name, a[[1]], a[[2]]),
    id = .Call(zsp_call_id, name, a[[1]], a[[2]]),
    dc = .Call(zsp_call_dc, name, a[[1]], a[[2]]),
    ic = .Call(zsp_call_ic, name, a[[1]], a[[2]]),
    cd = .Call(zsp_call_cd, name, a[[1]], a[[2]]),
    dd4 = .Call(zsp_call_dd4, name, a[[1]], a[[2]]),
    ddd = .Call(zsp_call_ddd, name, a[[1]], a[[2]], a[[3]]),
    ddc = .Call(zsp_call_ddc, name, a[[1]], a[[2]], a[[3]]),
    cid = .Call(zsp_call_cid, name, a[[1]], a[[2]], a[[3]]),
    dddd = .Call(zsp_call_dddd, name, a[[1]], a[[2]], a[[3]], a[[4]]),
    dddc = .Call(zsp_call_dddc, name, a[[1]], a[[2]], a[[3]], a[[4]]),
    stop("internal: no loop for signature ", signature)
  )

  report <- attr(value, "zsp_err")
  attr(value, "zsp_err") <- NULL
  if (is.null(outputs)) {
    if (!is.null(nan_order)) {
      value[nan_order] <- NaN
    }
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

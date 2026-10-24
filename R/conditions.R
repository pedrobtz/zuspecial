# The sf_error_t codes, in the order xsf numbers them (1 to 10).
zsp_codes <- c(
  "singular",
  "underflow",
  "overflow",
  "slow",
  "loss",
  "no_result",
  "domain",
  "arg",
  "other",
  "memory"
)

zsp_condition <- function(class, message, call, fields) {
  structure(
    c(list(message = message, call = call), fields),
    class = c(class, "condition")
  )
}

zsp_abort <- function(class, message, ..., call = NULL) {
  stop(zsp_condition(
    c(class, "zuspecial_error", "error"),
    message,
    call,
    list(...)
  ))
}

zsp_warn <- function(class, message, ..., call = NULL) {
  warning(zsp_condition(
    c(class, "zuspecial_warning", "warning"),
    message,
    call,
    list(...)
  ))
}

# Signals the codes in a report from the C glue: a double vector of length
# 20, the count for code k at k and its first (1-based) index at 10 + k
# (doubles, so long vectors are counted exactly). Each raised code is
# signalled once, under its action in sc_geterr().
zsp_signal_report <- function(report, fn, call = NULL) {
  actions <- sc_geterr()
  for (k in which(report[1:10] > 0)) {
    code <- zsp_codes[[k]]
    count <- report[[k]]
    first <- report[[10L + k]]
    message <- sprintf(
      "%s: %s in %s element%s, first at index %s.",
      fn,
      code,
      format(count, scientific = FALSE),
      if (count == 1) "" else "s",
      format(first, scientific = FALSE)
    )
    switch(
      actions[[code]],
      warn = zsp_warn(
        paste0("zuspecial_", code),
        message,
        fn = fn,
        code = code,
        count = count,
        first_index = first,
        call = call
      ),
      raise = zsp_abort(
        paste0("zuspecial_", code, "_error"),
        message,
        fn = fn,
        code = code,
        count = count,
        first_index = first,
        call = call
      )
    )
  }
  invisible()
}

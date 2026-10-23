zsp_actions <- c("ignore", "warn", "raise")

zsp_default_errstate <- function() {
  state <- c(rep("ignore", length(zsp_codes) - 1L), "raise")
  names(state) <- zsp_codes
  state
}

#' Floating-point error handling
#'
#' xsf, like `scipy.special`, reports conditions such as a pole or a loss of
#' precision through error codes rather than R conditions. These functions
#' choose what each code does, after `scipy.special.geterr()`, `seterr()` and
#' `errstate()`: `"ignore"` it, `"warn"` with a warning of class
#' `zuspecial_warning` and `zuspecial_<code>`, or `"raise"` an error of class
#' `zuspecial_error` and `zuspecial_<code>_error`. Each code is signalled once
#' per call, with the number of elements that raised it and the first one's
#' index.
#'
#' The defaults are SciPy's: every code is ignored except `memory`, which
#' raises. The state lives in the option `zuspecial.errstate`, so parallel
#' workers start from the defaults.
#'
#' @param all Action for every code, applied before the named ones.
#' @param singular,underflow,overflow,slow,loss,no_result,domain,arg,other
#'   Action for that code: `"ignore"`, `"warn"` or `"raise"`. `NULL` leaves
#'   it unchanged.
#' @param expr An expression to evaluate under the temporary actions.
#' @param ... Actions passed to `sc_seterr()` for the duration of `expr`.
#' @returns `sc_geterr()` returns a named character vector with one action
#'   per code. `sc_seterr()` returns the previous state, invisibly.
#'   `sc_errstate()` returns the value of `expr`.
#' @seealso <https://docs.scipy.org/doc/scipy/reference/generated/scipy.special.seterr.html>
#' @examples
#' sc_geterr()
#' sc_errstate(sc_gamma(-1), singular = "warn")
#' @name errstate
NULL

#' @rdname errstate
#' @export
sc_geterr <- function() {
  state <- getOption("zuspecial.errstate")
  if (is.null(state)) zsp_default_errstate() else state
}

#' @rdname errstate
#' @export
sc_seterr <- function(all = NULL, singular = NULL, underflow = NULL,
                      overflow = NULL, slow = NULL, loss = NULL,
                      no_result = NULL, domain = NULL, arg = NULL,
                      other = NULL) {
  old <- sc_geterr()
  new <- old
  given <- list(
    singular = singular, underflow = underflow, overflow = overflow,
    slow = slow, loss = loss, no_result = no_result, domain = domain,
    arg = arg, other = other
  )
  if (!is.null(all)) {
    zsp_check_action(all, "all")
    new[] <- all
  }
  for (code in names(given)) {
    action <- given[[code]]
    if (!is.null(action)) {
      zsp_check_action(action, code)
      new[[code]] <- action
    }
  }
  options(zuspecial.errstate = new)
  invisible(old)
}

#' @rdname errstate
#' @export
sc_errstate <- function(expr, ...) {
  old <- sc_seterr(...)
  on.exit(options(zuspecial.errstate = old), add = TRUE)
  expr
}

zsp_check_action <- function(action, name) {
  if (!is.character(action) || length(action) != 1L || is.na(action) ||
      !action %in% zsp_actions) {
    zsp_abort(
      "zuspecial_invalid_argument",
      sprintf(
        "`%s` must be one of \"ignore\", \"warn\" or \"raise\".", name
      ),
      argument = name,
      call = sys.call(-1)
    )
  }
}

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
#' workers start from the defaults. Set it with `sc_seterr()`; a value set
#' directly is completed from the defaults, and refused if malformed.
#'
#' @param all Action for every code, `memory` included, applied before the
#'   named ones.
#' @param singular,underflow,overflow,slow,loss,no_result,domain,arg,other,memory
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
#'
#' # sc_seterr() returns the previous state; restore it with do.call().
#' old <- sc_seterr(domain = "warn")
#' sc_geterr()[["domain"]]
#' do.call(sc_seterr, as.list(old))
#' @name errstate
NULL

#' @rdname errstate
#' @export
sc_geterr <- function() {
  state <- getOption("zuspecial.errstate")
  default <- zsp_default_errstate()
  if (is.null(state)) {
    return(default)
  }
  # Set by hand, the option may be partial or malformed: complete it from
  # the defaults, and refuse what no action can be read from.
  if (
    !is.character(state) ||
      is.null(names(state)) ||
      !all(names(state) %in% zsp_codes) ||
      anyNA(state) ||
      !all(state %in% zsp_actions)
  ) {
    zsp_abort(
      "zuspecial_invalid_argument",
      paste(
        "The option `zuspecial.errstate` must be a named character vector",
        "of \"ignore\", \"warn\" or \"raise\", one per error code;",
        "set it with `sc_seterr()`."
      ),
      argument = "zuspecial.errstate",
      call = NULL
    )
  }
  default[names(state)] <- state
  default
}

#' @rdname errstate
#' @export
sc_seterr <- function(
  all = NULL,
  singular = NULL,
  underflow = NULL,
  overflow = NULL,
  slow = NULL,
  loss = NULL,
  no_result = NULL,
  domain = NULL,
  arg = NULL,
  other = NULL,
  memory = NULL
) {
  zsp_seterr(
    list(
      all = all,
      singular = singular,
      underflow = underflow,
      overflow = overflow,
      slow = slow,
      loss = loss,
      no_result = no_result,
      domain = domain,
      arg = arg,
      other = other,
      memory = memory
    ),
    sys.call()
  )
}

zsp_seterr <- function(actions, call) {
  old <- sc_geterr()
  new <- old
  all <- actions$all
  given <- actions[names(actions) != "all"]
  if (!is.null(all)) {
    zsp_check_action(all, "all", call)
    new[] <- all
  }
  for (code in names(given)) {
    action <- given[[code]]
    if (!is.null(action)) {
      zsp_check_action(action, code, call)
      new[[code]] <- action
    }
  }
  options(zuspecial.errstate = new)
  invisible(old)
}

#' @rdname errstate
#' @export
sc_errstate <- function(expr, ...) {
  actions <- list(...)
  unknown <- setdiff(names(actions), c("all", zsp_codes))
  unnamed <- is.null(names(actions)) || any(!nzchar(names(actions)))
  if (length(actions) > 0L && (unnamed || length(unknown) > 0L)) {
    zsp_abort(
      "zuspecial_invalid_argument",
      "Actions in `...` must be named `all` or an error code.",
      argument = "...",
      call = sys.call()
    )
  }
  # Restore the option as it was, unset included.
  old <- getOption("zuspecial.errstate")
  zsp_seterr(actions, sys.call())
  on.exit(options(zuspecial.errstate = old), add = TRUE)
  expr
}

zsp_check_action <- function(action, name, call) {
  if (
    !is.character(action) ||
      length(action) != 1L ||
      is.na(action) ||
      !action %in% zsp_actions
  ) {
    zsp_abort(
      "zuspecial_invalid_argument",
      sprintf(
        "`%s` must be one of \"ignore\", \"warn\" or \"raise\".",
        name
      ),
      argument = name,
      call = call
    )
  }
}

# Validates, coerces and recycles the arguments of one call (design 6.1, 6.2).
#
# `args` is a named list of the user's arguments, `complex_ok` the names that
# may be complex. If any of those is complex, all of them become complex and
# the call takes the complex path. Returns the recycled arguments, their
# common length `n`, whether the path is complex, and the `template`: the
# first argument whose length is `n`, whose attributes the result takes.
zsp_prep <- function(args, complex_ok = character(), call = NULL) {
  for (name in names(args)) {
    zsp_check_type(args[[name]], name, name %in% complex_ok, call)
  }

  lengths <- vapply(args, length, integer(1))
  n <- if (any(lengths == 0L)) 0L else max(lengths)
  bad <- n > 0L & lengths != 1L & lengths != n
  if (any(bad)) {
    zsp_abort(
      "zuspecial_recycle_error",
      sprintf(
        "Arguments must have length one or a common length; got %s.",
        paste0("`", names(args), "` ", lengths, collapse = ", ")
      ),
      lengths = lengths,
      call = call
    )
  }

  complex <- any(vapply(args[complex_ok], is.complex, logical(1)))
  template <- NULL
  if (n > 0L) {
    template <- args[[which(lengths == n)[[1]]]]
  }

  for (name in names(args)) {
    x <- args[[name]]
    x <- if (complex && name %in% complex_ok) as.complex(x) else as.double(x)
    args[[name]] <- rep_len(x, n)
  }

  list(args = args, n = n, complex = complex, template = template)
}

zsp_check_type <- function(x, name, complex_ok, call) {
  ok_types <- c("double", "integer", "logical", if (complex_ok) "complex")
  if (is.factor(x) || !typeof(x) %in% ok_types) {
    what <- if (is.factor(x)) "a factor" else paste("of type", typeof(x))
    zsp_abort(
      "zuspecial_invalid_argument",
      sprintf(
        "`%s` must be %s, not %s.",
        name,
        if (complex_ok) "numeric or complex" else "numeric",
        what
      ),
      argument = name,
      call = call
    )
  }
}

# The result takes dim, dimnames and names from the template, as base R's
# arithmetic does.
zsp_finish <- function(value, template) {
  if (is.null(template)) {
    return(value)
  }
  if (!is.null(dim(template))) {
    dim(value) <- dim(template)
    dimnames(value) <- dimnames(template)
  } else if (!is.null(names(template))) {
    names(value) <- names(template)
  }
  value
}

# Integer-order arguments must be whole numbers within int range; NA is kept
# (design 6.2).
zsp_whole <- function(x, name, call = NULL) {
  bad <- !is.na(x) & (is.nan(x) | !is.finite(x) | x != trunc(x) |
    abs(x) > .Machine$integer.max)
  bad[is.nan(x)] <- TRUE
  if (any(bad)) {
    index <- which(bad)[[1]]
    zsp_abort(
      "zuspecial_invalid_argument",
      sprintf(
        "`%s` must hold whole numbers within integer range; element %d is %s.",
        name, index, format(x[[index]])
      ),
      argument = name,
      index = index,
      call = call
    )
  }
  as.integer(x)
}

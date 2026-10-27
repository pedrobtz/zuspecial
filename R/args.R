# Validates, coerces and recycles the arguments of one call (design 6.1, 6.2).
#
# `args` is a named list of the user's arguments, `complex_ok` the names that
# may be complex. If any of those is complex, all of them become complex and
# the call takes the complex path. Returns the recycled arguments, their
# common length `n` (a double, so long vectors work), whether the path is
# complex, and the `template` whose attributes the result takes: as in base
# R arithmetic, the first full-length argument with a dim, else the first
# with names, else the first of full length.
zsp_prep <- function(args, complex_ok = character(), call = NULL) {
  # Every sc_ function goes through here, so it is written for speed: plain
  # loops rather than vapply(), which cost most of the per-call overhead.
  arg_names <- names(args)
  can_complex <- arg_names %in% complex_ok
  for (j in seq_along(args)) {
    zsp_check_type(args[[j]], arg_names[[j]], can_complex[[j]], call)
  }

  arg_lengths <- as.double(lengths(args))
  names(arg_lengths) <- arg_names
  n <- if (any(arg_lengths == 0)) 0 else max(arg_lengths)
  bad <- n > 0 & arg_lengths != 1 & arg_lengths != n
  if (any(bad)) {
    zsp_abort(
      "zuspecial_recycle_error",
      sprintf(
        "Arguments must have length one or a common length; got %s.",
        paste0("`", names(args), "` ", arg_lengths, collapse = ", ")
      ),
      lengths = arg_lengths,
      call = call
    )
  }

  is_complex <- FALSE
  for (j in which(can_complex)) {
    if (is.complex(args[[j]])) {
      is_complex <- TRUE
      break
    }
  }

  template <- NULL
  first_full <- NULL
  first_named <- NULL
  for (j in which(arg_lengths == n)) {
    x <- args[[j]]
    if (!is.null(dim(x))) {
      if (is.null(template)) {
        template <- x
      } else if (!identical(dim(x), dim(template))) {
        # As base R's arithmetic: arrays of one length but different
        # shapes do not conform.
        zsp_abort(
          "zuspecial_recycle_error",
          "Array arguments must have the same dimensions.",
          lengths = arg_lengths,
          call = call
        )
      }
      next
    }
    if (is.null(first_named) && !is.null(names(x))) {
      first_named <- x
    }
    if (is.null(first_full)) first_full <- x
  }
  if (is.null(template)) {
    template <- first_named %||% first_full
  }

  for (j in seq_along(args)) {
    x <- args[[j]]
    x <- if (is_complex && can_complex[[j]]) as.complex(x) else as.double(x)
    # rep_len() copies even at full length; skip it there.
    args[[j]] <- if (length(x) == n) x else rep_len(x, n)
  }

  list(args = args, n = n, complex = is_complex, template = template)
}

zsp_check_type <- function(x, name, can_complex, call) {
  ok_types <- c("double", "integer", "logical", if (can_complex) "complex")
  # Classed numbers (factors, dates, difftimes) carry meaning the kernels
  # would discard; plain matrices and arrays are fine.
  classed <- is.object(x) && !all(class(x) %in% c("matrix", "array"))
  if (classed || !typeof(x) %in% ok_types) {
    what <- if (classed) {
      paste0("an object of class <", class(x)[[1]], ">")
    } else {
      paste("of type", typeof(x))
    }
    zsp_abort(
      "zuspecial_invalid_argument",
      sprintf(
        "`%s` must be %s, not %s.",
        name,
        if (can_complex) "numeric or complex" else "numeric",
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

# Integer-order arguments must be whole numbers within int range (design
# 6.2). NA and NaN become NA_integer_; zsp_eval() puts NaN back in the
# result, as SciPy returns NaN for a NaN order.
zsp_whole <- function(x, name, call = NULL) {
  bad <- !is.na(x) &
    (!is.finite(x) | x != trunc(x) | abs(x) > .Machine$integer.max)
  if (any(bad)) {
    index <- which(bad)[[1]]
    zsp_abort(
      "zuspecial_invalid_argument",
      sprintf(
        "`%s` must hold whole numbers within integer range; element %s is %s.",
        name,
        format(index, scientific = FALSE),
        format(x[[index]])
      ),
      argument = name,
      index = index,
      call = call
    )
  }
  as.integer(x)
}

# A logical flag argument: TRUE or FALSE, nothing else.
zsp_check_flag <- function(x, name, call = NULL) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    zsp_abort(
      "zuspecial_invalid_argument",
      sprintf("`%s` must be `TRUE` or `FALSE`.", name),
      argument = name,
      call = call
    )
  }
}

# Base R has %||% only from 4.4; the package supports 4.1.
`%||%` <- function(x, y) if (is.null(x)) y else x

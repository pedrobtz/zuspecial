test_that("defaults are SciPy's", {
  withr::local_options(zuspecial.errstate = NULL)
  expect_identical(
    sc_geterr(),
    c(
      singular = "ignore",
      underflow = "ignore",
      overflow = "ignore",
      slow = "ignore",
      loss = "ignore",
      no_result = "ignore",
      domain = "ignore",
      arg = "ignore",
      other = "ignore",
      memory = "raise"
    )
  )
})

test_that("seterr returns the previous state and `all` sets every code", {
  withr::local_options(zuspecial.errstate = NULL)
  old <- sc_seterr(all = "warn", domain = "raise")
  expect_identical(old[["memory"]], "raise")
  expect_identical(sc_geterr()[["domain"]], "raise")
  expect_identical(sc_geterr()[["singular"]], "warn")
  expect_identical(sc_geterr()[["memory"]], "warn")
})

test_that("seterr with no arguments changes nothing", {
  withr::local_options(zuspecial.errstate = NULL)
  before <- sc_geterr()
  expect_identical(sc_seterr(), before)
  expect_identical(sc_geterr(), before)
})

test_that("memory can be set like the other codes", {
  withr::local_options(zuspecial.errstate = NULL)
  expect_identical(
    sc_errstate(sc_geterr()[["memory"]], memory = "ignore"),
    "ignore"
  )
})

test_that("an invalid action names the user-facing call", {
  withr::local_options(zuspecial.errstate = NULL)
  cnd <- expect_error(
    sc_errstate(1, domain = "loud"),
    class = "zuspecial_invalid_argument"
  )
  expect_identical(deparse(conditionCall(cnd)[[1]]), "sc_errstate")
})

test_that("seterr refuses unknown actions", {
  withr::local_options(zuspecial.errstate = NULL)
  expect_error(sc_seterr(domain = "loud"), class = "zuspecial_invalid_argument")
  expect_error(sc_seterr(domain = NA), class = "zuspecial_invalid_argument")
  expect_error(
    sc_seterr(domain = c("warn", "raise")),
    class = "zuspecial_invalid_argument"
  )
})

test_that("errstate refuses unnamed or unknown actions and changes nothing", {
  withr::local_options(zuspecial.errstate = NULL)
  before <- sc_geterr()
  expect_error(sc_errstate(1, "warn"), class = "zuspecial_invalid_argument")
  expect_error(
    sc_errstate(1, singualr = "warn"),
    class = "zuspecial_invalid_argument"
  )
  expect_error(
    sc_errstate(1, "warn", domain = "raise"),
    class = "zuspecial_invalid_argument"
  )
  expect_identical(sc_geterr(), before)
})

test_that("errstate applies actions and restores state after an error", {
  withr::local_options(zuspecial.errstate = NULL)
  inside <- sc_errstate(sc_geterr()[["overflow"]], overflow = "warn")
  expect_identical(inside, "warn")
  expect_identical(sc_geterr()[["overflow"]], "ignore")
  expect_error(sc_errstate(stop("boom"), all = "raise"))
  expect_identical(sc_geterr()[["singular"]], "ignore")
})

test_that("a report signals each code once under its action", {
  withr::local_options(zuspecial.errstate = NULL)
  report <- numeric(20)
  report[c(1, 11)] <- c(2, 3) # singular: 2 elements, first at 3
  report[c(7, 17)] <- c(1, 5) # domain: 1 element at 5

  expect_silent(zsp_signal_report(report, "sc_gamma"))

  sc_seterr(singular = "warn", domain = "warn")
  w <- list()
  withCallingHandlers(
    zsp_signal_report(report, "sc_gamma"),
    warning = function(cnd) {
      w[[length(w) + 1]] <<- cnd
      invokeRestart("muffleWarning")
    }
  )
  expect_length(w, 2)
  expect_s3_class(w[[1]], c("zuspecial_singular", "zuspecial_warning"))
  expect_identical(w[[1]]$count, 2)
  expect_identical(w[[1]]$first_index, 3)
  expect_identical(w[[1]]$fn, "sc_gamma")
  expect_s3_class(w[[2]], "zuspecial_domain")

  sc_seterr(singular = "ignore", domain = "raise")
  cnd <- expect_error(
    zsp_signal_report(report, "sc_gamma"),
    class = "zuspecial_domain_error"
  )
  expect_s3_class(cnd, "zuspecial_error")
  expect_identical(cnd$first_index, 5)
})

test_that("a malformed zuspecial.errstate option is refused or completed", {
  withr::local_options(zuspecial.errstate = "bogus")
  expect_error(sc_geterr(), class = "zuspecial_invalid_argument")
  expect_error(sc_gamma(-1), class = "zuspecial_invalid_argument")

  withr::local_options(zuspecial.errstate = c(domain = "loud"))
  expect_error(sc_geterr(), class = "zuspecial_invalid_argument")

  # A partial state keeps the defaults for the codes it leaves out.
  withr::local_options(zuspecial.errstate = c(singular = "warn"))
  state <- sc_geterr()
  expect_identical(names(state), names(sc_seterr()))
  expect_identical(state[["singular"]], "warn")
  expect_identical(state[["memory"]], "raise")
  expect_warning(sc_gamma(-1), class = "zuspecial_singular")
  expect_silent(sc_gammainc(-1, 1))
})

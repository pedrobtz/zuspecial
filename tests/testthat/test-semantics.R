test_that("complex input takes the complex path, real input does not", {
  expect_type(sc_gamma(1 + 0i), "complex")
  expect_type(sc_gamma(1), "double")
  expect_true(is.nan(sc_gamma(-1)))
})

test_that("wofz has only a complex path, so real input is promoted", {
  expect_type(sc_wofz(1), "complex")
})

test_that("complex input to a real-only function is refused", {
  cnd <- expect_error(sc_erfcinv(1i), class = "zuspecial_invalid_argument")
  expect_identical(cnd$argument, "y")
  expect_error(sc_beta(1i, 1), class = "zuspecial_invalid_argument")
})

test_that("conditions follow the error state, once per call", {
  withr::local_options(zuspecial.errstate = NULL)
  expect_silent(sc_gamma(c(-1, -2)))

  w <- list()
  withCallingHandlers(
    sc_errstate(sc_gamma(c(1, -1, -2)), singular = "warn"),
    warning = function(cnd) {
      w[[length(w) + 1]] <<- cnd
      invokeRestart("muffleWarning")
    }
  )
  expect_length(w, 1)
  expect_s3_class(w[[1]], "zuspecial_singular")
  expect_identical(w[[1]]$fn, "sc_gamma")
  expect_identical(w[[1]]$count, 2L)
  expect_identical(w[[1]]$first_index, 2L)

  expect_error(
    sc_errstate(sc_gamma(-1), singular = "raise"),
    class = "zuspecial_singular_error"
  )
})

test_that("results keep the names and dim of the first full-length argument", {
  expect_named(sc_gamma(c(a = 1, b = 2)), c("a", "b"))
  m <- matrix(c(1, 2, 3, 4), 2)
  expect_identical(dim(sc_beta(m, 1)), c(2L, 2L))
  expect_identical(dim(sc_gamma(m + 0i)), c(2L, 2L))
})

test_that("NA gives NA without a condition, and zero length gives zero length", {
  withr::local_options(zuspecial.errstate = NULL)
  sc_seterr(all = "raise")
  expect_identical(sc_gamma(c(NA, 2)), c(NA, 1))
  expect_identical(sc_beta(NA_integer_, 1), NA_real_)
  expect_identical(sc_gamma(numeric()), numeric())
  expect_identical(sc_beta(numeric(), c(1, 2)), numeric())
})

test_that("integer orders are checked", {
  expect_error(sc_expn(1.5, 1), class = "zuspecial_invalid_argument")
  expect_identical(sc_expn(NA, 1), NA_real_)
})

test_that("argument errors name the user-facing function", {
  cnd <- expect_error(sc_beta(c(1, 2), c(1, 2, 3)))
  expect_s3_class(cnd, "zuspecial_recycle_error")
  expect_identical(deparse(conditionCall(cnd)[[1]]), "sc_beta")
})

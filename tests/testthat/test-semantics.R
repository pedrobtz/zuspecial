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
  expect_identical(w[[1]]$count, 2)
  expect_identical(w[[1]]$first_index, 2)

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

test_that("each complex kernel is the right one, off the real axis", {
  z <- 1.3 + 0.7i
  # Independent references: integrals, checked against R's integrate().
  ref <- 0.69265730408061355 - 0.04025594616115722i
  expect_lt(Mod(sc_gamma(z) / ref - 1), 1e-14)
  # Identities that tie each kernel to another, so a swapped table entry
  # cannot pass.
  expect_equal(sc_erfc(z), 1 - sc_erf(z), tolerance = 1e-14)
  expect_equal(sc_erfcx(z), exp(z^2) * sc_erfc(z), tolerance = 1e-14)
  expect_equal(sc_erfi(z), -1i * sc_erf(1i * z), tolerance = 1e-14)
  expect_equal(sc_dawsn(z), sqrt(pi) / 2 * exp(-z^2) * sc_erfi(z),
    tolerance = 1e-14
  )
  expect_equal(sc_wofz(z), exp(-z^2) * sc_erfc(-1i * z), tolerance = 1e-14)
  expect_equal(exp(sc_loggamma(z)), sc_gamma(z), tolerance = 1e-14)
  expect_equal(sc_rgamma(z), 1 / sc_gamma(z), tolerance = 1e-14)
  expect_equal(sc_psi(z + 1), sc_psi(z) + 1 / z, tolerance = 1e-14)
  expect_equal(sc_expi(z), -sc_exp1(-z) + 1i * pi, tolerance = 1e-14)
  expect_false(isTRUE(all.equal(sc_erf(z), sc_erfi(z))))
})

test_that("the complex loop reports codes too", {
  withr::local_options(zuspecial.errstate = NULL)
  cnd <- expect_warning(
    sc_errstate(sc_gamma(c(2, -1, -2) + 0i), singular = "warn"),
    class = "zuspecial_singular"
  )
  expect_identical(cnd$count, 2)
  expect_identical(cnd$first_index, 2)
})

test_that("empty and NULL inputs", {
  expect_identical(sc_gamma(complex()), complex())
  expect_identical(sc_wofz(numeric()), complex())
  expect_error(sc_gamma(NULL), class = "zuspecial_invalid_argument")
  m0 <- matrix(numeric(), 0, 3)
  expect_identical(dim(sc_gamma(m0)), c(0L, 3L))
})

test_that("attributes follow base R arithmetic", {
  m <- matrix(1:4, 2)
  expect_identical(dim(sc_beta(1:4, m)), dim(1:4 + m))
  expect_identical(dim(sc_beta(m, 1)), c(2L, 2L))
  expect_named(sc_beta(1:2, c(a = 1, b = 2)), c("a", "b"))
  expect_named(sc_beta(c(x = 1, y = 2), c(a = 1, b = 2)), c("x", "y"))
})

test_that("classed numbers such as dates are refused", {
  expect_error(
    sc_gamma(as.difftime(5, units = "days")),
    class = "zuspecial_invalid_argument"
  )
  expect_error(sc_gamma(Sys.Date()), class = "zuspecial_invalid_argument")
})

test_that("a NaN order gives NaN, as SciPy's expn does", {
  expect_identical(sc_expn(c(NaN, 1), 1), c(NaN, sc_expn(1, 1)))
})

test_that("lengths are measured as doubles, so long vectors are accepted", {
  prep <- zsp_prep(list(a = 1, b = 1:3))
  expect_type(prep$n, "double")
})

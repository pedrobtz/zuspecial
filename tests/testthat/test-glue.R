test_that("the real loop calls the kernel and passes NaN through", {
  out <- .Call(zsp_call_d, "gamma", c(5, 0.5, NaN))
  expect_equal(out, c(24, sqrt(pi), NaN), tolerance = 1e-15)
  expect_null(attr(out, "zsp_err"))
})

test_that("NA is decided before the kernel", {
  out <- .Call(zsp_call_d, "gamma", c(NA, -1))
  expect_identical(out[1], NA_real_)
  expect_true(is.nan(out[2]))
  report <- attr(out, "zsp_err")
  # NA never reaches the kernel, so the singular count is 1, at index 2.
  expect_identical(report[c(1, 11)], c(1, 2))
})

test_that("the report counts every element and keeps the first index", {
  out <- .Call(zsp_call_d, "gamma", c(1, -1, -2))
  report <- attr(out, "zsp_err")
  expect_length(report, 20)
  expect_identical(report[c(1, 11)], c(2, 2))
  expect_identical(sum(report[-c(1, 11)]), 0)
})

test_that("the complex loop treats either NA part as NA and passes NaN", {
  z <- complex(real = c(NA, 1, NaN), imaginary = c(0, NA, 0))
  out <- .Call(zsp_call_c, "gamma", z)
  expect_identical(out[1:2], c(NA_complex_, NA_complex_))
  expect_true(is.nan(Re(out[3])))
  expect_equal(
    .Call(zsp_call_c, "gamma", complex(real = 5, imaginary = 0)),
    24 + 0i,
    tolerance = 1e-14
  )
})

test_that("two- and three-argument loops and the integer-order loop", {
  expect_equal(.Call(zsp_call_dd, "beta", c(2, NA), c(3, 1)), c(1 / 12, NA))
  expect_equal(
    .Call(zsp_call_ddd, "voigt_profile", 0, 1, 0),
    1 / sqrt(2 * pi),
    tolerance = 1e-14
  )
  out <- .Call(zsp_call_id, "expn", c(1L, NA), c(1, 1))
  expect_equal(out[1], 0.21938393439552029, tolerance = 1e-14) # E1(1)
  expect_identical(out[2], NA_real_)
})

test_that("an unknown kernel is an error before the loop", {
  expect_error(.Call(zsp_call_d, "nosuch", 1), "nosuch")
})

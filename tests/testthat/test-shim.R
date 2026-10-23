test_that("gamma is reachable through the shim", {
  res <- .Call(zsp_spike_gamma, c(5, 0.5))
  expect_equal(res$value, c(24, sqrt(pi)), tolerance = 1e-15)
  expect_identical(res$codes, c(0L, 0L))
})

test_that("a pole sets SF_ERROR_SINGULAR and nothing else", {
  res <- .Call(zsp_spike_gamma, c(-1, -200))
  expect_true(all(is.nan(res$value)))
  expect_identical(res$codes, rep(bitwShiftL(1L, 1L), 2))
})

test_that("gamma(0) is infinite without an error code", {
  res <- .Call(zsp_spike_gamma, 0)
  expect_identical(res$value, Inf)
  expect_identical(res$codes, 0L)
})

test_that("the error mask is cleared between elements", {
  res <- .Call(zsp_spike_gamma, c(-1, 2))
  expect_identical(res$codes, c(bitwShiftL(1L, 1L), 0L))
})

test_that("normal functions match base R's normal distribution", {
  x <- c(-30, -5, -1, 0, 0.5, 3, 8)
  expect_equal(sc_ndtr(x), pnorm(x), tolerance = 1e-14)
  expect_equal(sc_log_ndtr(x), pnorm(x, log.p = TRUE), tolerance = 1e-14)
  p <- c(1e-300, 1e-10, 0.025, 0.5, 0.975, 1 - 1e-10)
  expect_equal(sc_ndtri(p), qnorm(p), tolerance = 1e-13)
  expect_identical(sc_ndtri(c(0, 1)), c(-Inf, Inf))
  # SciPy's argument name, so keyword calls translate.
  expect_identical(sc_ndtri(y = 0.3), sc_ndtri(0.3))
})

test_that("ndtri_exp inverts log_ndtr across its three branches", {
  # y < -2, -2 <= y <= log1p(-exp(-2)), and above it.
  y <- c(-1e4, -50, -2.5, -1, -0.2, -0.01, -1e-10)
  expect_equal(sc_ndtri_exp(y), qnorm(y, log.p = TRUE), tolerance = 1e-12)
  expect_equal(sc_log_ndtr(sc_ndtri_exp(y)), y, tolerance = 1e-12)
  expect_identical(sc_ndtri_exp(c(-Inf, 0)), c(-Inf, Inf))
  # Below -DBL_MAX / 2 the shim takes its own branch; SciPy 1.18.1's values.
  expect_equal(
    sc_ndtri_exp(c(-1e308, -.Machine$double.xmax)),
    c(-1.4142135623730953e+154, -1.8961503816218352e+154),
    tolerance = 1e-15
  )
})

test_that("owens_t at closed forms", {
  expect_identical(sc_owens_t(1.3, 0), 0)
  a <- c(0.3, 1, 5)
  expect_equal(sc_owens_t(0, a), atan(a) / (2 * pi), tolerance = 1e-14)
  # T(h, 1) = Phi(h) * (1 - Phi(h)) / 2
  h <- c(0.2, 1, 2.5)
  expect_equal(
    sc_owens_t(h, 1),
    pnorm(h) * (1 - pnorm(h)) / 2,
    tolerance = 1e-13
  )
})

test_that("ndtr and log_ndtr take complex arguments", {
  x <- c(-2, 0.5, 3)
  expect_type(sc_ndtr(x + 0i), "complex")
  expect_equal(Re(sc_ndtr(x + 0i)), pnorm(x), tolerance = 1e-14)
  expect_equal(
    Re(sc_log_ndtr(x + 0i)),
    pnorm(x, log.p = TRUE),
    tolerance = 1e-13
  )
  z <- 0.7 + 0.4i
  expect_equal(sc_ndtr(z), 0.5 * sc_erfc(-z / sqrt(2)), tolerance = 1e-14)
  expect_equal(exp(sc_log_ndtr(z)), sc_ndtr(z), tolerance = 1e-14)
})

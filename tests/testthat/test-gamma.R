test_that("gamma family matches base R on ordinary inputs", {
  x <- c(0.1, 0.5, 1, 2.5, 7, 20.3)
  expect_equal(sc_gamma(x), gamma(x), tolerance = 1e-14)
  expect_equal(sc_gammaln(x), lgamma(x), tolerance = 1e-14)
  expect_equal(sc_loggamma(x), lgamma(x), tolerance = 1e-14)
  expect_equal(sc_rgamma(x), 1 / gamma(x), tolerance = 1e-14)
  expect_equal(sc_psi(x), digamma(x), tolerance = 1e-14)
  expect_identical(sc_gammasgn(c(-0.5, -1.5, 2)), c(-1, 1, 1))
})

test_that("beta family and binom match base R", {
  a <- c(0.5, 1, 2, 3.5)
  b <- c(0.5, 4, 2, 10)
  expect_equal(sc_beta(a, b), beta(a, b), tolerance = 1e-14)
  expect_equal(sc_betaln(a, b), lbeta(a, b), tolerance = 1e-14)
  expect_equal(
    sc_binom(c(5, 10, 20), c(2, 3, 7)),
    choose(c(5, 10, 20), c(2, 3, 7)),
    tolerance = 1e-14
  )
  expect_equal(
    sc_poch(c(3, 0.5), c(2, 3)),
    c(12, 0.5 * 1.5 * 2.5),
    tolerance = 1e-14
  )
})

test_that("complex paths agree with the real path on the real axis", {
  x <- c(0.5, 2, 4.5)
  expect_equal(Re(sc_gamma(x + 0i)), gamma(x), tolerance = 1e-14)
  expect_equal(Re(sc_loggamma(x + 0i)), lgamma(x), tolerance = 1e-14)
  expect_equal(Re(sc_rgamma(x + 0i)), 1 / gamma(x), tolerance = 1e-14)
  expect_equal(Re(sc_psi(x + 0i)), digamma(x), tolerance = 1e-14)
  expect_type(sc_gamma(x + 0i), "complex")
})

test_that("incomplete gamma functions match base R's gamma distribution", {
  a <- c(0.5, 1, 2.5, 10, 40)
  x <- c(0.1, 1, 2, 12, 35)
  expect_equal(sc_gammainc(a, x), pgamma(x, a), tolerance = 1e-13)
  expect_equal(
    sc_gammaincc(a, x),
    pgamma(x, a, lower.tail = FALSE),
    tolerance = 1e-13
  )
  y <- c(0.01, 0.3, 0.5, 0.9, 0.999)
  expect_equal(sc_gammaincinv(a, y), qgamma(y, a), tolerance = 1e-12)
  expect_equal(
    sc_gammainccinv(a, y),
    qgamma(y, a, lower.tail = FALSE),
    tolerance = 1e-12
  )
  expect_equal(sc_gammainc(a, sc_gammaincinv(a, y)), y, tolerance = 1e-13)
})

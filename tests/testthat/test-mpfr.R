# Spot checks against 200-bit MPFR values (Rmpfr, Suggests; design 10):
# sweeps of a few hundred points per family, and points near zeros, poles
# and overflow thresholds. Oscillating functions are judged against their
# envelope, since relative error is unbounded at their zeros.

test_that("gamma, gammaln, psi and zeta sweep against MPFR", {
  skip_if_not_installed("Rmpfr")
  withr::local_seed(20261024)
  x <- sort(c(runif(200, 0.05, 170), -runif(100, 0.01, 30)))
  x <- x[abs(x - round(x)) > 1e-3] # away from the poles
  expect_lt(max(mpfr_rel_err(sc_gamma(x), gamma(mpfr_200(x)))), 1e-13)
  y <- 10^runif(200, log10(2.5), 300)
  expect_lt(max(mpfr_rel_err(sc_gammaln(y), lgamma(mpfr_200(y)))), 1e-14)
  p <- runif(200, 0.05, 50)
  expect_lt(max(mpfr_rel_err(sc_psi(p), digamma(mpfr_200(p)))), 1e-13)
  s <- 1 + 10^runif(200, -6, 2)
  expect_lt(max(mpfr_rel_err(sc_zeta(s), Rmpfr::zeta(mpfr_200(s)))), 1e-13)
})

test_that("error functions and Ei sweep against MPFR", {
  skip_if_not_installed("Rmpfr")
  withr::local_seed(20261025)
  x <- runif(300, -5.5, 5.5)
  expect_lt(max(mpfr_rel_err(sc_erf(x), Rmpfr::erf(mpfr_200(x)))), 1e-14)
  xc <- runif(300, -5, 26)
  expect_lt(max(mpfr_rel_err(sc_erfc(xc), Rmpfr::erfc(mpfr_200(xc)))), 1e-13)
  e <- c(-runif(150, 0.01, 50), runif(150, 0.5, 700))
  expect_lt(max(mpfr_rel_err(sc_expi(e), Rmpfr::Ei(mpfr_200(e)))), 1e-13)
})

test_that("Bessel J0, Y0 and Airy Ai sweep against MPFR, by envelope", {
  skip_if_not_installed("Rmpfr")
  withr::local_seed(20261026)
  x <- runif(300, 0.1, 200)
  envelope <- pmin(1, sqrt(2 / (pi * x)))
  expect_lt(
    max(mpfr_env_err(sc_j0(x), Rmpfr::j0(mpfr_200(x)), envelope)),
    1e-14
  )
  expect_lt(
    max(mpfr_env_err(sc_y0(x), Rmpfr::y0(mpfr_200(x)), envelope)),
    1e-14
  )
  a <- runif(300, -60, 0)
  ai_env <- pmin(0.6, abs(a)^-0.25 / sqrt(pi))
  expect_lt(
    max(mpfr_env_err(sc_airy(a)$ai, Rmpfr::Ai(mpfr_200(a)), ai_env)),
    1e-13
  )
})

test_that("Spence's function sweeps against MPFR's dilogarithm", {
  skip_if_not_installed("Rmpfr")
  withr::local_seed(20261027)
  z <- runif(300, 0, 4)
  # spence(z) = Li2(1 - z), with 1 - z formed exactly in MPFR.
  want <- Rmpfr::Li2(1 - mpfr_200(z))
  expect_lt(
    max(mpfr_env_err(sc_spence(z), want, pmax(1, abs(Rmpfr::asNumeric(want))))),
    1e-14
  )
})

test_that("near zeros, poles and overflow thresholds", {
  skip_if_not_installed("Rmpfr")
  # Near the poles of gamma, and its overflow threshold (171.62).
  g <- c(-3.999999, -1e-8, 1e-300, 171.5, 171.6)
  expect_lt(max(mpfr_rel_err(sc_gamma(g), gamma(mpfr_200(g)))), 1e-13)
  expect_identical(sc_gamma(171.7), Inf)
  # The pole of zeta at 1.
  s <- 1 + c(1e-10, 1e-6, 1e-3)
  expect_lt(max(mpfr_rel_err(sc_zeta(s), Rmpfr::zeta(mpfr_200(s)))), 1e-13)
  # At the zeros of J0, Y0, Ai and Ei the double input is next to the zero;
  # the error is judged in absolute terms, against the function's scale.
  j0_zeros <- c(2.404825557695773, 5.520078110286311, 8.653727912911013)
  expect_lt(
    max(abs(sc_j0(j0_zeros) - Rmpfr::asNumeric(Rmpfr::j0(mpfr_200(j0_zeros))))),
    4e-16
  )
  y0_zeros <- c(0.8935769662791675, 3.957678419314858)
  expect_lt(
    max(abs(sc_y0(y0_zeros) - Rmpfr::asNumeric(Rmpfr::y0(mpfr_200(y0_zeros))))),
    4e-16
  )
  ai_zero <- -2.338107410459767
  expect_lt(
    abs(sc_airy(ai_zero)$ai - Rmpfr::asNumeric(Rmpfr::Ai(mpfr_200(ai_zero)))),
    4e-16
  )
  ei_zero <- 0.3725074107813666
  expect_lt(
    abs(sc_expi(ei_zero) - Rmpfr::asNumeric(Rmpfr::Ei(mpfr_200(ei_zero)))),
    4e-16
  )
  # erfc underflows to 0 just past 26.55, as in SciPy, where MPFR's value is
  # subnormal.
  expect_identical(sc_erfc(27.2), 0)
})

test_that("explained disagreements: where xsf, and so SciPy, is less accurate", {
  skip_if_not_installed("Rmpfr")
  # gammaln near its zero at 1: SciPy 1.18.1 gives the same
  # 5.7721605273286514e-11 for 1 - 1e-10, 5.9e-7 relative but 3.4e-17
  # absolute from MPFR, because Cephes' lgam forms log(gamma(x)) there.
  x <- 0.99999999989999999
  # Compared with tolerance: the value is not bit-identical across platforms
  # (libm, FMA); same-platform parity with SciPy is test-xsref.R's job.
  expect_lt(abs(sc_gammaln(x) - 5.7721605273286514e-11), 1e-16)
  expect_lt(abs(sc_gammaln(x) - Rmpfr::asNumeric(lgamma(mpfr_200(x)))), 1e-16)
  # psi next to its pole at -3 is ill-conditioned; SciPy 1.18.1 gives the
  # same -9998.743581707211, 8.7e-14 relative from MPFR.
  expect_equal(
    sc_psi(-2.9998999999999998),
    -9998.743581707211,
    tolerance = 1e-12
  )
  expect_lt(
    mpfr_rel_err(
      sc_psi(-2.9998999999999998),
      digamma(mpfr_200(-2.9998999999999998))
    ),
    1e-12
  )
})

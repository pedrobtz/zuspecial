test_that("error functions match their normal-distribution forms", {
  x <- c(-2, -0.3, 0, 0.7, 1.5, 3)
  expect_equal(sc_erf(x), 2 * pnorm(x * sqrt(2)) - 1, tolerance = 1e-14)
  expect_equal(sc_erfc(x), 2 * pnorm(-x * sqrt(2)), tolerance = 1e-14)
  expect_equal(sc_erfcx(x), exp(x^2) * 2 * pnorm(-x * sqrt(2)),
    tolerance = 1e-13
  )
  expect_equal(sc_erfcinv(sc_erfc(x)), x, tolerance = 1e-13)
})

test_that("erfi, dawsn and wofz at known values", {
  expect_equal(sc_erfi(1), 1.6504257587975428, tolerance = 1e-15)
  expect_equal(sc_dawsn(1), 0.53807950691276841, tolerance = 1e-15)
  expect_equal(sc_wofz(0), 1 + 0i)
  expect_equal(Re(sc_erf(0.7 + 0i)), sc_erf(0.7), tolerance = 1e-15)
})

test_that("voigt_profile reduces to the normal density when gamma is 0", {
  x <- c(-1, 0, 2)
  expect_equal(sc_voigt_profile(x, 1.3, 0), dnorm(x, sd = 1.3),
    tolerance = 1e-14
  )
})

test_that("exponential integrals at known values", {
  expect_equal(sc_exp1(1), 0.21938393439552029, tolerance = 1e-14)
  expect_equal(sc_expi(1), 1.8951178163559368, tolerance = 1e-14)
  expect_equal(sc_expn(1, 1), sc_exp1(1), tolerance = 1e-14)
  expect_equal(
    sc_expn(0, c(0.5, 2)),
    exp(-c(0.5, 2)) / c(0.5, 2),
    tolerance = 1e-14
  )
  expect_equal(Re(sc_exp1(1 + 0i)), sc_exp1(1), tolerance = 1e-14)
})

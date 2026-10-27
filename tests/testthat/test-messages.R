# Condition wording, in snapshots; the other tests check classes only.

test_that("argument errors read well", {
  expect_snapshot(error = TRUE, {
    sc_beta(1:2, 1:3)
    sc_beta(matrix(1:6, 2), matrix(1:6, 3))
    sc_gamma("a")
    sc_beta("a", 1)
    sc_gamma(Sys.Date())
    sc_expn(c(1, 1.5), 1)
    sc_spherical_jn(1, 1, derivative = NA)
  })
})

test_that("errstate errors read well", {
  withr::local_options(zuspecial.errstate = NULL)
  expect_snapshot(error = TRUE, {
    sc_seterr(domain = "loud")
    sc_errstate(1, "warn")
  })
  withr::local_options(zuspecial.errstate = "bogus")
  expect_snapshot(error = TRUE, sc_geterr())
})

test_that("floating-point conditions count elements", {
  withr::local_options(zuspecial.errstate = NULL)
  expect_snapshot({
    sc_errstate(sc_gamma(-1), singular = "warn")
    sc_errstate(sc_gamma(c(1, -1, -2)), singular = "warn")
  })
  expect_snapshot(error = TRUE, {
    sc_errstate(sc_gamma(c(1, -1)), singular = "raise")
  })
})

test_that("an internal error says so", {
  expect_snapshot(error = TRUE, {
    zsp_eval("gamma", list(x = 1), outputs = c("a", "b", "c"))
  })
})

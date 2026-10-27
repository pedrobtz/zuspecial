test_that("incomplete beta functions match base R's beta distribution", {
  a <- c(0.5, 1, 2.5, 10, 40)
  b <- c(0.3, 2, 2.5, 3, 80)
  x <- c(0.1, 0.5, 0.3, 0.9, 0.33)
  expect_equal(sc_betainc(a, b, x), pbeta(x, a, b), tolerance = 1e-13)
  expect_equal(
    sc_betaincc(a, b, x),
    pbeta(x, a, b, lower.tail = FALSE),
    tolerance = 1e-13
  )
  y <- c(0.01, 0.3, 0.5, 0.9, 0.999)
  expect_equal(sc_betaincinv(a, b, y), qbeta(y, a, b), tolerance = 1e-12)
  expect_equal(
    sc_betainccinv(a, b, y),
    qbeta(y, a, b, lower.tail = FALSE),
    tolerance = 1e-12
  )
})

test_that("betainc and betaincc take SciPy's pointwise limits", {
  x <- c(0, 0.5, 1)
  expect_identical(sc_betainc(0, 2, x), c(0, 1, 1))
  expect_identical(sc_betainc(2, Inf, x), c(0, 1, 1))
  expect_identical(sc_betainc(2, 0, x), c(0, 0, 1))
  expect_identical(sc_betainc(Inf, 2, x), c(0, 0, 1))
  expect_true(all(is.nan(sc_betainc(c(0, Inf), c(0, Inf), 0.5))))
  expect_identical(sc_betaincc(0, 2, x), 1 - c(0, 1, 1))
  expect_identical(sc_betaincc(2, 0, x), 1 - c(0, 0, 1))
})

test_that("domain errors follow the error state", {
  withr::local_options(zuspecial.errstate = NULL)
  expect_true(is.nan(sc_betainc(1, 1, 2)))
  expect_error(
    sc_errstate(sc_betainc(1, 1, 2), domain = "raise"),
    class = "zuspecial_domain_error"
  )
  expect_error(
    sc_errstate(sc_betaincinv(-1, 1, 0.5), domain = "raise"),
    class = "zuspecial_domain_error"
  )
})

test_that("erfinv inverts erf and has SciPy's endpoints", {
  x <- c(-3, -0.5, 0, 0.1, 2.7)
  expect_equal(sc_erfinv(sc_erf(x)), x, tolerance = 1e-13)
  # Independently of sc_erf(): erfinv(y) = qnorm((1 + y) / 2) / sqrt(2).
  y <- c(-0.999, -0.3, 0.01, 0.5, 0.9999)
  expect_equal(sc_erfinv(y), qnorm((1 + y) / 2) / sqrt(2), tolerance = 1e-13)
  expect_identical(sc_erfinv(c(-1, 1)), c(-Inf, Inf))
  expect_true(is.nan(sc_erfinv(1.5)))
})

test_that("info reports the Boost backend and version", {
  info <- zuspecial_info()
  boost <- info$functions$r_name[info$functions$backend == "boost"]
  expect_setequal(
    boost,
    c(
      "sc_betainc",
      "sc_betaincc",
      "sc_betaincinv",
      "sc_betainccinv",
      "sc_erfinv",
      "sc_hyp1f1"
    )
  )
  expect_match(info$boost_version, "^1\\.[0-9]+\\.[0-9]+$")
})

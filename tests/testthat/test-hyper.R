test_that("hypergeometric functions at closed forms", {
  x <- c(0.1, 0.7, 2.5)
  expect_equal(sc_hyp0f1(0.5, x), cosh(2 * sqrt(x)), tolerance = 1e-13)
  expect_equal(sc_hyp0f1(0.5, -x), cos(2 * sqrt(x)), tolerance = 1e-13)
  expect_equal(sc_hyp1f1(1.3, 1.3, x), exp(x), tolerance = 1e-13)
  expect_equal(sc_hyp1f1(1, 2, x), expm1(x) / x, tolerance = 1e-13)
  y <- c(-0.9, 0.2, 0.6)
  expect_equal(sc_hyp2f1(1, 1, 2, y), -log1p(-y) / y, tolerance = 1e-13)
  expect_equal(sc_hyperu(0.7, 1.7, x), x^-0.7, tolerance = 1e-12)
  z <- 0.3 + 0.4i
  expect_equal(sc_hyp1f1(1.3, 1.3, z), exp(z), tolerance = 1e-13)
  expect_equal(sc_hyp2f1(1, 1, 2, z), -log(1 - z) / z, tolerance = 1e-13)
  expect_equal(sc_hyp0f1(0.5, z), cosh(2 * sqrt(z)), tolerance = 1e-13)
  expect_type(sc_hyp2f1(1, 1, 2, z), "complex")
})

test_that("elliptic integrals and Jacobi functions", {
  m <- c(0, 0.3, 0.9)
  expect_equal(sc_ellipk(0), pi / 2)
  expect_equal(sc_ellipe(c(0, 1)), c(pi / 2, 1))
  expect_equal(sc_ellipkinc(pi / 2, m), sc_ellipk(m), tolerance = 1e-14)
  expect_equal(sc_ellipeinc(pi / 2, m), sc_ellipe(m), tolerance = 1e-14)
  expect_equal(sc_ellipkm1(1 - m), sc_ellipk(m), tolerance = 1e-13)
  u <- c(0.2, 1, 2.5)
  j <- sc_ellipj(u, 0)
  expect_named(j, c("sn", "cn", "dn", "ph"))
  expect_equal(j$sn, sin(u), tolerance = 1e-14)
  expect_equal(j$cn, cos(u), tolerance = 1e-14)
  expect_equal(j$dn, rep(1, 3))
  expect_equal(j$ph, u, tolerance = 1e-14)
  j <- sc_ellipj(1.1, 0.6)
  expect_equal(j$sn^2 + j$cn^2, 1, tolerance = 1e-14)
  expect_equal(j$dn^2 + 0.6 * j$sn^2, 1, tolerance = 1e-14)
})

test_that("zeta: Riemann when q is NULL, Hurwitz otherwise", {
  expect_equal(sc_zeta(2), pi^2 / 6, tolerance = 1e-15)
  expect_equal(sc_zeta(4), pi^4 / 90, tolerance = 1e-15)
  expect_equal(sc_zeta(c(2, 3.5), 1), sc_zeta(c(2, 3.5)), tolerance = 1e-14)
  expect_equal(sc_zeta(2, 2), pi^2 / 6 - 1, tolerance = 1e-14)
  expect_equal(sc_zetac(2), pi^2 / 6 - 1, tolerance = 1e-14)
  expect_equal(Re(sc_zeta(2 + 0i)), pi^2 / 6, tolerance = 1e-14)
  expect_type(sc_zeta(2 + 1i, 1.5), "complex")
  # As in SciPy, the Hurwitz form takes complex x only on the real axis.
  expect_true(is.nan(Re(sc_zeta(2 + 1i, 1.5))))
  expect_equal(sc_zeta(2 + 0i, 2), pi^2 / 6 - 1 + 0i, tolerance = 1e-14)
  expect_error(
    sc_errstate(sc_zeta(2 + 1i, 1.5), domain = "raise"),
    class = "zuspecial_domain_error"
  )
})

test_that("Lambert W and Wright omega satisfy their equations", {
  z <- c(-0.3, 0.5, 1, 10)
  w <- sc_lambertw(z)
  expect_type(w, "complex")
  expect_equal(w * exp(w), z + 0i, tolerance = 1e-14)
  expect_equal(Re(sc_lambertw(1)), 0.56714329040978387, tolerance = 1e-15)
  wm <- sc_lambertw(-0.2, k = -1)
  expect_equal(wm * exp(wm), -0.2 + 0i, tolerance = 1e-14)
  expect_lt(Re(wm), -1)
  expect_error(sc_lambertw(1, k = 0.5), class = "zuspecial_invalid_argument")
  o <- sc_wrightomega(c(0.5, -2, 3))
  expect_equal(o + log(o), c(0.5, -2, 3), tolerance = 1e-14)
  oz <- sc_wrightomega(1 + 2i)
  expect_equal(oz, 0.7472910711119591 + 1.048443658219649i, tolerance = 1e-14)
  expect_equal(oz + log(oz), 1 + 2i, tolerance = 1e-14)
})

test_that("Spence's function and the Struve functions at closed forms", {
  expect_equal(
    sc_spence(c(0, 0.5, 1)),
    c(pi^2 / 6, pi^2 / 12 - log(2)^2 / 2, 0),
    tolerance = 1e-14
  )
  expect_equal(
    Re(sc_spence(0.5 + 0i)),
    pi^2 / 12 - log(2)^2 / 2,
    tolerance = 1e-14
  )
  x <- c(0.3, 2, 7)
  expect_equal(
    sc_struve(0.5, x),
    sqrt(2 / (pi * x)) * (1 - cos(x)),
    tolerance = 1e-13
  )
  expect_equal(
    sc_modstruve(0.5, x),
    sqrt(2 / (pi * x)) * (cosh(x) - 1),
    tolerance = 1e-13
  )
})

# Independent oracles (design 10): other R packages, with other algorithms.
# A disagreement is investigated and explained here, not failed by default.

test_that("gsl agrees on the real-argument functions", {
  skip_if_not_installed("gsl")
  x <- c(0.3, 1.7, 4.2, 11)
  expect_equal(sc_gammaln(x), gsl::lngamma(x), tolerance = 1e-14)
  expect_equal(sc_psi(x), gsl::psi(x), tolerance = 1e-14)
  expect_equal(sc_erf(x - 2), gsl::erf(x - 2), tolerance = 1e-14)
  expect_equal(sc_erfc(x), gsl::erfc(x), tolerance = 1e-13)
  expect_equal(sc_exp1(x), gsl::expint_E1(x), tolerance = 1e-14)
  expect_equal(sc_expi(x), gsl::expint_Ei(x), tolerance = 1e-14)
  expect_equal(sc_expn(3, x), gsl::expint_En(3, x), tolerance = 1e-14)
  # gsl's gamma_inc is the upper incomplete gamma, unregularised.
  a <- c(0.5, 2, 7.5, 20)
  expect_equal(
    sc_gammaincc(a, x) * gamma(a),
    gsl::gamma_inc(a, x),
    tolerance = 1e-13
  )
  nu <- c(0, 0.5, 2.3, 7)
  expect_equal(sc_jv(nu, x), gsl::bessel_Jnu(nu, x), tolerance = 1e-13)
  expect_equal(sc_yv(nu, x), gsl::bessel_Ynu(nu, x), tolerance = 1e-13)
  expect_equal(sc_iv(nu, x), gsl::bessel_Inu(nu, x), tolerance = 1e-13)
  expect_equal(sc_kv(nu, x), gsl::bessel_Knu(nu, x), tolerance = 1e-13)
  expect_equal(sc_spherical_jn(2, x), gsl::bessel_jl(2, x), tolerance = 1e-14)
  expect_equal(sc_airy(x - 3)$ai, gsl::airy_Ai(x - 3), tolerance = 1e-13)
  expect_equal(sc_airy(x - 3)$bi, gsl::airy_Bi(x - 3), tolerance = 1e-13)
  # gsl takes the modulus k, SciPy the parameter m = k^2.
  m <- c(0.1, 0.5, 0.9)
  expect_equal(sc_ellipk(m), gsl::ellint_Kcomp(sqrt(m)), tolerance = 1e-14)
  expect_equal(sc_ellipe(m), gsl::ellint_Ecomp(sqrt(m)), tolerance = 1e-14)
  expect_equal(
    sc_ellipkinc(0.7, m),
    gsl::ellint_F(0.7, sqrt(m)),
    tolerance = 1e-14
  )
  s <- c(1.5, 2, 3.3, 10)
  expect_equal(sc_zeta(s), gsl::zeta(s), tolerance = 1e-14)
  expect_equal(sc_zeta(s, 2.5), gsl::hzeta(s, 2.5), tolerance = 1e-14)
  # Spence's function is the dilogarithm Li2(1 - z).
  y <- c(0.1, 0.5, 0.9)
  expect_equal(sc_spence(1 - y), gsl::dilog(y), tolerance = 1e-14)
  # Explained disagreement: for y > 1, Li2(y) is complex and gsl::dilog()
  # returns its real part, while SciPy's real spence() is defined only for
  # z >= 0 and is NaN below (as in Cephes). The complex path agrees.
  expect_true(is.nan(sc_spence(1 - 1.5)))
  expect_equal(
    Re(sc_spence(complex(real = 1 - 1.5, imaginary = 0))),
    gsl::dilog(1.5),
    tolerance = 1e-14
  )
  expect_equal(sc_hyp0f1(1.5, x), gsl::hyperg_0F1(1.5, x), tolerance = 1e-13)
  expect_equal(
    sc_hyp1f1(0.5, 1.5, x),
    gsl::hyperg_1F1(0.5, 1.5, x),
    tolerance = 1e-13
  )
  z <- c(-0.5, 0.1, 0.5, 0.9)
  expect_equal(
    sc_hyp2f1(0.3, 1.2, 2.5, z),
    gsl::hyperg_2F1(0.3, 1.2, 2.5, z),
    tolerance = 1e-13
  )
  expect_equal(
    sc_hyperu(0.5, 1.3, x),
    gsl::hyperg_U(0.5, 1.3, x),
    tolerance = 1e-12
  )
})

test_that("Bessel agrees on complex Bessel, Hankel and Airy functions", {
  skip_if_not_installed("Bessel")
  z <- c(0.5 + 0.2i, 2 - 1i, -3 + 0.5i, 10 + 4i)
  nu <- 1.3
  expect_equal(sc_jv(nu, z), Bessel::BesselJ(z, nu), tolerance = 1e-13)
  expect_equal(sc_yv(nu, z), Bessel::BesselY(z, nu), tolerance = 1e-13)
  expect_equal(sc_iv(nu, z), Bessel::BesselI(z, nu), tolerance = 1e-13)
  expect_equal(sc_kv(nu, z), Bessel::BesselK(z, nu), tolerance = 1e-13)
  expect_equal(sc_hankel1(nu, z), Bessel::BesselH(1, z, nu), tolerance = 1e-13)
  expect_equal(sc_hankel2(nu, z), Bessel::BesselH(2, z, nu), tolerance = 1e-13)
  expect_equal(sc_airy(z)$ai, Bessel::AiryA(z), tolerance = 1e-13)
  expect_equal(sc_airy(z)$bi, Bessel::AiryB(z), tolerance = 1e-13)
})

test_that("hypergeo agrees on complex 2F1", {
  skip_if_not_installed("hypergeo")
  z <- c(0.3 + 0.2i, -0.5 + 0.5i, 0.8 - 0.1i)
  got <- sc_hyp2f1(0.7, 1.3, 2.4, z)
  want <- vapply(z, function(zz) hypergeo::hypergeo(0.7, 1.3, 2.4, zz), 0i)
  expect_equal(got, want, tolerance = 1e-12)
})

test_that("lamW agrees on both real branches of Lambert W", {
  skip_if_not_installed("lamW")
  x <- c(-0.3, 0.1, 1, 50)
  expect_equal(Re(sc_lambertw(x)), lamW::lambertW0(x), tolerance = 1e-14)
  xm <- c(-0.35, -0.2, -0.01)
  expect_equal(
    Re(sc_lambertw(xm, k = -1)),
    lamW::lambertWm1(xm),
    tolerance = 1e-14
  )
})

test_that("expint agrees on the exponential integrals", {
  skip_if_not_installed("expint")
  x <- c(0.2, 1, 5, 30)
  expect_equal(sc_exp1(x), expint::expint_E1(x), tolerance = 1e-14)
  expect_equal(sc_expn(2, x), expint::expint_En(x, 2), tolerance = 1e-14)
  expect_equal(sc_expi(x), expint::expint_Ei(x), tolerance = 1e-14)
})

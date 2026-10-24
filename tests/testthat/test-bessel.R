test_that("cylindrical Bessel functions match base R (note the argument order)", {
  v <- c(0, 0.5, 1, 2.5, 7)
  x <- c(0.3, 1, 4.2, 10, 25)
  expect_equal(sc_jv(v, x), besselJ(x, v), tolerance = 1e-13)
  expect_equal(sc_yv(v, x), besselY(x, v), tolerance = 1e-13)
  expect_equal(sc_iv(v, x), besselI(x, v), tolerance = 1e-13)
  expect_equal(sc_kv(v, x), besselK(x, v), tolerance = 1e-13)
  expect_equal(
    sc_ive(v, x),
    besselI(x, v, expon.scaled = TRUE),
    tolerance = 1e-13
  )
  expect_equal(
    sc_kve(v, x),
    besselK(x, v, expon.scaled = TRUE),
    tolerance = 1e-13
  )
  expect_equal(sc_jve(v, x), sc_jv(v, x), tolerance = 1e-14) # real x: no scaling
})

test_that("fixed-order functions agree with the general ones", {
  x <- c(0.2, 1.5, 8, 30)
  expect_equal(sc_j0(x), sc_jv(0, x), tolerance = 1e-13)
  expect_equal(sc_j1(x), sc_jv(1, x), tolerance = 1e-13)
  expect_equal(sc_y0(x), sc_yv(0, x), tolerance = 1e-13)
  expect_equal(sc_y1(x), sc_yv(1, x), tolerance = 1e-13)
  expect_equal(sc_i0(x), sc_iv(0, x), tolerance = 1e-13)
  expect_equal(sc_i1(x), sc_iv(1, x), tolerance = 1e-13)
  expect_equal(sc_k0(x), sc_kv(0, x), tolerance = 1e-13)
  expect_equal(sc_k1(x), sc_kv(1, x), tolerance = 1e-13)
  expect_equal(sc_i0e(x), exp(-x) * sc_i0(x), tolerance = 1e-13)
  expect_equal(sc_i1e(x), exp(-x) * sc_i1(x), tolerance = 1e-13)
  expect_equal(sc_k0e(x), exp(x) * sc_k0(x), tolerance = 1e-13)
  expect_equal(sc_k1e(x), exp(x) * sc_k1(x), tolerance = 1e-13)
  # Wronskian J1 Y0 - J0 Y1 = 2 / (pi x)
  expect_equal(
    sc_j1(x) * sc_y0(x) - sc_j0(x) * sc_y1(x),
    2 / (pi * x),
    tolerance = 1e-12
  )
})

test_that("real input stays real; complex input takes the complex path", {
  expect_true(is.nan(sc_jv(0.5, -1)))
  expect_type(sc_jv(0.5, -1 + 0i), "complex")
  expect_false(is.nan(Re(sc_jv(0.5, -1 + 0i))))
  z <- 1.3 - 0.4i
  expect_equal(
    sc_jv(1.5, z),
    complex(
      real = Re(sc_jv(1.5, z)),
      imaginary = Im(sc_jv(1.5, z))
    )
  )
  expect_error(sc_jv(1i, 2), class = "zuspecial_invalid_argument")
})

test_that("Hankel functions are complex only and combine J and Y", {
  v <- c(0, 1.5, 3)
  x <- c(0.7, 2, 9)
  expect_type(sc_hankel1(v, x), "complex")
  expect_equal(
    sc_hankel1(v, x),
    complex(real = sc_jv(v, x), imaginary = sc_yv(v, x)),
    tolerance = 1e-13
  )
  expect_equal(sc_hankel2(v, x), Conj(sc_hankel1(v, x)), tolerance = 1e-13)
  z <- 2 + 0.5i
  expect_equal(
    sc_hankel1e(1, z),
    sc_hankel1(1, z) * exp(-1i * z),
    tolerance = 1e-13
  )
  expect_equal(
    sc_hankel2e(1, z),
    sc_hankel2(1, z) * exp(1i * z),
    tolerance = 1e-13
  )
})

test_that("spherical Bessel functions at closed forms and derivatives", {
  x <- c(0.5, 2, 7.3)
  expect_equal(sc_spherical_jn(0, x), sin(x) / x, tolerance = 1e-14)
  expect_equal(sc_spherical_yn(0, x), -cos(x) / x, tolerance = 1e-14)
  expect_equal(sc_spherical_in(0, x), sinh(x) / x, tolerance = 1e-14)
  expect_equal(sc_spherical_kn(0, x), pi / 2 * exp(-x) / x, tolerance = 1e-14)
  # f_n'(z) = f_{n-1}(z) - (n + 1) / z f_n(z), for j and y
  n <- 3
  for (f in list(sc_spherical_jn, sc_spherical_yn)) {
    expect_equal(
      f(n, x, derivative = TRUE),
      f(n - 1, x) - (n + 1) / x * f(n, x),
      tolerance = 1e-12
    )
  }
  z <- 1.2 + 0.7i
  expect_equal(sc_spherical_jn(0, z), sin(z) / z, tolerance = 1e-14)
  expect_error(sc_spherical_jn(1.5, 1), class = "zuspecial_invalid_argument")
  expect_error(
    sc_spherical_jn(1, 1, derivative = NA),
    class = "zuspecial_invalid_argument"
  )
})

test_that("Airy functions: Wronskian, scaling and shape", {
  x <- c(-6, -1, 0, 0.8, 3)
  a <- sc_airy(x)
  expect_named(a, c("ai", "aip", "bi", "bip"))
  expect_equal(a$ai * a$bip - a$aip * a$bi, rep(1 / pi, 5), tolerance = 1e-12)
  ae <- sc_airye(x[x > 0])
  zeta <- 2 / 3 * x[x > 0]^1.5
  expect_equal(ae$ai, a$ai[x > 0] * exp(zeta), tolerance = 1e-13)
  expect_equal(ae$bi, a$bi[x > 0] * exp(-zeta), tolerance = 1e-13)
  m <- matrix(c(0.5, 1, 2, 3), 2)
  expect_identical(dim(sc_airy(m)$bi), c(2L, 2L))
  expect_type(sc_airy(1 + 1i)$ai, "complex")
})

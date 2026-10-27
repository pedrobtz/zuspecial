# Ported from SciPy 1.18.1's scipy/special/tests/test_wrightomega.py, then
# SciPy 1.18.1's values in the regions those tests do not reach. A signed
# zero is checked through 1 / x, which is -Inf for -0.

test_that("NaN anywhere gives NaN in both parts", {
  z <- complex(
    real = c(NaN, 0, NaN, NaN, 1),
    imaginary = c(0, NaN, NaN, 1, NaN)
  )
  out <- sc_wrightomega(z)
  expect_true(all(is.nan(Re(out)) & is.nan(Im(out))))
  expect_true(is.nan(sc_wrightomega(NaN)))
})

test_that("-Inf gives zeros signed by the branch", {
  y <- c(pi / 4, -pi / 4, 3 * pi / 4, -3 * pi / 4)
  out <- sc_wrightomega(complex(real = -Inf, imaginary = y))
  expect_identical(Re(out), rep(0, 4))
  expect_identical(Im(out), rep(0, 4))
  expect_identical(1 / Re(out), c(Inf, Inf, -Inf, -Inf))
  expect_identical(1 / Im(out), c(Inf, -Inf, Inf, -Inf))
})

test_that("infinite inputs return themselves", {
  z <- complex(real = c(Inf, -Inf, 10, 10), imaginary = c(10, 10, Inf, -Inf))
  expect_identical(sc_wrightomega(z), z)
  expect_identical(sc_wrightomega(c(-Inf, Inf)), c(0, Inf))
})

test_that("the singular points give -1 with a positive zero part", {
  out <- sc_wrightomega(complex(real = -1, imaginary = c(pi, -pi)))
  expect_identical(Re(out), c(-1, -1))
  expect_identical(1 / Im(out), c(Inf, Inf))
})

test_that("the real series and exp crossovers are accurate", {
  # The neighbours of each crossover (1e20's ulp is 2^14, 50's is
  # 2^5 eps) and mpmath's values, from SciPy's tests, at 2 eps.
  rel <- function(got, want) abs(got - want) / abs(want)
  x <- c(
    1e20 - 2^14,
    1e20 + 2^14,
    -50 + 2^5 * .Machine$double.eps,
    -50 - 2^5 * .Machine$double.eps
  )
  want <- c(
    99999999999999983569.948,
    100000000000000016337.948,
    1.9287498479639314876e-22,
    1.9287498479639040784e-22
  )
  expect_true(all(rel(sc_wrightomega(x), want) <= 2 * .Machine$double.eps))
})

test_that("real and complex paths agree on the real line", {
  x <- seq(-500, 500, by = 1)
  expect_equal(
    sc_wrightomega(x),
    Re(sc_wrightomega(complex(real = x, imaginary = 0))),
    tolerance = 1e-14
  )
})

test_that("SciPy's values on the branch cuts, at large |z| and in underflow", {
  # x, y, then SciPy 1.18.1's real and imaginary parts.
  rows <- rbind(
    c(-3, pi, -0.052469097457714865, 2.311115933264683e-33),
    c(-3, -pi, -4.505241495792884, 0),
    c(-1.5, pi, -2.357676673945899, -2.9582283945787943e-31),
    c(-1.5, -pi, -0.3017095626843359, 2.2420775429197073e-44),
    c(-2, pi, -0.15859433956303937, 0),
    c(-10, 3, -4.494756899741149e-05, 6.407414430118366e-06),
    c(-10, -3, -4.494756899741149e-05, -6.407414430118366e-06),
    c(1e10, 1e10, 9999999976.627575, 9999999999.214602),
    c(2, 1e3, -4.906190399249219, 998.4242897794222),
    c(0.5, 0.25, 0.7618991278801487, 0.1085191636715822)
  )
  got <- sc_wrightomega(complex(real = rows[, 1], imaginary = rows[, 2]))
  want <- complex(real = rows[, 3], imaginary = rows[, 4])
  expect_lt(max(Mod(got - want) / Mod(want)), 1e-14)

  # Underflow to zero, with SciPy's signs.
  out <- sc_wrightomega(complex(
    real = c(-1e10, -800, -750),
    imaginary = c(2, 0.5, -2.5)
  ))
  expect_identical(Re(out), c(0, 0, 0))
  expect_identical(1 / Im(out), c(Inf, Inf, -Inf))
})

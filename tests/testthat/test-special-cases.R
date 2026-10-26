# Branches of the ported code that the oracle tables do not reach, because
# their random inputs are continuous: SciPy's hyp1f1 conventions around
# Boost, NumPy's integer-power path in the hyp0f1 port, and the special
# inputs of the hyp0f1, hyperu and spence ports. Expected values are
# scipy.special 1.18.1's (NumPy 2.5.4, macOS), the codes those SciPy raises
# through sf_error under errstate(<code> = "raise").

test_that("hyp1f1 keeps SciPy's conventions around Boost", {
  withr::local_options(zuspecial.errstate = NULL)
  # b a non-positive integer: Inf, unless a is too.
  expect_identical(sc_hyp1f1(1, -2, 0.5), Inf)
  expect_identical(sc_hyp1f1(1, 0, 0.5), Inf)
  # a == b: the pFq route (boostorg/math#829).
  expect_equal(sc_hyp1f1(-2, -2, 0.5), 1.625, tolerance = 1e-15)
  # a a negative integer with a >= b: Boost's polynomial.
  expect_equal(sc_hyp1f1(-2, -3, 0.5), 1.375, tolerance = 1e-15)
  # a a negative integer, b == x: the pFq route (boostorg/math#833).
  expect_equal(sc_hyp1f1(-3, 1.5, 1.5), -0.4571428571428573, tolerance = 1e-14)
  expect_equal(sc_hyp1f1(2.5, 2.5, 0.7), 2.0137527074704766, tolerance = 1e-14)
  expect_equal(
    sc_hyp1f1(1, 1.5, -1000),
    0.000500250375940796,
    tolerance = 1e-14
  )
  # NaN in each argument, before Boost is called.
  expect_true(all(is.nan(c(
    sc_hyp1f1(NaN, 1, 1),
    sc_hyp1f1(1, NaN, 1),
    sc_hyp1f1(1, 1, NaN)
  ))))
  # Boost's overflow_error, mapped to Inf and the overflow code.
  expect_identical(sc_hyp1f1(1, 1.5, 1000), Inf)
  expect_error(
    sc_errstate(sc_hyp1f1(1, 1.5, 1000), overflow = "raise"),
    class = "zuspecial_overflow_error"
  )
  expect_error(
    sc_errstate(sc_hyp1f1(500, 1.5, 800), overflow = "raise"),
    class = "zuspecial_overflow_error"
  )
})

test_that("the incomplete beta wrappers return NaN and domain as SciPy's", {
  withr::local_options(zuspecial.errstate = NULL)
  expect_true(is.nan(sc_betainc(NaN, 1, 0.5)))
  expect_true(is.nan(sc_betaincinv(1, NaN, 0.5)))
  expect_true(is.nan(sc_betainccinv(1, 1, NaN)))
  expect_true(is.nan(sc_betainccinv(-1, 1, 0.5)))
  expect_error(
    sc_errstate(sc_betainccinv(-1, 1, 0.5), domain = "raise"),
    class = "zuspecial_domain_error"
  )
})

test_that("hyp0f1 at whole orders takes NumPy's integer-power path", {
  # 1 - v is 0, -1, -2, -4 and -11, then -24 for complex z.
  expect_equal(sc_hyp0f1(1, 2.5), 5.57162224874372, tolerance = 1e-14)
  expect_equal(sc_hyp0f1(2, 2.5), 2.8941043158779842, tolerance = 1e-14)
  expect_equal(sc_hyp0f1(3, -2.5), 0.38789491345416865, tolerance = 1e-14)
  expect_equal(sc_hyp0f1(5, 40), 275.5254195469886, tolerance = 1e-14)
  expect_equal(sc_hyp0f1(12, 3), 1.2810135950956818, tolerance = 1e-14)
  expect_equal(
    sc_hyp0f1(1, 2.5 + 1i),
    complex(real = 5.0389242469296756, imaginary = 2.8440690552272314),
    tolerance = 1e-14
  )
  expect_equal(
    sc_hyp0f1(2, -2.5 + 1i),
    complex(real = 0.13243530830804628, imaginary = 0.18983962873493812),
    tolerance = 1e-14
  )
  expect_equal(
    sc_hyp0f1(3, 30 - 4i),
    complex(real = 327.1132871450105, imaginary = -212.14603452148577),
    tolerance = 1e-14
  )
  expect_equal(
    sc_hyp0f1(12, 3 + 2i),
    complex(real = 1.2651776604931448, imaginary = 0.20879301100056138),
    tolerance = 1e-14
  )
  expect_equal(
    sc_hyp0f1(25, 1000 + 10i),
    complex(real = 958050570162.3834, imaginary = 210259830253.9989),
    tolerance = 1e-14
  )
})

test_that("hyp0f1, hyperu and spence give SciPy's special values", {
  withr::local_options(zuspecial.errstate = NULL)
  # Non-positive integer order: NaN; complex keeps a zero imaginary part.
  expect_true(is.nan(sc_hyp0f1(0, 1)))
  expect_true(is.nan(sc_hyp0f1(-2, 1)))
  expect_identical(sc_hyp0f1(0, 1 + 1i), complex(real = NaN, imaginary = 0))
  # z == 0, and the small-z series.
  expect_identical(sc_hyp0f1(2.5, 0), 1)
  expect_identical(sc_hyp0f1(2.5, 0i), 1 + 0i)
  expect_equal(sc_hyp0f1(2.5, 1e-10), 1.00000000004, tolerance = 1e-15)
  expect_equal(
    sc_hyp0f1(2.5, 1e-10 + 1e-10i),
    complex(real = 1.00000000004, imaginary = 4.0000000001142864e-11),
    tolerance = 1e-15
  )
  expect_true(is.nan(sc_hyperu(NaN, 1, 1)))
  expect_true(is.nan(sc_hyperu(1, 2, -1)))
  expect_error(
    sc_errstate(sc_hyperu(1, 2, -1), domain = "raise"),
    class = "zuspecial_domain_error"
  )
  expect_identical(sc_hyperu(1, 2, 0), Inf)
  expect_error(
    sc_errstate(sc_hyperu(1, 2, 0), singular = "raise"),
    class = "zuspecial_singular_error"
  )
  expect_identical(sc_hyperu(1, 0.5, 0), 2)
  expect_equal(sc_spence(0i), complex(real = pi^2 / 6, imaginary = 0))
  expect_identical(sc_spence(1 + 0i), 0 + 0i)
})

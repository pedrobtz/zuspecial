test_that("the real metric matches xsf's special cases", {
  tiny <- 4.9406564584124654e-324
  expect_identical(xsf_rel_err(1, 1), 0)
  expect_identical(xsf_rel_err(NaN, NaN), 0)
  expect_identical(xsf_rel_err(1, NaN), Inf)
  expect_identical(xsf_rel_err(NaN, 1), Inf)
  expect_identical(xsf_rel_err(Inf, Inf), 0)
  expect_identical(xsf_rel_err(-Inf, -Inf), 0)
  early <- xsf_rel_err(Inf, 1e308)
  expect_true(is.finite(early) && early > 0)
  expect_identical(xsf_rel_err(1e-300, 0), 1e-300 / tiny)
  expect_equal(xsf_rel_err(1 + 2^-52, 1), 2^-52)
  expect_identical(xsf_rel_err(c(1, 2), c(1, 4)), c(0, 0.5))
})

test_that("the complex metric rescales zero and infinite parts as xsf does", {
  expect_identical(xsf_rel_err(1 + 0i, 1 + 0i), 0)
  expect_equal(
    xsf_rel_err(complex(real = 1, imaginary = 1e-20), 1 + 0i),
    1e-20
  )
  expect_identical(
    xsf_rel_err(
      complex(real = NaN, imaginary = 0),
      complex(real = NaN, imaginary = 0)
    ),
    0
  )
  expect_identical(
    xsf_rel_err(
      complex(real = 1, imaginary = 0),
      complex(real = NaN, imaginary = 0)
    ),
    Inf
  )
  big <- complex(real = 1e308, imaginary = 1e308)
  expect_true(is.finite(xsf_rel_err(big, big * (1 + 1e-15))))
})

test_that("the tolerance follows xsf's tests", {
  expect_identical(xsf_tol(0), 4 * .Machine$double.eps)
  expect_identical(xsf_tol(1e-10), 4e-10)
})

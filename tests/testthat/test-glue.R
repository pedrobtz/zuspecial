test_that("the real loop calls the kernel and passes NaN through", {
  out <- .Call(zsp_call_d, "gamma", c(5, 0.5, NaN))
  expect_equal(out, c(24, sqrt(pi), NaN), tolerance = 1e-15)
  expect_null(attr(out, "zsp_err"))
})

test_that("NA is decided before the kernel", {
  out <- .Call(zsp_call_d, "gamma", c(NA, -1))
  expect_identical(out[1], NA_real_)
  expect_true(is.nan(out[2]))
  report <- attr(out, "zsp_err")
  # NA never reaches the kernel, so the singular count is 1, at index 2.
  expect_identical(report[c(1, 11)], c(1, 2))
})

test_that("the report counts every element and keeps the first index", {
  out <- .Call(zsp_call_d, "gamma", c(1, -1, -2))
  report <- attr(out, "zsp_err")
  expect_length(report, 20)
  expect_identical(report[c(1, 11)], c(2, 2))
  expect_identical(sum(report[-c(1, 11)]), 0)
})

test_that("the complex loop treats either NA part as NA and passes NaN", {
  z <- complex(real = c(NA, 1, NaN), imaginary = c(0, NA, 0))
  out <- .Call(zsp_call_c, "gamma", z)
  expect_identical(out[1:2], c(NA_complex_, NA_complex_))
  expect_true(is.nan(Re(out[3])))
  expect_equal(
    .Call(zsp_call_c, "gamma", complex(real = 5, imaginary = 0)),
    24 + 0i,
    tolerance = 1e-14
  )
})

test_that("two- and three-argument loops and the integer-order loop", {
  expect_equal(.Call(zsp_call_dd, "beta", c(2, NA), c(3, 1)), c(1 / 12, NA))
  expect_equal(
    .Call(zsp_call_ddd, "voigt_profile", 0, 1, 0),
    1 / sqrt(2 * pi),
    tolerance = 1e-14
  )
  out <- .Call(zsp_call_id, "expn", c(1L, NA), c(1, 1))
  expect_equal(out[1], 0.21938393439552029, tolerance = 1e-14) # E1(1)
  expect_identical(out[2], NA_real_)
})

test_that("an unknown kernel is an error before the loop", {
  expect_error(.Call(zsp_call_d, "nosuch", 1), "nosuch")
})

test_that("order-real, argument-complex loop handles NA in either argument", {
  out <- .Call(
    zsp_call_dc,
    "jv",
    c(0, NA, 1),
    complex(real = c(1, 1, NA), imaginary = 0)
  )
  expect_equal(Re(out[1]), besselJ(1, 0), tolerance = 1e-14)
  expect_identical(out[2:3], c(NA_complex_, NA_complex_))
})

test_that("integer-order complex loop", {
  out <- .Call(zsp_call_ic, "spherical_jn", c(0L, NA), c(1 + 0i, 1 + 0i))
  expect_equal(Re(out[1]), sin(1), tolerance = 1e-14)
  expect_identical(out[2], NA_complex_)
})

test_that("four-output loops return four vectors and one report", {
  out <- .Call(zsp_call_d4, "airy", c(0, NA))
  expect_length(out, 4)
  expect_equal(out[[1]][1], 1 / (3^(2 / 3) * gamma(2 / 3)), tolerance = 1e-14)
  expect_identical(vapply(out, function(x) x[2], 0), rep(NA_real_, 4))
  outc <- .Call(zsp_call_c4, "airy", c(0 + 0i, NA))
  expect_type(outc[[3]], "complex")
  expect_identical(outc[[4]][2], NA_complex_)
})

test_that("NA in any argument position gives NA in every C loop", {
  withr::local_options(zuspecial.errstate = NULL)
  sc_seterr(all = "raise")
  # One call per loop signature (d, c, dd, ddd, id, dc, ic, d4, c4, dd4,
  # dddd, dddc, ddc, cd, cid), with arguments that give a finite value.
  cases <- list(
    list(sc_gamma, list(1.5)),
    list(sc_gamma, list(1.5 + 1i)),
    list(sc_beta, list(1, 2)),
    list(sc_hyperu, list(1, 2, 3)),
    list(sc_expn, list(1, 1)),
    list(sc_jv, list(1, 1 + 1i)),
    list(sc_spherical_jn, list(1, 1 + 1i)),
    list(sc_airy, list(1)),
    list(sc_airy, list(1 + 1i)),
    list(sc_ellipj, list(1, 0.5)),
    list(sc_hyp2f1, list(1, 1, 2, 0.5)),
    list(sc_hyp2f1, list(1, 1, 2, 0.5i)),
    list(sc_hyp1f1, list(1, 2, 1i)),
    list(sc_zeta, list(2 + 0i, 2)),
    list(sc_lambertw, list(1, 0, 1e-8))
  )
  na_only <- function(x) is.na(x) & !is.nan(x)
  for (case in cases) {
    for (i in seq_along(case[[2]])) {
      args <- case[[2]]
      args[[i]] <- if (is.complex(args[[i]])) NA_complex_ else NA_real_
      value <- do.call(case[[1]], args)
      outputs <- if (is.list(value)) value else list(value)
      for (out in outputs) {
        expect_true(na_only(out))
      }
    }
  }
})

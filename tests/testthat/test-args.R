test_that("length-one arguments recycle to the common length", {
  prep <- zsp_prep(list(a = 1, b = c(1, 2, 3)))
  expect_identical(prep$n, 3L)
  expect_identical(prep$args$a, c(1, 1, 1))
  expect_false(prep$complex)
})

test_that("other mismatched lengths are an error", {
  cnd <- expect_error(
    zsp_prep(list(a = c(1, 2), b = c(1, 2, 3))),
    class = "zuspecial_recycle_error"
  )
  expect_identical(cnd$lengths, c(a = 2L, b = 3L))
})

test_that("a zero-length argument gives zero-length output", {
  prep <- zsp_prep(list(a = numeric(), b = c(1, 2, 3)))
  expect_identical(prep$n, 0L)
  expect_identical(prep$args$b, numeric())
})

test_that("integer and logical input become double, NA included", {
  prep <- zsp_prep(list(a = c(1L, NA), b = c(TRUE, NA)))
  expect_identical(prep$args$a, c(1, NA_real_))
  expect_identical(prep$args$b, c(1, NA_real_))
})

test_that("character, factor, list and unsupported complex are refused", {
  for (bad in list("a", factor("a"), list(1))) {
    cnd <- expect_error(
      zsp_prep(list(a = bad)),
      class = "zuspecial_invalid_argument"
    )
    expect_identical(cnd$argument, "a")
  }
  expect_error(zsp_prep(list(x = 1i)), class = "zuspecial_invalid_argument")
})

test_that("complex in a complex-capable argument selects the complex path", {
  prep <- zsp_prep(list(z = c(1, 2) + 0i), complex_ok = "z")
  expect_true(prep$complex)
  expect_type(prep$args$z, "complex")
  prep <- zsp_prep(list(z = c(1, 2)), complex_ok = "z")
  expect_false(prep$complex)
  expect_type(prep$args$z, "double")
})

test_that("the template is the first argument of the result's length", {
  m <- matrix(1:4, 2, dimnames = list(c("a", "b"), NULL))
  prep <- zsp_prep(list(a = 1, b = m))
  expect_identical(prep$template, m)
  out <- zsp_finish(c(5, 6, 7, 8), prep$template)
  expect_identical(dim(out), c(2L, 2L))
  expect_identical(dimnames(out), dimnames(m))
  expect_identical(
    names(zsp_finish(1:2 + 0, c(x = 1, y = 2))),
    c("x", "y")
  )
  expect_null(attributes(zsp_finish(1, NULL)))
})

test_that("integer orders must be whole and within int range", {
  expect_identical(zsp_whole(c(1, NA, -3), "n"), c(1L, NA, -3L))
  for (bad in list(c(1, 2.5), 2^31, Inf, NaN)) {
    expect_error(zsp_whole(bad, "n"), class = "zuspecial_invalid_argument")
  }
  cnd <- expect_error(zsp_whole(c(1, 2.5), "n"))
  expect_identical(cnd$index, 2L)
})

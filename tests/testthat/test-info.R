test_that("info reports the vendored xsf and SciPy versions", {
  info <- zuspecial_info()
  expect_identical(info$xsf_commit, "f7b85f505a94fd398024478d2e747b01dd2d7a6d")
  expect_identical(info$scipy_version, "1.18.1")
  expect_type(info$compiler, "character")
  expect_true(nzchar(info$compiler))
})

test_that("the function table lists every exported kernel function", {
  fns <- zuspecial_info()$functions
  exported <- setdiff(
    grep("^sc_", getNamespaceExports("zuspecial"), value = TRUE),
    c("sc_geterr", "sc_seterr", "sc_errstate")
  )
  expect_setequal(fns$r_name, exported)
  expect_identical(fns$r_name, paste0("sc_", fns$scipy_name))
  expect_true(all(fns$backend == "xsf"))
  expect_identical(
    sort(fns$r_name[fns$complex]),
    sort(paste0("sc_", c(
      "gamma", "loggamma", "rgamma", "psi", "erf", "erfc", "erfcx", "erfi",
      "dawsn", "wofz", "exp1", "expi"
    )))
  )
})

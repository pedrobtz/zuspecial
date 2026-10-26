# The registered C table (inst/include/zuspecial.h), as a downstream package
# sees it. These need the installed package, which R CMD check provides and
# devtools::load_all() does not, so they skip there.

test_that("the public header compiles on its own as C99", {
  skip_if_not_installed_layout()
  skip_on_cran()
  header <- system.file("include", "zuspecial.h", package = "zuspecial")
  expect_true(file.exists(header))
  cc <- strsplit(r_cmd("CMD", "config", "CC"), " ")[[1]]
  src <- withr::local_tempfile(fileext = ".c")
  writeLines(c("#include <zuspecial.h>", "int main(void) { return 0; }"), src)
  out <- system2(
    cc[[1]],
    c(
      cc[-1],
      "-std=c99",
      "-pedantic",
      "-Wall",
      "-fsyntax-only",
      paste0("-I", dirname(header)),
      src
    ),
    stdout = TRUE,
    stderr = TRUE
  )
  expect_null(attr(out, "status"), label = paste(out, collapse = "\n"))
  expect_false(any(grepl("warning", out)), label = paste(out, collapse = "\n"))
  expect_false(any(
    grepl("xsf|boost", readLines(header), ignore.case = TRUE) &
      grepl("#include", readLines(header))
  ))
})

test_that("a consumer package calls the table: real, complex, error code", {
  skip_if_not_installed_layout()
  skip_on_cran()
  lib <- withr::local_tempdir()
  fixture <- file.path(withr::local_tempdir(), "zsconsumer")
  dir.create(fixture)
  file.copy(
    list.files(test_path("fixtures", "zsconsumer"), full.names = TRUE),
    fixture,
    recursive = TRUE
  )
  withr::local_envvar(
    R_LIBS = paste(c(lib, .libPaths()), collapse = .Platform$path.sep)
  )
  out <- r_cmd(
    "CMD",
    "INSTALL",
    "--no-test-load",
    "-l",
    shQuote(lib),
    shQuote(fixture)
  )
  expect_null(attr(out, "status"), label = paste(out, collapse = "\n"))

  result <- withr::local_tempfile(fileext = ".rds")
  script <- sprintf(
    "library(zsconsumer, lib.loc = '%s'); saveRDS(list(info = zsc_info(), g5 = zsc_gamma(5), gp = zsc_gamma(-1), j = zsc_jv_c(1.5, 1 + 2i), all = zsc_all(c(0.3, 0.7, 0.6))), '%s')",
    normalizePath(lib, winslash = "/"),
    normalizePath(result, winslash = "/", mustWork = FALSE)
  )
  out <- system2(
    file.path(R.home("bin"), "Rscript"),
    c("-e", shQuote(script)),
    stdout = TRUE,
    stderr = TRUE
  )
  expect_null(attr(out, "status"), label = paste(out, collapse = "\n"))
  r <- readRDS(result)
  expect_identical(r$info[[2]], zuspecial_info()$xsf_commit)
  expect_true(r$info[[3]])
  expect_gt(r$info[[1]], 0L)
  expect_identical(r$g5[[1]], sc_gamma(5))
  expect_identical(r$g5[[2]], 0L)
  expect_true(is.nan(r$gp[[1]]))
  expect_identical(r$gp[[2]], 1L) # SF_ERROR_SINGULAR
  expect_identical(r$j[[1]], sc_jv(1.5, 1 + 2i))

  # Every member, in the table's order, against its sc_ function: a member
  # wired to the wrong kernel, or the table reordered, shows here.
  a <- 0.3
  b <- 0.7
  c <- 0.6
  want <- c(
    sc_gamma(a),
    sc_gammaln(a),
    sc_gammasgn(a),
    sc_rgamma(a),
    sc_psi(a),
    sc_erf(a),
    sc_erfc(a),
    sc_erfcx(a),
    sc_erfinv(a),
    sc_erfcinv(a),
    sc_ndtr(a),
    sc_log_ndtr(a),
    sc_ndtri(a),
    sc_zeta(a),
    sc_ndtri_exp(-a),
    sc_beta(a, b),
    sc_betaln(a, b),
    sc_binom(a, b),
    sc_gammainc(a, b),
    sc_gammaincc(a, b),
    sc_gammaincinv(a, b),
    sc_gammainccinv(a, b),
    sc_owens_t(a, b),
    sc_jv(a, b),
    sc_yv(a, b),
    sc_iv(a, b),
    sc_kv(a, b),
    sc_betainc(a, b, c),
    sc_betaincc(a, b, c),
    sc_betaincinv(a, b, c),
    sc_betainccinv(a, b, c),
    sc_gamma(a) # gamma again, with code = NULL
  )
  # Compared to 1e-14, not bit for bit: under valgrind this process
  # emulates long double at double precision while the consumer's Rscript,
  # which valgrind does not trace, does not, and the Boost-backed betaincc
  # then differs in the last bit. A mis-wired member differs by far more.
  expect_equal(r$all, want, tolerance = 1e-14)
  expect_false(anyNA(want))
  expect_identical(anyDuplicated(want[-length(want)]), 0L)
  expect_identical(r$j[[2]], 0L)
})

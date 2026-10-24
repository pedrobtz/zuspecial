# Shared by test-mpfr.R. In a helper, not at the test file's top level:
# devtools::test(shuffle = TRUE) reorders a file's top-level expressions.

mpfr_200 <- function(x) Rmpfr::mpfr(x, 200)

mpfr_rel_err <- function(got, want) {
  want <- Rmpfr::asNumeric(want)
  abs(got - want) / abs(want)
}

mpfr_env_err <- function(got, want, envelope) {
  abs(got - Rmpfr::asNumeric(want)) / envelope
}

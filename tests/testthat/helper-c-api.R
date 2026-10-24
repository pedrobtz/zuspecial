# Shared by test-c-api.R. In a helper, not at the test file's top level:
# devtools::test(shuffle = TRUE) reorders a file's top-level expressions.

skip_if_not_installed_layout <- function() {
  skip_if(
    !nzchar(system.file("Meta", "package.rds", package = "zuspecial")),
    "not an installed layout"
  )
}

r_cmd <- function(...) {
  system2(file.path(R.home("bin"), "R"), c(...), stdout = TRUE, stderr = TRUE)
}

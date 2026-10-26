test_that("test files hold only test_that() blocks at their top level", {
  # devtools::test(shuffle = TRUE) reorders each file's top-level
  # expressions, so a helper defined there can run after the tests that use
  # it. Helpers belong in helper-*.R (CLAUDE.md, Testing conventions).
  files <- list.files(test_path(), "^test-.*[.]R$", full.names = TRUE)
  skip_if(length(files) == 0L, "test sources not available")
  for (file in files) {
    exprs <- parse(file, keep.source = FALSE)
    heads <- vapply(
      exprs,
      function(e) {
        if (is.call(e)) deparse(e[[1]]) else class(e)[[1]]
      },
      ""
    )
    stray <- setdiff(heads, c("test_that", "describe"))
    expect(
      length(stray) == 0L,
      sprintf(
        "%s has top-level %s",
        basename(file),
        paste(stray, collapse = ", ")
      )
    )
  }
})

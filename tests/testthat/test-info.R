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
  expect_true(all(fns$backend %in% c("xsf", "boost")))
  expect_identical(
    sort(fns$r_name[fns$complex]),
    sort(paste0(
      "sc_",
      c(
        "gamma",
        "loggamma",
        "rgamma",
        "psi",
        "erf",
        "erfc",
        "erfcx",
        "erfi",
        "dawsn",
        "wofz",
        "exp1",
        "expi",
        "ndtr",
        "log_ndtr",
        "jv",
        "yv",
        "iv",
        "kv",
        "jve",
        "yve",
        "ive",
        "kve",
        "hankel1",
        "hankel2",
        "hankel1e",
        "hankel2e",
        "spherical_jn",
        "spherical_yn",
        "spherical_in",
        "spherical_kn",
        "airy",
        "airye",
        "hyp0f1",
        "hyp1f1",
        "hyp2f1",
        "zeta",
        "lambertw",
        "wrightomega",
        "spence"
      )
    ))
  )
})

test_that("info reports the xsref commit the shipped tables come from", {
  commit <- zuspecial_info()$xsref_commit
  expect_identical(commit, "4e9b2343813136e355f0262754a3929d98bc5bff")
  for (file in list.files(test_path("xsref"), "\\.rds$", full.names = TRUE)) {
    expect_identical(readRDS(file)$commit, commit)
  }
  for (file in list.files(test_path("scipy"), "\\.rds$", full.names = TRUE)) {
    expect_identical(readRDS(file)$commit, zuspecial_info()$scipy_version)
  }
})

test_that("every function has shipped oracle tables", {
  fns <- zuspecial_info()$functions
  read_meta <- function(dir) {
    files <- list.files(test_path(dir), "\\.rds$", full.names = TRUE)
    meta <- lapply(files, function(f) {
      readRDS(f)[c("r_name", "sig", "no_xsref")]
    })
    data.frame(
      r_name = vapply(meta, `[[`, "", "r_name"),
      sig = vapply(meta, `[[`, "", "sig"),
      no_xsref = vapply(meta, function(m) isTRUE(m$no_xsref), NA)
    )
  }
  scipy <- read_meta("scipy")
  xsref <- read_meta("xsref")
  # SciPy values for every function; xsref values for every function xsref
  # has a table for; a complex table for every complex function.
  expect_setequal(unique(scipy$r_name), fns$r_name)
  expect_setequal(
    unique(xsref$r_name),
    unique(scipy$r_name[!scipy$no_xsref])
  )
  complex_tables <- unique(scipy$r_name[grepl("c", scipy$sig)])
  expect_setequal(complex_tables, fns$r_name[fns$complex])

  # From a source tree, the list the tables are generated from matches too.
  tsv <- test_path("..", "..", "tools", "xsref", "functions.tsv")
  skip_if_not(file.exists(tsv), "tools/ is not in the installed tests")
  listed <- utils::read.delim(tsv)
  expect_setequal(listed$r_name, fns$r_name)
  sigs <- unlist(strsplit(listed$sigs, ",", fixed = TRUE))
  expect_setequal(unique(scipy$sig), unique(sigs))
})

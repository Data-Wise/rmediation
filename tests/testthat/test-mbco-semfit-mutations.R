# Mutate a local copy only; assert that the same oracle/refusal assertions fail.
.semfit_mutate <- function(fun, old, new) {
  source <- paste(deparse(fun), collapse = "\n")
  stopifnot(grepl(old, source, fixed = TRUE))
  code <- sub(old, new, source, fixed = TRUE)
  eval(parse(text = code), envir = environment(fun))
}

test_that("branch, label and df mutants fail the oracles", {
  skip_if_not_installed("medfit", "0.8.0")
  f <- .semfit_mbco_fits()
  expect_lt(abs(mbco(f$product, f$full)@statistic - 0.083100), 1e-6)
  larger <- .mbco_semfit(f$a1, f$full)
  expect_failure(expect_lt(abs(larger@statistic - 0.083100), 1e-6))
  shifted <- .fit_sem(paste(
    "repetition ~ a2*x", "imagery ~ cp*x",
    "recall ~ a1*x + b1*repetition + b2*imagery", "a1*b1 == 0",
    sep = "\n"
  ), f$data)
  expect_failure(expect_lt(abs(mbco(
    shifted,
    f$full
  )@statistic - 0.083100), 1e-6))
  wrong_df <- .semfit_mutate(
    .mbco_semfit,
    'as.numeric(comparison[2L, "Df diff"])', "1"
  )
  expect_failure(expect_identical(wrong_df(f$both, f$full)@df, 2))
})

test_that("boundary and version mutants fail refusals", {
  skip_if_not_installed("medfit", "0.8.0")
  f <- .semfit_mbco_fits()
  base <- paste(.semfit_mbco_syntax, "a1 > 0", sep = "\n")
  full <- .fit_sem(base, f$data)
  null <- .fit_sem(paste(base, "a1 == 0", sep = "\n"), f$data)
  missing_guard <- .semfit_mutate(
    .mbco_semfit,
    ".mbco_semfit_compare(h0, h1)", "suppressWarnings(stats::anova(h1, h0))"
  )
  expect_failure(expect_error(missing_guard(null, full), "boundary"))
  original <- utils::packageVersion
  local_mocked_bindings(packageVersion = function(pkg, ...) {
    if (pkg == "medfit") {
      return(package_version("0.7.0"))
    }
    original(pkg, ...)
  }, .package = "utils")
  expect_error(.mbco_semfit(
    f$b1,
    f$full
  ), "requires medfit >= 0.8.0", fixed = TRUE)
  unsafe <- .semfit_mutate(
    .mbco_semfit,
    'utils::packageVersion("medfit") < "0.8.0"', "FALSE"
  )
  expect_failure(expect_error(unsafe(
    f$b1,
    f$full
  ), "requires medfit >= 0.8.0", fixed = TRUE))
})

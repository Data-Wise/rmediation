test_that("SEMFit pairs reproduce independent OpenMx known answers", {
  skip_if_not_installed("medfit", "0.8.0")
  f <- .semfit_mbco_fits()
  for (label in c("a1", "b1", "product")) {
    r <- mbco(f[[label]], f$full)
    expected <- if (label == "a1") 221.045546 else 0.083100
    expect_s3_class(r, "RMediation::MBCOResult")
    expect_lt(abs(r@statistic - expected), 1e-6)
    expect_identical(r@df, 1)
    expect_identical(r@type, "asymp")
    expect_equal(
      r@p_value,
      stats::pchisq(r@statistic, r@df, lower.tail = FALSE)
    )
  }
  expect_equal(
    mbco(f$product, f$full)@statistic,
    min(mbco(f$a1, f$full)@statistic, mbco(f$b1, f$full)@statistic)
  )
  if (requireNamespace("OpenMx", quietly = TRUE)) {
    o <- .memory_exp_oracle()
    expect_equal(
      mbco(
        f$a1,
        f$full
      )@statistic, mbco(o$null_a1, o$full)@statistic,
      tolerance = 1e-6
    )
    expect_equal(
      mbco(
        f$b1,
        f$full
      )@statistic, mbco(o$null_b1, o$full)@statistic,
      tolerance = 1e-6
    )
  }
})

test_that("SEMFit mapping preserves degrees of freedom other than one", {
  skip_if_not_installed("medfit", "0.8.0")
  f <- .semfit_mbco_fits()
  r <- mbco(f$both, f$full)
  expect_identical(r@df, 2)
  expect_equal(r@statistic, stats::anova(f$full, f$both)[2, "Chisq diff"])
  expect_equal(r@p_value, stats::pchisq(r@statistic, 2, lower.tail = FALSE))
})

test_that("SEMFit arguments reject reversal, mixed pairs and unused controls", {
  skip_if_not_installed("medfit", "0.8.0")
  f <- .semfit_mbco_fits()
  expect_error(mbco(f$full, f$b1), "h0 must have more degrees of freedom")
  expect_error(mbco(f$a1, f$b1), "h0 must have more degrees of freedom")
  expect_error(mbco(f$b1, list()), "two SEMFit")
  expect_error(mbco(list(), f$full), "two SEMFit")
  for (type in c("parametric", "semi", "as", "bogus")) {
    expect_error(mbco(f$b1, f$full, type = type), "asymp")
  }
  for (arg in c("R", "checkHess", "checkSE", "optim", "precision", "typo")) {
    args <- list(h0 = f$b1, h1 = f$full)
    args[[arg]] <- 1
    expect_error(do.call(mbco, args), "unused.*SEMFit")
  }
  expect_error(mbco(f$b1, f$full, "asymp", .05, 123), "unused.*SEMFit")
  expect_error(mbco(f$b1, f$full, alpha = NA_real_), "alpha")
  expect_error(mbco(f$b1, f$full, alpha = 2), "alpha")
})

test_that("SEMFit comparisons preserve medfit refusal guards", {
  skip_if_not_installed("medfit", "0.8.0")
  f <- .semfit_mbco_fits()
  bad <- f$b1
  bad@converged <- FALSE
  expect_error(mbco(bad, f$full), "did not converge")
  bad <- f$b1
  bad@f <- f$full@f - 0.01
  expect_error(mbco(bad, f$full), "global optimum")
  weighted <- medfit::fit_sem(paste(.semfit_mbco_syntax, "b1 == 0", sep = "\n"),
    f$data,
    weights = rep(1, nrow(f$data)), se_type = "sandwich"
  )
  expect_error(mbco(weighted, f$full), "sampling weights")
  short <- medfit::fit_sem(paste(
    .semfit_mbco_syntax,
    "b1 == 0",
    sep = "\n"
  ), f$data[-1, ])
  expect_error(mbco(short, f$full), "different numbers of rows")
  changed <- f$data
  changed$recall[1] <- changed$recall[1] + 1
  other <- medfit::fit_sem(paste(
    .semfit_mbco_syntax,
    "b1 == 0",
    sep = "\n"
  ), changed)
  expect_error(mbco(other, f$full), "different data")
  not_nested <- medfit::fit_sem(paste(
    "repetition ~ a1*x", "recall ~ b1*repetition + b2*imagery",
    "imagery ~~ repetition", "imagery ~ 0*x",
    sep = "\n"
  ), f$data)
  expect_error(mbco(not_nested, f$full), "not nested")
  fewer <- medfit::fit_sem(
    "repetition ~ a1*x\nimagery ~ a2*x\na1 == 0\na2 == 0", f$data
  )
  # Two constraints give this different-variable model a larger df.
  expect_error(mbco(fewer, f$full), "same observed variables")
  if (requireNamespace("OpenMx", quietly = TRUE)) {
    mx <- .memory_exp_oracle()$full
    expect_error(mbco(f$b1, mx), "mixed pairs")
    expect_error(mbco(mx, f$full), "mixed pairs")
  }
})

test_that("tested bounds refuse p-values; interior nulls are accepted", {
  skip_if_not_installed("medfit", "0.8.0")
  f <- .semfit_mbco_fits()
  pair <- function(bound) {
    base <- paste(.semfit_mbco_syntax, bound, sep = "\n")
    list(
      full = medfit::fit_sem(base, f$data),
      null = medfit::fit_sem(paste(base, "a1 == 0", sep = "\n"), f$data)
    )
  }
  edge <- pair("a1 > 0")
  expect_warning(stats::anova(edge$full, edge$null), "its p-value is not valid")
  expect_error(mbco(edge$null, edge$full), "cannot report.*boundary")
  row <- pair("a1 - b1 > 0")
  expect_error(mbco(row$null, row$full), "cannot report.*boundary")
  interior <- pair("a1 < 0.2")
  expect_no_warning(mbco(interior$null, interior$full))
})

test_that("unrelated comparison warnings propagate", {
  skip_if_not_installed("medfit", "0.8.0")
  f <- .semfit_mbco_fits()
  original <- stats::anova
  local_mocked_bindings(anova = function(...) {
    warning("unrelated comparison warning", call. = FALSE)
    original(...)
  }, .package = "stats")
  expect_warning(r <- mbco(f$b1, f$full), "unrelated comparison warning")
  expect_lt(abs(r@statistic - 0.083100), 1e-6)
})

test_that("old SEMFit dispatch errors; CI integration remains available", {
  skip_if_not_installed("medfit", "0.7.0")
  if (utils::packageVersion("medfit") >= "0.8.0") {
    skip("old-version library gate")
  }
  d <- .memory_exp_data()
  full <- medfit::fit_sem(.semfit_mbco_syntax, d)
  null <- medfit::fit_sem(paste(.semfit_mbco_syntax, "b1 == 0", sep = "\n"), d)
  expect_error(mbco(null, full), "requires medfit >= 0.8.0", fixed = TRUE)
  obj <- medfit::fit_mediation(recall ~ x + repetition, repetition ~ x,
    data = d, treatment = "x", mediator = "repetition"
  )
  expect_no_error(ci(obj, type = "asymp"))
})

test_that("the adapter never refits either input", {
  skip_if_not_installed("medfit", "0.8.0")
  f <- .semfit_mbco_fits()
  local_mocked_bindings(
    fit_sem = function(...) stop("unexpected refit"),
    .package = "medfit"
  )
  expect_lt(abs(mbco(f$b1, f$full)@statistic - 0.083100), 1e-6)
})

test_that("SEMFit pairs agree across fixed_x settings; mismatched sets are refused", {
  skip_if_not_installed("medfit", "0.8.0")
  skip_if_not(
    "fixed_x" %in% names(formals(medfit::fit_sem)),
    "this medfit has no fixed_x argument"
  )
  d <- .memory_exp_data()
  fit <- function(fixed_x, extra = "") {
    medfit::fit_sem(
      paste(.semfit_mbco_syntax, extra, sep = "\n"), d,
      fixed_x = fixed_x
    )
  }
  expected <- 221.045546
  for (fx in list(FALSE, TRUE, "x")) {
    r <- mbco(fit(fx, "a1 == 0"), fit(fx))
    expect_lt(abs(r@statistic - expected), 1e-6)
    expect_identical(r@df, 1)
  }
  expect_error(
    mbco(fit(TRUE, "a1 == 0"), fit(FALSE)),
    "fixed_x", fixed = TRUE
  )
})

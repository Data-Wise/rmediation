# Issue #92: a bootstrap replicate whose OpenMx fit did not converge is dropped from the null
# distribution, up to 5% of the R replicates; above that the call stops. Only non-convergence may be
# dropped: an unrepairable constraint violation, a non-finite statistic and a negative statistic
# still stop the call (see test-mbco-parametric-replicates.R and test-mbco-worker-contracts.R).
# The p-value is the proportion of the KEPT replicates strictly above the observed statistic, with
# no +1 correction (the same rule as OpenMx's mxCompare(boot = TRUE)); the result reports the
# dropped count in @dropped.

test_that("the bootstrap p-value is taken over the kept replicates, strictly above the observed", {
  # 100 replicates: 4 dropped, 96 kept; 24 kept exceed 2, and 10 kept tie at 2 (not counted).
  null <- c(rep(NA_real_, 4), rep(3, 24), rep(2, 10), rep(1, 62))
  out <- .mbco_bootstrap_p(null, observed = 2)
  expect_identical(out$dropped, 4L)
  # Known answer: 24 / 96. A denominator of R (24 / 100) or a >= comparison (34 / 96) would differ.
  expect_equal(out$p, 24 / 96)
  expect_false(isTRUE(all.equal(out$p, 24 / 100)))
  expect_false(isTRUE(all.equal(out$p, 34 / 96)))
  # No dropped replicate: the ordinary proportion, and a zero count (not NULL).
  clean <- .mbco_bootstrap_p(c(3, 1, 1, 1), observed = 2)
  expect_identical(clean$dropped, 0L)
  expect_equal(clean$p, 1 / 4)
})

test_that("exactly 5% dropped is allowed; more than 5% stops with a classed error", {
  ok <- c(rep(NA_real_, 5), rep(3, 95))
  expect_identical(.mbco_bootstrap_p(ok, observed = 2)$dropped, 5L)
  too_many <- c(rep(NA_real_, 6), rep(3, 94))
  err <- tryCatch(.mbco_bootstrap_p(too_many, observed = 2), error = function(e) e)
  expect_s3_class(err, "RMediation_bootstrap_too_many_dropped")
  expect_match(conditionMessage(err), "6 of 100 bootstrap replicates did not converge")
  expect_match(conditionMessage(err), "more than 5%")
  # With R < 20 a single dropped replicate already exceeds 5%.
  expect_error(
    .mbco_bootstrap_p(c(NA_real_, rep(3, 9)), observed = 2),
    class = "RMediation_bootstrap_too_many_dropped"
  )
})

test_that("a bootstrap with no kept replicate is an error, never a p-value", {
  expect_error(
    .mbco_bootstrap_p(rep(NA_real_, 3), observed = 2),
    class = "RMediation_bootstrap_too_many_dropped"
  )
})

# A replicate whose fits did not converge reports NA; the callers drop it. The mocks make every
# OpenMx fit report status 6.
test_that("a replicate that does not converge returns NA instead of stopping", {
  skip_if_not_installed("OpenMx")
  f <- .memory_exp_oracle()
  testthat::local_mocked_bindings(mxRun = function(model, ...) {
    model@output$status$code <- 6L
    model
  }, .package = "OpenMx")
  stat <- .mbco_replicate_statistic(f$null_b1, f$full, f$null_b1$data$observed, 1L)
  expect_identical(stat, NA_real_)
})

test_that("an unrepairable constraint violation still stops, it is not dropped", {
  skip_if_not_installed("OpenMx")
  f <- .memory_exp_oracle()
  testthat::local_mocked_bindings(mxRun = function(model, ...) {
    model@output$status$code <- 0L
    model
  }, .package = "OpenMx")
  testthat::local_mocked_bindings(.mbco_refit_h0 = function(h0, h1, ...) {
    list(model = NULL, refit = NULL, failure = "a constraint is still violated after the refit")
  })
  expect_error(
    .mbco_replicate_statistic(f$null_b1, f$full, f$null_b1$data$observed, 1L),
    class = "RMediation_bootstrap_infeasible"
  )
})

# End to end through both bootstrap types with the replicate statistic mocked: replicate 3 does not
# converge (NA), odd replicates fall below and even replicates above the observed statistic.
.bounded_mock <- function(obs, drop = 3L) {
  function(h0, h1, data, x) {
    if (x %in% drop) NA_real_ else if (x %% 2L == 1L) obs - 1 else obs + 1
  }
}

test_that("mbco_parametric drops a non-converged replicate and reports the count", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("mvtnorm")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  obs <- .mbco_compare(f$null_b1, f$full)$diffLL[2]
  testthat::local_mocked_bindings(.mbco_replicate_statistic = .bounded_mock(obs))
  res <- mbco_parametric(f$null_b1, f$full, R = 40L, optim = "SLSQP")
  expect_identical(res$dropped, 1L)
  # 40 replicates, replicate 3 dropped: 39 kept, the 20 even ones exceed the observed statistic.
  expect_equal(res$p, 20 / 39)
  expect_identical(getOption("mxOptions"), saved)
})

test_that(".mbco_semi drops a non-converged replicate and reports the count", {
  skip_if_not_installed("OpenMx")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  obs <- .mbco_compare(f$null_b1, f$full)$diffLL[2]
  testthat::local_mocked_bindings(.mbco_replicate_statistic = .bounded_mock(obs))
  res <- .mbco_semi(f$null_b1, f$full, R = 40L, optim = "SLSQP")
  expect_identical(res$dropped, 1L)
  expect_equal(res$p, 20 / 39)
  expect_identical(getOption("mxOptions"), saved)
})

test_that("both bootstrap types stop when more than 5% of the replicates are dropped", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("mvtnorm")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  obs <- .mbco_compare(f$null_b1, f$full)$diffLL[2]
  testthat::local_mocked_bindings(.mbco_replicate_statistic = .bounded_mock(obs, drop = 1:3))
  expect_error(
    mbco_parametric(f$null_b1, f$full, R = 40L, optim = "SLSQP"),
    class = "RMediation_bootstrap_too_many_dropped"
  )
  expect_error(
    .mbco_semi(f$null_b1, f$full, R = 40L, optim = "SLSQP"),
    class = "RMediation_bootstrap_too_many_dropped"
  )
  expect_identical(getOption("mxOptions"), saved)
})

test_that("mbco() carries the dropped count in @dropped; non-bootstrap results have none", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("mvtnorm")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  obs <- .mbco_compare(f$null_b1, f$full)$diffLL[2]
  testthat::local_mocked_bindings(.mbco_replicate_statistic = .bounded_mock(obs))
  res <- mbco(f$null_b1, f$full, type = "parametric", R = 40L, optim = "SLSQP")
  expect_identical(res@dropped, 1L)
  expect_equal(res@p_value, 20 / 39)
  asym <- mbco(f$null_b1, f$full, type = "asymp")
  expect_null(asym@dropped)
})

test_that("MBCOResult validates @dropped as NULL or a single non-negative whole number", {
  base <- list(statistic = 1, df = 1, p_value = 0.5, type = "semi")
  expect_null(do.call(MBCOResult, base)@dropped)
  expect_identical(do.call(MBCOResult, c(base, list(dropped = 0L)))@dropped, 0L)
  expect_error(do.call(MBCOResult, c(base, list(dropped = -1L))), "dropped")
  expect_error(do.call(MBCOResult, c(base, list(dropped = c(1L, 2L)))), "dropped")
  expect_error(do.call(MBCOResult, c(base, list(dropped = NA_integer_))), "dropped")
})

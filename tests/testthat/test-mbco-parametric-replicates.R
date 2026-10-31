# mbco(type = "parametric") used to hand the bootstrap to mxCompare(boot = TRUE), so a replicate null
# fit that violated its constraint (e.g. OpenMx/OpenMx#433 dropping a zero-Jacobian equality at a
# replicate's start) entered the null distribution unchecked. The package now runs the replicate
# loop itself and applies the .mbco_semi() checks: convergence, refit, fail closed.

.par_failed_refit <- function(why = "a constraint is still violated after the refit") {
  list(model = NULL, refit = NULL, failure = why)
}

# Mocks every replicate fit as converged; the replicate statistic is 1 for an untouched h0 and 5
# for a repaired one, so the p-value shows which fit supplied each draw.
.par_boot_mocks <- function(env, refit) {
  testthat::local_mocked_bindings(mxRun = function(model, ...) {
    model@output$status$code <- 0L
    model
  }, mxCompare = function(h1, h0, ...) {
    data.frame(diffLL = c(NA_real_, if (isTRUE(attr(h0, "repaired"))) 5 else 1), df = c(1, 2))
  }, .package = "OpenMx", .env = env)
  testthat::local_mocked_bindings(.mbco_refit_h0 = refit, .env = env)
}

test_that("a replicate whose null fit violates its constraint is refit or errors (real fits)", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("mvtnorm")
  skip_if_not_installed("testthat", "3.2.0")
  f <- .memory_exp_oracle()
  calls <- 0L
  # The observed h0 is feasible (call 1); every replicate null fit then reports a violation that
  # cannot be repaired.
  testthat::local_mocked_bindings(.mbco_refit_h0 = function(h0, h1, ...) {
    calls <<- calls + 1L
    if (calls == 1L) NULL else .par_failed_refit()
  })
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  err <- tryCatch(
    mbco(f$null_b1, f$full, type = "parametric", R = 2L, optim = "SLSQP"),
    error = function(e) e
  )
  expect_s3_class(err, "RMediation_bootstrap_infeasible")
  expect_match(conditionMessage(err), "replicate 1.*violated h0 constraint")
  expect_identical(getOption("mxOptions"), saved)
})

test_that("every parametric replicate is checked once, after the observed h0", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("mvtnorm")
  skip_if_not_installed("testthat", "3.2.0")
  f <- .memory_exp_oracle()
  calls <- 0L
  testthat::local_mocked_bindings(.mbco_refit_h0 = function(h0, h1, ...) {
    calls <<- calls + 1L
    NULL
  })
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  res <- mbco(f$null_b1, f$full, type = "parametric", R = 3L, optim = "SLSQP")
  expect_identical(calls, 1L + 3L)
  expect_gte(res@p_value, 0)
  expect_lte(res@p_value, 1)
})

test_that("an unrepairable parametric replicate error is classed and restores options", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("mvtnorm")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  .par_boot_mocks(environment(), function(h0, h1, ...) .par_failed_refit())
  expect_error(
    mbco_parametric(f$null_b1, f$full, R = 2L, optim = "SLSQP"),
    class = "RMediation_bootstrap_infeasible"
  )
  expect_error(
    mbco_parametric(f$null_b1, f$full, R = 2L, optim = "SLSQP"),
    "replicate 1.*violated h0 constraint"
  )
  expect_identical(getOption("mxOptions"), saved)
})

test_that("a repaired parametric replicate supplies the statistic; a feasible one is untouched", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("mvtnorm")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  set.seed(1)
  .par_boot_mocks(environment(), function(h0, h1, ...) {
    attr(h0, "repaired") <- TRUE
    list(model = h0, refit = list())
  })
  res <- mbco_parametric(f$null_b1, f$full, R = 3L, optim = "SLSQP")
  # The observed statistic is the mocked 1; every replicate used the repaired fit (5).
  expect_equal(res$p, mean(rep(5, 3) > res$chisq))
  expect_equal(res$p, 1)
  .par_boot_mocks(environment(), function(h0, h1, ...) NULL)
  res2 <- mbco_parametric(f$null_b1, f$full, R = 3L, optim = "SLSQP")
  expect_equal(res2$p, mean(rep(1, 3) > res2$chisq))
  expect_equal(res2$p, 0)
  expect_named(res2, c("chisq", "df", "p", "dropped"))
  expect_equal(res2$df, 1)
})

test_that("when every parametric replicate fails to converge the call stops, not a p-value", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("mvtnorm")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  testthat::local_mocked_bindings(mxRun = function(model, ...) {
    model@output$status$code <- 6L
    model
  }, .package = "OpenMx")
  expect_error(
    mbco_parametric(f$null_b1, f$full, R = 2L, optim = "SLSQP"),
    class = "RMediation_bootstrap_too_many_dropped"
  )
  expect_error(
    mbco_parametric(f$null_b1, f$full, R = 2L, optim = "SLSQP"),
    "2 of 2 bootstrap replicates did not converge"
  )
  expect_identical(getOption("mxOptions"), saved)
})

test_that("a non-finite parametric replicate statistic is an error", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("mvtnorm")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  .par_boot_mocks(environment(), function(h0, h1, ...) NULL)
  calls <- 0L
  testthat::local_mocked_bindings(mxCompare = function(h1, h0, ...) {
    calls <<- calls + 1L
    data.frame(diffLL = c(NA_real_, if (calls == 1L) 1 else NA_real_), df = c(1, 2))
  }, .package = "OpenMx")
  expect_error(
    mbco_parametric(f$null_b1, f$full, R = 2L, optim = "SLSQP"),
    "replicate 1.*invalid statistic"
  )
  expect_identical(getOption("mxOptions"), saved)
})

test_that("a replicate where h1 fits worse than h0 is an error, for both bootstrap types", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("mvtnorm")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  .par_boot_mocks(environment(), function(h0, h1, ...) NULL)
  calls <- 0L
  testthat::local_mocked_bindings(mxCompare = function(h1, h0, ...) {
    calls <<- calls + 1L
    data.frame(diffLL = c(NA_real_, if (calls == 1L) 1 else -0.5), df = c(1, 2))
  }, .package = "OpenMx")
  expect_error(
    mbco_parametric(f$null_b1, f$full, R = 2L, optim = "SLSQP"),
    "replicate 1.*invalid statistic.*worse"
  )
  calls <- 0L
  expect_error(
    .mbco_semi(f$null_b1, f$full, R = 2L, optim = "SLSQP"),
    "replicate 1.*invalid statistic.*worse"
  )
  expect_identical(getOption("mxOptions"), saved)
})

test_that("parametric refuses a model without a single raw data set before any sampling", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("mvtnorm")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  # The comparison itself is mocked: the stand-in models only need to reach the data-type check.
  testthat::local_mocked_bindings(mxCompare = function(...) {
    data.frame(diffLL = c(NA_real_, 1), df = c(1, 2))
  }, .package = "OpenMx")
  cov_h0 <- f$null_b1
  cov_h0@data@type <- "cov"
  multi_h1 <- OpenMx::mxModel("container", f$full)
  for (pair in list(list(cov_h0, f$full), list(f$null_b1, multi_h1))) {
    set.seed(11)
    seed <- .Random.seed
    expect_error(
      mbco_parametric(pair[[1]], pair[[2]], R = 2L, optim = "SLSQP"),
      "single raw data set"
    )
    expect_identical(.Random.seed, seed)
  }
  expect_identical(getOption("mxOptions"), saved)
})

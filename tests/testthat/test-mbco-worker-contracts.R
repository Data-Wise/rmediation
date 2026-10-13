test_that("bootstrap workers restore global options after success or error", {
  skip_if_not_installed("OpenMx")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  cmp <- data.frame(
    diffLL = c(NA_real_, .0831), df = c(1, 2),
    p = c(NA_real_, .77)
  )
  local_mocked_bindings(mxCompare = function(...) cmp, .package = "OpenMx")
  mbco_parametric(f$null_b1, f$full, optim = "SLSQP", precision = 1e-6)
  expect_identical(getOption("mxOptions"), saved)
  options(mxOptions = saved)
  local_mocked_bindings(
    mxCompare = function(...) stop("bootstrap failed"),
    .package = "OpenMx"
  )
  expect_error(
    mbco_parametric(f$null_b1, f$full, optim = "SLSQP"),
    "bootstrap failed"
  )
  expect_identical(getOption("mxOptions"), saved)
})

test_that("singular covariance fails before resampling and restores options", {
  skip_if_not_installed("OpenMx")
  data <- data.frame(x = rep(1, 20), y = 1:20)
  h <- OpenMx::mxModel("singular",
    type = "RAM", manifestVars = c("x", "y"),
    OpenMx::mxData(data, type = "raw")
  )
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  local_mocked_bindings(mxCompare = function(...) {
    data.frame(diffLL = c(NA_real_, 1), df = c(1, 2))
  }, .package = "OpenMx")
  set.seed(477)
  seed <- .Random.seed
  expect_error(
    .mbco_semi(h, h, optim = "SLSQP", precision = 1e-6),
    "sample covariance.*positive definite"
  )
  expect_identical(.Random.seed, seed)
  expect_identical(getOption("mxOptions"), saved)
})

test_that("failed semiparametric refits do not become bootstrap p-values", {
  skip_if_not_installed("OpenMx")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  local_mocked_bindings(mxRun = function(model, ...) {
    model@output$status$code <- 6L
    model
  }, .package = "OpenMx")
  expect_error(
    .mbco_semi(f$null_b1, f$full, R = 2L, optim = "SLSQP"),
    "replicate 1.*did not converge"
  )
  expect_identical(getOption("mxOptions"), saved)
})

test_that("bootstrap sampling is seed reproducible and consumes RNG", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("mvtnorm")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  kind <- RNGkind()
  for (type in c("parametric", "semi")) {
    set.seed(482)
    initial <- .Random.seed
    first <- mbco(f$null_b1, f$full, type = type, R = 3L, optim = "SLSQP")
    after <- .Random.seed
    expect_false(identical(initial, after))
    set.seed(482)
    second <- mbco(f$null_b1, f$full, type = type, R = 3L, optim = "SLSQP")
    expect_identical(second@p_value, first@p_value)
    expect_identical(.Random.seed, after)
    expect_identical(RNGkind(), kind)
    expect_identical(getOption("mxOptions"), saved)
  }
})


test_that("parametric invalid results are refused with option cleanup", {
  skip_if_not_installed("OpenMx")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  cases <- list(
    list(diffLL = c(NA, 1), df = c(1, 2), p = c(NA, NA)),
    list(diffLL = c(NA, -1), df = c(1, 2), p = c(NA, .5)),
    list(diffLL = c(NA, 1), df = c(1, 1), p = c(NA, .5)),
    list(diffLL = c(NA, 1), df = c(1, 2), p = c(NA, 1.1)),
    list(diffLL = c(NA, 1), df = c(1, 2))
  )
  for (result in cases) {
    local_mocked_bindings(mxCompare = function(..., boot = FALSE) {
      if (boot) result else list(diffLL = c(NA, 1), df = c(1, 2))
    }, .package = "OpenMx")
    expect_error(
      mbco_parametric(f$null_b1, f$full, optim = "SLSQP"),
      "invalid results"
    )
    expect_identical(getOption("mxOptions"), saved)
  }
})

test_that("invalid null covariance and refit errors restore options", {
  skip_if_not_installed("OpenMx")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  original <- OpenMx::mxGetExpected
  local_mocked_bindings(
    mxGetExpected = function(...) diag(-1, 4),
    .package = "OpenMx"
  )
  expect_error(
    .mbco_semi(f$null_b1, f$full, optim = "SLSQP"),
    "null covariance.*positive definite"
  )
  expect_identical(getOption("mxOptions"), saved)
  local_mocked_bindings(
    mxGetExpected = original,
    mxRun = function(...) stop("refit failed"), .package = "OpenMx"
  )
  expect_error(
    .mbco_semi(f$null_b1, f$full, R = 2L, optim = "SLSQP"),
    "refit failed"
  )
  expect_identical(getOption("mxOptions"), saved)
})

test_that("nonfinite semiparametric replicate statistics are refused", {
  skip_if_not_installed("OpenMx")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  calls <- 0L
  local_mocked_bindings(mxRun = function(model, ...) {
    model@output$status$code <- 0L
    model
  }, mxCompare = function(...) {
    calls <<- calls + 1L
    data.frame(
      diffLL = c(NA_real_, if (calls == 1L) 1 else NA_real_),
      df = c(1, 2)
    )
  }, .package = "OpenMx")
  expect_error(
    .mbco_semi(f$null_b1, f$full, R = 2L, optim = "SLSQP"),
    "replicate 1.*invalid statistic"
  )
  expect_identical(getOption("mxOptions"), saved)
})

test_that("an actual degenerate resample aborts and restores options", {
  skip_if_not_installed("OpenMx")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  local_mocked_bindings(.resample_bootstrap = function(df) {
    df[rep(1L, nrow(df)), , drop = FALSE]
  })
  expect_error(
    .mbco_semi(f$null_b1, f$full, R = 1L, optim = "SLSQP"),
    "Bootstrap replicate 1 did not converge"
  )
  expect_identical(getOption("mxOptions"), saved)
})

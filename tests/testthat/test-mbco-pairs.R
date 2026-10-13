test_that("equal and reversed RAM pairs are refused before bootstrap", {
  skip_if_not_installed("OpenMx")
  f <- .memory_exp_oracle()
  original <- OpenMx::mxCompare
  boot_calls <- 0L
  local_mocked_bindings(mxCompare = function(..., boot = FALSE) {
    if (boot) boot_calls <<- boot_calls + 1L
    suppressWarnings(original(..., boot = boot))
  }, .package = "OpenMx")
  local_mocked_bindings(.resample_bootstrap = function(...) {
    stop("resampling must not run")
  })
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  for (type in c("asymp", "parametric", "semi")) {
    for (h1 in list(f$full, f$null_b1)) {
      set.seed(483)
      seed <- .Random.seed
      expect_error(
        mbco(f$full, h1, type = type, R = 1L, optim = "SLSQP"),
        "h0 must be more restricted than h1"
      )
      expect_identical(.Random.seed, seed)
      expect_identical(getOption("mxOptions"), saved)
    }
  }
  expect_identical(boot_calls, 0L)
})

test_that("malformed observed comparisons cannot reach bootstrap", {
  skip_if_not_installed("OpenMx")
  h <- .memory_exp_ram()
  calls <- 0L
  cases <- list(
    list(df = c(1, NA), diffLL = c(NA, 1)),
    list(df = numeric(), diffLL = c(NA, 1)),
    list(df = c(1, 2), diffLL = c(NA, NA)),
    list(df = c(1, 2), diffLL = c(NA, -1)),
    list(df = c(1, 2), diffLL = numeric())
  )
  for (result in cases) {
    local_mocked_bindings(mxCompare = function(..., boot = FALSE) {
      if (boot) calls <<- calls + 1L
      result
    }, .package = "OpenMx")
    for (type in c("asymp", "parametric", "semi")) {
      expect_error(mbco(h, h, type = type),
        if (length(result$df) != 2L || anyNA(result$df)) {
          "h0 must be more restricted than h1"
        } else {
          "observed MBCO statistic must be finite and nonnegative"
        }
      )
    }
  }
  expect_identical(calls, 0L)
})

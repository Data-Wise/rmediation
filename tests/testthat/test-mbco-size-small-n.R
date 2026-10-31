# Independent oracles for the real (unmocked) mbco(type = "asymp") path and its small-n size.
# test-mbco-routing.R mocks mbco_asymp(), so these tests fit real OpenMx RAM models.

# x -> m -> y with a direct path; `null_b` fixes the m -> y path b at 0 (H0: b = 0).
.size_small_n_ram <- function(d, null_b, name = "size_small_n") {
  man <- c("x", "m", "y")
  OpenMx::mxModel(
    name,
    type = "RAM", manifestVars = man,
    OpenMx::mxPath("x", "m", free = TRUE, values = .2, labels = "a"),
    OpenMx::mxPath("m", "y", free = !null_b, values = if (null_b) 0 else .2, labels = "b"),
    OpenMx::mxPath("x", "y", free = TRUE, values = .2, labels = "cp"),
    OpenMx::mxPath(man, arrows = 2, free = TRUE, values = 1),
    OpenMx::mxPath("one", man, free = TRUE, values = 0),
    OpenMx::mxData(d, type = "raw")
  )
}

.size_small_n_fit <- function(model) {
  suppressMessages(OpenMx::mxRun(model, silent = TRUE))
}

# Data from x -> m (a = .4), x -> y (cp = .3), m -> y (b), unit residual variances.
.size_small_n_data <- function(n, b) {
  x <- stats::rnorm(n)
  m <- .4 * x + stats::rnorm(n)
  y <- .3 * x + b * m + stats::rnorm(n)
  data.frame(x = x, m = m, y = y)
}

test_that("mbco(type = 'asymp') statistic equals the -2LL difference of two real OpenMx fits", {
  skip_on_cran()
  skip_if_not_installed("OpenMx")
  set.seed(20261031)
  d <- .size_small_n_data(n = 100, b = .4)
  h1 <- .size_small_n_fit(.size_small_n_ram(d, null_b = FALSE, "full"))
  h0 <- .size_small_n_fit(.size_small_n_ram(d, null_b = TRUE, "null_b"))

  # Oracle: the optimizer's own -2LL values, never touching mbco() or mxCompare().
  oracle_stat <- h0$output$Minus2LogLikelihood - h1$output$Minus2LogLikelihood
  oracle_p <- stats::pchisq(oracle_stat, df = 1, lower.tail = FALSE)
  expect_gt(oracle_stat, 5) # a real effect, so the statistic is far from 0

  res <- mbco(h0, h1, type = "asymp")
  expect_lt(abs(res@statistic - oracle_stat), 1e-8)
  expect_equal(res@df, 1)
  expect_lt(abs(res@p_value - oracle_p), 1e-8)

  # Cross-check against mxCompare's own diffLL.
  cmp <- OpenMx::mxCompare(h1, h0)
  expect_lt(abs(res@statistic - cmp$diffLL[2]), 1e-8)
})

test_that("asymptotic MBCO size at n = 25 stays inside a documented liberal band", {
  skip_on_cran()
  skip_if_not_installed("OpenMx")
  set.seed(20261031)
  n <- 25
  n_rep <- 400
  alpha <- .05
  # H0 (b = 0) is true in every replicate. This is a seed-pinned regression guard against gross
  # failures (a wrong df, a scaled statistic is NOT caught here: p comes from mxCompare), not a
  # claim that the test is exactly nominal. Asymptotic LRTs are commonly liberal at small n; the
  # measured rate with this seed is 30 / 400 = .075 (nominal .05). The band below is the 99.9%
  # binomial interval around that measured rate, so it pins the current behavior.
  errors <- character()
  p_value <- vapply(seq_len(n_rep), function(i) {
    d <- .size_small_n_data(n, b = 0)
    h1 <- .size_small_n_fit(.size_small_n_ram(d, null_b = FALSE, "full"))
    h0 <- .size_small_n_fit(.size_small_n_ram(d, null_b = TRUE, "null_b"))
    tryCatch(mbco(h0, h1, type = "asymp")@p_value, error = function(e) {
      errors <<- c(errors, conditionMessage(e))
      NA_real_
    })
  }, numeric(1))
  expect_identical(errors, character()) # every replicate fits and compares
  rate <- mean(p_value < alpha)

  expected <- .075
  half_width <- stats::qnorm(1 - .0005) * sqrt(expected * (1 - expected) / n_rep)
  expect_gte(rate, expected - half_width) # a p-value that (almost) never rejects is broken
  expect_lte(rate, expected + half_width) # upper edge is about .118, well under a gross .15+
})

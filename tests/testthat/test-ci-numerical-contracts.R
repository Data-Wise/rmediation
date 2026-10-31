test_that("correlated delta intervals match hand gradients", {
  means <- list(c(a = .3, b = -.4), c(a = .3, d = .5, b = -.4))
  covariances <- list(
    matrix(c(.01, .003, .003, .02), 2),
    matrix(c(.01, .002, -.001, .002, .02, .003, -.001, .003, .03), 3)
  )
  gradients <- list(c(-.4, .3), c(.5 * -.4, .3 * -.4, .3 * .5))
  formulas <- list(~ a * b, ~ a * d * b)
  for (i in seq_along(means)) {
    variance_terms <- outer(gradients[[i]], gradients[[i]]) * covariances[[i]]
    expected_se <- sqrt(sum(variance_terms))
    result <- ci(means[[i]], covariances[[i]], quant = formulas[[i]],
      type = "asymp", alpha = .1
    )
    expect_equal(as.numeric(result$SE), expected_se, tolerance = 1e-12)
    expect_equal(result$Estimate, prod(means[[i]]))
    expect_equal(as.numeric(result[[1]]),
      prod(means[[i]]) + c(-1, 1) * qnorm(.95) * expected_se
    )
  }
})

test_that("zero gradients do not erase small nonzero gradients", {
  zero <- ci(c(a = 0, b = 0), diag(.01, 2), quant = ~ a * b,
    type = "asymp"
  )
  expect_identical(as.numeric(zero$SE), 0)
  expect_equal(as.numeric(zero[[1]]), c(0, 0))
  tiny <- ci(c(a = 1e-12, b = 2e-12), diag(.01, 2), quant = ~ a * b,
    type = "asymp"
  )
  expected <- sqrt(.01 * ((2e-12)^2 + (1e-12)^2))
  expect_equal(as.numeric(tiny$SE) / expected, 1, tolerance = 1e-12)
})

test_that("rank-deficient PSD supports linear delta and Monte Carlo", {
  covariance <- outer(c(.1, .2), c(.1, .2))
  mu <- c(a = .3, b = -.2)
  delta <- ci(mu, covariance, quant = ~ a + 2 * b, type = "asymp")
  expect_equal(as.numeric(delta$SE), .5)
  set.seed(590)
  mc <- ci(mu, covariance, quant = ~ a + 2 * b, type = "MC", n.mc = 20000)
  # Six standard errors of the sample mean under the exact linear normal law.
  expect_lt(abs(mc$Estimate - (-.1)), 6 * .5 / sqrt(20000))
  expect_lt(abs(mc$SE - .5), 6 * .5 / sqrt(2 * (20000 - 1)))
})

test_that("Monte Carlo error is the sampling SE of the simulated mean", {
  mu <- c(a = .3, b = -.4)
  covariance <- matrix(c(.01, .003, .003, .02), 2)
  n <- 20000
  set.seed(591)
  result <- ci(mu, covariance, quant = ~ a * b, type = "MC", n.mc = n)
  expected_mean <- .3 * -.4 + .003
  expected_variance <- (-.4)^2 * .01 + .3^2 * .02 +
    2 * .3 * -.4 * .003 + .01 * .02 + .003^2
  expect_lt(abs(result$Estimate - expected_mean),
    6 * sqrt(expected_variance / n)
  )
  expect_equal(result$MCError / (result$SE / sqrt(n)), 1)
})

test_that("all preserves the Monte Carlo null arguments and results", {
  mu <- c(a = .3, b = .4)
  covariance <- diag(.01, 2)
  null_mu <- c(a = -.2, b = .2)
  null_covariance <- diag(.02, 2)
  for (sigma0 in list(null_covariance, c(.02, 0, .02))) {
    set.seed(592)
    expected <- ci(mu, covariance, quant = ~ a + b, type = "MC",
      H0 = TRUE, mu0 = null_mu, Sigma0 = sigma0, n.mc = 2000
    )
    set.seed(592)
    combined <- ci(mu, covariance, quant = ~ a + b, type = "all",
      H0 = TRUE, mu0 = null_mu, Sigma0 = sigma0, n.mc = 2000
    )
    expect_identical(combined$MC, expected)
    expect_equal(combined$Asymptotic$Estimate, .7)
  }
})

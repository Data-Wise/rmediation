# Known-answer tests for the legacy internals confintAsymp() and confintMC().
# Oracles: hand gradients, central finite differences written here, qnorm(), and the empirical
# quantiles of an independent MASS::mvrnorm sample. None of them calls the code under test.

kat_central_gradient <- function(f, x, h = 1e-5) {
  vapply(seq_along(x), function(i) {
    up <- dn <- x
    up[i] <- x[i] + h
    dn[i] <- x[i] - h
    (f(up) - f(dn)) / (2 * h)
  }, numeric(1))
}

kat_delta_oracle <- function(f, mu, Sigma, alpha) {
  g <- kat_central_gradient(f, mu)
  se <- sqrt(sum(outer(g, g) * Sigma))
  est <- f(mu)
  list(est = est, se = se, ci = est + c(-1, 1) * qnorm(1 - alpha / 2) * se)
}

test_that("confintAsymp matches the hand-gradient delta method for a*b", {
  mu <- c(b1 = .3, b2 = -.4)
  Sigma <- matrix(c(.01, .003, .003, .02), 2)
  grad <- c(-.4, .3)
  expected_se <- sqrt(sum(outer(grad, grad) * Sigma))
  res <- RMediation:::confintAsymp(mu, Sigma, quant = ~ b1 * b2, alpha = .1)
  expect_equal(res$Estimate, -.12)
  expect_equal(as.numeric(res$SE), expected_se, tolerance = 1e-12)
  expect_equal(as.numeric(res[[1]]), -.12 + c(-1, 1) * qnorm(.95) * expected_se)
  expect_identical(names(res)[-1], c("Estimate", "SE"))
})

test_that("confintAsymp collapses to the estimate when Sigma is zero", {
  res <- RMediation:::confintAsymp(c(b1 = .3, b2 = -.4), matrix(0, 2, 2), quant = ~ b1 * b2)
  expect_equal(as.numeric(res$SE), 0)
  expect_equal(as.numeric(res[[1]]), c(-.12, -.12))
})

test_that("confintAsymp matches finite-difference delta intervals for a*b/c", {
  mu <- c(a = .5, b = .8, c = 2)
  Sigma <- matrix(c(.010, .002, -.001, .002, .020, .003, -.001, .003, .040), 3)
  f <- function(p) p[1] * p[2] / p[3]
  for (alpha in c(.05, .2)) {
    oracle <- kat_delta_oracle(f, mu, Sigma, alpha)
    res <- RMediation:::confintAsymp(mu, Sigma, quant = ~ a * b / c, alpha = alpha)
    info <- paste("alpha =", alpha)
    expect_equal(res$Estimate, unname(oracle$est), info = info)
    expect_equal(as.numeric(res$SE), oracle$se, tolerance = 1e-7, info = info)
    expect_equal(as.numeric(res[[1]]), oracle$ci, tolerance = 1e-7, info = info)
  }
})

test_that("confintMC is exact for a linear function (qnorm oracle)", {
  skip_on_cran()
  set.seed(5101)
  n <- 2e5
  mu <- c(a = .3, b = -.2)
  Sigma <- matrix(c(.04, .01, .01, .09), 2)
  w <- c(1, 2)
  m <- sum(w * mu)
  s <- sqrt(sum(outer(w, w) * Sigma))
  res <- RMediation:::confintMC(mu, Sigma, quant = ~ a + 2 * b, n.mc = n)
  q_se <- function(p) sqrt(p * (1 - p) / n) / dnorm(qnorm(p)) * s
  expect_lt(abs(res$Estimate - m), 6 * s / sqrt(n))
  expect_lt(abs(res$SE - s), 6 * s / sqrt(2 * (n - 1)))
  expect_equal(res$MCError, res$SE / sqrt(n))
  # Two-sided p = 2 * P(Z > |m| / s); its SE is bounded by sqrt(.25 / n) * 2 * 1.
  expect_lt(abs(res$p - 2 * pnorm(-abs(m) / s)), 6 * 2 * sqrt(.25 / n))
  expect_lt(abs(res[[1]][[1]] - (m + qnorm(.025) * s)), 6 * q_se(.025))
  expect_lt(abs(res[[1]][[2]] - (m + qnorm(.975) * s)), 6 * q_se(.975))
})

test_that("confintMC interval matches empirical quantiles of an independent sample", {
  skip_on_cran()
  mu <- c(a = .3, b = -.4)
  Sigma <- matrix(c(.01, .003, .003, .02), 2)
  alpha <- .1
  n <- 1e5
  n_ref <- 2e5
  set.seed(5102)
  res <- RMediation:::confintMC(mu, Sigma, quant = ~ a * b, alpha = alpha, n.mc = n)
  set.seed(5103)
  draws <- MASS::mvrnorm(n_ref, mu, Sigma)
  ref <- draws[, 1] * draws[, 2]
  p <- c(alpha / 2, 1 - alpha / 2)
  expected <- unname(quantile(ref, p))
  # Quantile SE = sqrt(p(1-p)/n) / density; the density is a symmetric difference quotient of
  # reference quantiles. The two samples are independent, so their variances add.
  h <- .01
  dens <- vapply(p, function(pp) {
    2 * h / diff(unname(quantile(ref, c(pp - h, pp + h))))
  }, numeric(1))
  tol <- 6 * sqrt(p * (1 - p) / n + p * (1 - p) / n_ref) / dens
  expect_lt(abs(res[[1]][[1]] - expected[1]), tol[1])
  expect_lt(abs(res[[1]][[2]] - expected[2]), tol[2])
  expect_identical(names(res[[1]]), c("5 %", "95 %"))
  expect_lt(abs(res$Estimate - mean(ref)), 6 * sd(ref) * sqrt(1 / n + 1 / n_ref))
})

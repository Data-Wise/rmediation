# Two or more zero-variance components (issue #64). Exact oracles: the product of the means is
# a point mass, or a scaled normal when exactly one component is random.

m <- c(0.5, 0.4, 0.3) # prod = 0.06

test_that("an all-zero covariance is a point mass at prod(mean)", {
  S <- matrix(0, 3, 3)
  expect_equal(pprodnormal3(c(0.05), m, S), 0)
  expect_equal(pprodnormal3(0.06, m, S), 1) # right-continuous at the atom
  expect_equal(pprodnormal3(0.07, m, S), 1)
  expect_equal(pprodnormal3(1, m, S), 1)
  expect_equal(pprodnormal3(-1, m, S), 0)
})

test_that("a negative point mass steps at its (negative) value", {
  S <- matrix(0, 3, 3)
  mm <- c(-0.5, 0.4, 0.3)
  expect_equal(pprodnormal3(-0.07, mm, S), 0)
  expect_equal(pprodnormal3(-0.06, mm, S), 1)
})

test_that("two zero variances give a scaled normal: cX with c = product of the fixed means", {
  for (k in 1:3) {
    S <- matrix(0, 3, 3)
    S[k, k] <- 0.04
    cc <- prod(m[-k])
    for (q in c(-0.2, 0.0, 0.05, 0.1, 0.3)) {
      expect_equal(
        pprodnormal3(q, m, S),
        stats::pnorm(q / cc, m[k], 0.2),
        tolerance = 1e-12,
        info = paste("random component", k, "q", q)
      )
    }
  }
})

test_that("a negative fixed product flips the tail", {
  S <- diag(c(0, 0, 0.01))
  mm <- c(-0.5, 0.4, 0.3) # c = -0.2
  q <- -0.04
  expect_equal(pprodnormal3(q, mm, S), 1 - stats::pnorm(q / -0.2, 0.3, 0.1), tolerance = 1e-12)
})

test_that("a zero fixed product with one random component is a point mass at 0", {
  S <- diag(c(0, 0, 0.01))
  mm <- c(0, 0.4, 0.3)
  expect_equal(pprodnormal3(-0.01, mm, S), 0)
  expect_equal(pprodnormal3(0.01, mm, S), 1)
  expect_equal(pprodnormal3(0, mm, S), 1) # right-continuous: P(XYZ <= 0) = 1 for a point mass at 0
})

test_that("an all-zero covariance with a zero mean is right-continuous at zero", {
  expect_equal(pprodnormal3(0, c(0, 0.4, 0.3), matrix(0, 3, 3)), 1)
  expect_equal(pprodnormal3(0.01, c(0, 0.4, 0.3), matrix(0, 3, 3)), 1)
})

test_that("cdf() and dist_quantile() on a point-mass ProductNormal3 are consistent", {
  pn <- ProductNormal3(mu = m, Sigma = matrix(0, 3, 3))
  expect_equal(cdf(pn, c(0.05, 0.07)), c(0, 1))
})

test_that("two zero variances agree with a Monte Carlo draw", {
  set.seed(20261014)
  S <- diag(c(0, 0, 0.04))
  x <- m[1] * m[2] * stats::rnorm(2e6, m[3], 0.2)
  est <- mean(x <= 0.05)
  expect_lt(abs(pprodnormal3(0.05, m, S) - est), 5 * sqrt(est * (1 - est) / 2e6))
})

test_that("one fixed zero component with two random ones is a right-continuous point mass at 0", {
  # whichever component is the fixed zero, the product is identically 0
  for (k in 1:3) {
    S <- diag(c(0.2, 0.3, 0.1))
    S[k, k] <- 0
    mm <- c(0.4, 0.5, 0.6)
    mm[k] <- 0
    expect_equal(pprodnormal3(-0.01, mm, S), 0)
    expect_equal(pprodnormal3(0, mm, S), 1)
    expect_equal(pprodnormal3(0.01, mm, S), 1)
  }
})

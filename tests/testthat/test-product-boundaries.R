# Numerical boundaries and symmetry identities of the product-of-normals CDF/quantile
# (Task 4). Identities are exact; the quadrature oracle is independent of the package code.

# P(XY <= q) for independent X ~ N(mx, sx^2), Y ~ N(my, sy^2), by direct integration over x.
.oracle_pprod <- function(q, mx, my, sx, sy) {
  g <- function(x) {
    cond <- ifelse(
      x > 0, stats::pnorm((q / x - my) / sy),
      ifelse(x < 0, 1 - stats::pnorm((q / x - my) / sy), as.numeric(q >= 0))
    )
    stats::dnorm(x, mx, sx) * cond
  }
  stats::integrate(g, mx - 10 * sx, mx + 10 * sx, subdivisions = 2000L, rel.tol = 1e-10)$value
}

P <- function(q, mx, my, sx, sy, rho = 0, ...) pprodnormal(q, mx, my, sx, sy, rho, ...)

test_that("pprodnormal matches an independent quadrature oracle (rho = 0)", {
  grid <- list(
    c(0.7, 0.5, 0.3, 0.2, 0.4),
    c(-0.05, 0.5, 0.3, 0.2, 0.4),
    c(0.0, 0.2, -0.1, 0.3, 0.3),
    c(1.5, 1, 2, 0.5, 0.25)
  )
  for (a in grid) {
    expect_equal(do.call(P, as.list(a)), do.call(.oracle_pprod, as.list(a)), tolerance = 1e-6)
  }
})

test_that("CDF is exactly 1/2 at q = 0 for zero means and rho = 0", {
  expect_equal(P(0, 0, 0, 1, 1), 0.5)
  expect_equal(P(0, 0, 0, 0.3, 2), 0.5, tolerance = 1e-8)
})

test_that("sign identity: P(XY <= q) = 1 - P(XY <= -q) with mu.x negated and rho negated", {
  for (rho in c(0, 0.6, -0.6)) {
    expect_equal(
      P(0.7, 0.5, 0.3, 0.2, 0.4, rho),
      1 - P(-0.7, -0.5, 0.3, 0.2, 0.4, -rho),
      tolerance = 1e-8
    )
  }
})

test_that("permutation identity: swapping x and y leaves the CDF unchanged", {
  for (rho in c(0, 0.9, -0.5)) {
    expect_equal(
      P(0.7, 0.5, 0.3, 0.2, 0.4, rho),
      P(0.7, 0.3, 0.5, 0.4, 0.2, rho),
      tolerance = 1e-8
    )
  }
})

test_that("scaling identity: scaling X by c scales q, mu.x and se.x together", {
  expect_equal(P(0.7 * 3, 0.5 * 3, 0.3, 0.2 * 3, 0.4), P(0.7, 0.5, 0.3, 0.2, 0.4), tolerance = 1e-8)
  expect_equal(P(0.7 * 3, 0.5 * 3, 0.3, 0.2 * 3, 0.4, 0.7), P(0.7, 0.5, 0.3, 0.2, 0.4, 0.7), tolerance = 1e-8)
})

test_that("lower.tail = FALSE is the exact complement, also at extreme q", {
  for (q in c(-5, 0.1, 5)) {
    expect_equal(
      P(q, 0.5, 0.3, 0.2, 0.4, lower.tail = FALSE),
      1 - P(q, 0.5, 0.3, 0.2, 0.4),
      tolerance = 1e-8
    )
  }
})

test_that("CDF stays in [0, 1] and is monotone far in both tails", {
  q <- c(-1e3, -50, -5, 0, 5, 50, 1e3)
  p <- vapply(q, function(x) P(x, 0.5, 0.3, 0.2, 0.4), numeric(1))
  expect_true(all(p >= 0 & p <= 1))
  expect_true(all(diff(p) >= -1e-12))
  expect_lt(p[1], 1e-6)
  expect_gt(p[length(p)], 1 - 1e-6)
})

test_that("large standardized means up to 18 agree with Monte Carlo", {
  set.seed(20261014)
  for (m in c(10, 18)) {
    x <- stats::rnorm(2e6, m, 1) * stats::rnorm(2e6, m, 1)
    est <- mean(x <= m^2)
    expect_lt(abs(P(m^2, m, m, 1, 1) - est), 5 * sqrt(est * (1 - est) / 2e6))
  }
})

test_that("DOP stays correct at large standardized means (issue #60)", {
  # truth ~ 0.5074 by Monte Carlo (4e6 draws); the old integral returned 7.9e-7
  expect_equal(P(400, 20, 20, 1, 1), 0.5074, tolerance = 5e-3)
  expect_equal(P(2500, 50, 50, 1, 1), 0.5, tolerance = 2e-2)
  expect_gt(P(400, 20, 20, 1, 1), 0.4)
})

test_that("DOP far-tail probabilities match the independent oracle (issue #60)", {
  # the old code returned 5.8e-6 and 6.0e-6 for these two; the oracle gives 8.87e-6 and 4.35e-6
  expect_equal(P(-3, 2, 0.3, 0.2, 0.4), .oracle_pprod(-3, 2, 0.3, 0.2, 0.4), tolerance = 1e-4)
  expect_equal(P(-3, 0, 3, 0.2, 0.4), .oracle_pprod(-3, 0, 3, 0.2, 0.4), tolerance = 1e-4)
})

test_that("DOP far tail with rho = -0.8 matches Monte Carlo (issue #60)", {
  set.seed(20261014)
  n <- 2e7
  S <- matrix(c(0.2^2, -0.8 * 0.2 * 0.4, -0.8 * 0.2 * 0.4, 0.4^2), 2)
  d <- MASS::mvrnorm(n, c(0, 3), S)
  est <- mean(d[, 1] * d[, 2] <= -3)
  # old value 6e-9; truth ~1.8e-4
  expect_lt(abs(P(-3, 0, 3, 0.2, 0.4, -0.8) - est), 5 * sqrt(est * (1 - est) / n))
})

test_that("qprodnormal inverts pprodnormal at large standardized means (issue #60)", {
  q <- qprodnormal(0.3, 20, 20, 1, 1)
  expect_equal(P(q, 20, 20, 1, 1), 0.3, tolerance = 1e-4)
})

test_that("the upper tail is never negative and the CDF never exceeds 1", {
  expect_gte(P(5, 0.5, 0.3, 0.2, 0.4, lower.tail = FALSE), 0)
  expect_lte(P(5, 0.5, 0.3, 0.2, 0.4), 1)
  expect_lte(P(50, 0.5, 0.3, 0.2, 0.4), 1)
})

test_that("near-perfect correlation of either sign stays a valid probability and orders correctly", {
  hi <- P(0.1, 0.5, 0.3, 0.2, 0.4, 0.999)
  lo <- P(0.1, 0.5, 0.3, 0.2, 0.4, -0.999)
  expect_true(hi > 0 && hi < 1)
  expect_true(lo > 0 && lo < 1)
  expect_equal(hi, P(0.1, 0.5, 0.3, 0.2, 0.4, 0.99), tolerance = 0.02)
})

test_that("near-perfect correlation agrees with Monte Carlo within its uncertainty", {
  skip_if_not_installed("MASS")
  set.seed(20261014)
  n <- 4e5
  S <- matrix(c(0.2^2, 0.999 * 0.2 * 0.4, 0.999 * 0.2 * 0.4, 0.4^2), 2)
  d <- MASS::mvrnorm(n, c(0.5, 0.3), S)
  est <- mean(d[, 1] * d[, 2] <= 0.1)
  se <- sqrt(est * (1 - est) / n)
  expect_lt(abs(P(0.1, 0.5, 0.3, 0.2, 0.4, 0.999) - est), 5 * se)
})

test_that("rho = 1 is accepted and close to rho = 0.999; a zero standard error is handled exactly", {
  expect_equal(P(0.1, 0.5, 0.3, 0.2, 0.4, 1), P(0.1, 0.5, 0.3, 0.2, 0.4, 0.999), tolerance = 1e-3)
  # se = 0 is outside the DOP integral's domain; the CDF is the exact scaled normal instead
  expect_equal(P(0.1, 0.5, 0.3, 0, 0.4, 0), pnorm((0.1 / 0.5 - 0.3) / 0.4))
})

test_that("qprodnormal inverts pprodnormal at both extreme probabilities", {
  for (p in c(1e-6, 1e-3, 0.5, 1 - 1e-3, 1 - 1e-6)) {
    q <- qprodnormal(p, 0.5, 0.3, 0.2, 0.4)
    expect_equal(P(q, 0.5, 0.3, 0.2, 0.4), p, tolerance = 1e-4)
  }
})

test_that("qprodnormal obeys sign and permutation identities", {
  expect_equal(
    qprodnormal(0.3, 0.5, 0.3, 0.2, 0.4),
    qprodnormal(0.3, 0.3, 0.5, 0.4, 0.2),
    tolerance = 1e-6
  )
  expect_equal(
    qprodnormal(0.3, 0.5, 0.3, 0.2, 0.4),
    -qprodnormal(0.7, -0.5, 0.3, 0.2, 0.4),
    tolerance = 1e-6
  )
})

# --- three-way product ---------------------------------------------------------------------

.cov3 <- matrix(c(0.04, 0.002, 0.001, 0.002, 0.09, 0.003, 0.001, 0.003, 0.16), 3)
.m3 <- c(0.5, 0.4, 0.3)

test_that("pprodnormal3 obeys sign, permutation and scaling identities", {
  base <- pprodnormal3(0.05, .m3, .cov3)
  # negate component 1: product flips sign, covariance entries involving 1 flip sign
  D <- diag(c(-1, 1, 1))
  expect_equal(1 - pprodnormal3(-0.05, D %*% .m3, D %*% .cov3 %*% D), base, tolerance = 1e-6)
  # permute components
  pm <- c(3, 1, 2)
  expect_equal(pprodnormal3(0.05, .m3[pm], .cov3[pm, pm]), base, tolerance = 1e-6)
  # scale component 2 by 2
  Sc <- diag(c(1, 2, 1))
  expect_equal(pprodnormal3(0.1, Sc %*% .m3, Sc %*% .cov3 %*% Sc), base, tolerance = 1e-6)
})

test_that("pprodnormal3 is monotone and bounded across a wide q grid", {
  q <- c(-10, -1, -0.1, 0, 0.05, 0.1, 1, 10)
  p <- vapply(q, function(x) pprodnormal3(x, .m3, .cov3), numeric(1))
  expect_true(all(p >= 0 & p <= 1))
  expect_true(all(diff(p) >= -1e-9))
  expect_lt(p[1], 1e-4)
  expect_gt(p[length(p)], 1 - 1e-4)
})

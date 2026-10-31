# Truncation bias in pprodnormal3(): pins values against an independent oracle.
#
# .prod3_bound() derives the truncation box from a tail-mass argument. A box that
# is too small gives a *bias* that the integrator's self-consistency check cannot
# see, so only an accuracy test against an outside reference can catch it. The
# oracle below never calls pprodnormal3(): it conditions on X, then on Y | X, and
# integrates the exact normal conditional probability of Z with stats::integrate()
# over +/- 12 sd (wider than the package box), splitting at the kink x * y = 0.

.p3bd_oracle <- function(q, mean, cov) {
  szxy <- cov[3, 1:2]
  beta <- solve(cov[1:2, 1:2], szxy)
  csd <- sqrt(cov[3, 3] - sum(szxy * beta))
  by <- cov[1, 2] / cov[1, 1]
  ysd <- sqrt(cov[2, 2] - cov[1, 2]^2 / cov[1, 1])
  pz <- function(x, y) {
    mz <- mean[3] + beta[1] * (x - mean[1]) + beta[2] * (y - mean[2])
    p <- x * y
    out <- numeric(length(x))
    pos <- p > 0
    neg <- p < 0
    out[pos] <- stats::pnorm(q / p[pos], mz[pos], csd)
    out[neg] <- 1 - stats::pnorm(q / p[neg], mz[neg], csd)
    out[!pos & !neg] <- as.numeric(q >= 0)
    out
  }
  split_int <- function(f, lo, hi) {
    cuts <- sort(unique(c(lo, min(max(0, lo), hi), hi)))
    sum(vapply(seq_len(length(cuts) - 1), function(k) {
      stats::integrate(f, cuts[k], cuts[k + 1],
        rel.tol = 1e-8, abs.tol = 1e-18, subdivisions = 500L
      )$value
    }, numeric(1)))
  }
  inner <- function(x) {
    vapply(x, function(xi) {
      my <- mean[2] + by * (xi - mean[1])
      f <- function(y) stats::dnorm(y, my, ysd) * pz(rep(xi, length(y)), y)
      split_int(f, my - 12 * ysd, my + 12 * ysd)
    }, numeric(1))
  }
  sx <- sqrt(cov[1, 1])
  split_int(function(x) stats::dnorm(x, mean[1], sx) * inner(x), mean[1] - 12 * sx, mean[1] + 12 * sx)
}

.p3bd_cov <- function(rho) {
  cov <- diag(3)
  cov[1, 2] <- cov[2, 1] <- rho
  cov
}

test_that("pprodnormal3 matches nested quadrature where a shrunken bound biases it", {
  # A bound of 4 biases these points by 5e-6 to 4e-5; a bound of 0.6 (10x smaller)
  # by 1e-4 to 0.3. The correct code agrees to about 2e-9 (default tol = 1e-6, so
  # the bound is 6); 1e-7 is an empirical margin between the two.
  cases <- list(
    # lower tail, probability 1.2e-4, large standardized means
    list(q = -10, mean = c(3, 3, 3), rho = 0),
    # ill-conditioned covariance
    list(q = 0, mean = c(1.5, 1.5, 1.5), rho = 0.99),
    # standardized means of 5 to 6 with rho = 0.99
    list(q = -150, mean = c(6, 6, -5), rho = 0.99)
  )
  for (case in cases) {
    cov <- .p3bd_cov(case$rho)
    expected <- .p3bd_oracle(case$q, case$mean, cov)
    expect_gt(expected, 1e-5)
    expect_lt(abs(pprodnormal3(case$q, case$mean, cov) - expected), 1e-7)
  }
})

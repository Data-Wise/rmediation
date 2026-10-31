# Closed-form / quadrature oracles for pMC() and qMC() (independent of package code).
# Tolerances come from the Monte Carlo standard error at n.mc:
#   CDF value  p-hat:   se = sqrt(p (1 - p) / n.mc),          tolerance = 4 * se
#   quantile  q-hat:   se = sqrt(p (1 - p) / n.mc) / f(q),    tolerance = 4 * se (f = true density at q)

n_mc <- 2e5

# P(XY <= q) for independent normals, by integration over x (local copy of the idea in
# test-product-boundaries.R).
.pmc_oracle_pprod <- function(q, mx, my, sx, sy) {
  g <- function(x) {
    cond <- ifelse(
      x > 0, stats::pnorm((q / x - my) / sy),
      ifelse(x < 0, 1 - stats::pnorm((q / x - my) / sy), as.numeric(q >= 0))
    )
    stats::dnorm(x, mx, sx) * cond
  }
  stats::integrate(g, mx - 10 * sx, mx + 10 * sx, subdivisions = 2000L, rel.tol = 1e-10)$value
}

# Absolute-tolerance comparison (testthat 3e `tolerance` is relative).
expect_pmc_close <- function(actual, expected, tol) {
  testthat::expect_lt(
    abs(actual - expected), tol,
    label = sprintf("|actual - expected| (actual = %.5f, expected = %.5f)", actual, expected)
  )
}

.pmc_mc_tol <- function(p, n, dens = 1) 4 * sqrt(p * (1 - p) / n) / dens

test_that("pMC and qMC for ~ b1 match the marginal normal", {
  set.seed(2026)
  mu <- c(b1 = 0.8, b2 = -0.3)
  Sigma <- matrix(c(0.25, 0.05, 0.05, 0.16), 2)
  m <- mu[[1]]
  s <- sqrt(Sigma[1, 1])

  for (q in c(0.2, 0.8, 1.4)) {
    p0 <- stats::pnorm(q, m, s)
    expect_pmc_close(pMC(q, mu, Sigma, ~b1, n.mc = n_mc), p0, tol = .pmc_mc_tol(p0, n_mc))
    expect_pmc_close(
      pMC(q, mu, Sigma, ~b1, lower.tail = FALSE, n.mc = n_mc), 1 - p0,
      tol = .pmc_mc_tol(p0, n_mc)
    )
  }
  for (p in c(0.05, 0.5, 0.95)) {
    q0 <- stats::qnorm(p, m, s)
    tol <- .pmc_mc_tol(p, n_mc, stats::dnorm(q0, m, s))
    expect_pmc_close(unname(qMC(p, mu, Sigma, ~b1, n.mc = n_mc)), q0, tol = tol)
  }
})

test_that("pMC and qMC for ~ b1 + b2 use the correlated-sum variance", {
  set.seed(2027)
  mu <- c(b1 = 0.5, b2 = 0.4)
  Sigma <- matrix(c(0.25, 0.06, 0.06, 0.16), 2) # rho = 0.3, so the covariance term is not negligible
  m <- sum(mu)
  v <- Sigma[1, 1] + Sigma[2, 2] + 2 * Sigma[1, 2]
  s <- sqrt(v)

  for (q in c(0.4, 0.9, 1.5)) {
    p0 <- stats::pnorm(q, m, s)
    expect_pmc_close(pMC(q, mu, Sigma, ~ b1 + b2, n.mc = n_mc), p0, tol = .pmc_mc_tol(p0, n_mc))
  }
  for (p in c(0.025, 0.5, 0.975)) {
    q0 <- stats::qnorm(p, m, s)
    tol <- .pmc_mc_tol(p, n_mc, stats::dnorm(q0, m, s))
    expect_pmc_close(unname(qMC(p, mu, Sigma, ~ b1 + b2, n.mc = n_mc)), q0, tol = tol)
  }
  # Stacked lower-triangle Sigma gives the same target.
  q <- 0.9
  p0 <- stats::pnorm(q, m, s)
  expect_pmc_close(
    pMC(q, mu, c(0.25, 0.06, 0.16), ~ b1 + b2, n.mc = n_mc), p0,
    tol = .pmc_mc_tol(p0, n_mc)
  )
})

test_that("pMC and qMC for ~ b1 * b2 (independent) match the quadrature CDF", {
  set.seed(2028)
  mx <- 0.5
  my <- 0.4
  sx <- 0.3
  sy <- 0.2
  mu <- c(b1 = mx, b2 = my)
  Sigma <- diag(c(sx^2, sy^2))

  for (q in c(0.05, 0.2, 0.35)) {
    p0 <- .pmc_oracle_pprod(q, mx, my, sx, sy)
    expect_pmc_close(pMC(q, mu, Sigma, ~ b1 * b2, n.mc = n_mc), p0, tol = .pmc_mc_tol(p0, n_mc))
  }
  for (p in c(0.05, 0.5, 0.95)) {
    q0 <- stats::uniroot(function(z) .pmc_oracle_pprod(z, mx, my, sx, sy) - p, c(-1, 2), tol = 1e-10)$root
    h <- 1e-4 # numerical density of the oracle CDF
    f0 <- (.pmc_oracle_pprod(q0 + h, mx, my, sx, sy) - .pmc_oracle_pprod(q0 - h, mx, my, sx, sy)) / (2 * h)
    expect_pmc_close(
      unname(qMC(p, mu, Sigma, ~ b1 * b2, n.mc = n_mc)), q0,
      tol = .pmc_mc_tol(p, n_mc, f0)
    )
  }
})

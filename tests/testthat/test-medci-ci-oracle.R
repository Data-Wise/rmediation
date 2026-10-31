# Independent-oracle pins for the 95% interval endpoints of medci() and ci(<ProductNormal>).
# Oracle: invert a local quadrature CDF with uniroot at alpha/2 and 1 - alpha/2. Nothing here
# calls pprodnormal(), qprodnormal() or the Meeker integral.

# P(XY <= q) for independent X ~ N(mx, sx^2), Y ~ N(my, sy^2), by direct integration over x.
.mci_oracle_pprod <- function(q, mx, my, sx, sy) {
  g <- function(x) {
    cond <- ifelse(
      x > 0, stats::pnorm((q / x - my) / sy),
      ifelse(x < 0, 1 - stats::pnorm((q / x - my) / sy), as.numeric(q >= 0))
    )
    stats::dnorm(x, mx, sx) * cond
  }
  stats::integrate(g, mx - 10 * sx, mx + 10 * sx, subdivisions = 2000L, rel.tol = 1e-10)$value
}

# rho = 1: X = mx + sx z, Y = my + sy z, so XY = A z^2 + B z + C0 with A = sx sy > 0.
# P(XY <= q) = P(z1 <= z <= z2) over the roots of A z^2 + B z + (C0 - q) = 0 (0 if no real root).
.mci_oracle_pprod_rho1 <- function(q, mx, my, sx, sy) {
  A <- sx * sy
  B <- mx * sy + my * sx
  disc <- B^2 - 4 * A * (mx * my - q)
  if (disc <= 0) {
    return(0)
  }
  r <- sqrt(disc)
  stats::pnorm((-B + r) / (2 * A)) - stats::pnorm((-B - r) / (2 * A))
}

# Endpoints at alpha/2 and 1 - alpha/2 by root-finding on a bracket [lo, hi].
.mci_oracle_endpoints <- function(cdf, lo, hi, alpha = 0.05) {
  vapply(
    c(alpha / 2, 1 - alpha / 2),
    function(p) stats::uniroot(function(q) cdf(q) - p, c(lo, hi), tol = 1e-12)$root,
    numeric(1)
  )
}

.mci_sets <- list(
  c(0.5, 0.6, 0.08, 0.04),
  c(0.2, 0.3, 0.15, 0.12),
  c(0.05, 0.4, 0.1, 0.1)
)

.mci_pn <- function(m, rho = 0) {
  ProductNormal(mu = m[1:2], Sigma = matrix(c(m[3]^2, rho * m[3] * m[4], rho * m[3] * m[4], m[4]^2), 2))
}

.mci_sd_prod <- function(m) sqrt(m[1]^2 * m[4]^2 + m[2]^2 * m[3]^2 + m[3]^2 * m[4]^2)

.mci_dop_oracle <- function(m, alpha = 0.05) {
  est <- m[1] * m[2]
  .mci_oracle_endpoints(
    function(q) .mci_oracle_pprod(q, m[1], m[2], m[3], m[4]),
    est - 8 * .mci_sd_prod(m), est + 8 * .mci_sd_prod(m),
    alpha = alpha
  )
}

test_that("medci() and ci() DOP endpoints equal the inverted quadrature CDF (rho = 0)", {
  for (m in .mci_sets) {
    expected <- .mci_dop_oracle(m)
    res <- medci(m[1], m[2], m[3], m[4], type = "dop")
    expect_equal(unname(res[["95% CI"]]), expected, tolerance = 1e-6)
    expect_equal(unname(ci(.mci_pn(m), type = "dop")$CI), expected, tolerance = 1e-6)
  }
})

test_that("the DOP level follows alpha: 90% endpoints equal the oracle at 0.05 and 0.95", {
  m <- .mci_sets[[1]]
  res <- medci(m[1], m[2], m[3], m[4], alpha = 0.10, type = "dop")
  expect_equal(unname(res[[1]]), .mci_dop_oracle(m, alpha = 0.10), tolerance = 1e-6)
})

test_that("medci() and ci() MC endpoints are within 5 Monte Carlo standard errors of the oracle", {
  skip_on_cran()
  n_mc <- 1e5
  for (m in .mci_sets) {
    expected <- .mci_dop_oracle(m)
    cdf <- function(q) .mci_oracle_pprod(q, m[1], m[2], m[3], m[4])
    # SE of a sample quantile: sqrt(p (1 - p) / n) / f(q), with f the central-difference density
    h <- 1e-4
    dens <- vapply(expected, function(q) (cdf(q + h) - cdf(q - h)) / (2 * h), numeric(1))
    tol <- 5 * sqrt(0.025 * 0.975 / n_mc) / dens

    set.seed(20261031)
    res <- medci(m[1], m[2], m[3], m[4], type = "mc", n.mc = n_mc)
    expect_lt(abs(res[["95% CI"]][1] - expected[1]), tol[1])
    expect_lt(abs(res[["95% CI"]][2] - expected[2]), tol[2])

    set.seed(20261031)
    s7 <- ci(.mci_pn(m), type = "mc", n.mc = n_mc)
    expect_lt(abs(s7$CI[1] - expected[1]), tol[1])
    expect_lt(abs(s7$CI[2] - expected[2]), tol[2])
  }
})

test_that("medci(rho = 1, type = 'dop') endpoints equal the closed-form quadratic-in-z oracle", {
  for (m in .mci_sets) {
    est <- m[1] * m[2]
    # lower support bound is the parabola vertex; the upper bound is far in the tail
    vertex <- est - (m[1] * m[4] + m[2] * m[3])^2 / (4 * m[3] * m[4])
    far <- est + 12 * (m[1] * m[4] + m[2] * m[3] + m[3] * m[4])
    cdf <- function(q) .mci_oracle_pprod_rho1(q, m[1], m[2], m[3], m[4])
    expected <- .mci_oracle_endpoints(cdf, vertex, far)
    res <- medci(m[1], m[2], m[3], m[4], rho = 1, type = "dop")
    expect_equal(unname(res[["95% CI"]]), expected, tolerance = 1e-5)
    expect_equal(unname(ci(.mci_pn(m, 1), type = "dop")$CI), expected, tolerance = 1e-5)
  }
})

# Independent-oracle pins for qprodnormal(): type "dop" (Meeker path), "MC" and lower.tail = FALSE.
# Existing quantile tests only round-trip through pprodnormal() or check identities; none compares
# against an expected value computed without the package.

# P(XY <= q) for independent X, Y by direct integration over x (same idea as the CDF oracle in
# test-product-boundaries.R, copied under a unique name).
.qq_oracle_pprod <- function(q, mx, my, sx, sy) {
  g <- function(x) {
    cond <- ifelse(
      x > 0, stats::pnorm((q / x - my) / sy),
      ifelse(x < 0, 1 - stats::pnorm((q / x - my) / sy), as.numeric(q >= 0))
    )
    stats::dnorm(x, mx, sx) * cond
  }
  stats::integrate(g, mx - 10 * sx, mx + 10 * sx, subdivisions = 2000L, rel.tol = 1e-11)$value
}

# Quantile by inverting the quadrature CDF with uniroot (rho = 0 only).
.qq_oracle_q <- function(p, mx, my, sx, sy) {
  bound <- (abs(mx) + 8 * sx) * (abs(my) + 8 * sy)
  stats::uniroot(
    function(q) .qq_oracle_pprod(q, mx, my, sx, sy) - p,
    c(-bound, bound), tol = 1e-12
  )$root
}

# Standard error of an order-statistic quantile from n iid draws: sqrt(p (1 - p) / n) / f(q).
# The density f(q) is a central difference of the quadrature CDF, so it is also package-free.
.qq_se <- function(p, q, n, mx, my, sx, sy) {
  h <- 1e-3 * (abs(q) + sx * sy)
  f <- (.qq_oracle_pprod(q + h, mx, my, sx, sy) - .qq_oracle_pprod(q - h, mx, my, sx, sy)) / (2 * h)
  sqrt(p * (1 - p) / n) / f
}

# Empirical quantile of x * y from a large correlated normal sample, with a tolerance of
# `k` order-statistic standard errors, sqrt(p (1 - p) / n) / f(q), where f(q) is a central
# difference of the empirical CDF over a window of +/- 0.005 sd of the product.
.qq_empirical <- function(a, rho, n, p) {
  sig <- matrix(c(a[3]^2, rho * a[3] * a[4], rho * a[3] * a[4], a[4]^2), 2)
  xy <- MASS::mvrnorm(n, c(a[1], a[2]), sig)
  prod_xy <- xy[, 1] * xy[, 2]
  h <- 0.005 * stats::sd(prod_xy)
  out <- lapply(p, function(pp) {
    emp <- unname(stats::quantile(prod_xy, pp))
    f <- (mean(prod_xy <= emp + h) - mean(prod_xy <= emp - h)) / (2 * h)
    list(q = emp, se = sqrt(pp * (1 - pp) / n) / f)
  })
  list(q = vapply(out, `[[`, numeric(1), "q"), se = vapply(out, `[[`, numeric(1), "se"))
}

.qq_cases <- list(
  c(0.3, 0.5, 0.2, 0.1), # nonzero means
  c(0.02, 0.03, 0.2, 0.1) # means near zero (mass piled near 0)
)
.qq_probs <- c(0.025, 0.5, 0.975)

test_that("qprodnormal(type = 'dop') matches the inverted quadrature CDF (rho = 0)", {
  skip_on_cran()
  for (a in .qq_cases) {
    for (p in .qq_probs) {
      expected <- .qq_oracle_q(p, a[1], a[2], a[3], a[4])
      expect_equal(
        qprodnormal(p, a[1], a[2], a[3], a[4], rho = 0, type = "dop"), expected,
        tolerance = 1e-6
      )
    }
  }
})

test_that("qprodnormal(type = 'dop', lower.tail = FALSE) matches the inverted quadrature CDF", {
  skip_on_cran()
  a <- .qq_cases[[1]]
  for (p in .qq_probs) {
    expect_equal(
      qprodnormal(p, a[1], a[2], a[3], a[4], rho = 0, lower.tail = FALSE, type = "dop"),
      .qq_oracle_q(1 - p, a[1], a[2], a[3], a[4]),
      tolerance = 1e-6
    )
  }
})

test_that("the Meeker path (qprodnormalMeeker) matches the quadrature oracle (rho = 0)", {
  skip_on_cran()
  a <- .qq_cases[[1]]
  for (p in .qq_probs) {
    expect_equal(
      qprodnormalMeeker(p, a[1], a[2], a[3], a[4], rho = 0)$q,
      .qq_oracle_q(p, a[1], a[2], a[3], a[4]),
      tolerance = 1e-6
    )
  }
})

test_that("qprodnormal(type = 'dop') matches empirical quantiles of a large sample (rho = 0.5)", {
  skip_on_cran()
  set.seed(20261031)
  for (a in .qq_cases) {
    emp <- .qq_empirical(a, rho = 0.5, n = 2e6, p = .qq_probs)
    got <- qprodnormal(.qq_probs, a[1], a[2], a[3], a[4], rho = 0.5, type = "dop")
    # Tolerance: 5 order-statistic standard errors.
    for (i in seq_along(.qq_probs)) {
      expect_lt(abs(got[i] - emp$q[i]), 5 * emp$se[i], label = paste("p =", .qq_probs[i]))
    }
  }
})

test_that("qprodnormal(type = 'MC') matches the quadrature oracle within Monte Carlo error", {
  skip_on_cran()
  set.seed(20261032)
  n_mc <- 1e6
  for (a in .qq_cases) {
    for (p in .qq_probs) {
      expected <- .qq_oracle_q(p, a[1], a[2], a[3], a[4])
      # 5 order-statistic standard errors for n.mc draws (formula at .qq_se).
      tol <- 5 * .qq_se(p, expected, n_mc, a[1], a[2], a[3], a[4])
      got <- qprodnormal(p, a[1], a[2], a[3], a[4], rho = 0, type = "MC", n.mc = n_mc)
      expect_lt(abs(got - expected), tol)
    }
  }
})

test_that("qprodnormalMC matches empirical quantiles at rho = 0.5 within Monte Carlo error", {
  skip_on_cran()
  set.seed(20261033)
  n_mc <- 1e6
  a <- .qq_cases[[1]]
  emp <- .qq_empirical(a, rho = 0.5, n = 2e6, p = .qq_probs)
  got <- qprodnormalMC(.qq_probs, a[1], a[2], a[3], a[4], rho = 0.5, n.mc = n_mc)$q
  # Two independent samples (n.mc and 2e6): the variances of the two quantiles add, so the
  # standard error of the difference is se * sqrt(1 + 2e6 / n.mc) with se from the 2e6 sample.
  tol <- 5 * emp$se * sqrt(1 + 2e6 / n_mc)
  for (i in seq_along(.qq_probs)) {
    expect_lt(abs(got[i] - emp$q[i]), tol[i], label = paste("p =", .qq_probs[i]))
  }
})

test_that("qprodnormal(type = 'MC', lower.tail = FALSE) matches the quadrature oracle", {
  skip_on_cran()
  set.seed(20261034)
  n_mc <- 1e6
  a <- .qq_cases[[1]]
  for (p in .qq_probs) {
    expected <- .qq_oracle_q(1 - p, a[1], a[2], a[3], a[4])
    tol <- 5 * .qq_se(1 - p, expected, n_mc, a[1], a[2], a[3], a[4])
    got <- qprodnormal(p, a[1], a[2], a[3], a[4], rho = 0, lower.tail = FALSE, type = "MC", n.mc = n_mc)
    expect_lt(abs(got - expected), tol)
  }
})

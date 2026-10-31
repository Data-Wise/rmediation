# dist_quantile() and show() for ProductNormal3, plus the zero-gradient fallback shared with
# confint(). Oracles: the package's own CDF (consistency only), a Monte Carlo quantile with its
# sampling bound (independent), and exact limiting cases.

.pn3 <- function(mu = c(0.5, 0.4, 0.3), Sigma = diag(c(0.01, 0.02, 0.015))) {
  ProductNormal3(mu = mu, Sigma = Sigma)
}

test_that("dist_quantile inverts cdf at several probabilities", {
  pn <- .pn3()
  p <- c(0.025, 0.25, 0.5, 0.75, 0.975)
  q <- dist_quantile(pn, p, tol = 1e-6)
  expect_equal(cdf(pn, q), p, tolerance = 1e-4)
})

test_that("dist_quantile is strictly increasing in p", {
  q <- dist_quantile(.pn3(), c(0.05, 0.2, 0.5, 0.8, 0.95))
  expect_true(all(diff(q) > 0))
})

test_that("dist_quantile agrees with a Monte Carlo quantile within its sampling error", {
  pn <- .pn3()
  set.seed(20261014)
  n <- 2e6
  d <- MASS::mvrnorm(n, pn@mu, pn@Sigma)
  x <- d[, 1] * d[, 2] * d[, 3]
  for (p in c(0.05, 0.5, 0.95)) {
    est <- stats::quantile(x, p)
    # sampling sd of an empirical quantile: sqrt(p(1-p)/n) / density at the quantile
    dens <- stats::density(x, from = est, to = est, n = 1)$y
    se <- sqrt(p * (1 - p) / n) / dens
    expect_lt(abs(dist_quantile(pn, p) - est), 6 * se + 1e-4)
  }
})

test_that("dist_quantile at the two interval probabilities equals confint", {
  pn <- .pn3()
  q <- dist_quantile(pn, c(0.025, 0.975), tol = 1e-5)
  ci <- confint(pn, level = 0.95, tol = 1e-5)
  expect_equal(unname(q), unname(ci), tolerance = 1e-4)
})

test_that("dist_quantile is symmetric under sign flip of one mean (p <-> 1 - p)", {
  q_pos <- dist_quantile(.pn3(), 0.2)
  q_neg <- dist_quantile(.pn3(mu = c(-0.5, 0.4, 0.3)), 0.8)
  expect_equal(q_pos, -q_neg, tolerance = 1e-4)
})

test_that("dist_quantile falls back to the component sds when the delta-method sd is 0", {
  # all means 0: gradient is 0, delta sd is 0; the product is symmetric about 0
  pn <- .pn3(mu = c(0, 0, 0))
  q <- dist_quantile(pn, c(0.1, 0.5, 0.9))
  expect_equal(q[2], 0, tolerance = 1e-3)
  expect_equal(q[1], -q[3], tolerance = 1e-3)
  expect_lt(q[1], 0)
})

test_that("an all-zero covariance is a point mass for cdf() (issue #64)", {
  pn <- .pn3(Sigma = matrix(0, 3, 3))
  expect_equal(cdf(pn, c(0.05, 0.07)), c(0, 1))
})

test_that("dist_quantile validates its arguments", {
  pn <- .pn3()
  expect_error(dist_quantile(pn, 1.5))
  expect_error(dist_quantile(pn, -0.1))
  expect_error(dist_quantile(pn, NA_real_))
  expect_error(dist_quantile(pn, 0.5, tol = -1))
})

test_that("show() prints the same text as print()", {
  pn <- .pn3()
  expect_identical(capture.output(show(pn)), capture.output(print(pn)))
  expect_match(paste(capture.output(show(pn)), collapse = "\n"), "ProductNormal3 Distribution")
})

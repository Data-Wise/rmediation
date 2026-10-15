# dprodnormal3(): density of X1 X2 X3 for trivariate normal. Oracles that share no code with it:
#  - d/dv of the CDF pprodnormal3() (finite difference; the CDF is a different 2-D integral);
#  - a Monte Carlo histogram, with a binomial uncertainty bound;
#  - exact identities (CDF difference, sign flip, scaling, permutation).

S0 <- matrix(c(1, .3, .2, .3, 1, .1, .2, .1, 1), 3)
sd0 <- c(.2, .3, .25)
S1 <- S0 * outer(sd0, sd0)
mu1 <- c(.5, .4, .3)

test_that("the density is the derivative of pprodnormal3() (positive, negative, zero means)", {
  h <- 1e-5
  cases <- list(
    list(mu = mu1, S = S1, v = c(0.01, 0.05, 0.1, -0.02)),
    list(mu = c(0, 0, 0), S = S1, v = c(0.002, -0.01, 0.03)),
    list(mu = c(.3, -.4, .2), S = S0, v = c(-0.2, 0.15, 0.6))
  )
  for (cs in cases) {
    for (v in cs$v) {
      num <- (pprodnormal3(v + h, cs$mu, cs$S, tol = 1e-10) - pprodnormal3(v - h, cs$mu, cs$S, tol = 1e-10)) / (2 * h)
      expect_equal(dprodnormal3(v, cs$mu, cs$S), num, tolerance = 1e-5, info = paste(cs$mu, v))
    }
  }
})

test_that("the density integrates to the CDF difference", {
  a <- 0.02
  b <- 0.2
  val <- integrate(function(v) dprodnormal3(v, mu1, S1), a, b, rel.tol = 1e-6)$value
  expect_equal(val, pprodnormal3(b, mu1, S1, tol = 1e-10) - pprodnormal3(a, mu1, S1, tol = 1e-10), tolerance = 1e-6)
})

test_that("it agrees with a Monte Carlo histogram within sampling error", {
  skip_on_cran()
  set.seed(20261014)
  n <- 4e5
  z <- matrix(rnorm(3 * n), n) %*% chol(S1)
  p <- (z[, 1] + mu1[1]) * (z[, 2] + mu1[2]) * (z[, 3] + mu1[3])
  for (v in c(0.03, 0.08, 0.15)) {
    w <- 0.004
    phat <- mean(p > v - w & p < v + w)
    dens_mc <- phat / (2 * w)
    se <- sqrt(phat * (1 - phat) / n) / (2 * w)
    expect_lt(abs(dens_mc - dprodnormal3(v, mu1, S1)), 5 * se + 0.01 * dens_mc, label = paste("v", v))
  }
})

test_that("sign flip, scaling and permutation identities hold", {
  v <- c(0.03, 0.12)
  f <- dprodnormal3(v, mu1, S1)
  # X1 -> -X1 flips the product's sign: mean[1] and the covariances with X1 change sign
  Dm <- diag(c(-1, 1, 1))
  expect_equal(dprodnormal3(-v, Dm %*% mu1, Dm %*% S1 %*% Dm), f, tolerance = 1e-7)
  # X -> c X multiplies the product by c^3: f_cX(w) = f_X(w / c^3) / c^3
  expect_equal(dprodnormal3(8 * v, 2 * mu1, 4 * S1) * 8, f, tolerance = 1e-7)
  # permuting the factors changes nothing
  P <- c(3, 1, 2)
  expect_equal(dprodnormal3(v, mu1[P], S1[P, P]), f, tolerance = 1e-6)
})

test_that("log, vectorization, non-finite arguments and the singularity at 0", {
  v <- c(-0.05, 0.04, 0.2)
  d <- dprodnormal3(v, mu1, S1)
  expect_length(d, 3)
  expect_true(all(d > 0))
  expect_equal(dprodnormal3(v, mu1, S1, log = TRUE), log(d))
  expect_identical(dprodnormal3(c(-Inf, Inf), mu1, S1), c(0, 0))
  expect_identical(dprodnormal3(0, mu1, S1), Inf)
  # near the singularity the density grows as v -> 0
  expect_gt(dprodnormal3(1e-6, mu1, S1), dprodnormal3(1e-3, mu1, S1))
})

test_that("far-tail values stay finite and non-negative", {
  d <- dprodnormal3(c(5, -5), mu1, S1)
  expect_true(all(is.finite(d) & d >= 0))
})

test_that("invalid arguments and covariances are rejected", {
  expect_error(dprodnormal3(NA_real_, mu1, S1))
  expect_error(dprodnormal3(0.1, c(1, 2), S1))
  expect_error(dprodnormal3(0.1, mu1, diag(2)))
  expect_error(dprodnormal3(0.1, mu1, "a"))
  expect_error(dprodnormal3(0.1, mu1, S1, log = NA))
  expect_error(dprodnormal3(0.1, mu1, diag(c(-1, 1, 1))), "positive semidefinite")
  expect_error(dprodnormal3(0.1, mu1, diag(c(1, 1, 0))), "positive definite")
  expect_error(dprodnormal3(0.1, mu1, matrix(c(1, 1, 0, 1, 1, 0, 0, 0, 1), 3)), "positive definite")
})

test_that("small v (log-singular region) still matches the CDF derivative", {
  for (v in c(1e-3, 1e-4)) {
    h <- v / 10 # a central difference this wide is accurate to ~0.1% on the log-like curve
    num <- suppressWarnings(
      (pprodnormal3(v + h, mu1, S1, tol = 1e-10) - pprodnormal3(v - h, mu1, S1, tol = 1e-10)) / (2 * h)
    )
    expect_equal(dprodnormal3(v, mu1, S1), num, tolerance = 2e-3, info = paste("v", v))
  }
})

test_that("dprodnormal() resolves small z at nonzero conditional means (decade breaks)", {
  # z ~ 1e-8 used to give 'the integral is probably divergent' once the means were nonzero
  expect_no_error(d <- dprodnormal(1e-8, 0.5, 0.3, 0.2, 0.4, 0.3))
  expect_gt(d, dprodnormal(1e-3, 0.5, 0.3, 0.2, 0.4, 0.3))
})

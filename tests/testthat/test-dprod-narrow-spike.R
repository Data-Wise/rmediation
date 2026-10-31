# Issue #117: the density integrand is a narrow spike when a factor's mean is large relative to its standard
# error (mu / se above about 3000 for dprodnormal(); above about 1000 for some dprodnormal3() inner integrals),
# and a fixed integration window missed it, returning 0 or a silently low value. Oracles that do not use the
# density code: (a) direct conditioning quadrature, f(z) = integral of f_X(x) f_{Y|X}(z / x) / |x| dx on a fine
# Gauss-Legendre rule over X +/- 9 sd, and (b) when one factor is nearly constant, the density of the product of
# the remaining factors scaled by that factor's mean. A CDF central difference was tried and rejected: it carries
# the CDF's own absolute error divided by the step, which exceeds the density tolerance at these scales.

.dns_oracle2 <- function(z, mu.x, mu.y, se.x, se.y, rho, n = 400L) {
  i <- seq_len(n - 1L)
  b <- i / sqrt(4 * i^2 - 1)
  jac <- matrix(0, n, n)
  jac[cbind(i, i + 1L)] <- b
  jac[cbind(i + 1L, i)] <- b
  e <- eigen(jac, symmetric = TRUE)
  lo <- mu.x - 9 * se.x
  hi <- mu.x + 9 * se.x
  x <- (hi - lo) / 2 * e$values + (hi + lo) / 2
  w <- (hi - lo) / 2 * 2 * e$vectors[1, ]^2
  cm <- mu.y + rho * se.y / se.x * (x - mu.x)
  vapply(z, function(zz) sum(w * dnorm(x, mu.x, se.x) * dnorm(zz / x, cm, se.y * sqrt(1 - rho^2)) / abs(x)),
         numeric(1))
}

test_that("dprodnormal matches conditioning quadrature for a tiny se.x (mu.x / se.x up to 3e5)", {
  grid <- c(0.09, 0.12, 0.15)
  for (se.x in c(1e-3, 1e-4, 1e-5, 1e-6)) {
    for (rho in c(0, 0.5, -0.5)) {
      expect_equal(dprodnormal(grid, 0.3, 0.4, se.x, 0.1, rho),
                   .dns_oracle2(grid, 0.3, 0.4, se.x, 0.1, rho),
                   tolerance = 1e-6, info = paste("se.x =", se.x, "rho =", rho))
    }
  }
})

test_that("dprodnormal matches the normal density of mu.x * Y when X is nearly constant", {
  grid <- c(0.09, 0.12, 0.15)
  for (se.x in c(1e-4, 1e-5, 1e-6)) {
    expect_equal(dprodnormal(grid, 0.3, 0.4, se.x, 0.1),
                 dnorm(grid, 0.3 * 0.4, sqrt((0.3 * 0.1)^2 + (0.4 * se.x)^2)),
                 tolerance = 1e-4, info = paste("se.x =", se.x))
  }
})

test_that("dprodnormal is correct when both means are large relative to the standard errors", {
  # mu.x / se.x = 3000 and mu.y / se.y = 4000: the product is nearly normal with the delta-method variance
  d <- dprodnormal(c(0.11, 0.12, 0.13), 0.3, 0.4, 1e-4, 1e-4)
  sd.p <- sqrt((0.3 * 1e-4)^2 + (0.4 * 1e-4)^2)
  expect_equal(d, dnorm(c(0.11, 0.12, 0.13), 0.12, sd.p), tolerance = 1e-4)
})

test_that("dprodnormal keeps Inf at zero and a consistent log", {
  expect_identical(dprodnormal(0, 0.3, 0.4, 1e-4, 0.1), Inf)
  x <- c(0.09, 0.12)
  expect_equal(dprodnormal(x, 0.3, 0.4, 1e-4, 0.1, log = TRUE), log(dprodnormal(x, 0.3, 0.4, 1e-4, 0.1)))
})

test_that("dprodnormal3 matches the scaled lower-order density when one factor has a tiny standard error", {
  skip_on_cran()
  mean <- c(0.3, 0.4, 0.5)
  x <- 0.06
  d3 <- function(sds) dprodnormal3(x, mean = mean, cov = diag(sds^2))
  tol <- 1e-3
  expect_equal(d3(c(0.1, 0.1, 1e-4)), dprodnormal(x / mean[3], mean[1], mean[2], 0.1, 0.1) / mean[3], tolerance = tol)
  expect_equal(d3(c(0.1, 3e-4, 0.1)), dprodnormal(x / mean[2], mean[1], mean[3], 0.1, 0.1) / mean[2], tolerance = tol)
  expect_equal(d3(c(0.1, 1e-4, 0.1)), dprodnormal(x / mean[2], mean[1], mean[3], 0.1, 0.1) / mean[2], tolerance = tol)
  expect_equal(d3(c(1e-4, 0.1, 0.1)), dprodnormal(x / mean[1], mean[2], mean[3], 0.1, 0.1) / mean[1], tolerance = tol)
  expect_equal(d3(c(1e-4, 1e-4, 0.1)), dnorm(x, prod(mean), prod(mean[1:2]) * 0.1), tolerance = tol)
})

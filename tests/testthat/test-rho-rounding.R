# A perfectly correlated pair (the same coefficient twice, e.g. `a*a`) has Sigma[1,2] == Sigma[1,1] == Sigma[2,2].
# sqrt(v)^2 is not always v in floating point, so rho = cov / (se.x * se.y) can come out as 1 +/- one rounding
# step. rho above 1 used to produce NaN warnings and "non-finite function value" in the DOP root-finder.

variances <- seq(0.001, 0.2, length.out = 400)
rho_of <- function(v) v / (sqrt(v) * sqrt(v))
above <- variances[rho_of(variances) > 1]
below <- variances[rho_of(variances) < 1]

test_that("the grid contains variances whose rounded rho is above and below 1", {
  expect_gt(length(above), 10L)
  expect_gt(length(below), 10L)
})

test_that("ci(type = 'dop') on a perfectly correlated pair matches the exact collinear quantiles", {
  for (v in c(above[1:5], below[1:5])) {
    object <- ProductNormal(mu = c(.4, .4), Sigma = matrix(v, 2, 2))
    expect_no_warning(res <- ci(object, type = "dop"))
    expected <- qprodnormal(c(.025, .975), .4, .4, sqrt(v), sqrt(v), rho = 1)
    expect_equal(as.numeric(res$CI), expected, tolerance = 1e-6)
  }
})

test_that("the cdf and quantile methods accept the rounded rho too", {
  v <- above[1]
  object <- ProductNormal(mu = c(.4, .4), Sigma = matrix(v, 2, 2))
  expect_no_warning(p <- cdf(object, .3))
  # the object cdf and pprodnormal() agree to the integrator tolerance, not to machine precision
  expect_equal(p, pprodnormal(.3, .4, .4, sqrt(v), sqrt(v), rho = 1), tolerance = 1e-5)
  # one probability per call here; a vector p is covered in test-dist-quantile-vector-p.R
  for (pr in c(.025, .975)) {
    expect_no_warning(q <- dist_quantile(object, pr))
    expect_equal(q, qprodnormal(pr, .4, .4, sqrt(v), sqrt(v), rho = 1), tolerance = 1e-6)
  }
})

test_that("a genuinely invalid correlation is still rejected, not snapped", {
  expect_error(
    ci(ProductNormal(mu = c(.4, .4), Sigma = matrix(c(1, 1.5, 1.5, 1), 2)), type = "dop")
  )
})

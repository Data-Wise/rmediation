# cdf(<ProductNormal3>, lower.tail = FALSE) uses the directly integrated upper tail (issue #177),
# and dist_quantile() / confint() use the object's integration method.

# Independent oracle for independent unit-mean, unit-sd factors: P(X1 * W > q), W = X2 * X3.
upper_oracle <- function(q) {
  f <- function(w) {
    dprodnormal(w, 1, 1, 1, 1, rho = 0) *
      ifelse(w > 0, stats::pnorm(q / w - 1, lower.tail = FALSE), stats::pnorm(q / w - 1))
  }
  integrate(f, 0, 60, rel.tol = 1e-12, subdivisions = 2000)$value +
    integrate(f, -60, 0, rel.tol = 1e-12, subdivisions = 2000)$value
}

test_that("the object upper tail matches the independent oracle far out", {
  object <- ProductNormal3(mu = rep(1, 3), Sigma = diag(3))
  for (q in c(5, 30)) {
    got <- cdf(object, q, lower.tail = FALSE, tol = 1e-10)
    expect_equal(got, upper_oracle(q), tolerance = 1e-7)
  }
  # the old `1 - p` could not resolve this: its result at the default tolerance was about 50 times too large
  far <- cdf(object, 100, lower.tail = FALSE, tol = 1e-10)
  expect_lt(far, 1e-9)
  expect_equal(far, pprodnormal3(100, rep(1, 3), diag(3), tol = 1e-10, lower.tail = FALSE))
})

test_that("lower and upper tails of the object sum to one", {
  R <- matrix(c(1, .5, .3, .5, 1, -.2, .3, -.2, 1), 3)
  Sigma <- R * outer(c(.2, .3, .25), c(.2, .3, .25))
  object <- ProductNormal3(mu = c(.5, .25, -.15), Sigma = Sigma)
  q <- c(-.2, 0, .05, .2)
  expect_equal(cdf(object, q, tol = 1e-8) + cdf(object, q, lower.tail = FALSE, tol = 1e-8), rep(1, 4),
    tolerance = 1e-7
  )
})

test_that("dist_quantile() and confint() pass the object's method to pprodnormal3()", {
  seen <- new.env(parent = emptyenv())
  seen$methods <- character()
  local_mocked_bindings(
    pprodnormal3 = function(q, mean, cov, method = "gauss", ...) {
      seen$methods <- c(seen$methods, method)
      stats::pnorm((q - prod(mean)) / .3)
    }
  )
  object <- ProductNormal3(mu = c(.5, .5, .5), Sigma = diag(3) * .01, method = "hcubature")
  for (call in list(
    function() dist_quantile(object, .5),
    function() confint(object),
    function() cdf(object, .1)
  )) {
    seen$methods <- character()
    call()
    expect_true(length(seen$methods) > 0L && all(seen$methods == "hcubature"))
  }
})

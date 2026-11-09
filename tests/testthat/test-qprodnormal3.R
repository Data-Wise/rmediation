# qprodnormal3(): inversion of pprodnormal3(), both tails.

test_that("round trip recovers p in both tails, including far tails", {
  R <- matrix(c(1, .5, .3, .5, 1, -.2, .3, -.2, 1), 3)
  Sigma <- R * outer(c(.2, .3, .25), c(.2, .3, .25))
  cases <- list(
    # far tails need a tolerance below the tail probability
    list(mean = c(1, 1, 1), S = diag(3), tol = 1e-12, ps = c(1e-8, 1e-4, .025, .3, .5, .7, .975, 1 - 1e-4, 1 - 1e-8)),
    list(mean = c(.5, .25, -.15), S = Sigma, tol = 1e-9, ps = c(1e-4, .025, .3, .5, .7, .975, 1 - 1e-4))
  )
  for (k in cases) {
    for (lt in c(TRUE, FALSE)) {
      q <- qprodnormal3(k$ps, k$mean, k$S, lower.tail = lt, tol = k$tol)
      back <- vapply(q, pprodnormal3, numeric(1), mean = k$mean, cov = k$S, tol = k$tol, lower.tail = lt)
      expect_equal(back, k$ps, tolerance = 1e-6)
      # monotone: a larger lower-tail p is a larger quantile; reversed for the upper tail
      expect_false(is.unsorted(if (lt) q else rev(q), strictly = TRUE))
    }
  }
})

test_that("agrees with dist_quantile() on a ProductNormal3 object", {
  mu <- c(.4, .5, .3)
  Sigma <- diag(c(.01, .02, .015))
  obj <- ProductNormal3(mu = mu, Sigma = Sigma)
  ps <- c(.025, .5, .975)
  expect_equal(qprodnormal3(ps, mu, Sigma, tol = 1e-4), dist_quantile(obj, ps, tol = 1e-4),
    tolerance = 1e-12
  )
})

test_that("matches an independent two-factor quantile when one factor is fixed", {
  # X1 fixed at 2: the quantile of 2 * X2 * X3 is 2 * the two-factor quantile
  for (lt in c(TRUE, FALSE)) {
    got <- qprodnormal3(c(.1, .9), c(2, 1, .5), diag(c(0, 1, 2)), lower.tail = lt, tol = 1e-10)
    want <- 2 * qprodnormal(c(.1, .9), 1, .5, 1, sqrt(2), 0, lower.tail = lt)
    expect_equal(got, want, tolerance = 1e-5)
  }
})

test_that("edges: p = 0 and 1, names, point mass, vectors", {
  expect_identical(qprodnormal3(c(0, 1), rep(1, 3), diag(3)), c(-Inf, Inf))
  expect_identical(qprodnormal3(c(0, 1), rep(1, 3), diag(3), lower.tail = FALSE), c(Inf, -Inf))
  named <- qprodnormal3(c(lo = .2, hi = .8), rep(1, 3), diag(3))
  expect_identical(names(named), c("lo", "hi"))
  expect_lt(named[["lo"]], named[["hi"]])
  expect_identical(qprodnormal3(.3, c(1, 2, 3), matrix(0, 3, 3)), 6)
})

test_that("invalid input is rejected", {
  expect_error(qprodnormal3(1.2, rep(1, 3), diag(3)))
  expect_error(qprodnormal3(NA_real_, rep(1, 3), diag(3)))
  expect_error(qprodnormal3(.5, rep(1, 2), diag(3)))
  expect_error(qprodnormal3(.5, rep(1, 3), diag(2)))
  expect_error(qprodnormal3(.5, rep(1, 3), diag(3), lower.tail = NA))
  expect_error(qprodnormal3(.5, rep(1, 3), diag(3), tol = 0), "strictly positive")
  expect_error(qprodnormal3(.5, rep(1, 3), matrix(c(1, 1, 0, 1, 1, 0, 0, 0, 1), 3)), "positive-definite")
})

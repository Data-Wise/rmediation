test_that("ProductNormal3 class validates inputs", {
  expect_error(
    ProductNormal3(mu = c(1, 2), Sigma = diag(3), method = "hcubature"),
    "mu must have length 3"
  )
  expect_error(
    ProductNormal3(mu = c(1, 2, 3), Sigma = diag(2), method = "hcubature"),
    "Sigma must be a 3x3 matrix"
  )
  expect_error(
    ProductNormal3(mu = c(1, 2, 3), Sigma = diag(3), method = "cuhre"),
    "method must be 'gauss' or 'hcubature'"
  )
})

test_that("p_prod3 returns 0.5 for zero-mean symmetric distributions", {
  expect_equal(p_prod3(0, c(0, 0, 0), diag(3)), 0.5)

  Sigma_cor <- matrix(
    c(1, 0.5, 0.3, 0.5, 1, 0.2, 0.3, 0.2, 1),
    nrow = 3, byrow = TRUE
  )
  expect_equal(p_prod3(0, c(0, 0, 0), Sigma_cor), 0.5)
})

test_that("p_prod3 matches Monte Carlo ground truth", {
  set.seed(42)
  Sigma <- matrix(
    c(1, 0.3, 0.1, 0.3, 1, 0.2, 0.1, 0.2, 1),
    nrow = 3, byrow = TRUE
  )
  mu <- c(0.5, 0.3, 0.2)
  X <- MASS::mvrnorm(1e5, mu = mu, Sigma = Sigma)
  V <- X[, 1] * X[, 2] * X[, 3]

  for (q in c(-0.5, 0, 0.5, 1)) {
    mc_prob <- mean(V <= q)
    p3_prob <- p_prod3(q, mu, Sigma, tol = 1e-4)
    expect_lt(abs(p3_prob - mc_prob), 5e-3)
  }
})

test_that("cdf method on ProductNormal3 is consistent with p_prod3", {
  mu <- c(0.5, 0.3, 0.2)
  Sigma <- diag(3)
  # Both sides must use the same integrator for this to test dispatch rather
  # than the (tiny) numerical gap between methods, so leave `method` at its
  # default on the object as well as in the p_prod3() calls.
  obj <- ProductNormal3(mu = mu, Sigma = Sigma)

  expect_equal(cdf(obj, 1), p_prod3(1, mu, Sigma))
  expect_equal(
    cdf(obj, c(0, 1, 2)),
    c(p_prod3(0, mu, Sigma), p_prod3(1, mu, Sigma), p_prod3(2, mu, Sigma))
  )
})

test_that("p_prod3 handles degenerate covariance matrices", {
  # X1 is degenerate; reduces to product of X2 and X3 scaled by X1.
  Sigma <- diag(c(0, 1, 1))
  mu <- c(0.5, 0.3, 0.2)
  expected <- pprodnormal(
    0.1 / 0.5,
    mu.x = 0.3, mu.y = 0.2, se.x = 1, se.y = 1, rho = 0
  )
  expect_equal(p_prod3(0.1, mu, Sigma), expected)

  # X2 is degenerate.
  Sigma2 <- diag(c(1, 0, 1))
  mu2 <- c(0.5, 0.3, 0.2)
  expected2 <- pprodnormal(
    0.1 / 0.3,
    mu.x = 0.5, mu.y = 0.2, se.x = 1, se.y = 1, rho = 0,
    lower.tail = TRUE
  )
  expect_equal(p_prod3(0.1, mu2, Sigma2), expected2)

  # X3 is degenerate.
  Sigma3 <- diag(c(1, 1, 0))
  mu3 <- c(0.5, 0.3, 0.2)
  expected3 <- pprodnormal(
    0.1 / 0.2,
    mu.x = 0.5, mu.y = 0.3, se.x = 1, se.y = 1, rho = 0,
    lower.tail = TRUE
  )
  expect_equal(p_prod3(0.1, mu3, Sigma3), expected3)

  # All three variables degenerate at zero -> product is identically zero.
  expect_equal(p_prod3(0, c(0, 0, 0), diag(c(0, 0, 0))), 0.5)
  expect_equal(p_prod3(1, c(0, 0, 0), diag(c(0, 0, 0))), 1)
  expect_equal(p_prod3(-1, c(0, 0, 0), diag(c(0, 0, 0))), 0)
})

test_that("p_prod3 is accurate on near-singular covariance, not merely finite", {
  # Regression for #27. This test previously asserted only expect_no_error()
  # and 0 <= p <= 1, which is why a 24% error at higher rho shipped unnoticed:
  # at this covariance (kappa = 207) the old hcubature default already returned
  # 0.6810183, off by 1.8e-03, and nothing here looked at the value.
  Sigma <- matrix(
    c(1, 0.99, 0.99, 0.99, 1, 0.99, 0.99, 0.99, 1),
    nrow = 3, byrow = TRUE
  )
  mu <- c(0.5, 0.3, 0.2)

  # Reference: Gauss-Legendre, identical to 1e-10 at n = 512, 1024 and 2048,
  # and within 3 SE of a 5e6-draw Monte Carlo estimate (0.6826886, 3SE 6.2e-04).
  expect_equal(p_prod3(0.5, mu, Sigma), 0.6828012535, tolerance = 1e-7)
})

test_that("pprodnormal3 is accurate at rho = 0.999 across the whole support", {
  # Regression for #27. The issue reported only q = 0.5; the error is in fact
  # present at every q, and worst in relative terms in the lower tail
  # (92% at q = -2). confint()/ci() invert this CDF, so they inherited it.
  mu <- c(0.2, 0.1, 0.0)
  Sigma <- matrix(c(1, .999, .5, .999, 1, .5, .5, .5, 1), 3, 3)

  # References: Gauss-Legendre at n = 512 vs 1024 agree to <= 1.7e-14 for every
  # q below, and Monte Carlo at 1e7 lands within 3 SE of each.
  reference <- c(
    "-2" = 0.05711903, "-0.5" = 0.16636496, "0" = 0.49727060,
    "0.5" = 0.80671502, "2" = 0.92056384
  )

  for (q in c(-2, -0.5, 0, 0.5, 2)) {
    expect_equal(
      pprodnormal3(q, mu, Sigma), reference[[as.character(q)]],
      tolerance = 1e-6,
      info = paste("q =", q)
    )
  }
})

test_that("node count escalates when the covariance demands it", {
  mu <- c(0.2, 0.1, 0.0)
  mk <- function(r) matrix(c(1, r, .5, r, 1, .5, .5, .5, 1), 3, 3)

  easy <- pprodnormal3(0.5, mu, mk(0.99), diagnostics = TRUE)
  hard <- pprodnormal3(0.5, mu, mk(0.9999), diagnostics = TRUE)

  # Harder conditioning must buy more nodes, not a silently worse answer.
  expect_gt(attr(hard, "nodes"), attr(easy, "nodes"))
  expect_lt(attr(hard, "error"), 1e-6)
  expect_equal(as.numeric(hard), 0.80662217, tolerance = 1e-6)
})

test_that("the vectorized integrand matches the scalar one exactly", {
  # The Gauss path uses .prod3_integrand_vec() and the hcubature path uses
  # .prod3_integrand_2d(). If they drift, the two methods silently stop
  # computing the same quantity.
  Sigma <- matrix(c(1, .95, .4, .95, 1, .3, .4, .3, 1), 3, 3)
  mu <- c(0.4, 0.2, 0.1)
  sds <- sqrt(diag(Sigma))
  R <- Sigma / outer(sds, sds)
  R <- (R + t(R)) / 2
  U <- chol(R[1:2, 1:2])
  beta <- as.numeric(backsolve(U, forwardsolve(t(U), R[1:2, 3])))
  args <- list(
    q_std = 0.5 / prod(sds), m = mu / sds, beta = beta,
    cond_sd = sqrt(max(1 - sum(beta * R[1:2, 3]), .Machine$double.eps)),
    Rxy_inv = chol2inv(U), det_Rxy = prod(diag(U))^2
  )

  set.seed(3)
  xs <- runif(200, -6, 6)
  ys <- runif(200, -6, 6)
  scalar <- vapply(
    seq_along(xs),
    function(i) do.call(.prod3_integrand_2d, c(list(arg = c(xs[i], ys[i])), args)),
    numeric(1)
  )
  vec <- do.call(.prod3_integrand_vec, c(list(x = xs, y = ys), args))

  expect_lt(max(abs(scalar - vec)), 1e-12)
})

test_that("accuracy holds when the standardized mean exceeds the bound", {
  # When |m| > bound the first cell gets reversed limits, so it contributes a
  # negative-weight integral that telescopes with the second cell to the
  # intended truncation box. This reads like a defect and is not one; the test
  # exists so it does not get "fixed" into a real one.
  #
  # References are Monte Carlo at 4e6 draws (3 SE ~ 7.5e-04). Precision here is
  # deliberately modest: the point is that accuracy does not collapse, and MC
  # is the only independent check available for these configurations.
  benign <- matrix(c(1, .5, .3, .5, 1, .2, .3, .2, 1), 3, 3)
  stiff <- matrix(c(1, .999, .5, .999, 1, .5, .5, .5, 1), 3, 3)

  expect_equal(pprodnormal3(0.5, c(10, 0.3, 0.2), benign), 0.4855733,
    tolerance = 1e-3
  )
  expect_equal(pprodnormal3(0.5, c(20, 0.3, 0.2), benign), 0.4583408,
    tolerance = 1e-3
  )
  expect_equal(pprodnormal3(0.5, c(-15, 0.3, 0.2), benign), 0.6248695,
    tolerance = 1e-3
  )
  # Both stressors at once: mean far outside the bound AND ill-conditioned.
  expect_equal(pprodnormal3(0.5, c(15, 0.1, 0.0), stiff), 0.3867492,
    tolerance = 1e-3
  )
})

test_that("the legacy hcubature path collapses on large means", {
  # Not a regression -- documents a second silent failure in the pre-1.7.0
  # integrator, distinct from the ill-conditioning bug in #27. It returns
  # exactly 0 where the true probability is ~0.46. Recorded so the default
  # change is not mistaken for a mere accuracy refinement.
  benign <- matrix(c(1, .5, .3, .5, 1, .2, .3, .2, 1), 3, 3)
  expect_equal(
    pprodnormal3(0.5, c(20, 0.3, 0.2), benign, method = "hcubature"), 0
  )
  expect_equal(pprodnormal3(0.5, c(20, 0.3, 0.2), benign), 0.4583408,
    tolerance = 1e-3
  )
})

test_that("the truncation bound is derived from tol, never tuned below 6", {
  # Truncation error is a bias, and bias is invisible to the self-consistency
  # check: at bound = 4 successive rules agree to 1.7e-14 while the answer is
  # 3.2e-05 wrong. The bound must stay wide enough to make that impossible.
  expect_gte(.prod3_bound(1e-6), 6)
  expect_gte(.prod3_bound(1e-2), 6)
  expect_gt(.prod3_bound(1e-12), .prod3_bound(1e-6))
  expect_lte(.prod3_bound(1e-300), 12)
})

test_that("gauss and hcubature agree on well-conditioned input", {
  # The default change must not move results for ordinary users.
  mu <- c(0.2, 0.1, 0.0)
  for (r in c(0, 0.5, 0.9)) {
    Sigma <- matrix(c(1, r, .5, r, 1, .5, .5, .5, 1), 3, 3)
    expect_equal(
      pprodnormal3(0.5, mu, Sigma),
      pprodnormal3(0.5, mu, Sigma, method = "hcubature"),
      tolerance = 1e-5,
      info = paste("rho =", r)
    )
  }
})

test_that("the legacy hcubature path is still reachable", {
  mu <- c(0.2, 0.1, 0.0)
  Sigma <- matrix(c(1, .999, .5, .999, 1, .5, .5, .5, 1), 3, 3)
  legacy <- pprodnormal3(0.5, mu, Sigma, method = "hcubature")

  expect_true(is.numeric(legacy) && length(legacy) == 1)
  # Documents, rather than endorses, the pre-1.7.0 behavior: this is the
  # value the old default returned, and it is wrong by ~0.196.
  expect_equal(legacy, 0.6109671, tolerance = 1e-5)
})

test_that("diagnostics are opt-in so the return stays a bare numeric", {
  mu <- c(0.2, 0.1, 0.0)
  Sigma <- matrix(c(1, .9, .5, .9, 1, .5, .5, .5, 1), 3, 3)

  plain <- pprodnormal3(0.5, mu, Sigma)
  expect_null(attributes(plain))

  noisy <- pprodnormal3(0.5, mu, Sigma, diagnostics = TRUE)
  expect_true(is.numeric(attr(noisy, "error")))
  expect_true(is.numeric(attr(noisy, "nodes")))
  expect_equal(as.numeric(noisy), as.numeric(plain))
})

test_that("the error diagnostic follows its documented per-method contract", {
  mu <- c(0.2, 0.1, 0.0)
  Sigma <- matrix(c(1, .9, .5, .9, 1, .5, .5, .5, 1), 3, 3)

  # gauss: a real successive-rule gap, below the requested tol.
  g <- pprodnormal3(0.5, mu, Sigma, diagnostics = TRUE)
  expect_false(is.na(attr(g, "error")))
  expect_lt(attr(g, "error"), 1e-6)

  # hcubature: that integrator's own estimate, passed through rather than
  # suppressed. Documented as present-but-untrustworthy, so assert it is a
  # number and NOT NA. The docs previously promised NA here, which the code
  # never did -- caught in review of PR #28, and this test pins the resolution.
  h <- pprodnormal3(0.5, mu, Sigma, method = "hcubature", diagnostics = TRUE)
  expect_false(is.na(attr(h, "error")))
  expect_true(is.numeric(attr(h, "error")))

  # fixed nodes: no successive-rule gap exists, so NA.
  f <- pprodnormal3(0.5, mu, Sigma, nodes = 256, diagnostics = TRUE)
  expect_true(is.na(attr(f, "error")))
  expect_equal(attr(f, "nodes"), 256L)
})

test_that("a fixed node count can be forced and is validated", {
  mu <- c(0.2, 0.1, 0.0)
  Sigma <- matrix(c(1, .999, .5, .999, 1, .5, .5, .5, 1), 3, 3)

  expect_equal(pprodnormal3(0.5, mu, Sigma, nodes = 512), 0.80671502,
    tolerance = 1e-6
  )
  expect_error(pprodnormal3(0.5, mu, Sigma, nodes = 2))
  expect_error(pprodnormal3(0.5, mu, Sigma, method = "simpson"))
})

test_that("ProductNormal3 defaults to gauss and accepts both methods", {
  obj <- ProductNormal3(mu = c(0.5, 0.3, 0.2), Sigma = diag(3))
  expect_equal(obj@method, "gauss")

  expect_no_error(
    ProductNormal3(mu = c(0.5, 0.3, 0.2), Sigma = diag(3), method = "hcubature")
  )
  expect_error(
    ProductNormal3(mu = c(0.5, 0.3, 0.2), Sigma = diag(3), method = "simpson"),
    "gauss"
  )
})

test_that("confint handles zero delta-method standard deviation", {
  # Covariance where the gradient-based delta SD is zero but the product
  # distribution is not degenerate.
  Sigma <- diag(c(1, 1, 0))
  mu <- c(0, 0, 0.5)
  obj <- ProductNormal3(mu = mu, Sigma = Sigma, method = "hcubature")
  ci_res <- confint(obj, level = 0.95, tol = 1e-4)
  expect_named(ci_res, c("lower", "upper"))
  expect_lt(ci_res["lower"], ci_res["upper"])
})

test_that("confint and ci methods return valid intervals", {
  mu <- c(0.5, 0.3, 0.2)
  Sigma <- diag(3)
  obj <- ProductNormal3(mu = mu, Sigma = Sigma, method = "hcubature")

  ci_res <- confint(obj, level = 0.95, tol = 1e-4)
  expect_named(ci_res, c("lower", "upper"))
  expect_lt(ci_res["lower"], ci_res["upper"])

  ci_alias <- ci(obj, level = 0.95, tol = 1e-4)
  expect_equal(ci_alias, ci_res)

  set.seed(42)
  X <- MASS::mvrnorm(1e5, mu = mu, Sigma = Sigma)
  V <- X[, 1] * X[, 2] * X[, 3]
  mc_ci <- quantile(V, c(0.025, 0.975))

  expect_lt(abs(ci_res["lower"] - mc_ci[1]), 0.1)
  expect_lt(abs(ci_res["upper"] - mc_ci[2]), 0.1)
})

test_that("print method works", {
  obj <- ProductNormal3(mu = c(0.5, 0.3, 0.2), Sigma = diag(3), method = "hcubature")
  expect_output(print(obj), "ProductNormal3")
  expect_output(print(obj), "hcubature")
})

test_that("ProductNormal3 works end-to-end from a lavaan serial model", {
  skip_if_not_installed("lavaan")

  set.seed(123)
  n <- 200
  x <- rnorm(n)
  m1 <- 0.4 * x + rnorm(n)
  m2 <- 0.3 * m1 + rnorm(n)
  y <- 0.2 * m2 + rnorm(n)
  data <- data.frame(x = x, m1 = m1, m2 = m2, y = y)

  model <- "
    m1 ~ a1 * x
    m2 ~ a2 * m1
    y ~ b * m2 + cp * x
  "
  fit <- lavaan::sem(model, data = data)
  pe <- lavaan::parameterEstimates(fit, se = TRUE)

  labels <- c("a1", "a2", "b")
  idx <- match(labels, pe$label)
  mu_hat <- pe$est[idx]
  cov_hat <- lavaan::vcov(fit)[labels, labels]

  obj <- ProductNormal3(mu = mu_hat, Sigma = cov_hat, method = "hcubature")
  ci_res <- confint(obj, level = 0.95, tol = 1e-4)

  expect_named(ci_res, c("lower", "upper"))
  expect_lt(ci_res["lower"], ci_res["upper"])
})

test_that("p_prod3 rejects non-positive-definite covariance instead of hanging", {
  # Indefinite cov whose (X, Y) block is still PD (eigenvalues 1.9, 1.9, -0.8):
  # previously this entered a non-convergent integral and hung. Must error.
  bad <- matrix(c(1, .9, .9, .9, 1, -.9, .9, -.9, 1), 3)
  expect_error(p_prod3(0.5, c(0, 0, 0), bad), "positive-definite")
  # Perfect correlation between X and Y (singular (X, Y) block): previously
  # surfaced a raw Lapack error from inside the integrand. Must error cleanly.
  corr1 <- matrix(c(1, 1, .3, 1, 1, .3, .3, .3, 1), 3)
  expect_error(p_prod3(0.5, c(0, 0, 0), corr1), "positive-definite")
})

test_that("p_prod3 rejects non-positive tolerance", {
  expect_error(
    p_prod3(0.1, c(0.5, 0.3, 0.2), diag(3), tol = 0),
    "strictly positive"
  )
})

test_that("cdf lower.tail = FALSE is the complement of lower.tail = TRUE", {
  obj <- ProductNormal3(
    mu = c(0.4, 0.3, 0.2), Sigma = diag(3),
    method = "hcubature"
  )
  expect_equal(cdf(obj, 0.1, lower.tail = FALSE), 1 - cdf(obj, 0.1))
})

test_that("p_prod3 handles a negative-mean degenerate component", {
  # sds[1] = 0 with mean[1] < 0 reduces to the two-variable product with
  # lower.tail = FALSE; result must be a valid, monotone probability.
  mu <- c(-0.5, 0.3, 0.2)
  Sigma <- diag(c(0, 1, 1))
  p <- p_prod3(0.1, mu, Sigma)
  expect_gte(p, 0)
  expect_lte(p, 1)
  expect_lte(p_prod3(-1, mu, Sigma), p_prod3(1, mu, Sigma))
})

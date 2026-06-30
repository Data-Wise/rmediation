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
    "method must be 'hcubature'"
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
  obj <- ProductNormal3(mu = mu, Sigma = Sigma, method = "hcubature")

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

  # All three variables degenerate at zero -> product is identically zero.
  expect_equal(p_prod3(0, c(0, 0, 0), diag(c(0, 0, 0))), 0.5)
  expect_equal(p_prod3(1, c(0, 0, 0), diag(c(0, 0, 0))), 1)
  expect_equal(p_prod3(-1, c(0, 0, 0), diag(c(0, 0, 0))), 0)
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

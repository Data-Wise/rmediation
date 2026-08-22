test_that("pMC accepts a stacked lower-triangle Sigma vector or a full matrix", {
  set.seed(42)
  mu <- c(b1 = 1, b2 = .7, b3 = .6, b4 = .45)
  Sigma_vech <- c(.05, 0, 0, 0, .05, 0, 0, .03, 0, .03)
  Sigma_mat <- lavaan::lav_matrix_vech_reverse(Sigma_vech)

  p_vech <- pMC(.2, mu = mu, Sigma = Sigma_vech, quant = ~ b1 * b2 * b3 * b4, n.mc = 2e4)
  p_mat <- pMC(.2, mu = mu, Sigma = Sigma_mat, quant = ~ b1 * b2 * b3 * b4, n.mc = 2e4)

  expect_type(p_vech, "double")
  expect_gte(p_vech, 0)
  expect_lte(p_vech, 1)
  # Same underlying covariance, both parameterizations -> close MC estimates.
  expect_equal(p_vech, p_mat, tolerance = 0.05)
})

test_that("pMC assigns default b1, b2, ... names when mu is unnamed", {
  set.seed(42)
  Sigma_mat <- lavaan::lav_matrix_vech_reverse(c(.05, 0, 0, 0, .05, 0, 0, .03, 0, .03))
  p <- pMC(.2, mu = c(1, .7, .6, .45), Sigma = Sigma_mat, quant = ~ b1 * b2 * b3 * b4, n.mc = 2e4)

  expect_type(p, "double")
  expect_gte(p, 0)
  expect_lte(p, 1)
})

test_that("pMC(lower.tail = FALSE) is the complement of the default", {
  mu <- c(b1 = 1, b2 = .7, b3 = .6, b4 = .45)
  Sigma <- c(.05, 0, 0, 0, .05, 0, 0, .03, 0, .03)

  set.seed(7)
  p_lower <- pMC(.2, mu = mu, Sigma = Sigma, quant = ~ b1 * b2 * b3 * b4, n.mc = 2e4)
  set.seed(7)
  p_upper <- pMC(.2, mu = mu, Sigma = Sigma, quant = ~ b1 * b2 * b3 * b4, lower.tail = FALSE, n.mc = 2e4)

  expect_equal(p_lower + p_upper, 1)
})

test_that("pMC errors when Sigma's stacked length doesn't match mu", {
  expect_error(
    pMC(.2, mu = c(b1 = 1, b2 = 1), Sigma = c(.05, 0), quant = ~ b1 * b2, n.mc = 1e3),
    "must have"
  )
})

test_that("pMC errors when the quant formula references a name not in mu", {
  expect_error(
    pMC(.2, mu = c(b1 = 1, b2 = 1), Sigma = diag(2), quant = ~ b1 * bad, n.mc = 1e3),
    "must match the parameters names"
  )
})

test_that("pMC warns and caps n.mc when length(mu) * n.mc overflows integer.max", {
  mu <- c(b1 = 1, b2 = .7, b3 = .6, b4 = .45)
  expect_warning(
    p <- pMC(.2, mu = mu, Sigma = diag(4) * .05, quant = ~ b1 * b2 * b3 * b4, n.mc = 1e9),
    "n.mc is too large"
  )
  expect_gte(p, 0)
  expect_lte(p, 1)
})

test_that("qMC returns a quantile consistent with pMC on the same distribution", {
  mu <- c(b1 = 1, b2 = .7, b3 = .6, b4 = .45)
  Sigma <- c(.05, 0, 0, 0, .05, 0, 0, .03, 0, .03)

  set.seed(11)
  q <- qMC(.05, mu = mu, Sigma = Sigma, quant = ~ b1 * b2 * b3 * b4, n.mc = 5e4)
  set.seed(11)
  p_at_q <- pMC(as.numeric(q), mu = mu, Sigma = Sigma, quant = ~ b1 * b2 * b3 * b4, n.mc = 5e4)

  expect_type(q, "double")
  expect_equal(p_at_q, .05, tolerance = 0.02)
})

test_that("qMC errors when Sigma's stacked length doesn't match mu", {
  expect_error(
    qMC(.2, mu = c(b1 = 1, b2 = 1), Sigma = c(.05, 0), quant = ~ b1 * b2, n.mc = 1e3),
    "must have"
  )
})

test_that("qMC errors when the quant formula references a name not in mu", {
  expect_error(
    qMC(.2, mu = c(b1 = 1, b2 = 1), Sigma = diag(2), quant = ~ b1 * bad, n.mc = 1e3),
    "must match the parameters names"
  )
})

test_that("qMC warns and caps n.mc when length(mu) * n.mc overflows integer.max", {
  mu <- c(b1 = 1, b2 = .7, b3 = .6, b4 = .45)
  expect_warning(
    q <- qMC(.05, mu = mu, Sigma = diag(4) * .05, quant = ~ b1 * b2 * b3 * b4, n.mc = 1e9),
    "n.mc is too large"
  )
  expect_type(q, "double")
})

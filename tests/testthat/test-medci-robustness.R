# Input and boundary robustness of medci() / .ci_core() / the DOP functions (code review items).

test_that("plot and plotCI must be single non-missing flags", {
  expect_error(medci(.3, .4, .1, .1, plot = c(TRUE, FALSE)), "plot")
  expect_error(medci(.3, .4, .1, .1, plot = NA), "plot")
  expect_error(medci(.3, .4, .1, .1, plotCI = c(TRUE, TRUE)), "plotCI")
  expect_error(medci(.3, .4, .1, .1, plotCI = NA), "plotCI")
  expect_error(.ci_core(c(a = 1, b = 2), diag(2), ~ a * b, plot = c(TRUE, FALSE)), "plot")
  expect_error(.ci_core(c(a = 1, b = 2), diag(2), ~ a * b, plotCI = NA), "plotCI")
})

test_that("medci(plot = TRUE) works at perfect correlation (singular covariance)", {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_no_error(medci(.3, .4, .1, .1, rho = 1, plot = TRUE, n.mc = 2000))
  expect_no_error(medci(.3, .4, .1, .1, rho = -1, plot = TRUE, n.mc = 2000))
})

test_that("a zero standard error gives an actionable error for type = 'dop', not a numerical one", {
  expect_error(medci(.3, .4, 0, .1, type = "dop"), "positive standard errors")
  expect_error(medci(.3, .4, .1, 0, type = "all"), "positive standard errors")
  expect_error(pprodnormal(0.1, .3, .4, 0, .1), "positive standard errors")
  expect_error(qprodnormal(0.5, .3, .4, .1, 0), "positive standard errors")
  # the other methods keep working with se = 0
  expect_no_error(medci(.3, .4, 0, .1, type = "asymp"))
  expect_no_error(medci(.3, .4, 0, .1, type = "mc", n.mc = 1000))
})

test_that(".ci_core reports a missing Sigma with the intended message", {
  expect_error(.ci_core(mu = c(a = 1, b = 2), quant = ~ a * b), "cannot be a NULL value")
  expect_error(.ci_core(mu = c(a = 1, b = 2), Sigma = NULL, quant = ~ a * b), "cannot be a NULL value")
})

test_that("MC.Error is the standard error of the simulated mean, SE / sqrt(n.mc)", {
  set.seed(1)
  r <- medci(.3, .4, .1, .1, type = "mc", n.mc = 4000)
  expect_equal(r$MC.Error, r$SE / sqrt(4000))
})

test_that(".chol_psd equals chol() when chol works (same draws under a seed) and factors a singular V", {
  V <- matrix(c(1, .3, .3, 2), 2)
  expect_equal(.chol_psd(V), chol(V))
  S <- matrix(c(1, 1, 1, 1), 2) # rho = 1, singular
  R <- .chol_psd(S)
  expect_equal(crossprod(R), S, tolerance = 1e-12)
  expect_error(.chol_psd(matrix(c(1, 2, 2, 1), 2)), "not positive semi-definite")
})

test_that("medci MC results under a fixed seed are unchanged by the PSD factorization", {
  set.seed(42)
  a <- medci(.3, .4, .1, .1, rho = .5, type = "mc", n.mc = 3000)
  set.seed(42)
  m <- c(.3, .4)
  V <- matrix(c(.01, .5 * .01, .5 * .01, .01), 2)
  z <- matrix(rnorm(2 * 3000), ncol = 3000)
  ab <- t(crossprod(chol(V), z) + m)
  ab <- ab[, 1] * ab[, 2]
  expect_equal(a$Estimate, mean(ab))
})

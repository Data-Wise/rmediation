# The asymptotic interval is named for its confidence level, 100 * (1 - alpha), as in medci() (issue #123).
# It was named 100 * (1 - alpha / 2), so the default 95% interval was labeled "97.5% CI".
test_that("ci(type = 'asymp') names the interval by its confidence level", {
  mu <- c(a = 0.5, b = 0.6)
  Sigma <- c(0.0064, 0, 0.0016)
  for (case in list(c(0.05, "95% CI"), c(0.10, "90% CI"), c(0.01, "99% CI"))) {
    alpha <- as.numeric(case[1])
    r <- ci(mu, Sigma = Sigma, quant = ~ a * b, type = "asymp", alpha = alpha)
    expect_identical(names(r)[1], case[2], info = paste("alpha =", alpha))
    # The label must describe the interval that is returned: half-width = qnorm(1 - alpha / 2) * SE.
    expect_equal((r[[1]][2] - r[[1]][1]) / 2, qnorm(1 - alpha / 2) * as.numeric(r[["SE"]]), tolerance = 1e-10,
                 info = paste("alpha =", alpha))
  }
})

test_that("ci(type = 'asymp') and medci(type = 'asymp') use the same label", {
  r1 <- ci(c(a = 0.5, b = 0.6), Sigma = c(0.0064, 0, 0.0016), quant = ~ a * b, type = "asymp", alpha = 0.10)
  r2 <- medci(0.5, 0.6, 0.08, 0.04, alpha = 0.10, type = "asymp")
  expect_identical(names(r1)[1], names(r2)[1])
})

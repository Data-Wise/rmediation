# The Monte Carlo result of ci() carries a `p` element (documented in ?ci).
# It is recomputed here from the same draws, so a change to its definition fails.

test_that("p is the two-sided sign proportion of the simulated estimate", {
  mu <- c(a = .3, b = .25)
  Sigma <- diag(c(.02, .02))
  set.seed(11)
  result <- ci(mu, Sigma, quant = ~ a * b, type = "MC", n.mc = 5000)
  set.seed(11)
  draws <- MASS::mvrnorm(5000, mu, Sigma)
  positive <- mean(draws[, 1] * draws[, 2] > 0)
  expect_identical(names(result), c("", "Estimate", "SE", "MCError", "p"))
  expect_equal(result$p, 2 * min(positive, 1 - positive), tolerance = 1e-12)
  expect_gt(result$p, 0)
  expect_lt(result$p, 1)
})

test_that("p is 0 when every draw has the same sign, so it is not a null test", {
  set.seed(12)
  result <- ci(c(a = 5, b = 4), diag(c(.01, .01)),
    quant = ~ a * b, type = "MC", n.mc = 2000
  )
  expect_identical(result$p, 0)
})

test_that("only the Monte Carlo result has p; the asymptotic result does not", {
  asymptotic <- ci(c(a = .5, b = .4), diag(c(.01, .01)),
    quant = ~ a * b, type = "asymp"
  )
  expect_null(asymptotic$p)
  expect_identical(names(asymptotic)[2:3], c("Estimate", "SE"))
})

# ci(<ProductNormal>, type = "dop") must agree with medci() everywhere. The S7 core used to
# carry its own copy of the Meeker integral over (-Inf, Inf) (issue #60's bug), so it errored
# at standardized means >= ~20 where medci() was already fixed.

.pn2 <- function(mx, my, sx, sy, rho = 0) {
  ProductNormal(mu = c(mx, my), Sigma = matrix(c(sx^2, rho * sx * sy, rho * sx * sy, sy^2), 2))
}

test_that("ci(ProductNormal, 'dop') works at large standardized means and matches medci()", {
  s7 <- ci(.pn2(20, 20, 1, 1), type = "dop")
  legacy <- medci(20, 20, 1, 1, type = "dop")
  expect_equal(unname(s7$CI), unname(legacy[[1]]), tolerance = 1e-8)
})

test_that("S7 and medci() DOP intervals agree across correlation and scale", {
  for (rho in c(-0.7, 0, 0.9)) {
    for (m in list(c(0.2, 0.4, 1, 1), c(0.5, 0.3, 0.2, 0.4), c(-0.3, 0.6, 0.5, 0.1))) {
      s7 <- ci(.pn2(m[1], m[2], m[3], m[4], rho), type = "dop")
      legacy <- medci(m[1], m[2], m[3], m[4], rho, type = "dop")
      expect_equal(unname(s7$CI), unname(legacy[[1]]), tolerance = 1e-8)
      expect_equal(s7$Estimate, legacy$Estimate)
    }
  }
})

test_that("the S7 quantile helper equals qprodnormal() for both tails", {
  for (lt in c(TRUE, FALSE)) {
    expect_equal(
      .compute_quantile_dop_internal(0.025, 0.5, 0.3, 0.2, 0.4, 0.3, lower.tail = lt)$q,
      qprodnormal(0.025, 0.5, 0.3, 0.2, 0.4, 0.3, lower.tail = lt),
      tolerance = 1e-10
    )
  }
})

# The upper tail P(XY > q) is integrated directly (the lower-tail integrand with the sign of the
# conditional probability flipped), not computed as 1 - P(XY <= q), which cancels below ~1e-10.
# Independent oracle: the exact reflection P(XY > q; mu.x, mu.y, rho) = P(XY < -q; -mu.x, mu.y, -rho),
# which evaluates the same probability through the LOWER-tail path.

U <- function(q, rho = 0.3, ...) pprodnormal(q, 0.5, 0.3, 0.2, 0.4, rho, lower.tail = FALSE, ...)
L_reflected <- function(q, rho = 0.3) pprodnormal(-q, -0.5, 0.3, 0.2, 0.4, -rho)

test_that("the upper tail equals its lower-tail reflection deep in the tail (relative 1e-6)", {
  for (q in c(2, 3, 4, 5)) {
    for (rho in c(-0.6, 0, 0.3, 0.8)) {
      ref <- L_reflected(q, rho)
      expect_gt(ref, 0)
      expect_equal(U(q, rho) / ref, 1, tolerance = 1e-6, info = paste("q", q, "rho", rho))
    }
  }
})

test_that("it resolves probabilities far below 1 - machine epsilon", {
  p <- U(5)
  expect_lt(p, 1e-12)
  expect_gt(p, 0)
})

test_that("in the bulk it still equals 1 - lower to near machine precision", {
  for (q in c(-0.2, 0, 0.1, 0.3)) {
    expect_equal(U(q), 1 - pprodnormal(q, 0.5, 0.3, 0.2, 0.4, 0.3), tolerance = 1e-9)
  }
})

test_that("the upper tail is positive, monotone decreasing and at most 1", {
  q <- seq(-1, 6, by = 0.5)
  p <- U(q)
  expect_true(all(p >= 0 & p <= 1))
  expect_true(all(diff(p) <= 0))
})

test_that("qprodnormal(lower.tail = FALSE) round-trips at tiny upper-tail probabilities", {
  for (p in c(1e-6, 1e-10, 1e-14, 1e-18)) {
    q <- qprodnormal(p, 0.5, 0.3, 0.2, 0.4, 0.3, lower.tail = FALSE)
    expect_equal(U(q) / p, 1, tolerance = 1e-5, info = paste("p", p))
  }
})

test_that("the upper-tail quantile equals the lower-tail quantile of the reflected problem", {
  p <- 1e-14
  qu <- qprodnormal(p, 0.5, 0.3, 0.2, 0.4, 0.3, lower.tail = FALSE)
  ql <- qprodnormal(p, -0.5, 0.3, 0.2, 0.4, -0.3, lower.tail = TRUE)
  expect_equal(qu, -ql, tolerance = 1e-6)
})

test_that("vectorized upper tails agree with element-wise calls", {
  q <- c(0, 2, 4)
  expect_equal(U(q), vapply(q, U, numeric(1)), tolerance = 1e-12)
})

test_that("the DOP interval upper bound uses the direct tail (CI at alpha = 1e-12)", {
  r <- medci(0.5, 0.3, 0.2, 0.4, 0.3, alpha = 1e-12, type = "dop")
  expect_equal(U(r[[1]][2]) / 5e-13, 1, tolerance = 1e-5)
})

test_that("perfect correlation (a point-mass conditional) gives finite tails in both directions", {
  for (rho in c(-1, 1)) {
    lo <- pprodnormal(0.1, 0.3, 0.4, 0.1, 0.1, rho)
    up <- pprodnormal(0.1, 0.3, 0.4, 0.1, 0.1, rho, lower.tail = FALSE)
    expect_true(is.finite(lo) && is.finite(up))
    expect_equal(lo + up, 1, tolerance = 1e-8)
  }
  expect_no_error(medci(0.3, 0.4, 0.1, 0.1, rho = -1, type = "dop"))
})

# pprodnormal() is vectorized over q and qprodnormal() over p. Scalar calls are unchanged.

args <- list(mu.x = 0.5, mu.y = 0.3, se.x = 0.2, se.y = 0.4, rho = 0.3)
P <- function(q, ...) do.call(pprodnormal, c(list(q), args, list(...)))
Q <- function(p, ...) do.call(qprodnormal, c(list(p), args, list(...)))

test_that("pprodnormal(dop) over a vector equals element-wise scalar calls", {
  q <- c(-0.1, 0, 0.05, 0.15, 0.4)
  expect_equal(P(q), vapply(q, P, numeric(1)), tolerance = 1e-12)
  expect_length(P(q), length(q))
})

test_that("qprodnormal(dop) over a vector equals element-wise scalar calls", {
  p <- c(0.025, 0.25, 0.5, 0.9)
  expect_equal(Q(p), vapply(p, Q, numeric(1)), tolerance = 1e-12)
  expect_true(all(diff(Q(p)) > 0))
})

test_that("lower.tail is applied element-wise", {
  q <- c(0, 0.1, 0.3)
  expect_equal(P(q, lower.tail = FALSE), 1 - P(q), tolerance = 1e-12)
  p <- c(0.1, 0.5)
  expect_equal(Q(p, lower.tail = FALSE), Q(1 - p), tolerance = 1e-8)
})

test_that("a vector round-trips through p and q", {
  p <- c(0.05, 0.4, 0.95)
  expect_equal(P(Q(p)), p, tolerance = 1e-5)
})

test_that("scalar results keep their previous shape", {
  expect_type(P(0.1), "double")
  expect_length(P(0.1), 1L)
  expect_named(P(0.1, type = "all"), c("Distribution of Product", "Monte Carlo"))
  expect_named(Q(0.5, type = "all"), c("Distribution of Product", "Monte Carlo"))
})

test_that("type = 'all' returns two vectors for a vector input", {
  set.seed(1)
  r <- P(c(0, 0.1, 0.2), type = "all", n.mc = 20000)
  expect_named(r, c("Distribution of Product", "Monte Carlo"))
  expect_length(r[[1]], 3L)
  expect_length(r[[2]], 3L)
  expect_equal(r[[2]], r[[1]], tolerance = 0.02)
})

test_that("type = 'MC' over a vector shares one sample: monotone, and equal to the scalar call at length 1", {
  q <- c(-0.1, 0, 0.1, 0.2, 0.3)
  set.seed(7)
  v <- P(q, type = "MC", n.mc = 20000)
  expect_true(all(diff(v) >= 0))
  set.seed(7)
  s <- P(0.1, type = "MC", n.mc = 20000)
  set.seed(7)
  one <- P(c(0.1), type = "MC", n.mc = 20000)
  expect_equal(one, s)
  set.seed(3)
  pv <- Q(c(0.1, 0.5, 0.9), type = "MC", n.mc = 20000)
  expect_true(all(diff(pv) > 0))
})

test_that("invalid vector elements and empty input are rejected", {
  expect_error(P(numeric(0)))
  expect_error(P(c(0, NA)))
  expect_error(P(c(0, Inf)))
  expect_error(Q(c(0.5, 1.5)))
  expect_error(Q(c(0.5, -0.1)))
  expect_error(Q(numeric(0)))
})

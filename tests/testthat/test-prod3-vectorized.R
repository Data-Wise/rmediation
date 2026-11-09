# pprodnormal3() takes a vector of quantiles, like pprodnormal(), dprodnormal(), qprodnormal() and
# dprodnormal3(). A length-one q keeps the old scalar path (same value, same error messages, no names
# or attributes unless diagnostics = TRUE).

m3 <- c(1, 1, 1)
S3 <- diag(3)

test_that("a vector q equals the scalar call at each element, in the order given", {
  q <- c(2, -1, 1, 0, 0.5)
  vec <- pprodnormal3(q, m3, S3)
  scal <- vapply(q, function(x) pprodnormal3(x, m3, S3), numeric(1))
  expect_equal(vec, scal)
  expect_length(vec, length(q))
  expect_null(attributes(vec)) # a bare numeric, like the scalar call
  # the order of q is kept: the unsorted input gives the matching permutation of the sorted result
  srt <- sort(q)
  expect_equal(pprodnormal3(srt, m3, S3)[order(order(q))], vec)
})

test_that("a vector q agrees with the empirical CDF of simulated products (independent oracle)", {
  skip_if_not_installed("MASS")
  mu <- c(0.8, 1.1, 0.9)
  Sg <- matrix(c(0.5, 0.1, 0, 0.1, 0.4, 0.05, 0, 0.05, 0.3), 3)
  q <- c(-0.5, 0, 0.4, 0.9, 1.5)
  set.seed(31)
  x <- MASS::mvrnorm(3e5, mu, Sg)
  emp <- vapply(q, function(v) mean(x[, 1] * x[, 2] * x[, 3] <= v), numeric(1))
  expect_lt(max(abs(pprodnormal3(q, mu, Sg) - emp)), 0.01)
})

test_that("known answers and bounds hold across a vector q", {
  # a symmetric centered product is below 0 half the time
  expect_equal(pprodnormal3(c(0, 0), c(0, 0, 0), S3), c(0.5, 0.5), tolerance = 1e-5)
  sorted_q <- seq(-2, 4, length.out = 9)
  p <- pprodnormal3(sorted_q, m3, S3)
  expect_true(all(p >= 0 & p <= 1))
  expect_false(is.unsorted(p)) # a CDF never decreases
})

test_that("a length-one q is unchanged: bare numeric, same value as the vector call", {
  one <- pprodnormal3(1, m3, S3)
  expect_null(attributes(one))
  expect_equal(pprodnormal3(c(1, 1), m3, S3), c(one, one))
  expect_equal(p_prod3(c(0, 1), m3, S3), pprodnormal3(c(0, 1), m3, S3)) # the alias takes vectors too
})

test_that("names of q are kept on a vector result", {
  expect_named(pprodnormal3(c(lo = 0, hi = 2), m3, S3), c("lo", "hi"))
})

test_that("point-mass covariances give the right-continuous CDF at every element", {
  expect_equal(pprodnormal3(c(0.5, 1, 2), m3, matrix(0, 3, 3)), c(0, 1, 1))
})

test_that("diagnostics = TRUE returns per-element error and nodes matching the scalar calls", {
  q <- c(-0.5, 0.5, 1.5)
  vec <- pprodnormal3(q, m3, S3, diagnostics = TRUE)
  expect_length(attr(vec, "error"), length(q))
  expect_length(attr(vec, "nodes"), length(q))
  for (i in seq_along(q)) {
    one <- pprodnormal3(q[i], m3, S3, diagnostics = TRUE)
    expect_equal(as.numeric(vec[i]), as.numeric(one))
    expect_equal(attr(vec, "error")[i], attr(one, "error"))
    expect_equal(attr(vec, "nodes")[i], attr(one, "nodes"))
  }
  # a point mass has no quadrature, so there is nothing to report: NA, not an error
  pm <- pprodnormal3(c(0.5, 2), m3, matrix(0, 3, 3), diagnostics = TRUE)
  expect_equal(as.numeric(pm), c(0, 1))
  expect_true(all(is.na(attr(pm, "error"))))
})

test_that("diagnostics work on the hcubature path too (its own error estimate, nodes NA)", {
  skip_if_not_installed("cubature")
  q <- c(0.5, 1.5)
  vec <- pprodnormal3(q, m3, S3, method = "hcubature", diagnostics = TRUE)
  expect_length(attr(vec, "error"), 2L)
  expect_true(all(is.finite(attr(vec, "error"))))
  expect_true(all(is.na(attr(vec, "nodes"))))
  expect_equal(as.numeric(vec[2]), as.numeric(pprodnormal3(1.5, m3, S3, method = "hcubature")))
})

test_that("invalid q is rejected: NA, infinite, empty; the scalar messages are unchanged", {
  expect_error(pprodnormal3(c(0, NA), m3, S3), "q")
  expect_error(pprodnormal3(c(0, Inf), m3, S3), "q")
  expect_error(pprodnormal3(numeric(0), m3, S3), "q")
  expect_error(pprodnormal3(NA_real_, m3, S3), "May not be NA")
})

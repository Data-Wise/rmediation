# dist_quantile(<ProductNormal>, p) accepts a vector of probabilities (issue #176).

object <- ProductNormal(mu = c(.4, .5), Sigma = diag(c(.01, .02)))
ps <- c(.025, .5, .975)

test_that("a vector p gives one quantile per element, equal to the scalar calls", {
  for (lt in c(TRUE, FALSE)) {
    vec <- dist_quantile(object, ps, lower.tail = lt)
    one <- vapply(ps, function(pp) dist_quantile(object, pp, lower.tail = lt), numeric(1))
    expect_length(vec, 3L)
    expect_equal(vec, one, tolerance = 1e-12)
  }
})

test_that("the vector result is the exact quantile function, in order", {
  vec <- dist_quantile(object, ps)
  expect_equal(vec, qprodnormal(ps, .4, .5, sqrt(.01), sqrt(.02), rho = 0), tolerance = 1e-6)
  expect_false(is.unsorted(vec, strictly = TRUE))
})

test_that("names of p are kept and the scalar call is unchanged", {
  named <- dist_quantile(object, c(lo = .025, hi = .975))
  expect_identical(names(named), c("lo", "hi"))
  expect_equal(dist_quantile(object, .5), 0.193156, tolerance = 1e-5) # value from before the change
})

test_that("type = 'mc' and type = 'all' accept a vector p", {
  set.seed(5)
  mc_vec <- dist_quantile(object, ps, type = "mc", n.mc = 5000)
  mc_one <- vapply(ps, function(pp) {
    set.seed(5)
    dist_quantile(object, pp, type = "mc", n.mc = 5000)
  }, numeric(1))
  expect_equal(mc_vec, mc_one)
  all <- dist_quantile(object, ps, type = "all", n.mc = 5000)
  expect_length(all$dop$q, 3L)
})

test_that("an invalid p is rejected", {
  expect_error(dist_quantile(object, c(.5, 1.5)))
  expect_error(dist_quantile(object, c(.5, NA)))
})

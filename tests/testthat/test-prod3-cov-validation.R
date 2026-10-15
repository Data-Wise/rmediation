# Codex adversarial review: pprodnormal3() clamped negative variances to 0 and the degenerate
# branches returned before any covariance check, so invalid matrices gave plausible probabilities.
m <- c(1, 0.5, 0.5)

test_that("invalid covariance matrices are rejected on every branch", {
  # negative variance: all random, one fixed, two fixed, three fixed
  expect_error(pprodnormal3(0.1, m, diag(c(-1, 1, 1))), "positive semidefinite")
  expect_error(pprodnormal3(0.1, m, diag(c(-1, 1, 0))), "positive semidefinite")
  expect_error(pprodnormal3(0.1, m, diag(c(-1, 0, 0))), "positive semidefinite")
  # a zero-variance component with a nonzero covariance
  S <- matrix(c(1, 0.9, 0, 0.9, 0, 0, 0, 0, 0), 3)
  expect_error(pprodnormal3(0.1, m, S), "positive semidefinite")
  # indefinite (correlation above 1)
  expect_error(pprodnormal3(0.1, m, matrix(c(1, 2, 0, 2, 1, 0, 0, 0, 1), 3)), "positive semidefinite")
  # non-finite
  bad <- diag(3)
  bad[1, 2] <- bad[2, 1] <- NaN
  expect_error(pprodnormal3(0.1, m, bad), "finite")
})

test_that("tolerance is relative: a tiny-scale negative variance is still rejected", {
  expect_error(pprodnormal3(0.1, m, diag(c(1e-6, 1e-6, -1e-6))), "positive semidefinite")
})

test_that("valid singular and ill-conditioned matrices still pass", {
  expect_no_error(pprodnormal3(0.1, m, diag(c(1, 0, 0))))
  expect_no_error(pprodnormal3(0.1, m, diag(c(0, 0, 0))))
  expect_no_error(pprodnormal3(0.1, m, diag(3)))
})

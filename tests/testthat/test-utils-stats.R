# Reference values below are hand-computed from the documented formulas
# (SAS/SPSS type-2 adjusted skewness/kurtosis), independent of e1071 (which
# this internal implementation replaces and which is no longer a dependency).
test_that(".skewness matches the type-2 (SAS/SPSS) formula", {
  x <- c(2, 4, 4, 4, 5, 5, 7, 9)
  n <- length(x)
  m <- mean(x)
  s <- sqrt(sum((x - m)^2) / n)
  g1 <- sum((x - m)^3) / (n * s^3)

  expect_equal(.skewness(x, type = 1), g1)
  expect_equal(.skewness(x, type = 2), g1 * sqrt(n * (n - 1)) / (n - 2))
  expect_equal(.skewness(x, type = 3), g1 * ((n - 1) / n)^(3 / 2))
  expect_equal(.skewness(x, type = 99), g1) # falls through to the raw g1 default
})

test_that(".skewness handles edge cases", {
  expect_equal(.skewness(c(1, 2)), NA_real_) # n < 3
  expect_equal(.skewness(c(5, 5, 5, 5)), NA_real_) # zero variance
  x <- c(2, 4, 4, 4, 5, 5, 7, 9)
  expect_equal(.skewness(c(x, NA), na.rm = TRUE), .skewness(x))
})

test_that(".kurtosis matches the type-2 (SAS/SPSS) formula", {
  x <- c(2, 4, 4, 4, 5, 5, 7, 9)
  n <- length(x)
  m <- mean(x)
  s2 <- sum((x - m)^2) / n
  m4 <- sum((x - m)^4) / n
  g2 <- m4 / s2^2 - 3

  expect_equal(.kurtosis(x, type = 1), g2)
  expect_equal(.kurtosis(x, type = 2), ((n + 1) * g2 + 6) * (n - 1) / ((n - 2) * (n - 3)))
  expect_equal(.kurtosis(x, type = 3), (g2 + 3) * ((n - 1) / n)^2 - 3)
  expect_equal(.kurtosis(x, type = 99), g2) # falls through to the raw g2 default
})

test_that(".kurtosis handles edge cases", {
  expect_equal(.kurtosis(c(1, 2, 3)), NA_real_) # n < 4
  expect_equal(.kurtosis(c(5, 5, 5, 5, 5)), NA_real_) # zero variance
  x <- c(2, 4, 4, 4, 5, 5, 7, 9)
  expect_equal(.kurtosis(c(x, NA), na.rm = TRUE), .kurtosis(x))
})

test_that(".resample_bootstrap draws n rows with replacement, reproducibly", {
  df <- data.frame(a = 1:5, b = letters[1:5])

  set.seed(99)
  r1 <- .resample_bootstrap(df)
  set.seed(99)
  r2 <- .resample_bootstrap(df)

  expect_identical(r1, r2)
  expect_equal(nrow(r1), nrow(df))
  expect_identical(names(r1), names(df))
  # With replacement: not every draw needs to be a permutation of 1:5.
  expect_true(all(r1$a %in% df$a))
})

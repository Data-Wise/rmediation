test_that("ProductNormal2 builds a ProductNormal from a matrix Sigma", {
  pn <- ProductNormal2(mu = c(0.5, 0.3), Sigma = diag(2) * 0.1)

  expect_true(S7::S7_inherits(pn, ProductNormal))
  expect_equal(pn@mu, c(0.5, 0.3))
  expect_equal(pn@Sigma, diag(2) * 0.1)
})

test_that("ProductNormal2 builds a ProductNormal from a vech Sigma vector", {
  pn <- ProductNormal2(mu = c(0.5, 0.3, 0.2), Sigma = c(.1, 0, 0, .1, 0, .1))

  expect_true(S7::S7_inherits(pn, ProductNormal))
  expect_equal(pn@mu, c(0.5, 0.3, 0.2))
})

test_that("ProductNormal2 rejects mu with fewer than 2 elements", {
  expect_error(ProductNormal2(mu = 0.5, Sigma = diag(1)), "at least 2 elements")
})

test_that("ProductNormal2 rejects a vech Sigma of the wrong length", {
  expect_error(
    ProductNormal2(mu = c(.5, .3), Sigma = c(1, 2, 3, 4)),
    "expected 3 elements"
  )
})

test_that("ProductNormal2 rejects a non-square Sigma matrix", {
  expect_error(
    ProductNormal2(mu = c(.5, .3), Sigma = matrix(1:6, nrow = 2)),
    "square matrix"
  )
})

test_that("ProductNormal2 rejects Sigma/mu dimension mismatch", {
  expect_error(
    ProductNormal2(mu = c(.5, .3, .1), Sigma = diag(2)),
    "Dimensions of Sigma must match length of mu"
  )
})

test_that("validate_ProductNormal accepts a well-formed object and rejects others", {
  pn <- ProductNormal2(mu = c(0.5, 0.3), Sigma = diag(2) * 0.1)
  expect_true(validate_ProductNormal(pn))
  expect_error(validate_ProductNormal(list(mu = 1)), "not of class ProductNormal")
})

test_that("validate_ProductNormal rejects NA/infinite mu", {
  pn_na <- ProductNormal(mu = c(NA_real_, .3), Sigma = diag(2))
  expect_error(validate_ProductNormal(pn_na), "NA or infinite values")
})

test_that("is_valid_for_computation returns FALSE for non-ProductNormal input", {
  expect_false(is_valid_for_computation(list(mu = 1)))
})

test_that("is_valid_for_computation returns TRUE for a well-formed object", {
  pn <- ProductNormal2(mu = c(0.5, 0.3), Sigma = diag(2) * 0.1)
  expect_true(is_valid_for_computation(pn))
})

test_that("is_valid_for_computation warns on very large parameter values", {
  pn_large <- ProductNormal(mu = c(1e7, 1), Sigma = diag(2))
  expect_warning(
    result <- is_valid_for_computation(pn_large),
    "Very large parameter values"
  )
  expect_true(result)
})

test_that("ProductNormal_from_lavaan extracts named coefficients into a ProductNormal", {
  skip_if_not_installed("lavaan")

  set.seed(1234)
  X <- rnorm(100)
  M <- 0.5 * X + rnorm(100)
  Y <- 0.7 * M + rnorm(100)
  Data <- data.frame(X = X, M = M, Y = Y)
  model <- "
    Y ~ b*M
    M ~ a*X
    ab := a*b
  "
  fit <- lavaan::sem(model, data = Data)

  pn <- ProductNormal_from_lavaan(fit, c("a", "b"))

  expect_true(S7::S7_inherits(pn, ProductNormal))
  # ProductNormal_from_lavaan() strips names via as.numeric() before
  # constructing the object (R/utils_validation.R), so @mu is unnamed.
  expect_equal(pn@mu, unname(lavaan::coef(fit)[c("a", "b")]))
})

test_that("ProductNormal_from_lavaan rejects a non-lavaan model", {
  expect_error(ProductNormal_from_lavaan(list(), c("a", "b")), "must be a lavaan object")
})

test_that("ProductNormal_from_lavaan errors when a requested parameter is missing", {
  skip_if_not_installed("lavaan")

  set.seed(1234)
  X <- rnorm(100)
  M <- 0.5 * X + rnorm(100)
  Y <- 0.7 * M + rnorm(100)
  Data <- data.frame(X = X, M = M, Y = Y)
  model <- "
    Y ~ b*M
    M ~ a*X
    ab := a*b
  "
  fit <- lavaan::sem(model, data = Data)

  expect_error(
    ProductNormal_from_lavaan(fit, c("a", "zzz")),
    "Parameters not found in model: zzz"
  )
})

# Guards in validate_ProductNormal(), is_valid_for_computation(), ProductNormal_from_lavaan()
# and ci()'s input handling. Each test plants the defect the guard exists for, so a deleted
# or weakened guard fails the test.

.pn_ok <- function() ProductNormal(mu = c(0.5, 0.3), Sigma = diag(2) * 0.1)

# Assign a slot without running the class validator, to reach guards the constructor pre-empts.
.pn_with <- function(prop, value) {
  obj <- .pn_ok()
  S7::prop(obj, prop, check = FALSE) <- value
  obj
}

test_that("validate_ProductNormal accepts a valid object", {
  expect_true(validate_ProductNormal(.pn_ok()))
})

test_that("validate_ProductNormal rejects a non-ProductNormal", {
  expect_error(validate_ProductNormal(list()), "not of class ProductNormal")
})

test_that("validate_ProductNormal rejects each malformed slot", {
  expect_error(validate_ProductNormal(.pn_with("mu", 1)), "at least 2 elements")
  expect_error(validate_ProductNormal(.pn_with("mu", c("a", "b"))), "mu must be numeric")
  expect_error(validate_ProductNormal(.pn_with("Sigma", c(1, 0, 0, 1))), "Sigma must be a matrix")
  expect_error(
    validate_ProductNormal(.pn_with("Sigma", matrix(1, 2, 3))),
    "square matrix"
  )
  expect_error(
    validate_ProductNormal(.pn_with("Sigma", diag(3))),
    "Dimensions of Sigma must match"
  )
  expect_error(
    validate_ProductNormal(.pn_with("Sigma", matrix(c(1, 2, 2, 1), 2))),
    "positive semi-definite.*Smallest eigenvalue"
  )
  expect_error(
    validate_ProductNormal(.pn_with("Sigma", matrix(c(1, NA, NA, 1), 2))),
    "Cannot compute eigenvalues"
  )
  expect_error(
    validate_ProductNormal(.pn_with("mu", c(NA_real_, 1))),
    "mu contains NA"
  )
})

test_that("is_valid_for_computation rejects a non-ProductNormal and an indefinite Sigma", {
  expect_false(is_valid_for_computation(list()))
  expect_false(is_valid_for_computation(.pn_with("Sigma", matrix(c(1, 2, 2, 1), 2))))
  expect_true(is_valid_for_computation(.pn_ok()))
})

test_that("is_valid_for_computation rejects a Sigma whose eigenvalues cannot be computed", {
  expect_false(is_valid_for_computation(.pn_with("Sigma", matrix(c(1, NA, NA, 1), 2))))
})

test_that("is_valid_for_computation warns on very large values", {
  expect_warning(
    is_valid_for_computation(ProductNormal(mu = c(2e6, 1), Sigma = diag(2))),
    "Very large parameter values"
  )
})

test_that("ProductNormal_from_lavaan rejects a non-lavaan input", {
  expect_error(ProductNormal_from_lavaan(1, c("a", "b")), "must be a lavaan object")
})

test_that("ProductNormal_from_lavaan rejects missing parameter names", {
  skip_if_not_installed("lavaan")
  set.seed(1)
  d <- data.frame(x = rnorm(100))
  d$m <- 0.4 * d$x + rnorm(100)
  d$y <- 0.3 * d$m + rnorm(100)
  fit <- lavaan::sem("m ~ a*x\n y ~ b*m", data = d)
  expect_error(ProductNormal_from_lavaan(fit, c("a", "zz")), "not found in model: zz")
  pn <- ProductNormal_from_lavaan(fit, c("a", "b"))
  expect_equal(pn@mu, unname(lavaan::coef(fit)[c("a", "b")]))
})

# --- .ci_core() input handling -----------------------------------------------------------------

test_that("`.ci_core()` requires Sigma when mu is not a lavaan fit", {
  expect_error(
    .ci_core(mu = c(a = 1, b = 2), Sigma = NULL, quant = ~ a * b),
    "cannot be a NULL value"
  )
})

test_that("`.ci_core()` rejects a vech Sigma of the wrong length with the expected size", {
  expect_error(
    .ci_core(mu = c(a = 1, b = 2), Sigma = c(1, 0, 0, 1), quant = ~ a * b, type = "asymp"),
    "must have +3 elements, instead of 4"
  )
})

test_that("`.ci_core()` rejects a formula naming parameters absent from a lavaan fit", {
  skip_if_not_installed("lavaan")
  set.seed(1)
  d <- data.frame(x = rnorm(100))
  d$m <- 0.4 * d$x + rnorm(100)
  d$y <- 0.3 * d$m + rnorm(100)
  fit <- lavaan::sem("m ~ a*x\n y ~ b*m", data = d)
  expect_error(.ci_core(fit, quant = ~ a * zz), "must match the parameters names provided in lavaan")
})

test_that("`.ci_core()` resets an n.mc that would overflow the draw matrix, with a warning", {
  expect_warning(
    res <- .ci_core(
      mu = c(a = 1, b = 2), Sigma = diag(2) * 0.01, quant = ~ a * b,
      type = "mc", n.mc = 2e9
    ),
    "n.mc is too large. It is reset to 1e\\+06"
  )
  expect_equal(unname(res$Estimate), 2, tolerance = 1e-3)
})

# --- medfit method registration ------------------------------------------------------------

test_that(".register_medfit_methods() reports a registration failure without raising", {
  skip_if_not_installed("medfit")
  testthat::local_mocked_bindings(
    .register_semfit_mbco = function() stop("boom"),
    .package = "RMediation"
  )
  expect_message(
    .register_medfit_methods(),
    "failed to register medfit S7 methods: boom"
  )
})

test_that(".register_medfit_methods() registers ci methods for medfit classes", {
  skip_if_not_installed("medfit")
  testthat::local_mocked_bindings(.register_semfit_mbco = function() invisible(NULL), .package = "RMediation")
  expect_no_error(suppressMessages(.register_medfit_methods()))
  expect_true(is.function(S7::method(ci, medfit::MediationData)))
})

# --- edge cases --------------------------------------------------------------------------

test_that("validate_ProductNormal tolerates eigenvalues within -1e-10 and rejects beyond", {
  near <- .pn_with("Sigma", diag(c(1, -1e-11)))
  far <- .pn_with("Sigma", diag(c(1, -1e-9)))
  expect_true(validate_ProductNormal(near))
  expect_error(validate_ProductNormal(far), "positive semi-definite")
})

test_that("validate_ProductNormal rejects infinite mu and Sigma entries", {
  expect_error(validate_ProductNormal(.pn_with("mu", c(Inf, 1))), "NA or infinite")
  # Inf in Sigma makes eigen() fail before the entry check is reached
  expect_error(validate_ProductNormal(.pn_with("Sigma", diag(c(Inf, 1)))))
})

test_that("ProductNormal2 skips extra validation only when validate = FALSE", {
  bad <- diag(c(1, -1e-9))
  expect_s7_class <- function(x) expect_true(S7::S7_inherits(x, ProductNormal))
  expect_s7_class(ProductNormal2(c(1, 2), bad, validate = FALSE))
  expect_error(ProductNormal2(c(1, 2), bad, validate = TRUE), "positive semi-definite")
})

test_that("ProductNormal2 rejects non-numeric mu and non-numeric Sigma", {
  expect_error(ProductNormal2(c("a", "b"), diag(2)), "mu must be numeric")
  expect_error(ProductNormal2(c(1, 2), "x"), "Sigma must be a matrix or numeric vector")
})

test_that("is_valid_for_computation boundary: -1e-9 passes, -1e-7 fails", {
  expect_true(is_valid_for_computation(.pn_with("Sigma", diag(c(1, -1e-9)))))
  expect_false(is_valid_for_computation(.pn_with("Sigma", diag(c(1, -1e-7)))))
})

test_that(".ci_core rejects out-of-range alpha, bad type and non-positive n.mc", {
  mu <- c(a = 1, b = 2)
  S <- diag(2) * 0.01
  expect_error(.ci_core(mu, S, ~ a * b, alpha = 1.5))
  expect_error(.ci_core(mu, S, ~ a * b, alpha = NA_real_))
  expect_error(.ci_core(mu, S, ~ a * b, type = "bogus"))
  expect_error(.ci_core(mu, S, ~ a * b, n.mc = 0))
  expect_error(.ci_core(mu, S, ~ a * b, n.mc = 10.5))
})

test_that(".ci_core rejects non-finite mu and a Sigma of the wrong dimension", {
  S <- diag(2) * 0.01
  expect_error(.ci_core(c(a = Inf, b = 2), S, ~ a * b))
  expect_error(.ci_core(c(a = 1, b = 2), diag(3), ~ a * b))
})

test_that(".ci_core rejects a formula naming parameters absent from mu", {
  expect_error(
    .ci_core(c(a = 1, b = 2), diag(2) * 0.01, ~ a * zz, type = "asymp"),
    "must match the parameters names provided in"
  )
})

test_that(".ci_core names unnamed mu b1, b2 so a formula in those names works", {
  res <- .ci_core(c(1, 2), diag(2) * 0.01, ~ b1 * b2, type = "asymp")
  expect_equal(unname(res[["Estimate"]]), 2)
})

test_that(".ci_core accepts a vech Sigma of the right length", {
  res <- .ci_core(c(a = 1, b = 2), c(0.01, 0, 0.01), ~ a * b, type = "asymp")
  expect_equal(unname(res[["Estimate"]]), 2)
})

test_that(".ci_core H0 validates mu0 length and Sigma0 type", {
  mu <- c(a = 1, b = 2)
  S <- diag(2) * 0.01
  expect_error(.ci_core(mu, S, ~ a * b, H0 = TRUE, mu0 = c(0, 0, 0)))
  expect_error(.ci_core(mu, S, ~ a * b, H0 = TRUE, Sigma0 = "x"))
})

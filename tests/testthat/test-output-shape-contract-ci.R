# Output-shape contract for ci() and ci_mediation_data(), the surface the
# sibling package missingmed actually uses (R/infer.R reads `r[[1L]]`,
# `$Estimate`, `$SE`, `$MCError` from ci(estimates, Sigma, quant, type = "MC")
# and imports ci_mediation_data()). Companion to test-output-shape-contract.R.
#
# The three shapes below are deliberately different today (interval label
# "CI" vs "" vs "95% CI"; "MC.Error" vs "MCError"). They are pinned as they
# are, not as they ought to be: a rename breaks consumers one line after the
# call. If one of these must change, deprecate first (NEWS + lifecycle).

.shape_md <- function() {
  medfit::MediationData(
    a_path = 0.5, b_path = 0.4, c_prime = 0.1,
    estimates = c(a = 0.5, b = 0.4, c_prime = 0.1),
    vcov = matrix(c(0.01, 0, 0, 0, 0.02, 0, 0, 0, 0.015), 3,
      dimnames = list(c("a", "b", "c_prime"), c("a", "b", "c_prime"))
    ),
    sigma_m = NULL, sigma_y = NULL,
    treatment = "X", mediator = "M", outcome = "Y",
    mediator_predictors = character(0), outcome_predictors = character(0),
    data = NULL, n_obs = 200L, converged = TRUE, source_package = "manual"
  )
}

.shape_numeric_inputs <- function() {
  est <- c(a = 0.39, b = 0.39, theta3 = 0.1)
  S <- diag(c(0.01, 0.012, 0.004))
  dimnames(S) <- list(names(est), names(est))
  list(est = est, S = S, quant = ~ a * (b + theta3 * 0.5))
}

test_that("ci_mediation_data() keeps the CI/Estimate/SE shape for each type", {
  skip_if_not_installed("medfit")
  md <- .shape_md()
  dop <- ci_mediation_data(md, type = "dop")
  asy <- ci_mediation_data(md, type = "asymp")
  mc <- ci_mediation_data(md, type = "MC", n.mc = 2000)

  expect_identical(names(dop), c("CI", "Estimate", "SE"))
  expect_identical(names(asy), c("CI", "Estimate", "SE"))
  expect_identical(names(mc), c("CI", "Estimate", "SE", "MC.Error"))
  for (r in list(dop, asy, mc)) {
    expect_type(r[[1]], "double")
    expect_length(r[[1]], 2L)
    expect_identical(r[[1]], r$CI)
  }
  expect_equal(dop$Estimate, 0.5 * 0.4)
  expect_equal(asy$Estimate, 0.5 * 0.4)
})

test_that("ci_mediation_data() label stays 'CI' whatever the level", {
  skip_if_not_installed("medfit")
  md <- .shape_md()
  expect_identical(names(ci_mediation_data(md, level = 0.90))[1], "CI")
  expect_identical(names(ci_mediation_data(md, level = 0.99))[1], "CI")
})

test_that("ci() on a ProductNormal matches the ci_mediation_data() shape", {
  pn <- ProductNormal(mu = c(0.5, 0.4), Sigma = diag(c(0.01, 0.02)))
  dop <- ci(pn, type = "dop")
  mc <- ci(pn, type = "MC", n.mc = 2000)
  expect_identical(names(dop), c("CI", "Estimate", "SE"))
  expect_identical(names(mc), c("CI", "Estimate", "SE", "MC.Error"))
  expect_identical(dop[[1]], dop$CI)
})

test_that("ci(estimates, Sigma, quant, type = 'MC') keeps the shape missingmed reads", {
  x <- .shape_numeric_inputs()
  set.seed(1)
  r <- ci(x$est, Sigma = x$S, quant = x$quant, alpha = 0.05, type = "MC", n.mc = 2000)
  # The interval is the first element and is UNNAMED; consumers use r[[1]].
  expect_identical(names(r), c("", "Estimate", "SE", "MCError", "p"))
  expect_type(r[[1]], "double")
  expect_length(r[[1]], 2L)
  expect_true(is.numeric(r$Estimate) && is.numeric(r$SE) && is.numeric(r$MCError))
  # No dotted spelling on this method.
  expect_null(r$MC.Error)
})

test_that("ci(estimates, Sigma, quant, type = 'asymp') labels the interval by alpha", {
  x <- .shape_numeric_inputs()
  r95 <- ci(x$est, Sigma = x$S, quant = x$quant, alpha = 0.05, type = "asymp")
  r90 <- ci(x$est, Sigma = x$S, quant = x$quant, alpha = 0.10, type = "asymp")
  expect_identical(names(r95), c("95% CI", "Estimate", "SE"))
  expect_identical(names(r90)[1], "90% CI")
  expect_equal(r95$Estimate, 0.39 * (0.39 + 0.1 * 0.5))
  expect_identical(r95[[1]], r95[["95% CI"]])
})

# Slice 2 of the B+E plan (tasks/plan-34-be.md): .mbco_refit_h0() refits a violated h0 at
# feasibility tolerance 1e-8 and reports what changed. Fixtures come from the guard tests.

src <- readLines(test_path("test-mbco-constraint-guard.R"))
eval(parse(text = src[3:39])) # .guard_med_model(), .guard_fits(): same reprex, a = .5, b = 0

.exact_lrt <- function(f, d_seed) {
  set.seed(d_seed)
  n <- 300
  X <- rnorm(n)
  M <- .5 * X + rnorm(n)
  Y <- .2 * X + rnorm(n)
  d <- data.frame(X, M, Y)
  m2ll <- function(m) OpenMx::mxEval(fitfunction, m)[1]
  start <- OpenMx::omxGetParameters(f$h1)
  one <- function(lab) {
    m <- OpenMx::omxSetParameters(.guard_med_model(d), labels = names(start), values = start)
    m <- OpenMx::omxSetParameters(m, labels = lab, free = FALSE, values = 0)
    suppressWarnings(m2ll(OpenMx::mxRun(m, silent = TRUE))) - m2ll(f$h1)
  }
  min(one("a"), one("b"))
}

test_that("a violated h0 is refit and matches the exact two-fit LRT (seeds 1-3)", {
  skip_if_not_installed("OpenMx")
  for (seed in 1:3) {
    f <- .guard_fits(seed)
    out <- RMediation:::.mbco_refit_h0(f$h0, f$h1)
    expect_false(is.null(out), info = seed)
    expect_equal(out$refit$tolerance, 1e-8)
    expect_lt(RMediation:::.mbco_constraint_violation(out$model)[["ind_eq0"]], 1e-6)
    exact <- .exact_lrt(f, seed)
    expect_equal(out$refit$statistic_after, exact, tolerance = 1e-5, info = seed)
    expect_lt(out$refit$statistic_before, out$refit$statistic_after)
  }
})

test_that("the issue's 0 versus 0.4745 case is corrected (seed 1)", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  out <- RMediation:::.mbco_refit_h0(f$h0, f$h1)
  expect_equal(out$refit$statistic_before, 0, tolerance = 1e-6)
  expect_equal(out$refit$statistic_after, 0.4745, tolerance = 1e-3)
})

test_that("a clean h0 and a model without constraints are not refit", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1, tol = 1e-8)
  expect_null(RMediation:::.mbco_refit_h0(f$h0, f$h1))
  expect_null(RMediation:::.mbco_refit_h0(f$h1, f$h1))
})

test_that("the user's models are not modified", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  before <- OpenMx::omxGetParameters(f$h0)
  RMediation:::.mbco_refit_h0(f$h0, f$h1)
  expect_identical(OpenMx::omxGetParameters(f$h0), before)
  expect_null(f$h0@options[["Feasibility tolerance"]])
})

test_that("a refit that fails falls back: no model, a reason, never an error", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  f <- .guard_fits(1)
  testthat::local_mocked_bindings(
    .mbco_run_refit = function(model) stop("optimizer exploded"),
    .package = "RMediation"
  )
  out <- RMediation:::.mbco_refit_h0(f$h0, f$h1)
  expect_null(out$model)
  expect_null(out$refit)
  expect_match(out$failure, "optimizer exploded")
})

test_that("a refit that is still violated is rejected as a failure", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  f <- .guard_fits(1)
  testthat::local_mocked_bindings(
    .mbco_run_refit = function(model) f$h0, # returns the still-violated fit
    .package = "RMediation"
  )
  out <- RMediation:::.mbco_refit_h0(f$h0, f$h1)
  expect_null(out$model)
  expect_match(out$failure, "still violated")
})

test_that("a refit that did not converge is rejected as a failure", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  f <- .guard_fits(1, tol = 1e-8)
  bad <- f$h0
  bad@output$status$code <- 6
  # make h0 look violated so the helper tries, then hand back a clean-but-status-6 fit
  viol <- .guard_fits(1)$h0
  testthat::local_mocked_bindings(.mbco_run_refit = function(model) bad, .package = "RMediation")
  out <- RMediation:::.mbco_refit_h0(viol, f$h1)
  expect_null(out$model)
  expect_match(out$failure, "did not converge")
})

test_that("the refit h0 carries the tolerance into the bootstrap refits (B comes free)", {
  skip_if_not_installed("OpenMx")
  for (seed in 1:3) {
    f <- .guard_fits(seed)
    out <- RMediation:::.mbco_refit_h0(f$h0, f$h1)
    seen <- character()
    withCallingHandlers(
      mbco(out$model, f$h1, type = "parametric", R = 10L),
      warning = function(w) {
        seen <<- c(seen, class(w)[1L])
        invokeRestart("muffleWarning")
      }
    )
    expect_false(any(seen != "RMediation_constraint_violation" & seen != "simpleWarning"),
      info = seed
    )
    expect_identical(sum(seen == "simpleWarning"), 0L, info = seed)
    set.seed(seed)
    expect_no_error(suppressWarnings(mbco(out$model, f$h1, type = "semi", R = 10L)))
  }
})

test_that("planted defect: a helper that never refits is caught by the exactness test", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  f <- .guard_fits(1)
  testthat::local_mocked_bindings(
    .mbco_run_refit = function(model) f$h0, # "refit" that returns the user's fit
    .package = "RMediation"
  )
  out <- RMediation:::.mbco_refit_h0(f$h0, f$h1)
  expect_failure(expect_false(is.null(out$model)))
})

# Issue #84: OpenMx can silently drop an equality
# constraint whose Jacobian row is zero at the starting values (OpenMx/OpenMx#433), so h0 comes
# back as the unconstrained fit. A fitted h0 keeps no starting values, so mbco() cannot tell that
# cause from a violation within the feasibility tolerance; it signals
# RMediation_constraint_dropped when the refit ran and h0's fit was identical to h1's.

src <- readLines(test_path("test-mbco-constraint-guard.R"))
eval(parse(text = src[3:39])) # .guard_med_model(), .guard_fits()

.cd_collect <- function(expr) {
  classes <- character()
  messages <- list()
  value <- withCallingHandlers(expr, warning = function(w) {
    classes <<- c(classes, class(w)[1L])
    messages[[class(w)[1L]]] <<- conditionMessage(w)
    invokeRestart("muffleWarning")
  })
  list(value = value, classes = classes, messages = messages)
}

# Dataset 1 of the seeded script in OpenMx#433 (seed 20261103): x -> m1 -> y, all true paths 0.
# h0 is built from the UNFITTED model, so every path starts at 0 and b1*b2 has a zero Jacobian row.
.cd_fits <- function() {
  set.seed(20261103)
  d <- data.frame(x = rnorm(100), m1 = rnorm(100), y = rnorm(100))
  man <- c("x", "m1", "y")
  base <- OpenMx::mxModel("c",
    type = "RAM", manifestVars = man,
    OpenMx::mxPath("one", man, free = TRUE, values = 0),
    OpenMx::mxPath("x", "m1", free = TRUE, values = 0, labels = "b1"),
    OpenMx::mxPath("m1", "y", free = TRUE, values = 0, labels = "b2"),
    OpenMx::mxPath(man, arrows = 2, free = TRUE, values = 1),
    OpenMx::mxData(d, type = "raw")
  )
  run <- function(m) suppressWarnings(OpenMx::mxRun(m, silent = TRUE))
  h1 <- run(base)
  h0 <- run(OpenMx::mxModel(base,
    name = "h0",
    OpenMx::mxAlgebra(b1 * b2, name = "ind"), OpenMx::mxConstraint(ind == 0, name = "ind0")
  ))
  list(h1 = h1, h0 = h0)
}

.cd_skip_if_enforced <- function(f) {
  m2ll <- function(m) as.numeric(m$output$Minus2LogLikelihood)
  skip_if(
    abs(m2ll(f$h0) - m2ll(f$h1)) > 1e-6,
    "this OpenMx enforced the constraint at the zero start (no #433 behavior to reproduce)"
  )
}

test_that("zero-start h0 (seed 20261103): class raised, statistic repaired to 0.0878", {
  skip_if_not_installed("OpenMx")
  f <- .cd_fits()
  .cd_skip_if_enforced(f)
  out <- .cd_collect(mbco(f$h0, f$h1))
  expect_true("RMediation_constraint_dropped" %in% out$classes)
  expect_true("RMediation_h0_refit" %in% out$classes)
  expect_lt(
    match("RMediation_h0_refit", out$classes),
    match("RMediation_constraint_dropped", out$classes)
  )
  # the repaired statistic is positive and equals the exact product-null statistic
  expect_gt(out$value@statistic, 0.01)
  exact <- mbco_product_null(f$h1, c("b1", "b2"))@statistic
  expect_equal(out$value@statistic, exact, tolerance = 1e-4)
  # pinned regression (OpenMx 2.22.11, SLSQP and CSOLNP); not a cross-optimizer oracle
  expect_equal(out$value@statistic, 0.0878, tolerance = 1e-3)
  expect_equal(out$value@refit$statistic_before, 0, tolerance = 1e-6)
})

test_that("the warning is honest: 'may', both possible causes, the OpenMx issue, the exact test", {
  skip_if_not_installed("OpenMx")
  f <- .cd_fits()
  .cd_skip_if_enforced(f)
  msg <- .cd_collect(mbco(f$h0, f$h1))$messages[["RMediation_constraint_dropped"]]
  expect_match(msg, "may not have been enforced", fixed = TRUE)
  expect_match(msg, "OpenMx/OpenMx#433", fixed = TRUE)
  expect_match(msg, "feasibility tolerance", fixed = TRUE)
  expect_match(msg, "cannot tell", fixed = TRUE)
  expect_match(msg, "mbco_product_null()", fixed = TRUE)
  expect_match(msg, "?mbco", fixed = TRUE)
})

test_that("competing history: a tolerance violation has the same symptom and class", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  out <- .cd_collect(mbco(f$h0, f$h1))
  expect_true("RMediation_h0_refit" %in% out$classes)
  expect_true("RMediation_constraint_dropped" %in% out$classes)
  expect_equal(out$value@statistic, 0.4745, tolerance = 1e-3)
})

test_that("a clean h0 raises neither the refit nor the dropped warning", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1, tol = 1e-8)
  out <- .cd_collect(mbco(f$h0, f$h1))
  expect_false("RMediation_constraint_dropped" %in% out$classes)
  expect_length(out$classes, 0L)
})

test_that("a refit with statistic_before > 0 (h0 differed from h1) does not raise it", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  f <- .guard_fits(1)
  real <- RMediation:::.mbco_refit_h0(f$h0, f$h1)
  real$refit$statistic_before <- 0.5
  testthat::local_mocked_bindings(
    .mbco_refit_h0 = function(h0, h1, ...) real,
    .package = "RMediation"
  )
  out <- .cd_collect(mbco(f$h0, f$h1))
  expect_true("RMediation_h0_refit" %in% out$classes)
  expect_false("RMediation_constraint_dropped" %in% out$classes)
})

test_that("a missing or non-finite statistic_before is ignored, never an error", {
  skip_if_not_installed("OpenMx")
  for (bad in list(NA_real_, NaN, NULL)) {
    refit <- list(model = NULL, refit = list(statistic_before = bad))
    expect_no_warning(expect_null(RMediation:::.mbco_report_dropped(refit)))
  }
  expect_no_warning(RMediation:::.mbco_report_dropped(NULL))
})

test_that("the existing refit warning, result and slot are unchanged by the new check", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  out <- .cd_collect(mbco(f$h0, f$h1))
  expect_identical(out$classes[1L], "RMediation_h0_refit")
  expect_match(out$messages[["RMediation_h0_refit"]], "refit at 1e-08", fixed = TRUE)
  expect_equal(out$value@refit$tolerance, 1e-8)
  expect_equal(out$value@refit$statistic_after, out$value@statistic)
})

test_that("planted defect: a no-op check is caught by the known-answer assertions", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  f <- .cd_fits()
  .cd_skip_if_enforced(f)
  testthat::local_mocked_bindings(
    .mbco_report_dropped = function(refit) invisible(NULL), # the defect: the check never signals
    .package = "RMediation"
  )
  out <- .cd_collect(mbco(f$h0, f$h1))
  expect_failure(expect_true("RMediation_constraint_dropped" %in% out$classes))
})

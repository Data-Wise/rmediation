# Slice 3 of the B+E plan (tasks/plan-34-be.md): mbco() refits a violated h0 once, before the
# type branch, so asymp, parametric and semi all see the same refit model.

src <- readLines(test_path("test-mbco-constraint-guard.R"))
eval(parse(text = src[3:39])) # .guard_med_model(), .guard_fits()

.collect <- function(expr) {
  seen <- character()
  value <- withCallingHandlers(expr, warning = function(w) {
    seen <<- c(seen, class(w)[1L])
    invokeRestart("muffleWarning")
  })
  list(value = value, classes = seen)
}

test_that("a violated h0 is refit for every type and the slot records it (seed 1)", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  for (type in c("asymp", "parametric", "semi")) {
    set.seed(1)
    out <- .collect(mbco(f$h0, f$h1, type = type, R = 3L))
    res <- out$value
    expect_true("RMediation_h0_refit" %in% out$classes, info = type)
    expect_false("RMediation_constraint_violation" %in% out$classes, info = type)
    expect_equal(res@statistic, 0.4745, tolerance = 1e-3, info = type)
    expect_equal(res@refit$tolerance, 1e-8, info = type)
    expect_equal(res@refit$statistic_before, 0, tolerance = 1e-6, info = type)
    expect_equal(res@refit$statistic_after, res@statistic, info = type)
  }
})

test_that("the refit warning states the old and new statistic", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  w <- tryCatch(mbco(f$h0, f$h1), RMediation_h0_refit = function(w) w)
  expect_s3_class(w, "RMediation_h0_refit")
  expect_match(conditionMessage(w), "1e-08", fixed = TRUE)
  expect_match(conditionMessage(w), "0.4745", fixed = TRUE)
  expect_match(conditionMessage(w), "?mbco", fixed = TRUE)
})

test_that("a clean h0 and a constraint-free comparison are untouched", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1, tol = 1e-8)
  out <- .collect(mbco(f$h0, f$h1))
  expect_length(out$classes, 0L)
  expect_null(out$value@refit)
  expect_equal(out$value@statistic, OpenMx::mxCompare(f$h1, f$h0)$diffLL[2])
})

test_that("a refit that fails falls back to the user's fit with a note and the guard warning", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  f <- .guard_fits(1)
  testthat::local_mocked_bindings(
    .mbco_run_refit = function(model) stop("optimizer exploded"),
    .package = "RMediation"
  )
  out <- .collect(mbco(f$h0, f$h1))
  expect_true("RMediation_h0_refit_failed" %in% out$classes)
  expect_true("RMediation_constraint_violation" %in% out$classes)
  expect_false("RMediation_h0_refit" %in% out$classes)
  expect_null(out$value@refit)
  expect_equal(out$value@statistic, OpenMx::mxCompare(f$h1, f$h0)$diffLL[2])
})

test_that("global OpenMx options are restored after a refit bootstrap", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  before <- getOption("mxOptions")
  suppressWarnings(mbco(f$h0, f$h1, type = "parametric", R = 3L))
  expect_identical(getOption("mxOptions"), before)
})

test_that("planted defect: wiring that skips the refit is caught by the known-answer test", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  f <- .guard_fits(1)
  testthat::local_mocked_bindings(
    .mbco_refit_h0 = function(h0, h1, ...) NULL,
    .package = "RMediation"
  )
  res <- suppressWarnings(mbco(f$h0, f$h1))
  expect_failure(expect_equal(res@statistic, 0.4745, tolerance = 1e-3))
  expect_failure(expect_false(is.null(res@refit)))
})

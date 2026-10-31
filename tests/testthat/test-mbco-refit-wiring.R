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

# Fail closed (tasks/plan-34-failclosed.md): a violated h0 that cannot be repaired is an error,
# never a number.
test_that("a refit that errors stops with a classed error naming the constraint, for every type", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  f <- .guard_fits(1)
  testthat::local_mocked_bindings(
    .mbco_run_refit = function(model) stop("optimizer exploded"),
    .package = "RMediation"
  )
  for (type in c("asymp", "parametric", "semi")) {
    err <- tryCatch(mbco(f$h0, f$h1, type = type, R = 3L), error = function(e) e)
    expect_s3_class(err, "RMediation_h0_refit_failed")
    expect_match(conditionMessage(err), "'ind_eq0'", fixed = TRUE)
    expect_match(conditionMessage(err), "optimizer exploded", fixed = TRUE)
    expect_match(conditionMessage(err), "1e-8", fixed = TRUE)
    expect_match(conditionMessage(err), "mbco_product_null()", fixed = TRUE)
  }
})

test_that("a refit that is still violated, or did not converge, is also an error", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  f <- .guard_fits(1)
  testthat::local_mocked_bindings(.mbco_run_refit = function(model) f$h0, .package = "RMediation")
  err <- tryCatch(mbco(f$h0, f$h1), error = function(e) e)
  expect_s3_class(err, "RMediation_h0_refit_failed")
  expect_match(conditionMessage(err), "still violated")
  bad <- f$h0
  bad@output$status$code <- 6
  testthat::local_mocked_bindings(.mbco_run_refit = function(model) bad, .package = "RMediation")
  err <- tryCatch(mbco(f$h0, f$h1), error = function(e) e)
  expect_s3_class(err, "RMediation_h0_refit_failed")
  expect_match(conditionMessage(err), "did not converge")
})

test_that("the error fires before any result or other warning is produced", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  f <- .guard_fits(1)
  testthat::local_mocked_bindings(
    .mbco_run_refit = function(model) stop("optimizer exploded"),
    .package = "RMediation"
  )
  seen <- character()
  res <- withCallingHandlers(
    tryCatch(mbco(f$h0, f$h1), error = function(e) NULL),
    warning = function(w) {
      seen <<- c(seen, class(w)[1L])
      invokeRestart("muffleWarning")
    }
  )
  expect_null(res)
  expect_false(any(c("RMediation_h0_refit", "RMediation_constraint_violation") %in% seen))
})

test_that("a successful refit and a clean h0 are unchanged by the fail-closed rule", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  out <- .collect(mbco(f$h0, f$h1))
  expect_true("RMediation_h0_refit" %in% out$classes)
  expect_equal(out$value@statistic, 0.4745, tolerance = 1e-3)
  clean <- .guard_fits(1, tol = 1e-8)
  expect_length(.collect(mbco(clean$h0, clean$h1))$classes, 0L)
})

test_that("planted defect: a path that falls back instead of stopping is caught", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  f <- .guard_fits(1)
  testthat::local_mocked_bindings(
    .mbco_run_refit = function(model) stop("optimizer exploded"),
    .mbco_stop_refit_failed = function(h0, failure) invisible(NULL), # the defect: no stop
    .package = "RMediation"
  )
  expect_failure(expect_error(suppressWarnings(mbco(f$h0, f$h1)), class = "RMediation_h0_refit_failed"))
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

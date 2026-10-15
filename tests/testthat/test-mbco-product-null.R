# Slice 2 of tasks/plan-35.md: mbco_product_null(h1, paths, ...) tests a product null
# (any path = 0) as an intersection-union test: one single-path null per label, result of
# the branch with the largest p-value. Oracle: the memory_exp fixture (a1 = 0 branch
# 221.0455, b1 = 0 branch 0.0831; see test-mbco-memory-exp-oracle.R).

.pn_oracle_b1 <- 0.083100
.pn_oracle_a1 <- 221.045546

test_that("memory_exp: the helper returns the b1 branch, 0.0831, df 1 (the correct answer)", {
  skip_if_not_installed("OpenMx")
  o <- .memory_exp_oracle()
  res <- mbco_product_null(o$full, c("a1", "b1"))
  expect_s7_class(res, MBCOResult)
  expect_lt(abs(res@statistic - .pn_oracle_b1), 1e-6)
  expect_identical(res@df, 1)
  expect_identical(res@branch, "b1")
  expect_equal(res@p_value, stats::pchisq(.pn_oracle_b1, 1, lower.tail = FALSE), tolerance = 1e-5)
  expect_identical(res@type, "asymp")
  expect_null(res@refit)
})

test_that("the order of paths does not matter", {
  skip_if_not_installed("OpenMx")
  o <- .memory_exp_oracle()
  r1 <- mbco_product_null(o$full, c("a1", "b1"))
  r2 <- mbco_product_null(o$full, c("b1", "a1"))
  expect_equal(r1@statistic, r2@statistic)
  expect_identical(r1@branch, r2@branch)
})

test_that("three paths: the binding branch is the one with the smallest statistic", {
  skip_if_not_installed("OpenMx")
  o <- .memory_exp_oracle()
  base <- .memory_exp_ram("fixed")
  # b1 binds here and is listed last, so a helper that drops the last path changes the answer
  stat <- vapply(c("a1", "b2", "b1"), function(lab) {
    fixed <- .mx_fit(OpenMx::omxSetParameters(
      base, labels = lab, free = FALSE, values = 0, name = paste0(lab, "_fixed")
    ))
    .mx_lrt(o$full, fixed)[["diffLL"]]
  }, numeric(1))
  res <- mbco_product_null(o$full, c("a1", "b2", "b1"))
  expect_lt(abs(res@statistic - min(stat)), 1e-6)
  expect_identical(res@branch, "b1")
  expect_identical(res@branch, names(stat)[which.min(stat)])
})

test_that("the user's h1 is not modified", {
  skip_if_not_installed("OpenMx")
  o <- .memory_exp_oracle()
  before <- OpenMx::omxGetParameters(o$full)
  mbco_product_null(o$full, c("a1", "b1"))
  expect_identical(OpenMx::omxGetParameters(o$full), before)
  expect_true(all(c("a1", "b1") %in% names(OpenMx::omxGetParameters(o$full, free = TRUE))))
})

test_that("input validation", {
  skip_if_not_installed("OpenMx")
  o <- .memory_exp_oracle()
  expect_error(mbco_product_null("x", c("a1", "b1")), "h1 must be an MxModel")
  expect_error(mbco_product_null(o$full, "a1"))
  expect_error(mbco_product_null(o$full, 1:2))
  expect_error(mbco_product_null(o$full, c("a1", "a1")))
  expect_error(mbco_product_null(o$full, c("a1", NA_character_)))
  expect_error(mbco_product_null(o$full, c("a1", "")))
  expect_error(mbco_product_null(o$full, c("a1", "nope")), "nope")
  fixed_b1 <- OpenMx::omxSetParameters(o$full, labels = "b1", free = FALSE)
  expect_error(mbco_product_null(fixed_b1, c("a1", "b1")), "b1")
})

test_that("planted defect: choosing the smallest p-value (the wrong branch) is caught", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  o <- .memory_exp_oracle()
  testthat::local_mocked_bindings(
    .mbco_pick_branch = function(results) {
      which.min(vapply(results, function(r) r@p_value, numeric(1)))
    },
    .package = "RMediation"
  )
  res <- mbco_product_null(o$full, c("a1", "b1"))
  expect_failure(expect_lt(abs(res@statistic - .pn_oracle_b1), 1e-6))
  expect_equal(res@statistic, .pn_oracle_a1, tolerance = 1e-6) # the 221.05 branch
})

test_that("planted defect: ignoring a path is caught by the three-path test", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  o <- .memory_exp_oracle()
  orig <- RMediation:::.mbco_product_models
  testthat::local_mocked_bindings(
    .mbco_product_models = function(h1, paths) orig(h1, paths[-length(paths)]),
    .package = "RMediation"
  )
  res <- mbco_product_null(o$full, c("a1", "b2", "b1")) # b1 (the binding path) is dropped
  expect_failure(expect_identical(res@branch, "b1"))
  expect_gt(abs(res@statistic - .pn_oracle_b1), 1e-3)
})

# Codex review 2026-10-14: every branch fit must have an accepted OpenMx status (0 or 1).
test_that("a branch that did not converge is an error naming the branch", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  o <- .memory_exp_oracle()
  orig <- RMediation:::.mbco_run_null
  testthat::local_mocked_bindings(
    .mbco_run_null = function(model) {
      fit <- orig(model)
      if (grepl("_b1_zero$", model$name)) fit@output$status$code <- 6
      fit
    },
    .package = "RMediation"
  )
  expect_error(
    mbco_product_null(o$full, c("a1", "b1")),
    "branch 'b1'.*did not converge"
  )
})

test_that("statuses 0 and 1 are accepted for every branch", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  o <- .memory_exp_oracle()
  orig <- RMediation:::.mbco_run_null
  testthat::local_mocked_bindings(
    .mbco_run_null = function(model) {
      fit <- orig(model)
      fit@output$status$code <- 1
      fit
    },
    .package = "RMediation"
  )
  res <- mbco_product_null(o$full, c("a1", "b1"))
  expect_identical(res@branch, "b1")
})

test_that("planted defect: skipping the status check is caught", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  o <- .memory_exp_oracle()
  orig <- RMediation:::.mbco_run_null
  testthat::local_mocked_bindings(
    .mbco_run_null = function(model) {
      fit <- orig(model)
      if (grepl("_b1_zero$", model$name)) fit@output$status$code <- 6
      fit
    },
    .mbco_check_branch_fit = function(fit, label) invisible(fit), # the defect: no check
    .package = "RMediation"
  )
  # the unchecked status-6 branch fit now also reaches mbco()'s own nonconvergence warning
  suppressWarnings(
    expect_failure(expect_error(mbco_product_null(o$full, c("a1", "b1")), "did not converge"))
  )
})

# Codex review 2026-10-14: h1 itself was never checked. A nonconverged h1 only failed by luck, in
# a branch fit, with a message that blamed the branch.
test_that("a nonconverged h1 is refused before any branch is fitted, and named as h1", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  o <- .memory_exp_oracle()
  bad <- o$full
  bad@output$status$code <- 6
  fitted <- 0L
  testthat::local_mocked_bindings(
    .mbco_run_null = function(model) {
      fitted <<- fitted + 1L
      OpenMx::mxRun(model, silent = TRUE)
    }
  )
  cond <- tryCatch(mbco_product_null(bad, c("a1", "b1")), error = function(e) e)
  expect_s3_class(cond, "RMediation_h1_nonconverged")
  expect_match(conditionMessage(cond), "full model h1 did not converge.*status code 6")
  expect_identical(fitted, 0L)
})

test_that("an unfitted h1 (no status) is refused; statuses 0 and 1 are accepted", {
  skip_if_not_installed("OpenMx")
  o <- .memory_exp_oracle()
  unfit <- o$full
  unfit@output <- list()
  expect_error(mbco_product_null(unfit, c("a1", "b1")), "h1 has no fit result.*never run")
  for (code in c(0, 1)) {
    ok <- o$full
    ok@output$status$code <- code
    expect_no_error(.mbco_check_full_fit(ok))
  }
})

test_that("mbco() warns, with a class, when a user-supplied fit did not converge", {
  skip_if_not_installed("OpenMx")
  o <- .memory_exp_oracle()
  bad <- o$full
  bad@output$status$code <- 6
  expect_warning(.mbco_warn_unconverged(bad, "h1"), class = "RMediation_fit_nonconverged")
  expect_warning(.mbco_warn_unconverged(bad, "h1"), "h1 did not converge.*status code 6")
  expect_no_warning(.mbco_warn_unconverged(o$full, "h1"))
  unfit <- o$full
  unfit@output <- list()
  expect_no_warning(.mbco_warn_unconverged(unfit, "h1")) # no status at all is not flagged
})

test_that(".mbco_status_ok accepts exactly status 0 and 1", {
  mk <- function(code) list(output = list(status = list(code = code)))
  expect_true(.mbco_status_ok(mk(0)))
  expect_true(.mbco_status_ok(mk(1)))
  for (code in list(2, 5, 6, NA_real_, NULL, c(0, 1))) expect_false(.mbco_status_ok(mk(code)))
})

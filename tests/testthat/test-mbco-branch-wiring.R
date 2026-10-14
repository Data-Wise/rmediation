# Slice 3 of tasks/plan-35-probe.md: mbco() runs the wrong-branch probe once per call, after the
# refit, and warns (class RMediation_constraint_branch); the result is never changed.

src <- readLines(test_path("test-mbco-constraint-guard.R"))
eval(parse(text = src[3:39])) # .guard_med_model(), .guard_fits()

.pbw_collect <- function(expr) {
  seen <- character()
  msgs <- character()
  value <- withCallingHandlers(expr,
    warning = function(w) {
      seen <<- c(seen, class(w)[1L])
      msgs <<- c(msgs, conditionMessage(w))
      invokeRestart("muffleWarning")
    },
    message = function(m) {
      seen <<- c(seen, class(m)[1L])
      msgs <<- c(msgs, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  list(value = value, classes = seen, messages = msgs)
}

.pbw_memory <- function(from) {
  base <- OpenMx::mxModel(.memory_exp_ram("pbw"), OpenMx::mxAlgebra(a1 * b1, name = "ind1"))
  full <- .mx_fit(base)
  h0 <- OpenMx::mxModel(if (from == "unfitted") base else full, name = "nl",
    OpenMx::mxConstraint(ind1 == 0, name = "c"))
  h0 <- suppressWarnings(OpenMx::mxRun(OpenMx::mxOption(h0, "Feasibility tolerance", 1e-8), silent = TRUE))
  list(full = full, h0 = h0)
}

test_that("a wrong-branch null warns for every type and the result is unchanged (memory_exp)", {
  skip_if_not_installed("OpenMx")
  m <- .pbw_memory("unfitted")
  for (type in c("asymp", "parametric", "semi")) {
    set.seed(1)
    out <- .pbw_collect(mbco(m$h0, m$full, type = type, R = 3L))
    expect_true("RMediation_constraint_branch" %in% out$classes, info = type)
    expect_identical(sum(out$classes == "RMediation_constraint_branch"), 1L, info = type) # once per call
    expect_equal(out$value@statistic, .mx_lrt(m$full, m$h0)[["diffLL"]], info = type)
  }
})

test_that("the warning names the constraint, the better parameter, the gap and the remedy", {
  skip_if_not_installed("OpenMx")
  m <- .pbw_memory("unfitted")
  w <- tryCatch(mbco(m$h0, m$full), RMediation_constraint_branch = function(w) w)
  expect_s3_class(w, "RMediation_constraint_branch")
  msg <- conditionMessage(w)
  expect_match(msg, "'c'", fixed = TRUE)
  expect_match(msg, "b1", fixed = TRUE)
  expect_match(msg, "220.9", fixed = TRUE)
  expect_match(msg, "mbco_product_null()", fixed = TRUE)
})

test_that("the right branch, a clean fit and a model without constraints do not warn", {
  skip_if_not_installed("OpenMx")
  m <- .pbw_memory("fitted")
  expect_false("RMediation_constraint_branch" %in% .pbw_collect(mbco(m$h0, m$full))$classes)
  g <- .guard_fits(1, tol = 1e-8)
  expect_false("RMediation_constraint_branch" %in% .pbw_collect(mbco(g$h0, g$h1))$classes)
  # after a successful refit the null is on the right branch: refit warning only
  f <- .guard_fits(1)
  out <- .pbw_collect(mbco(f$h0, f$h1))
  expect_true("RMediation_h0_refit" %in% out$classes)
  expect_false("RMediation_constraint_branch" %in% out$classes)
})

test_that("a probe failure never breaks mbco()", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  m <- .pbw_memory("unfitted")
  testthat::local_mocked_bindings(
    .mbco_branch_probe = function(h0, h1, ...) stop("probe exploded"),
    .package = "RMediation"
  )
  out <- .pbw_collect(mbco(m$h0, m$full))
  expect_equal(out$value@statistic, .mx_lrt(m$full, m$h0)[["diffLL"]])
  expect_false("RMediation_constraint_branch" %in% out$classes)
})

test_that("a constraint skipped by the cap is reported as a message, not a warning", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  m <- .pbw_memory("fitted")
  testthat::local_mocked_bindings(
    .mbco_branch_probe = function(h0, h1, ...) structure(list(), skipped = "c"),
    .package = "RMediation"
  )
  out <- .pbw_collect(mbco(m$h0, m$full))
  expect_true("RMediation_constraint_branch_skipped" %in% out$classes)
  expect_match(out$messages[out$classes == "RMediation_constraint_branch_skipped"], "'c'", fixed = TRUE)
})

test_that("planted defect: wiring that skips the probe is caught", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  m <- .pbw_memory("unfitted")
  testthat::local_mocked_bindings(
    .mbco_branch_probe = function(h0, h1, ...) list(),
    .package = "RMediation"
  )
  out <- .pbw_collect(mbco(m$h0, m$full))
  expect_failure(expect_true("RMediation_constraint_branch" %in% out$classes))
})

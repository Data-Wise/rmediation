# Slice 2 of tasks/plan-35-probe.md: .mbco_branch_probe(h0, h1) returns, per equality constraint
# of h0, the involved parameter whose zero-fit beats h0 by more than `gap` in -2LL, if any.

src <- readLines(test_path("test-mbco-constraint-guard.R"))
eval(parse(text = src[3:39])) # .guard_med_model(), .guard_fits()

.m2ll <- function(m) OpenMx::mxEval(fitfunction, m)[1]
.run <- function(m) suppressWarnings(OpenMx::mxRun(m, silent = TRUE))

# memory_exp with the single constraint ind1 == 0: unfitted start -> wrong branch (a1 = 0, 221.05);
# start from the fitted full model at tolerance 1e-8 -> right branch (b1 = 0, 0.0831)
.pb_memory <- function(from = c("unfitted", "fitted")) {
  from <- match.arg(from)
  base <- OpenMx::mxModel(.memory_exp_ram("pb"), OpenMx::mxAlgebra(a1 * b1, name = "ind1"))
  full <- .mx_fit(base)
  src_model <- if (from == "unfitted") base else full
  h0 <- OpenMx::mxModel(src_model, name = "nl", OpenMx::mxConstraint(ind1 == 0, name = "c"))
  h0 <- .run(OpenMx::mxOption(h0, "Feasibility tolerance", 1e-8))
  list(full = full, h0 = h0)
}

# X -> M -> Y with both paths substantial (b = .4): the wrong branch is common (28 of 60 seeds)
.pb_synth <- function(seed, b = 0.4) {
  set.seed(seed)
  n <- 200
  X <- rnorm(n)
  M <- .5 * X + rnorm(n)
  Y <- .2 * X + b * M + rnorm(n)
  d <- data.frame(X, M, Y)
  h1 <- .run(.guard_med_model(d))
  h0 <- .run(OpenMx::mxOption(.guard_med_model(d, TRUE), "Feasibility tolerance", 1e-8))
  list(h1 = h1, h0 = h0, exact_gap = .m2ll(h0) - .m2ll(h1))
}

test_that("memory_exp wrong branch (a1 = 0, 221.05) is flagged with b1 as the better candidate", {
  skip_if_not_installed("OpenMx")
  m <- .pb_memory("unfitted")
  expect_equal(.mx_lrt(m$full, m$h0)[["diffLL"]], 221.0455, tolerance = 1e-5) # it is the wrong branch
  out <- RMediation:::.mbco_branch_probe(m$h0, m$full)
  expect_length(out, 1L)
  expect_identical(out[[1]]$constraint, "c")
  expect_identical(out[[1]]$parameter, "b1")
  expect_equal(out[[1]]$improvement, 221.0455 - 0.0831, tolerance = 1e-3)
})

test_that("memory_exp right branch (b1 = 0, 0.0831) is not flagged", {
  skip_if_not_installed("OpenMx")
  m <- .pb_memory("fitted")
  expect_equal(.mx_lrt(m$full, m$h0)[["diffLL"]], 0.0831, tolerance = 1e-3)
  expect_length(RMediation:::.mbco_branch_probe(m$h0, m$full), 0L)
})

test_that("synthetic seeds with both paths substantial: wrong-branch fits are flagged, optimal ones are not", {
  skip_if_not_installed("OpenMx")
  flagged <- vapply(1:4, function(s) {
    p <- .pb_synth(s)
    length(RMediation:::.mbco_branch_probe(p$h0, p$h1)) > 0L
  }, logical(1))
  expect_true(all(flagged[1:2])) # seeds 1 and 2 are wrong-branch fits (35.18 vs 23.59, 50.61 vs 35.58)
  # a null that is already optimal: fitted from the full model's estimates (guard fixture)
  g <- .guard_fits(1, tol = 1e-8)
  expect_length(RMediation:::.mbco_branch_probe(g$h0, g$h1), 0L)
})

test_that("no constraints, inequality constraints and linear constraints give no finding", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  expect_length(RMediation:::.mbco_branch_probe(f$h1, f$h1), 0L)
  ineq <- OpenMx::mxModel(f$h1, name = "ineq",
    OpenMx::mxAlgebra(a * b, name = "ind"), OpenMx::mxConstraint(ind > -5, name = "slack")
  )
  expect_length(RMediation:::.mbco_branch_probe(.run(ineq), f$h1), 0L)
  lin <- .run(OpenMx::mxModel(f$h1, name = "lin", OpenMx::mxConstraint(b == 0, name = "b0")))
  expect_length(RMediation:::.mbco_branch_probe(lin, f$h1), 0L)
})

test_that("the gap threshold is honored", {
  skip_if_not_installed("OpenMx")
  m <- .pb_memory("unfitted")
  expect_length(RMediation:::.mbco_branch_probe(m$h0, m$full, gap = 1e6), 0L)
  expect_length(RMediation:::.mbco_branch_probe(m$h0, m$full, gap = 1e-4), 1L)
  r <- .pb_memory("fitted") # candidate ties the null (improvement ~ 0): flagged only if gap is negative
  expect_length(RMediation:::.mbco_branch_probe(r$h0, r$full, gap = 1e-4), 0L)
  expect_gt(length(RMediation:::.mbco_branch_probe(r$h0, r$full, gap = -1)), 0L)
})

test_that("a constraint with more than `cap` involved parameters is skipped and reported", {
  skip_if_not_installed("OpenMx")
  m <- .pb_memory("unfitted")
  out <- RMediation:::.mbco_branch_probe(m$h0, m$full, cap = 1L)
  expect_length(out, 0L)
  expect_identical(attr(out, "skipped"), "c")
})

test_that("probe failures are skipped silently: errors and non-convergence", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  m <- .pb_memory("unfitted")
  orig <- RMediation:::.mbco_run_probe
  testthat::local_mocked_bindings(
    .mbco_run_probe = function(model) stop("optimizer exploded"),
    .package = "RMediation"
  )
  expect_no_error(out <- RMediation:::.mbco_branch_probe(m$h0, m$full))
  expect_length(out, 0L)
  testthat::local_mocked_bindings(
    .mbco_run_probe = function(model) {
      fit <- orig(model)
      fit@output$status$code <- 6
      fit
    },
    .package = "RMediation"
  )
  expect_length(RMediation:::.mbco_branch_probe(m$h0, m$full), 0L)
})

test_that("the user's models are not modified", {
  skip_if_not_installed("OpenMx")
  m <- .pb_memory("unfitted")
  before <- OpenMx::omxGetParameters(m$h0)
  RMediation:::.mbco_branch_probe(m$h0, m$full)
  expect_identical(OpenMx::omxGetParameters(m$h0), before)
  expect_length(m$h0@constraints, 1L)
})

test_that("planted defect: probing at the null's own solution misses the better branch", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  m <- .pb_memory("unfitted")
  testthat::local_mocked_bindings(
    .mbco_probe_point = function(h0, h1) h0,
    .package = "RMediation"
  )
  # at a1 = 0 only a1 moves the constraint, so b1 is never tried
  expect_failure(expect_length(RMediation:::.mbco_branch_probe(m$h0, m$full), 1L))
})

test_that("planted defect: ignoring the feasibility recheck flags an infeasible candidate", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  f <- .guard_fits(1)
  # a == 5 is far from the data (a is about 0.5), so fixing a at 0 fits better but violates a == 5
  far <- .run(OpenMx::mxModel(f$h1, name = "far", OpenMx::mxConstraint(a == 5, name = "a5")))
  expect_length(RMediation:::.mbco_branch_probe(far, f$h1), 0L)
  testthat::local_mocked_bindings(
    .mbco_candidate_violation = function(fit, h0, constraint) 0,
    .package = "RMediation"
  )
  expect_failure(expect_length(RMediation:::.mbco_branch_probe(far, f$h1), 0L))
})

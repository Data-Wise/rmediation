# Issue #34: OpenMx's default feasibility tolerance (0.05) lets a fit of a nonlinear
# equality constraint (ab == 0) end off the null set, understating the MBCO statistic.
# The guard warns when a fitted constraint of h0 or h1 is violated; it never changes a result.

.guard_med_model <- function(d, constrain = FALSE) {
  m <- OpenMx::mxModel("med",
    type = "RAM", manifestVars = c("X", "M", "Y"),
    OpenMx::mxPath("X", "M", labels = "a", values = .1),
    OpenMx::mxPath("X", "Y", labels = "cp", values = .1),
    OpenMx::mxPath("M", "Y", labels = "b", values = .1),
    OpenMx::mxPath(c("X", "M", "Y"), arrows = 2, values = 1),
    OpenMx::mxPath("one", c("X", "M", "Y"), values = 0),
    OpenMx::mxData(d, type = "raw")
  )
  if (constrain) {
    m <- OpenMx::mxModel(m,
      OpenMx::mxAlgebra(a * b, name = "ind"),
      OpenMx::mxConstraint(ind == 0, name = "ind_eq0")
    )
  }
  m
}

# H0 (ab = 0) is true: a = .5, b = 0; same data generation as the issue's reprex.
.guard_fits <- function(seed, tol = NULL) {
  set.seed(seed)
  n <- 300
  X <- rnorm(n)
  M <- .5 * X + rnorm(n)
  Y <- .2 * X + rnorm(n)
  d <- data.frame(X, M, Y)
  h1 <- suppressWarnings(OpenMx::mxRun(.guard_med_model(d), silent = TRUE))
  start <- OpenMx::omxGetParameters(h1)
  h0 <- OpenMx::omxSetParameters(.guard_med_model(d, TRUE),
    labels = names(start), values = start
  )
  if (!is.null(tol)) h0 <- OpenMx::mxOption(h0, "Feasibility tolerance", tol)
  list(h1 = h1, h0 = suppressWarnings(OpenMx::mxRun(h0, silent = TRUE)))
}

# mbco() now refits a violated h0 before the guard looks at it (tasks/plan-34-be.md), so tests that
# exercise the guard through mbco() switch the refit off; the refit has its own test files.
.guard_no_refit <- function(env = parent.frame()) {
  testthat::local_mocked_bindings(
    .mbco_refit_h0 = function(h0, h1, ...) NULL,
    .package = "RMediation",
    .env = env
  )
}

test_that("a nonlinear equality fitted at the default tolerance triggers the guard (seeds 1-3)", {
  .guard_no_refit()
  skip_if_not_installed("OpenMx")
  for (seed in 1:3) {
    f <- .guard_fits(seed)
    expect_warning(
      mbco(f$h0, f$h1),
      class = "RMediation_constraint_violation"
    )
  }
})

test_that("the same model fitted at tolerance 1e-8 is silent", {
  skip_if_not_installed("OpenMx")
  for (seed in 1:3) {
    f <- .guard_fits(seed, tol = 1e-8)
    expect_no_warning(mbco(f$h0, f$h1), class = "RMediation_constraint_violation")
  }
})

test_that("the warning names the constraint, the model and the remedy", {
  .guard_no_refit()
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  w <- tryCatch(mbco(f$h0, f$h1), RMediation_constraint_violation = function(w) w)
  expect_s3_class(w, "RMediation_constraint_violation")
  expect_match(conditionMessage(w), "ind_eq0", fixed = TRUE)
  expect_match(conditionMessage(w), "h0", fixed = TRUE)
  expect_match(conditionMessage(w), "Feasibility tolerance", fixed = TRUE)
  expect_match(conditionMessage(w), "a = 0", fixed = TRUE) # the two-fit route
})

test_that("the guard never changes the returned result", {
  .guard_no_refit()
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(2)
  res <- suppressWarnings(mbco(f$h0, f$h1))
  cmp <- OpenMx::mxCompare(f$h1, f$h0)
  expect_identical(res@statistic, as.numeric(cmp$diffLL[2]))
  expect_identical(res@df, as.numeric(cmp$df[2] - cmp$df[1]))
  expect_identical(res@p_value, as.numeric(cmp$p[2]))
})

# A linear equality is also fitted only to within the feasibility tolerance when the
# fit starts from the full model's estimates (b ends near 0.015-0.041, not 0).
.guard_linear_null <- function(f, tol = NULL) {
  lin <- OpenMx::mxModel(f$h1, name = "lin", OpenMx::mxConstraint(b == 0, name = "b_eq0"))
  if (!is.null(tol)) lin <- OpenMx::mxOption(lin, "Feasibility tolerance", tol)
  suppressWarnings(OpenMx::mxRun(lin, silent = TRUE))
}

test_that("a linear equality fitted at the default tolerance is also flagged (seeds 1-3)", {
  .guard_no_refit()
  skip_if_not_installed("OpenMx")
  for (seed in 1:3) {
    f <- .guard_fits(seed)
    expect_warning(
      mbco(.guard_linear_null(f), f$h1),
      class = "RMediation_constraint_violation"
    )
  }
})

test_that("a linear equality fitted at tolerance 1e-8 is silent, and so are models without constraints", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  expect_no_warning(
    mbco(.guard_linear_null(f, tol = 1e-8), f$h1),
    class = "RMediation_constraint_violation"
  )
  expect_length(RMediation:::.mbco_constraint_violation(f$h1), 0L)
})

# Constraint formulas are evaluated at the model's parameter values, so the scaling and
# operator rules can be tested on models run without the optimizer, at chosen values.
.guard_unfitted <- function(a_value, ...) {
  set.seed(1)
  d <- data.frame(X = rnorm(50), M = rnorm(50), Y = rnorm(50))
  m <- OpenMx::omxSetParameters(.guard_med_model(d), labels = "a", values = a_value)
  m <- OpenMx::mxModel(m, OpenMx::mxAlgebra(a * 1, name = "alg"), ...)
  # evaluate the algebras at the chosen values without optimizing
  suppressWarnings(OpenMx::mxRun(m, useOptimizer = FALSE, silent = TRUE))
}

test_that("equality violation is scaled by the size of the two sides", {
  skip_if_not_installed("OpenMx")
  small <- .guard_unfitted(0.03, OpenMx::mxConstraint(alg == 0, name = "unit"))
  big <- .guard_unfitted(0.03, OpenMx::mxAlgebra(alg + 1e6, name = "big"),
    OpenMx::mxConstraint(big == 1e6, name = "large")
  )
  expect_equal(unname(RMediation:::.mbco_constraint_violation(small)), 0.03)
  # the same absolute gap (0.03) on a constraint of size 1e6 is a relative 3e-8
  expect_lt(unname(RMediation:::.mbco_constraint_violation(big)), 1e-6)
  expect_silent(RMediation:::.mbco_warn_constraints(big, "h0"))
  expect_warning(RMediation:::.mbco_warn_constraints(small, "h0"),
    class = "RMediation_constraint_violation"
  )
})

test_that("the threshold boundary behaves as specified on both sides", {
  skip_if_not_installed("OpenMx")
  m <- function(v) .guard_unfitted(v, OpenMx::mxConstraint(alg == 0, name = "eq"))
  expect_no_warning(RMediation:::.mbco_warn_constraints(m(9e-7), "h0"),
    class = "RMediation_constraint_violation"
  )
  expect_warning(RMediation:::.mbco_warn_constraints(m(2e-6), "h0"),
    class = "RMediation_constraint_violation"
  )
})

test_that("inequalities are violated only on the wrong side", {
  skip_if_not_installed("OpenMx")
  v <- function(...) RMediation:::.mbco_constraint_violation(.guard_unfitted(0.03, ...))
  C <- OpenMx::mxConstraint
  expect_equal(unname(v(C(alg < 1, name = "slack_lt"))), 0)
  expect_equal(unname(v(C(alg > -1, name = "slack_gt"))), 0)
  expect_equal(unname(v(C(alg < 0, name = "bad_lt"))), 0.03)
  expect_equal(unname(v(C(alg > 1, name = "bad_gt"))), (1 - 0.03) / 1)
  expect_identical(names(v(C(alg < 0, name = "bad_lt"))), "bad_lt")
  expect_silent(RMediation:::.mbco_warn_constraints(
    .guard_unfitted(0.03, C(alg < 1, name = "s1"), C(alg > -1, name = "s2")), "h0"
  ))
  expect_warning(
    RMediation:::.mbco_warn_constraints(.guard_unfitted(0.03, C(alg > 1, name = "bad")), "h0"),
    class = "RMediation_constraint_violation"
  )
})

test_that("the warning labels the model: h1 as well as h0", {
  skip_if_not_installed("OpenMx")
  bad <- .guard_unfitted(0.03, OpenMx::mxConstraint(alg == 0, name = "eq"))
  w <- tryCatch(RMediation:::.mbco_warn_constraints(bad, "h1"),
    RMediation_constraint_violation = function(w) w
  )
  expect_match(conditionMessage(w), "of h1", fixed = TRUE)
  expect_match(conditionMessage(w), "'eq'", fixed = TRUE)
})

test_that("an infeasible inequality fitted by mbco() warns", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  infeasible <- OpenMx::mxModel(f$h1, name = "ineq",
    OpenMx::mxAlgebra(a * b, name = "ind"),
    OpenMx::mxConstraint(ind > 0.5, name = "ind_gt")
  )
  infeasible <- suppressWarnings(OpenMx::mxRun(infeasible, silent = TRUE))
  expect_gt(RMediation:::.mbco_constraint_violation(infeasible)[["ind_gt"]], 1e-6)
})

# Slice 3: a constraint the guard cannot evaluate is an error that names it (grill decision 5).
.guard_tamper <- function(model, formula) {
  model@constraints[[1L]]@formula <- formula
  model
}

test_that("an unevaluable constraint errors, naming the constraint", {
  skip_if_not_installed("OpenMx")
  m <- .guard_unfitted(0.03, OpenMx::mxConstraint(alg == 0, name = "eq"))
  broken <- .guard_tamper(m, quote(no_such_object == 0))
  expect_error(
    RMediation:::.mbco_constraint_violation(broken),
    "could not evaluate constraint 'eq' for the violation check"
  )
})

test_that("an unevaluable constraint errors from mbco() too", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1, tol = 1e-8)
  broken <- .guard_tamper(f$h0, quote(no_such_object == 0))
  expect_error(
    mbco(broken, f$h1),
    "could not evaluate constraint 'ind_eq0' for the violation check"
  )
})

test_that("unsupported operators are skipped, not errors", {
  skip_if_not_installed("OpenMx")
  m <- .guard_unfitted(0.03, OpenMx::mxConstraint(alg == 0, name = "eq"))
  odd <- .guard_tamper(m, quote(alg != 0))
  expect_length(RMediation:::.mbco_constraint_violation(odd), 0L)
  expect_no_warning(RMediation:::.mbco_warn_constraints(odd, "h0"))
})

test_that("a model with no constraints is untouched", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  expect_length(RMediation:::.mbco_constraint_violation(f$h1), 0L)
  expect_no_warning(RMediation:::.mbco_warn_constraints(f$h1, "h1"))
})

test_that("planted defect: a guard that ignores constraints is caught", {
  .guard_no_refit()
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  f <- .guard_fits(1)
  testthat::local_mocked_bindings(
    .mbco_constraint_violation = function(model) numeric(0),
    .package = "RMediation"
  )
  expect_failure(expect_warning(mbco(f$h0, f$h1), class = "RMediation_constraint_violation"))
})

# Slice 4: every type goes through the one call site, and each planted defect is caught.
.guard_classes <- function(expr) {
  seen <- character()
  withCallingHandlers(
    tryCatch(expr, error = function(e) NULL),
    warning = function(w) {
      seen <<- c(seen, class(w)[1L])
      invokeRestart("muffleWarning")
    }
  )
  seen
}

test_that("the guard fires through type = 'parametric' and 'semi'", {
  .guard_no_refit()
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  for (type in c("parametric", "semi")) {
    seen <- .guard_classes(mbco(f$h0, f$h1, type = type, R = 3L))
    expect_true("RMediation_constraint_violation" %in% seen, info = type)
  }
  f8 <- .guard_fits(1, tol = 1e-8)
  for (type in c("parametric", "semi")) {
    seen <- .guard_classes(mbco(f8$h0, f8$h1, type = type, R = 3L))
    expect_false("RMediation_constraint_violation" %in% seen, info = type)
  }
})

# Oracles: each asserts one behavior the guard must have; a mutant that breaks it fails here.
.oracle_fires <- function() {
  .guard_no_refit()
  f <- .guard_fits(1)
  expect_warning(mbco(f$h0, f$h1), class = "RMediation_constraint_violation")
}
.oracle_boundary <- function() {
  m <- .guard_unfitted(2e-6, OpenMx::mxConstraint(alg == 0, name = "eq"))
  expect_warning(RMediation:::.mbco_warn_constraints(m, "h0"),
    class = "RMediation_constraint_violation"
  )
}
.oracle_scaled <- function() {
  big <- .guard_unfitted(0.03, OpenMx::mxAlgebra(alg + 1e6, name = "big"),
    OpenMx::mxConstraint(big == 1e6, name = "large")
  )
  expect_no_warning(RMediation:::.mbco_warn_constraints(big, "h0"),
    class = "RMediation_constraint_violation"
  )
}
.oracle_h1 <- function() {
  .guard_no_refit()
  f <- .guard_fits(1)
  h0b <- OpenMx::omxSetParameters(f$h1, labels = c("a", "b"), free = FALSE, values = 0)
  h0b <- suppressWarnings(OpenMx::mxRun(h0b, silent = TRUE))
  expect_warning(mbco(h0b, f$h0), "of h1", class = "RMediation_constraint_violation")
}

test_that("the oracles pass on the real guard", {
  .guard_no_refit()
  skip_if_not_installed("OpenMx")
  .oracle_fires()
  .oracle_boundary()
  .oracle_scaled()
  .oracle_h1()
})

test_that("planted defect: threshold 1e4 too loose is caught by the boundary oracle", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  orig <- RMediation:::.mbco_constraint_violation
  testthat::local_mocked_bindings(
    .mbco_constraint_violation = function(model) orig(model) / 1e4,
    .package = "RMediation"
  )
  expect_failure(.oracle_boundary())
})

test_that("planted defect: checking only h0 is caught by the h1 oracle", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  orig <- RMediation:::.mbco_warn_constraints
  testthat::local_mocked_bindings(
    .mbco_warn_constraints = function(model, label, threshold = 1e-6) {
      if (identical(label, "h1")) invisible(numeric(0)) else orig(model, label, threshold)
    },
    .package = "RMediation"
  )
  expect_failure(.oracle_h1())
})

test_that("planted defect: an unscaled violation is caught by the scaled oracle", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  testthat::local_mocked_bindings(
    .mbco_constraint_violation = function(model) {
      vapply(model@constraints, function(cn) {
        f <- cn@formula
        ev <- function(e) eval(bquote(OpenMx::mxEval(.(e), model, compute = FALSE)))
        abs(ev(f[[2L]]) - ev(f[[3L]]))
      }, numeric(1))
    },
    .package = "RMediation"
  )
  expect_failure(.oracle_scaled())
})

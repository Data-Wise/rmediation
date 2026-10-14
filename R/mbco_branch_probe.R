# Wrong-branch probe for equality constraints (issue #35; tasks/plan-35-probe.md).
# A fitted null can be feasible, converged and still sit on the larger-statistic branch of a
# product null; the violation guard cannot see it. These helpers find the parameters a
# constraint depends on, without parsing its formula.

# The model whose parameter values the constraint is evaluated at: h0 with the full model's
# estimates. Evaluating at the null's own solution fails: at a = 0 the constraint a * b does not
# move with b, so only a would be found.
.mbco_probe_point <- function(h0, h1) {
  est <- OpenMx::omxGetParameters(h1)
  use <- intersect(names(est), names(OpenMx::omxGetParameters(h0, free = TRUE)))
  OpenMx::omxSetParameters(h0, labels = use, values = est[use])
}

# lhs - rhs of one constraint with the model's current parameter values (no optimization).
.mbco_constraint_gap <- function(model, constraint) {
  model <- suppressWarnings(OpenMx::mxRun(model, useOptimizer = FALSE, silent = TRUE))
  f <- constraint@formula
  side <- function(expr) eval(bquote(OpenMx::mxEval(.(expr), model, compute = FALSE)))
  as.numeric(side(f[[2L]]) - side(f[[3L]]))
}

# Free parameters of h0 that the named constraint depends on: those whose perturbation by
# `delta` moves lhs - rhs by more than `tol`.
.mbco_involved <- function(h0, h1, name, delta = 1e-3, tol = 1e-9) {
  constraint <- h0@constraints[[name]]
  if (is.null(constraint)) {
    stop("h0 has no constraint named '", name, "'", call. = FALSE)
  }
  at <- .mbco_probe_point(h0, h1)
  base <- .mbco_constraint_gap(at, constraint)
  values <- OpenMx::omxGetParameters(at, free = TRUE)
  moved <- vapply(names(values), function(lab) {
    shifted <- OpenMx::omxSetParameters(at, labels = lab, values = values[[lab]] + delta)
    max(abs(.mbco_constraint_gap(shifted, constraint) - base)) > tol
  }, logical(1))
  names(values)[moved]
}

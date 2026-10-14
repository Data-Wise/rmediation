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

# Candidate for one involved parameter: h0 without the constraint under test, that parameter fixed
# at 0. The constraint is dropped so the result does not depend on how the optimizer handles a
# constraint whose gradient vanishes at the fixed path (SLSQP was observed to cope: keeping it
# flagged the same 14 of 24 seeds); feasibility is rechecked afterwards instead.
.mbco_probe_model <- function(h0, constraint, label) {
  nocon <- OpenMx::mxModel(h0, name = "probe_base", remove = TRUE, constraint@name)
  OpenMx::omxSetParameters(nocon, labels = label, free = FALSE, values = 0, name = "probe")
}

.mbco_run_probe <- function(model) {
  suppressWarnings(OpenMx::mxRun(model, silent = TRUE))
}

# Scaled violation of the original constraint at a candidate fit (re-added, evaluated without
# optimizing).
.mbco_candidate_violation <- function(fit, h0, constraint) {
  with_c <- suppressWarnings(OpenMx::mxRun(
    OpenMx::mxModel(fit, constraint), useOptimizer = FALSE, silent = TRUE
  ))
  max(.mbco_constraint_violation(with_c)[[constraint@name]])
}

# Per equality constraint of h0: the involved parameter whose zero-fit has a converged, feasible
# fit with -2LL lower than h0's by more than `gap`. Returns a list of
# list(constraint, parameter, improvement); attribute "skipped" names constraints with more than
# `cap` involved parameters. Advisory: any failure inside is skipped, never raised.
.mbco_branch_probe <- function(h0, h1, gap = 1e-4, cap = 5L, threshold = 1e-6) {
  out <- list()
  skipped <- character()
  m2ll <- function(m) OpenMx::mxEval(fitfunction, m)[1]
  base_ll <- m2ll(h0)
  for (constraint in h0@constraints) {
    if (!identical(as.character(constraint@formula[[1L]]), "==")) next
    involved <- tryCatch(.mbco_involved(h0, h1, constraint@name), error = function(e) NULL)
    if (is.null(involved) || !length(involved)) next
    if (length(involved) > cap) {
      skipped <- c(skipped, constraint@name)
      next
    }
    best <- NULL
    for (label in involved) {
      ll <- tryCatch({
        fit <- .mbco_run_probe(.mbco_probe_model(h0, constraint, label))
        code <- fit$output$status$code
        ok <- length(code) == 1L && !is.na(code) && code %in% c(0, 1) &&
          .mbco_candidate_violation(fit, h0, constraint) <= threshold
        if (ok) m2ll(fit) else NA_real_
      }, error = function(e) NA_real_)
      improvement <- base_ll - ll
      if (!is.na(improvement) && improvement > gap &&
            (is.null(best) || improvement > best$improvement)) {
        best <- list(constraint = constraint@name, parameter = label, improvement = improvement)
      }
    }
    if (!is.null(best)) out[[length(out) + 1L]] <- best
  }
  attr(out, "skipped") <- skipped
  out
}

# Run the probe and report: one warning per flagged constraint, a message for constraints skipped
# by the cap. Advisory: any error inside is swallowed.
.mbco_report_branch <- function(h0, h1) {
  found <- tryCatch(.mbco_branch_probe(h0, h1), error = function(e) NULL)
  if (is.null(found)) {
    return(invisible(NULL))
  }
  for (f in found) {
    .mbco_signal("RMediation_constraint_branch", sprintf(
      paste0(
        "Constraint '%s' of h0 is feasible but not optimal: fixing %s at 0 gives a fit with -2LL ",
        "lower by %s, so h0 may sit on the wrong branch and the MBCO statistic may be overstated. ",
        "For a product null such as a*b = 0 use mbco_product_null() (see ?mbco)."
      ),
      f$constraint, f$parameter, format(round(f$improvement, 4))
    ))
  }
  for (nm in attr(found, "skipped")) {
    message(structure(
      class = c("RMediation_constraint_branch_skipped", "message", "condition"),
      list(
        message = sprintf(
          "Constraint '%s' depends on more than 5 parameters; the wrong-branch check was skipped.\n", nm
        ),
        call = NULL
      )
    ))
  }
  invisible(NULL)
}

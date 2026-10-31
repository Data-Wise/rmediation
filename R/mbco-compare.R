# Scaled violation of every constraint of a fitted MxModel, named by constraint:
# the violation divided by max(1, |lhs|, |rhs|) (largest entry for matrix-valued
# sides). For "==" the violation is |lhs - rhs|; for "<" it is max(lhs - rhs, 0)
# and for ">" it is max(rhs - lhs, 0), so a slack inequality has violation 0.
# Evaluated at the final parameters, so it does not depend on how the model was
# fitted. Operators other than these are not evaluated.
.mbco_constraint_violation <- function(model) {
  out <- vapply(model@constraints, function(constraint) {
    f <- constraint@formula
    op <- as.character(f[[1L]])
    if (!op %in% c("==", "<", "<=", ">", ">=")) {
      return(NA_real_)
    }
    side <- function(expr) {
      tryCatch(
        eval(bquote(OpenMx::mxEval(.(expr), model, compute = FALSE))),
        error = function(e) {
          stop(sprintf(
            "could not evaluate constraint '%s' for the violation check: %s",
            constraint@name, conditionMessage(e)
          ), call. = FALSE)
        }
      )
    }
    lhs <- side(f[[2L]])
    rhs <- side(f[[3L]])
    d <- switch(op,
      "==" = abs(lhs - rhs),
      "<" = , "<=" = pmax(lhs - rhs, 0),
      pmax(rhs - lhs, 0)
    )
    max(d / pmax(1, abs(lhs), abs(rhs)))
  }, numeric(1))
  out[!is.na(out)]
}

# Warn (class RMediation_constraint_violation) when a fitted constraint is
# violated by more than `threshold`. The result of mbco() is never altered.
.mbco_warn_constraints <- function(model, label, threshold = 1e-6) {
  v <- .mbco_constraint_violation(model)
  bad <- v[v > threshold]
  for (nm in names(bad)) {
    warning(structure(
      class = c("RMediation_constraint_violation", "warning", "condition"),
      list(
        message = sprintf(
          paste0(
            "Constraint '%s' of %s is violated at the fitted solution ",
            "(scaled violation %.3g), so the MBCO statistic may be understated. ",
            "OpenMx accepts constraint violations up to its \"Feasibility ",
            "tolerance\" (default 0.05); refit with mxOption(model, ",
            "\"Feasibility tolerance\", 1e-8). For a product null such as ",
            "a*b = 0, use mbco_product_null() (or fit a = 0 and b = 0 separately and ",
            "use the smaller -2LL); ",
            "note that a feasible single-constraint fit can still sit on the ",
            "wrong branch (see ?mbco)."
          ),
          nm, label, bad[[nm]]
        ),
        call = NULL
      )
    ))
  }
  invisible(v)
}

# Refit a violated h0 at a tighter feasibility tolerance (issue #34, grill 2026-10-14).
# NULL when h0 has no violated constraint. Otherwise a list: `model` and `refit`
# (tolerance, statistic_before, statistic_after) on success, or `model = NULL`,
# `refit = NULL` and a `failure` reason when the refit errors, does not converge or is
# still violated. Never an error: the caller falls back to the user's fit.
.mbco_run_refit <- function(model) {
  suppressWarnings(OpenMx::mxRun(model, silent = TRUE))
}

.mbco_signal <- function(class, message) {
  warning(structure(
    class = c(class, "warning", "condition"),
    list(message = message, call = NULL)
  ))
}

# Issue #84: after a successful refit, say so when h0's fit was identical to h1's (-2LL difference
# about 0) although a constraint was violated: the constraint may not have been enforced. OpenMx can
# silently drop an equality constraint whose Jacobian row is zero at the starting values
# (OpenMx/OpenMx#433), and a violation within the feasibility tolerance looks the same. A fitted h0
# keeps no starting values, so the two causes cannot be told apart here; the message says so.
.mbco_report_dropped <- function(refit, threshold = 1e-6) {
  before <- refit$refit$statistic_before
  if (is.null(before) || !is.finite(before) || abs(before) >= threshold) {
    return(invisible(NULL))
  }
  .mbco_signal("RMediation_constraint_dropped", paste0(
    "The fit of h0 is identical to the fit of h1 (-2LL difference ",
    format(round(before, 4)), ") although a constraint of h0 was violated, ",
    "so the constraint may not have been enforced. OpenMx can silently drop an equality ",
    "constraint whose Jacobian is zero at the starting values (OpenMx/OpenMx#433), for example ",
    "b1 * b2 == 0 started at zero; a violation within the feasibility tolerance looks the same. ",
    "A fitted h0 keeps no starting values, so mbco() cannot tell these causes apart. The reported ",
    "statistic comes from the refit. For a product null use mbco_product_null() (see ?mbco)."
  ))
  invisible(NULL)
}

# A violated h0 that cannot be repaired is an error, never a number (grill 2026-10-14).
.mbco_stop_refit_failed <- function(h0, failure, threshold = 1e-6) {
  v <- .mbco_constraint_violation(h0)
  bad <- names(v)[v > threshold]
  stop(structure(
    class = c("RMediation_h0_refit_failed", "error", "condition"),
    list(
      message = sprintf(
        paste0(
          "Constraint %s of h0 is violated at the fitted solution and %s, so the MBCO ",
          "statistic would be understated. Refit h0 yourself with mxOption(model, ",
          "\"Feasibility tolerance\", 1e-8), or for a product null such as a*b = 0 use ",
          "mbco_product_null() (see ?mbco)."
        ),
        paste0("'", bad, "'", collapse = ", "), failure
      ),
      call = NULL
    )
  ))
}

.mbco_refit_h0 <- function(h0, h1, threshold = 1e-6, tolerance = 1e-8) {
  if (!any(.mbco_constraint_violation(h0) > threshold)) {
    return(NULL)
  }
  failed <- function(why) list(model = NULL, refit = NULL, failure = why)
  fit <- tryCatch(
    .mbco_run_refit(OpenMx::mxOption(h0, "Feasibility tolerance", tolerance)),
    error = function(e) e
  )
  if (inherits(fit, "error")) {
    return(failed(sprintf("the refit failed: %s", conditionMessage(fit))))
  }
  if (!.mbco_status_ok(fit)) {
    return(failed("the refit did not converge"))
  }
  if (any(.mbco_constraint_violation(fit) > threshold)) {
    return(failed("a constraint is still violated after the refit"))
  }
  list(
    model = fit,
    refit = list(
      tolerance = tolerance,
      statistic_before = OpenMx::mxCompare(h1, h0)$diffLL[2],
      statistic_after = OpenMx::mxCompare(h1, fit)$diffLL[2]
    )
  )
}

# Validate the observed comparison before any bootstrap sampling.
# OpenMx optimizer status accepted as "converged" everywhere in this package: 0 (converged) and 1
# (the final iterate meets the optimality conditions to the accuracy requested, though the
# iterates have not converged; OpenMx itself still returns usable estimates). One definition so
# the guards cannot drift apart.
.mbco_status_ok <- function(fit) {
  code <- fit$output$status$code
  length(code) == 1L && !is.na(code) && code %in% c(0, 1)
}

# Warn (class RMediation_fit_nonconverged) when a user-supplied fit carries a status that is not
# accepted. A model with no status at all (never run, or a stand-in) is not flagged here.
.mbco_warn_unconverged <- function(model, label) {
  code <- model$output$status$code
  if (length(code) == 1L && !is.na(code) && !.mbco_status_ok(model)) {
    .mbco_signal("RMediation_fit_nonconverged", sprintf(
      paste0(
        "%s did not converge (OpenMx status code %s), so the MBCO statistic and p-value may ",
        "be unreliable; refit it until it converges."
      ),
      label, format(code)
    ))
  }
  invisible(NULL)
}

.mbco_compare <- function(h0, h1) {
  .mbco_warn_constraints(h0, "h0")
  .mbco_warn_constraints(h1, "h1")
  .mbco_warn_unconverged(h0, "h0")
  .mbco_warn_unconverged(h1, "h1")
  result <- OpenMx::mxCompare(h1, h0)
  df <- result$df[2] - result$df[1]
  if (length(df) != 1L || !is.finite(df) || df <= 0) {
    stop("h0 must be more restricted than h1 (positive df difference).",
      call. = FALSE
    )
  }
  statistic <- result$diffLL[2]
  if (length(statistic) != 1L || !is.finite(statistic) || statistic < 0) {
    stop("The observed MBCO statistic must be finite and nonnegative.",
      call. = FALSE
    )
  }
  result
}

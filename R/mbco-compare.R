# Scaled violation of every equality constraint of a fitted MxModel, named by
# constraint: |lhs - rhs| / max(1, |lhs|, |rhs|) (largest entry for matrix-valued
# sides). Evaluated at the final parameters, so it does not depend on how the
# model was fitted. Operators other than "==" are not evaluated.
.mbco_constraint_violation <- function(model) {
  out <- vapply(model@constraints, function(constraint) {
    f <- constraint@formula
    if (!identical(as.character(f[[1L]]), "==")) {
      return(NA_real_)
    }
    lhs <- eval(bquote(OpenMx::mxEval(.(f[[2L]]), model, compute = FALSE)))
    rhs <- eval(bquote(OpenMx::mxEval(.(f[[3L]]), model, compute = FALSE)))
    max(abs(lhs - rhs) / pmax(1, abs(lhs), abs(rhs)))
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
            "a*b = 0, fit a = 0 and b = 0 separately and use the smaller -2LL; ",
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

# Validate the observed comparison before any bootstrap sampling.
.mbco_compare <- function(h0, h1) {
  .mbco_warn_constraints(h0, "h0")
  .mbco_warn_constraints(h1, "h1")
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

S7::method(mbco, list(S7::class_any, S7::class_any)) <- function(
  h0,
  h1,
  R = 10L,
  type = "asymp",
  alpha = .05,
  checkHess = "No",
  checkSE = "No",
  optim = "SLSQP",
  precision = 1e-9,
  ...
) {
  # Check OpenMx availability
  if (!requireNamespace("OpenMx", quietly = TRUE)) {
    stop(
      "Package 'OpenMx' is required for MBCO functions but is not installed.\n",
      "Install it with: install.packages('OpenMx')\n",
      "Note: OpenMx requires compilation and may take several minutes to install.",
      call. = FALSE
    )
  }

  # Input validation (check class without requiring OpenMx at load time)
  if (!methods::is(h0, "MxModel")) stop("h0 must be an MxModel")
  if (!methods::is(h1, "MxModel")) stop("h1 must be an MxModel")

  checkmate::assert_count(R, positive = TRUE)
  type <- match.arg(type, c("asymp", "parametric", "semi"))
  checkmate::assert_number(alpha, lower = 0, upper = 1, finite = TRUE)
  checkmate::assert_choice(checkHess, c("Yes", "No"))
  checkmate::assert_choice(checkSE, c("Yes", "No"))
  optim <- match.arg(optim, c("NPSOL", "CSOLNP", "SLSQP"))
  checkmate::assert_number(precision, lower = 0, finite = TRUE)

  if (!OpenMx::imxHasNPSOL()) {
    optim <- "SLSQP"
  } # if NPSOL is not available, use SLSQP

  # A violated h0 is refit once at a tighter tolerance, so all three types see the same
  # model; if it cannot be repaired the call stops (fail closed, see ?mbco).
  refit <- .mbco_refit_h0(h0, h1)
  if (!is.null(refit)) {
    if (is.null(refit$model)) {
      .mbco_stop_refit_failed(h0, refit$failure)
    } else {
      h0 <- refit$model
      .mbco_signal("RMediation_h0_refit", sprintf(
        paste0(
          "h0 violated a constraint at the default feasibility tolerance and was ",
          "refit at %s: the statistic changed from %s to %s (see ?mbco)."
        ),
        format(refit$refit$tolerance), format(round(refit$refit$statistic_before, 4)),
        format(round(refit$refit$statistic_after, 4))
      ))
    }
  }

  # Advisory wrong-branch probe on the h0 that will be used: warns, never changes the result or
  # fails the call (see ?mbco).
  .mbco_report_branch(h0, h1)

  res_list <-
    if (type == "asymp") {
      # Asymptotic MBCO LRT
      mbco_asymp(h0 = h0, h1 = h1, alpha = alpha)
    } else if (type == "parametric") {
      # Parametric bootstrap MBCO LRT
      mbco_parametric(
        h0 = h0,
        h1 = h1,
        R = R,
        alpha = alpha,
        checkHess = checkHess,
        checkSE = checkSE,
        optim = optim,
        precision = precision
      )
    } else if (type == "semi") {
      # Semiparametric bootstrap MBCO LRT
      .mbco_semi(
        h0 = h0,
        h1 = h1,
        R = R,
        alpha = alpha,
        checkHess = checkHess,
        checkSE = checkSE,
        optim = optim,
        precision = precision
      )
    }

  # Convert list result to MBCOResult object
  # Assuming res_list has components: chisq, df, p
  MBCOResult(
    statistic = as.numeric(res_list$chisq),
    df = as.numeric(res_list$df),
    p_value = as.numeric(res_list$p),
    type = type,
    refit = refit$refit
  )
}

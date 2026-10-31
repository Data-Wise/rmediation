mbco_parametric <- function(h0 = NULL,
                            h1 = NULL,
                            R = 10L,
                            alpha = .05,
                            checkHess = "No",
                            checkSE = "No",
                            optim = "NPSOL",
                            precision = 1e-9) {
  res <- .mbco_compare(h0, h1)
  # Simulated replicates are raw data, so both models must carry a single raw data set; refuse
  # before any sampling rather than refit a covariance-data model as if it were raw.
  for (model in list(h0, h1)) {
    if (!identical(model$data$type, "raw")) {
      stop("type = \"parametric\" requires h0 and h1 to each have a single raw data set.",
        call. = FALSE
      )
    }
  }
  mbco_chisq <- res$diffLL[2] # Observed chi-square
  mbco_df <- res$df[2] - res$df[1] # df
  saved_options <- getOption("mxOptions")
  on.exit(options(mxOptions = saved_options), add = TRUE)
  OpenMx::mxOption(NULL, "Calculate Hessian", checkHess)
  OpenMx::mxOption(NULL, "Standard Errors", checkSE)
  OpenMx::mxOption(NULL, "Function precision", precision)
  OpenMx::mxOption(NULL, "Default optimizer", optim)

  # The replicate loop is ours, not mxCompare(boot = TRUE)'s, so every replicate null fit gets the
  # convergence and constraint-feasibility checks that .mbco_semi() applies.
  compare_boot <- function(x) {
    sim <- OpenMx::mxGenerateData(h0, returnModel = FALSE)
    .mbco_replicate_statistic(h0, h1, sim, x)
  }
  null_samp <- vapply(seq.int(R), compare_boot, FUN.VALUE = numeric(1))
  mbco_pvalue <- mean(null_samp > mbco_chisq)
  list(
    chisq = mbco_chisq,
    df = mbco_df,
    p = mbco_pvalue
  )
}

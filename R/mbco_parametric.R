mbco_parametric <- function(h0 = NULL,
                            h1 = NULL,
                            R = 10L,
                            alpha = .05,
                            checkHess = "No",
                            checkSE = "No",
                            optim = "NPSOL",
                            precision = 1e-9) {
  saved_options <- getOption("mxOptions")
  on.exit(options(mxOptions = saved_options), add = TRUE)
  OpenMx::mxOption(NULL, "Calculate Hessian", checkHess)
  OpenMx::mxOption(NULL, "Standard Errors", checkSE)
  OpenMx::mxOption(NULL, "Function precision", precision)
  OpenMx::mxOption(NULL, "Default optimizer", optim)

  res <- OpenMx::mxCompare(h1,
    h0,
    boot = TRUE,
    replications = R
  )
  mbco_chisq <- res$diffLL[2] # Chi-square
  mbco_pvalue <- res$p[2] # p-value
  mbco_df <- res$df[2] - res$df[1] # df
  values <- list(mbco_chisq, mbco_df, mbco_pvalue)
  if (any(lengths(values) != 1L) || any(!is.finite(unlist(values))) ||
        mbco_chisq < 0 || mbco_df <= 0 || mbco_pvalue < 0 || mbco_pvalue > 1) {
    stop("Parametric bootstrap comparison returned invalid results.",
      call. = FALSE
    )
  }
  mbcoTest <-
    list(
      chisq = mbco_chisq,
      df = mbco_df,
      p = mbco_pvalue
    )
  return(mbcoTest)
}

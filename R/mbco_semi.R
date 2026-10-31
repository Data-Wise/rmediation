############# semi-parametric mbco

.mbco_semi <- function(h0 = NULL,
                       h1 = NULL,
                       R = 10L,
                       alpha = .05,
                       checkHess = "No",
                       checkSE = "No",
                       optim = "NPSOL",
                       precision = 1e-9) {
  res <- .mbco_compare(h0, h1)
  mbco_chisq <- res$diffLL[2] # Asymptotic chi-square
  mbco_df <- res$df[2] - res$df[1] # df
  saved_options <- getOption("mxOptions")
  on.exit(options(mxOptions = saved_options), add = TRUE)
  OpenMx::mxOption(NULL, "Calculate Hessian", checkHess)
  OpenMx::mxOption(NULL, "Standard Errors", checkSE)
  OpenMx::mxOption(NULL, "Function precision", precision)
  OpenMx::mxOption(NULL, "Default optimizer", optim)

  df <-
    h1$data$observed # Extract the original data from the fitted model
  df <-
    df[h1$manifestVars] # Subset of the manifest variables used to fit the model
  if (any(lapply(df, class) %in% c("factor", "character"))) {
    # Check to see if any of the manisfest variables is factor or character
    stop("One of the variables is factor or character. Please change it to numeric.")
  }

  S <- cov(df) #  sample covariance marix
  US <- tryCatch(chol(S), error = function(e) {
    stop("The sample covariance must be positive definite.", call. = FALSE)
  })
  US_inv <- solve(US) # Cholesky inverse
  Sigma0 <- OpenMx::mxGetExpected(h0, "covariance") # Null covariance
  # if(!matrixcalc::is.positive.definite(Sigma0) ){
  #   Sigma0 <- Matrix::nearPD(Sigma0)
  #   warning(" Sigma0 is not positive defnite. A near positive defnite Sigma0 will be used instead.")
  # }

  USigma0 <- tryCatch(chol(Sigma0), error = function(e) {
    stop("The null covariance must be positive definite.", call. = FALSE)
  })
  df_trans <- as.matrix(df) %*% US_inv %*% USigma0
  df_trans <- data.frame(df_trans)
  compare_boot <- function(x, df) {
    .mbco_replicate_statistic(h0, h1, data.frame(.resample_bootstrap(df)), x)
  }

  null_samp <- vapply(seq.int(R), compare_boot,
    FUN.VALUE = numeric(1), df = df_trans
  )
  boot_p <- .mbco_bootstrap_p(null_samp, mbco_chisq)
  mbco_boot <- list(
    chisq = mbco_chisq,
    df = mbco_df,
    p = boot_p$p,
    dropped = boot_p$dropped
  )
  return(mbco_boot)
}

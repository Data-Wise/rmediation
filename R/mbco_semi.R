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
    df <- .resample_bootstrap(df)
    df <- data.frame(df)
    h0 <-
      OpenMx::mxRun(
        OpenMx::mxModel(h0, OpenMx::mxData(df, type = "raw")),
        silent = TRUE,
        suppressWarnings = TRUE
      )
    h1 <-
      OpenMx::mxRun(
        OpenMx::mxModel(h1, OpenMx::mxData(df, type = "raw")),
        silent = TRUE,
        suppressWarnings = TRUE
      )
    for (fit in list(h0, h1)) {
      if (!.mbco_status_ok(fit)) {
        stop("Bootstrap replicate ", x, " did not converge.", call. = FALSE)
      }
    }
    # A converged replicate null can still violate its constraint, and an infeasible fit
    # understates the statistic. Repair it as the observed h0 is repaired; a replicate that
    # cannot be repaired is an error, never a draw from the null distribution.
    repaired <- .mbco_refit_h0(h0, h1)
    if (!is.null(repaired)) {
      if (is.null(repaired$model)) {
        stop(structure(
          class = c("RMediation_bootstrap_infeasible", "error", "condition"),
          list(
            message = paste0(
              "Bootstrap replicate ", x, " has a violated h0 constraint and ",
              repaired$failure, ", so its statistic would be understated."
            ),
            call = NULL
          )
        ))
      }
      h0 <- repaired$model
    }
    statistic <- OpenMx::mxCompare(h1, h0)$diffLL[2]
    if (length(statistic) != 1L || !is.finite(statistic)) {
      stop("Bootstrap replicate ", x, " has an invalid statistic.",
        call. = FALSE
      )
    }
    statistic
  }

  null_samp <- vapply(seq.int(R), compare_boot,
    FUN.VALUE = numeric(1), df = df_trans
  )
  mbco_pvalue <- mean(null_samp > mbco_chisq)
  mbco_boot <- list(
    chisq = mbco_chisq,
    df = mbco_df,
    p = mbco_pvalue
  )
  return(mbco_boot)
}

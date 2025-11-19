#' @importFrom S7 method
NULL

#' @export
#' @export
S7::method(cdf, ProductNormal) <- function(object, q, type = "dop", n.mc = 1e5, ...) {
  checkmate::assert_numeric(q)
  type <- match.arg(type, c("dop", "MC", "all"))
  checkmate::assert_count(n.mc, positive = TRUE)

  mu <- object@mu
  Sigma <- object@Sigma
  
  if (length(mu) == 2) {
    # Dispatch to existing pprodnormal
    # Extract standard errors and correlation from Sigma
    se.x <- sqrt(Sigma[1, 1])
    se.y <- sqrt(Sigma[2, 2])
    rho <- Sigma[1, 2] / (se.x * se.y)
    
    return(pprodnormal(q, mu.x = mu[1], mu.y = mu[2], se.x = se.x, se.y = se.y, rho = rho, type = type, n.mc = n.mc))
  } else {
    # For > 2 variables, currently only MC is supported/implemented effectively for general case
    # We can implement a simple MC here or dispatch to a new internal function
    # For now, let's implement a direct MC for N variables
    
    if (type == "dop") {
      warning("Exact distribution (dop) not available for > 2 variables. Using Monte Carlo.")
    }
    
    # Monte Carlo implementation for N variables
    # Generate multivariate normal samples
    samples <- MASS::mvrnorm(n = n.mc, mu = mu, Sigma = Sigma)
    # Compute product
    prod_samples <- apply(samples, 1, prod)
    # Compute empirical CDF
    mean(prod_samples <= q)
  }
}

#' @export
S7::method(quantile, ProductNormal) <- function(object, p, type = "dop", n.mc = 1e5, ...) {
  checkmate::assert_numeric(p, lower = 0, upper = 1)
  type <- match.arg(type, c("dop", "MC", "all"))
  checkmate::assert_count(n.mc, positive = TRUE)

  mu <- object@mu
  Sigma <- object@Sigma
  
  if (length(mu) == 2) {
    # Dispatch to existing qprodnormal
    se.x <- sqrt(Sigma[1, 1])
    se.y <- sqrt(Sigma[2, 2])
    rho <- Sigma[1, 2] / (se.x * se.y)
    
    return(qprodnormal(p, mu.x = mu[1], mu.y = mu[2], se.x = se.x, se.y = se.y, rho = rho, type = type, n.mc = n.mc))
  } else {
     if (type == "dop") {
      warning("Exact distribution (dop) not available for > 2 variables. Using Monte Carlo.")
    }
    
    # Monte Carlo implementation for N variables
    samples <- MASS::mvrnorm(n = n.mc, mu = mu, Sigma = Sigma)
    prod_samples <- apply(samples, 1, prod)
    stats::quantile(prod_samples, probs = p)
  }
}

#' @export
S7::method(ci, ProductNormal) <- function(mu, level = 0.95, type = "dop", n.mc = 1e5, ...) {
  object <- mu # Alias for internal use if needed, or just use mu
  checkmate::assert_number(level, lower = 0, upper = 1)
  type <- match.arg(type, c("dop", "MC", "asymp", "all", "prodclin"))
  checkmate::assert_count(n.mc, positive = TRUE)

  alpha <- 1 - level
  mu_vec <- object@mu # Rename local var to avoid conflict
  Sigma <- object@Sigma
  
  if (length(mu_vec) == 2) {
    # Dispatch to existing medci
    se.x <- sqrt(Sigma[1, 1])
    se.y <- sqrt(Sigma[2, 2])
    rho <- Sigma[1, 2] / (se.x * se.y)
    
    res <- medci(mu.x = mu_vec[1], mu.y = mu_vec[2], se.x = se.x, se.y = se.y, rho = rho, alpha = alpha, type = type, n.mc = n.mc, plot = FALSE)
    # medci returns a list or vector depending on type. 
    # If type="dop" (default), it returns a list with CI.
    # We should standardize the output of this method to just the CI vector or a specific object.
    # Let's return the CI vector for consistency with stats::confint
    
    if (is.list(res) && !is.null(res$`95% CI`)) {
       return(res$`95% CI`)
    } else if (is.list(res) && !is.null(res$CI)) {
       return(res$CI)
    } else if (is.numeric(res)) {
       return(res)
    } else {
       # Fallback for other return types of medci
       return(res)
    }

  } else {
     if (type == "dop") {
      warning("Exact distribution (dop) not available for > 2 variables. Using Monte Carlo.")
    }
    
    # Monte Carlo implementation for N variables
    samples <- MASS::mvrnorm(n = n.mc, mu = mu_vec, Sigma = Sigma)
    prod_samples <- apply(samples, 1, prod)
    stats::quantile(prod_samples, probs = c(alpha/2, 1 - alpha/2))
  }
}

#' @export
S7::method(print, ProductNormal) <- function(x, ...) {
  cat("ProductNormal Distribution\n")
  cat("Number of variables:", length(x@mu), "\n")
  cat("Means:", paste(round(x@mu, 4), collapse = ", "), "\n")
  if (length(x@mu) <= 3) {
    cat("Covariance matrix:\n")
    base::print(x@Sigma)
  } else {
    cat("Covariance matrix: ", nrow(x@Sigma), "x", ncol(x@Sigma), "\n")
  }
  invisible(x)
}

#' @export
S7::method(summary, ProductNormal) <- function(object, ...) {
  cat("ProductNormal Distribution Summary\n")
  cat("==================================\n")
  cat("Number of variables:", length(object@mu), "\n\n")
  
  cat("Means:\n")
  base::print(data.frame(Variable = paste0("V", seq_along(object@mu)), 
                         Mean = object@mu))
  
  cat("\nStandard Deviations:\n")
  sds <- sqrt(diag(object@Sigma))
  base::print(data.frame(Variable = paste0("V", seq_along(sds)), 
                         SD = sds))
  
  cat("\nCorrelation Matrix:\n")
  cor_mat <- cov2cor(object@Sigma)
  base::print(round(cor_mat, 4))
  
  invisible(object)
}

#' @export
S7::method(show, ProductNormal) <- function(object) {
  print(object)
}

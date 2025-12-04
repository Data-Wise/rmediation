# Integration with medfit package
#
# This file provides ci() method for medfit's MediationData class,
# enabling seamless use of RMediation's CI methods with medfit objects.

#' Confidence Interval for MediationData Objects
#'
#' @description
#' Computes confidence intervals for the indirect effect from a medfit
#' MediationData object using RMediation's methods (DOP, Monte Carlo, etc.).
#'
#' @param mu A MediationData object from the medfit package
#' @param level Confidence level (default 0.95 for 95% CI)
#' @param type Type of CI method: "dop" (Distribution of Product),
#'   "MC" (Monte Carlo), or "asymp" (asymptotic normal)
#' @param n.mc Number of Monte Carlo samples (for type = "MC")
#' @param ... Additional arguments passed to underlying methods
#'
#' @return A list with components:
#'   \item{CI}{The confidence interval (lower, upper)}
#'   \item{Estimate}{Point estimate of indirect effect (a*b)}
#'   \item{SE}{Standard error of indirect effect}
#'   \item{type}{Method used for CI computation}
#'
#' @details
#' This method extracts the a and b path coefficients from the MediationData

#' object, along with their standard errors and covariance, and computes
#' confidence intervals using RMediation's methods.
#'
#' ## Method Options
#'
#' - **"dop"**: Distribution of Product method. Uses the exact or approximate
#'   distribution of the product of two normal random variables. Recommended
#'   for most applications.
#'
#' - **"MC"**: Monte Carlo simulation. Samples from the joint distribution
#'   of a and b to estimate the CI. Use `n.mc` to control precision.
#'
#' - **"asymp"**: Asymptotic normal approximation using the delta method.
#'   Fast but may be inaccurate for small samples or non-normal distributions.
#'
#' @examples
#' \dontrun{
#' library(medfit)
#' library(RMediation)
#'
#' # Fit mediation models
#' fit_m <- lm(M ~ X + C, data = mydata)
#' fit_y <- lm(Y ~ X + M + C, data = mydata)
#'
#' # Extract mediation structure
#' med_data <- extract_mediation(fit_m, model_y = fit_y,
#'                                treatment = "X", mediator = "M")
#'
#' # Compute CI using Distribution of Product
#' ci(med_data, type = "dop")
#'
#' # Compute CI using Monte Carlo
#' ci(med_data, type = "MC", n.mc = 10000)
#' }
#'
#' @seealso
#' \code{\link{ci}} for the generic function,
#' \code{\link[medfit]{MediationData}} for the input class,
#' \code{\link{ProductNormal}} for the underlying distribution class
#'
#' @export
ci_mediation_data <- function(mu, level = 0.95, type = "dop", n.mc = 1e5, ...) {
  # Validate medfit is available

  if (!requireNamespace("medfit", quietly = TRUE)) {
    stop("Package 'medfit' is required for this method. ",
         "Install with: pak::pak('data-wise/medfit')",
         call. = FALSE)
  }

  # Extract path coefficients
  a <- mu@a_path
  b <- mu@b_path

  # Get standard errors from estimates and vcov
  # The estimates vector should have named elements or we need to find them
  est_names <- names(mu@estimates)
  vcov_mat <- mu@vcov

  # Try to find a and b in the estimates
  # Common naming conventions: "a", "b", treatment name, mediator name
  a_idx <- NULL
  b_idx <- NULL

  # Strategy 1: Look for "a" and "b" labels

if (!is.null(est_names)) {
    if ("a" %in% est_names) a_idx <- which(est_names == "a")
    if ("b" %in% est_names) b_idx <- which(est_names == "b")
  }

  # Strategy 2: If vcov has row/col names, use those
  if (is.null(a_idx) || is.null(b_idx)) {
    vcov_names <- rownames(vcov_mat)
    if (!is.null(vcov_names)) {
      if ("a" %in% vcov_names) a_idx <- which(vcov_names == "a")
      if ("b" %in% vcov_names) b_idx <- which(vcov_names == "b")
    }
  }

  # Strategy 3: For simple mediation, a is typically position 1, b is position 2
  # in a minimal parameter vector [a, b] or [a, b, c']
  if (is.null(a_idx) || is.null(b_idx)) {
    if (length(mu@estimates) >= 2) {
      # Check if first two elements match a and b paths
      if (abs(mu@estimates[1] - a) < 1e-10) a_idx <- 1
      if (abs(mu@estimates[2] - b) < 1e-10) b_idx <- 2
    }
  }

  # If we still can't find indices, compute SEs differently
  if (is.null(a_idx) || is.null(b_idx)) {
    # Use robust approach: extract SE from diagonal elements
    # This is a fallback that may not capture covariance correctly
    warning("Could not identify a and b parameters in vcov matrix. ",
            "Using approximation assuming independent parameters.",
            call. = FALSE)

    # Estimate SEs from vcov diagonal
    diag_var <- diag(vcov_mat)

    # Find which diagonal element gives the closest match to typical SE
    # This is a heuristic approach
    se_a <- sqrt(diag_var[1])
    se_b <- sqrt(diag_var[2])
    cov_ab <- 0  # Assume independent as fallback
  } else {
    # Extract variances and covariance
    se_a <- sqrt(vcov_mat[a_idx, a_idx])
    se_b <- sqrt(vcov_mat[b_idx, b_idx])
    cov_ab <- vcov_mat[a_idx, b_idx]
  }

  # Build covariance matrix for a, b
  sigma_ab <- matrix(c(se_a^2, cov_ab, cov_ab, se_b^2), nrow = 2,
                     dimnames = list(c("a", "b"), c("a", "b")))

  # Create ProductNormal and compute CI
  pn <- ProductNormal(
    mu = c(a, b),
    Sigma = sigma_ab
  )

  # Use the ProductNormal ci method
  ci(pn, level = level, type = type, n.mc = n.mc, ...)
}

#' @rdname ci_mediation_data
#' @export
ci_serial_mediation_data <- function(mu, level = 0.95, type = "MC", n.mc = 1e5, ...) {
  # Validate medfit is available
  if (!requireNamespace("medfit", quietly = TRUE)) {
    stop("Package 'medfit' is required for this method. ",
         "Install with: pak::pak('data-wise/medfit')",
         call. = FALSE)
  }

  # For serial mediation (product of 3+), Monte Carlo is the practical choice
  # since DOP doesn't generalize easily to products of 3+ normal RVs

  # Extract all path coefficients
  a <- mu@a_path
  d <- mu@d_path  # Vector for serial mediation
  b <- mu@b_path

  # Total number of paths in product
  all_paths <- c(a, d, b)
  k <- length(all_paths)

  # Point estimate of indirect effect
  indirect <- prod(all_paths)

  # For Monte Carlo, we need the full covariance matrix of [a, d1, d2, ..., b]
  # This is complex because we need to map to the vcov matrix

  # Get the vcov matrix
  vcov_mat <- mu@vcov

  # For now, use simplified approach assuming we can identify the parameters
  # TODO: Implement full covariance extraction

  # Use Monte Carlo simulation
  # Generate samples from multivariate normal
  if (!requireNamespace("MASS", quietly = TRUE)) {
    stop("Package 'MASS' is required for Monte Carlo CI",
         call. = FALSE)
  }

  # Try to extract sub-covariance matrix for the paths
  # This is a placeholder - full implementation would need parameter mapping
  n_params <- length(mu@estimates)

  if (n_params == k) {
    # Simple case: estimates are just the path coefficients
    sigma_paths <- vcov_mat
  } else {
    # Complex case: need to extract relevant sub-matrix
    # For now, use diagonal (assuming independence) with warning
    warning("Full covariance extraction for serial mediation not yet implemented. ",
            "Using diagonal variance approximation.",
            call. = FALSE)
    sigma_paths <- diag(diag(vcov_mat)[seq_len(k)])
  }

  # Monte Carlo simulation
  samples <- MASS::mvrnorm(n = n.mc, mu = all_paths, Sigma = sigma_paths)

  # Compute product for each sample (product across columns)
  indirect_samples <- apply(samples, 1, prod)

  # Compute CI from quantiles
  alpha <- 1 - level
  ci_lower <- stats::quantile(indirect_samples, alpha / 2)
  ci_upper <- stats::quantile(indirect_samples, 1 - alpha / 2)

  # Standard error from samples
  se_indirect <- stats::sd(indirect_samples)

  list(
    CI = c(lower = unname(ci_lower), upper = unname(ci_upper)),
    Estimate = indirect,
    SE = se_indirect,
    type = "MC (serial mediation)",
    level = level,
    n.mc = n.mc,
    k = k  # Number of paths in product
  )
}


# Dynamic method registration in .onLoad
# This will be called from zzz.R
.register_medfit_methods <- function() {
  if (requireNamespace("medfit", quietly = TRUE)) {
    # Get the MediationData and SerialMediationData classes from medfit
    tryCatch({
      # Register ci method for MediationData
      MediationData_class <- medfit::MediationData
      S7::method(ci, MediationData_class) <- ci_mediation_data

      # Register ci method for SerialMediationData
      SerialMediationData_class <- medfit::SerialMediationData
      S7::method(ci, SerialMediationData_class) <- ci_serial_mediation_data
    }, error = function(e) {
      # Silently fail if registration doesn't work
      # Methods will still be available as regular functions
    })
  }
}

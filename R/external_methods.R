#' @importFrom S7 method
#' @importFrom lavaan parameterEstimates
NULL

# Helper function to parse product strings
.parse_product_string <- function(expr_str) {
  expr_str <- gsub("\\s+", "", expr_str)
  parts <- strsplit(expr_str, "\\*")[[1]]
  if (any(grepl("[^a-zA-Z0-9_.]", parts))) {
    return(NULL)
  }
  return(parts)
}

#' @return A named list with elements \code{CI}, \code{Estimate}, \code{SE},
#'   and (for Monte Carlo) \code{MC.Error}. When \code{type = "all"}, a list
#'   with elements \code{MC} and \code{Asymptotic}.
#' @noRd
S7::method(ci, S7::class_numeric) <- function(object, Sigma, quant, alpha = 0.05, type = "MC", ...) {
  # Dispatch to legacy .ci_core
  mu <- object
  checkmate::assert_numeric(mu)
  checkmate::assert(
    checkmate::check_matrix(Sigma, mode = "numeric"),
    checkmate::check_numeric(Sigma)
  )
  checkmate::assert_formula(quant)
  checkmate::assert_number(alpha, lower = 0, upper = 1)
  type <- match.arg(type, c("MC", "asymp", "all"))

  # We pass all arguments explicitly to .ci_core
  .ci_core(mu = mu, Sigma = Sigma, quant = quant, alpha = alpha, type = type, ...)
}

#' @return A named list of CI results (one per defined parameter in the lavaan
#'   object), each with elements \code{CI}, \code{Estimate}, and \code{SE}.
#' @noRd
S7::method(ci, S7::class_any) <- function(object, level = 0.95, type = "dop", n.mc = 1e5, ...) {
  type_given <- !missing(type) # before match.arg() rebinds `type`
  checkmate::assert_number(level, lower = 0, upper = 1)
  type <- match.arg(type, c("dop", "MC", "asymp", "all", "prodclin"))
  checkmate::assert_count(n.mc, positive = TRUE)

  if (!inherits(object, "lavaan")) {
    # If we want to support other classes later (like MxModel), add checks here.
    # For now, if it's not lavaan, we throw an error (or let S7 dispatch fail if we didn't define this).
    # But since we defined it for class_any, we must handle it.
    stop(paste("No method defined for class:", paste(class(object), collapse = ", ")))
  }

  # Lavaan logic
  args <- list(...)

  # Check if 'quant' is provided in ...
  if ("quant" %in% names(args)) {
    # Legacy behavior: user provided a specific formula
    if ("alpha" %in% names(args)) {
      alpha <- args[["alpha"]]
      args[["alpha"]] <- NULL
    } else {
      alpha <- 1 - level
    }
    return(do.call(.ci_core, c(list(mu = object, alpha = alpha), args)))
  }

  # New behavior: Auto-detect defined parameters
  est <- lavaan::parameterEstimates(object)
  defined <- est[est$op == ":=", ]

  if (nrow(defined) == 0) {
    warning("No defined parameters (:=) found in lavaan object.")
    return(NULL)
  }

  results <- list()

  # Determine alpha for new behavior
  if ("alpha" %in% names(args)) {
    alpha <- args[["alpha"]]
  } else {
    alpha <- 1 - level
  }

  # General Monte Carlo interval for a defined parameter that is not a simple
  # product of estimated coefficients. It ignores `type`, so say so when the
  # caller chose one explicitly. A formula .ci_core cannot resolve (for example
  # one that names another defined parameter) must not discard the other
  # results: warn and return NULL for that label only.
  mc_fallback <- function(label, rhs) {
    if (type_given && type != "MC") {
      warning(sprintf(
        "Defined parameter '%s' is not a product of estimated coefficients; using a Monte Carlo interval instead of type = \"%s\".",
        label, type
      ), call. = FALSE)
    }
    quant <- as.formula(paste("~", rhs))
    tryCatch(
      .ci_core(mu = object, quant = quant, alpha = alpha, type = "MC", n.mc = n.mc, plot = FALSE),
      error = function(e) {
        warning(sprintf(
          "No interval for defined parameter '%s' (:= %s): %s",
          label, rhs, conditionMessage(e)
        ), call. = FALSE)
        NULL
      }
    )
  }

  for (i in 1:nrow(defined)) {
    label <- defined$lhs[i]
    rhs <- defined$rhs[i]

    vars <- .parse_product_string(rhs)

    if (!is.null(vars) && length(vars) >= 2) {
      # Product of coefficients
      coefs <- lavaan::coef(object)
      vcov_mat <- lavaan::vcov(object)

      if (all(vars %in% names(coefs))) {
        mu_vals <- coefs[vars]
        Sigma_vals <- vcov_mat[vars, vars]

        pn <- ProductNormal(mu = as.numeric(mu_vals), Sigma = as.matrix(Sigma_vals))

        # Calculate CI using ProductNormal method
        # Note: ci(ProductNormal) returns vector.
        # We pass level/alpha correctly. ProductNormal ci uses level.
        # If user passed alpha, we convert back to level for consistency with S7 generic?
        # Or just pass level if we have it.
        # The generic has 'level'.
        res_ci <- ci(pn, level = 1 - alpha, type = type, n.mc = n.mc)
        results[[label]] <- res_ci
      } else {
        # Fallback to general MC via .ci_core (e.g. a product that includes
        # another defined parameter, which is not an estimated coefficient).
        results[label] <- list(mc_fallback(label, rhs))
      }
    } else {
      # Not a simple product, use general MC
      results[label] <- list(mc_fallback(label, rhs))
    }
  }

  return(results)
}

# Note: removed quantile methods for class_numeric since dist_quantile is for distributions only
# Data quantiles should use stats::quantile directly

#' @return A numeric vector of empirical CDF values at \code{q}.
#' @noRd
S7::method(cdf, S7::class_numeric) <- function(object, q, ...) {
  # Empirical CDF for numeric vectors
  stats::ecdf(object)(q)
}

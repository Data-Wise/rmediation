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

# Replace symbols by the expressions in `env`, leaving function names alone (a defined
# parameter called `log` must not rewrite the call `log(a)`).
.subst_symbols <- function(e, env) {
  if (is.symbol(e)) {
    nm <- as.character(e)
    return(if (nm %in% names(env)) env[[nm]] else e)
  }
  if (is.call(e)) {
    for (k in seq_along(e)[-1L]) {
      e[[k]] <- .subst_symbols(e[[k]], env)
    }
  }
  e
}

# Expand defined parameters (`:=`) that refer to other defined parameters.
# `rhs` is a named character vector (names = labels). Substitution is done on parsed
# expressions, never on the text, so a label that is a substring of another name
# (`ab` inside `tab`) or that is also a function name (`c`) is handled correctly.
# Returns list(expr = <named list of calls, NULL where unresolved>,
#              problem = <named character vector, NA where resolved>).
.expand_defined <- function(rhs) {
  labels <- names(rhs)
  parsed <- lapply(rhs, function(r) tryCatch(str2lang(r), error = function(e) NULL))
  # Mutable state lives in an environment, so `resolve()` updates it without `<<-`.
  st <- new.env(parent = emptyenv())
  st$expr <- stats::setNames(vector("list", length(rhs)), labels)
  st$problem <- stats::setNames(rep(NA_character_, length(rhs)), labels)
  st$state <- stats::setNames(rep("todo", length(rhs)), labels) # todo | active | done

  resolve <- function(lab) {
    if (st$state[[lab]] == "done") {
      return(invisible())
    }
    if (st$state[[lab]] == "active") {
      return(invisible()) # caller sees the cycle through the still-unresolved entry
    }
    st$state[[lab]] <- "active"
    e <- parsed[[lab]]
    if (is.null(e)) {
      st$problem[[lab]] <- sprintf("cannot parse `%s`", rhs[[lab]])
      st$state[[lab]] <- "done"
      return(invisible())
    }
    refs <- intersect(all.vars(e), labels)
    bad <- NULL
    env <- list()
    for (r in refs) {
      resolve(r)
      if (st$state[[r]] == "active" || is.null(st$expr[[r]])) {
        bad <- c(bad, r)
      } else {
        env[[r]] <- st$expr[[r]]
      }
    }
    if (length(bad) > 0L) {
      st$problem[[lab]] <- sprintf(
        "depends on defined parameter(s) that cannot be resolved (%s), possibly a cycle",
        paste(bad, collapse = ", ")
      )
    } else {
      st$expr[[lab]] <- if (length(env) > 0L) .subst_symbols(e, env) else e
    }
    st$state[[lab]] <- "done"
    invisible()
  }
  for (lab in labels) resolve(lab)
  list(expr = st$expr, problem = st$problem)
}

# Factor names when `e` is a pure product of symbols (through `*` and parentheses),
# else NULL. `(a*b)*c` and `a*b*c` give the same factors.
.product_factors <- function(e) {
  if (is.symbol(e)) {
    return(as.character(e))
  }
  if (!is.call(e)) {
    return(NULL)
  }
  op <- as.character(e[[1L]])
  if (identical(op, "(") && length(e) == 2L) {
    return(.product_factors(e[[2L]]))
  }
  if (identical(op, "*") && length(e) == 3L) {
    l <- .product_factors(e[[2L]])
    r <- .product_factors(e[[3L]])
    if (is.null(l) || is.null(r)) {
      return(NULL)
    }
    return(c(l, r))
  }
  NULL
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

  # A defined parameter may refer to another one (`abc := ab*c`): expand those references
  # first. One that cannot be resolved loses only its own entry, with a warning.
  expanded <- .expand_defined(stats::setNames(defined$rhs, defined$lhs))
  coefs <- lavaan::coef(object)
  vcov_mat <- lavaan::vcov(object)

  # General Monte Carlo interval for a defined parameter that is not a product of
  # estimated coefficients. It ignores `type`, so say so when the caller chose one
  # explicitly.
  mc_fallback <- function(label, e) {
    if (type_given && type != "MC") {
      warning(sprintf(
        paste0(
          "Defined parameter '%s' is not a product of estimated coefficients; ",
          "using a Monte Carlo interval instead of type = \"%s\"."
        ),
        label, type
      ), call. = FALSE)
    }
    tryCatch(
      .ci_core(
        mu = object, quant = stats::as.formula(paste("~", deparse1(e))), alpha = alpha,
        type = "MC", n.mc = n.mc, plot = FALSE
      ),
      error = function(err) {
        warning(sprintf(
          "No interval for defined parameter '%s' (:= %s): %s",
          label, deparse1(e), conditionMessage(err)
        ), call. = FALSE)
        NULL
      }
    )
  }

  for (i in seq_len(nrow(defined))) {
    label <- defined$lhs[i]
    e <- expanded$expr[[label]]

    if (is.null(e)) {
      warning(sprintf(
        "No interval for defined parameter '%s' (:= %s): %s",
        label, defined$rhs[i], expanded$problem[[label]]
      ), call. = FALSE)
      results[label] <- list(NULL)
      next
    }

    vars <- .product_factors(e)

    if (!is.null(vars) && length(vars) >= 2L && all(vars %in% names(coefs))) {
      pn <- ProductNormal(
        mu = as.numeric(coefs[vars]),
        Sigma = as.matrix(vcov_mat[vars, vars])
      )
      k <- length(vars)
      if (k == 3L && type != "MC") {
        # Exactly three factors have an exact interval of their own (pprodnormal3()).
        # It does not depend on `type`, so say so when the caller asked for the
        # asymptotic or prodclin interval, or for all of them. Its result is the named
        # c(lower, upper) that ci(<ProductNormal3>) returns.
        if (type_given && type != "dop") {
          warning(sprintf(
            paste0(
              "Defined parameter '%s' is a product of 3 coefficients; ",
              "using the exact three-factor interval instead of type = \"%s\"."
            ),
            label, type
          ), call. = FALSE)
        }
        results[[label]] <- ci(
          ProductNormal3(mu = as.numeric(coefs[vars]), Sigma = as.matrix(vcov_mat[vars, vars])),
          level = 1 - alpha
        )
      } else {
        # Four or more factors have no exact interval: Monte Carlo, with a warning when
        # the caller chose another `type` explicitly. `type = "MC"` is used as asked.
        ptype <- type
        if (k >= 4L && type != "MC") {
          if (type_given) {
            warning(sprintf(
              paste0(
                "Defined parameter '%s' is a product of %d coefficients; ",
                "using a Monte Carlo interval instead of type = \"%s\"."
              ),
              label, k, type
            ), call. = FALSE)
          }
          ptype <- "MC"
        }
        # ci(ProductNormal) takes `level`, so convert back from alpha.
        results[[label]] <- ci(pn, level = 1 - alpha, type = ptype, n.mc = n.mc)
      }
    } else {
      results[label] <- list(mc_fallback(label, e))
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

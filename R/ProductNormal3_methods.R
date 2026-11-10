#' @importFrom S7 method
#' @importFrom stats confint qnorm uniroot
NULL

#' @return The object \code{x} invisibly.
#' @export
S7::method(print, ProductNormal3) <- function(x, ...) {
  cat("ProductNormal3 Distribution\n")
  cat("Variables: a1 * a2 * b\n")
  cat("Means:", paste(round(x@mu, 4), collapse = ", "), "\n")
  cat("Covariance matrix:\n")
  base::print.default(x@Sigma)
  cat("Integration method:", x@method, "\n")
  invisible(x)
}

#' @return The object \code{object} invisibly (via \code{print}).
#' @export
S7::method(show, ProductNormal3) <- function(object) {
  print(object)
}

#' @return A numeric vector of CDF probabilities at \code{q}.
#' @export
S7::method(cdf, ProductNormal3) <- function(object, q, lower.tail = TRUE, tol = 1e-6, ...) {
  checkmate::assert_numeric(q, finite = TRUE)
  checkmate::assert_flag(lower.tail)
  checkmate::assert_number(tol, lower = 0)

  # The upper tail is integrated directly, not computed as 1 - p, so a far upper tail is resolved (#177).
  vapply(q, function(qq) {
    pprodnormal3(qq, # nolint: object_usage_linter.
      mean = object@mu, cov = object@Sigma,
      method = object@method, tol = tol, lower.tail = lower.tail
    )
  }, FUN.VALUE = numeric(1))
}

#' @noRd
.prod3_quantile <- function(p, mean, cov, lower, upper, tol = 1e-4, lower.tail = TRUE, method = "gauss") {
  f <- function(q) {
    # nolint next: object_usage_linter.
    pprodnormal3(q, mean = mean, cov = cov, method = method, tol = tol, lower.tail = lower.tail) - p
  }
  res <- stats::uniroot(f, interval = c(lower, upper), tol = tol, extendInt = "yes")
  res$root
}

# Delta-method centre and scale used to bracket the root; shared by dist_quantile() and qprodnormal3().
#' @noRd
.prod3_delta_scale <- function(mean, cov) {
  grad <- c(mean[2L] * mean[3L], mean[1L] * mean[3L], mean[1L] * mean[2L])
  var_delta <- as.numeric(t(grad) %*% cov %*% grad)
  sd_delta <- sqrt(max(var_delta, 0))
  sds <- sqrt(pmax(diag(cov), 0))
  if (sd_delta <= .Machine$double.eps) {
    non_zero_sds <- sds[sds > .Machine$double.eps]
    sd_delta <- if (length(non_zero_sds) > 0) prod(non_zero_sds) else 1
  }
  list(center = prod(mean), sd = sd_delta, point_mass = all(sds <= .Machine$double.eps))
}

# One quantile: bracket with the delta interval (8 sd wide) and invert the CDF by root-finding.
#' @noRd
.qprodnormal3_one <- function(p, mean, cov, lower.tail, tol, method = "gauss") {
  if (p == 0 || p == 1) {
    return(if ((p == 0) == lower.tail) -Inf else Inf)
  }
  sc <- .prod3_delta_scale(mean, cov)
  if (sc$point_mass) {
    return(sc$center)
  }
  p_lower <- if (lower.tail) p else 1 - p
  center <- sc$center + sign(p_lower - 0.5) * stats::qnorm(0.975) * sc$sd
  width <- 8 * sc$sd
  .prod3_quantile(p,
    mean = mean, cov = cov, lower = center - width, upper = center + width,
    tol = tol, lower.tail = lower.tail, method = method
  )
}

#' @return A numeric vector of quantiles at probabilities \code{p}.
#' @export
S7::method(dist_quantile, ProductNormal3) <- function(object, p, tol = 1e-4, ...) {
  checkmate::assert_numeric(p, lower = 0, upper = 1, finite = TRUE)
  checkmate::assert_number(tol, lower = 0)
  vapply(p, .qprodnormal3_one, FUN.VALUE = numeric(1),
    mean = object@mu, cov = object@Sigma, lower.tail = TRUE, tol = tol, method = object@method
  )
}

#' @noRd
.confint_productnormal3 <- function(object, level = 0.95, tol = 1e-4) {
  checkmate::assert_number(level, lower = 0, upper = 1)
  checkmate::assert_number(tol, lower = 0)

  mu <- object@mu
  Sigma <- object@Sigma
  alpha <- 1 - level
  probs <- c(alpha / 2, 1 - alpha / 2)

  mean_v <- prod(mu)
  grad <- c(mu[2L] * mu[3L], mu[1L] * mu[3L], mu[1L] * mu[2L])
  var_delta <- as.numeric(t(grad) %*% Sigma %*% grad)
  sd_delta <- sqrt(max(var_delta, 0))
  sds <- sqrt(pmax(diag(Sigma), 0))

  if (sd_delta <= .Machine$double.eps) {
    non_zero_sds <- sds[sds > .Machine$double.eps]
    sd_delta <- if (length(non_zero_sds) > 0) prod(non_zero_sds) else 1
  }

  z <- stats::qnorm(1 - alpha / 2)
  # Delta-method interval; expand generously to guarantee the true quantiles
  # are bracketed.
  delta_width <- 8 * sd_delta

  quantiles <- vapply(probs, function(p) {
    center <- mean_v + sign(p - 0.5) * z * sd_delta
    lower <- center - delta_width
    upper <- center + delta_width
    .prod3_quantile(p,
      mean = mu, cov = Sigma, lower = lower, upper = upper, tol = tol,
      method = object@method
    )
  }, FUN.VALUE = numeric(1))

  c(lower = quantiles[1L], upper = quantiles[2L])
}

#' @return A named numeric vector with elements \code{lower} and \code{upper}.
#' @export
S7::method(confint, ProductNormal3) <- function(object, parm, level = 0.95, tol = 1e-5, ...) {
  .confint_productnormal3(object, level = level, tol = tol)
}

#' @return A named numeric vector with elements \code{lower} and \code{upper}.
#' @export
S7::method(ci, ProductNormal3) <- function(object, level = 0.95, tol = 1e-5, ...) {
  .confint_productnormal3(object, level = level, tol = tol)
}

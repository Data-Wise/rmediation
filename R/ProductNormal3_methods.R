#' @importFrom S7 method
#' @importFrom stats confint qnorm uniroot
NULL

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

#' @export
S7::method(show, ProductNormal3) <- function(object) {
  print(object)
}

#' @export
S7::method(cdf, ProductNormal3) <- function(object, q, lower.tail = TRUE, tol = 1e-6, ...) {
  checkmate::assert_numeric(q, finite = TRUE)
  checkmate::assert_logical(lower.tail)
  checkmate::assert_number(tol, lower = 0)

  p <- vapply(q, function(qq) {
    p_prod3(qq, # nolint: object_usage_linter.
      mean = object@mu, cov = object@Sigma,
      method = object@method, tol = tol
    )
  }, FUN.VALUE = numeric(1))

  if (!lower.tail) {
    p <- 1 - p
  }

  p
}

#' @noRd
.prod3_quantile <- function(p, mean, cov, lower, upper, tol = 1e-4) {
  f <- function(q) p_prod3(q, mean = mean, cov = cov, tol = tol) - p # nolint: object_usage_linter.
  res <- stats::uniroot(f, interval = c(lower, upper), tol = tol, extendInt = "yes")
  res$root
}

#' @export
S7::method(dist_quantile, ProductNormal3) <- function(object, p, tol = 1e-4, ...) {
  checkmate::assert_numeric(p, lower = 0, upper = 1, finite = TRUE)
  checkmate::assert_number(tol, lower = 0)

  mu <- object@mu
  Sigma <- object@Sigma
  mean_v <- prod(mu)
  grad <- c(mu[2L] * mu[3L], mu[1L] * mu[3L], mu[1L] * mu[2L])
  var_delta <- as.numeric(t(grad) %*% Sigma %*% grad)
  sd_delta <- sqrt(max(var_delta, 0))
  sds <- sqrt(pmax(diag(Sigma), 0))
  if (sd_delta <= .Machine$double.eps) {
    non_zero_sds <- sds[sds > .Machine$double.eps]
    sd_delta <- if (length(non_zero_sds) > 0) prod(non_zero_sds) else 1
  }
  z <- stats::qnorm(0.975)
  delta_width <- 8 * sd_delta

  vapply(p, function(pp) {
    center <- mean_v + sign(pp - 0.5) * z * sd_delta
    .prod3_quantile(pp, mean = mu, cov = Sigma,
                    lower = center - delta_width, upper = center + delta_width, tol = tol)
  }, FUN.VALUE = numeric(1))
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
    .prod3_quantile(p, mean = mu, cov = Sigma, lower = lower, upper = upper, tol = tol)
  }, FUN.VALUE = numeric(1))

  c(lower = quantiles[1L], upper = quantiles[2L])
}

#' @export
S7::method(confint, ProductNormal3) <- function(object, parm, level = 0.95, tol = 1e-5, ...) {
  .confint_productnormal3(object, level = level, tol = tol)
}

#' @export
S7::method(ci, ProductNormal3) <- function(mu, level = 0.95, tol = 1e-5, ...) {
  object <- mu # S7 method signature requires 'mu' as first arg
  .confint_productnormal3(object, level = level, tol = tol)
}

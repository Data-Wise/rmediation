#' @importFrom cubature hcubature
#' @importFrom stats dnorm pnorm
NULL

#' Conditional mean and standard deviation of Z | X = x, Y = y
#'
#' Assumes the variables have already been standardised to correlation scale.
#'
#' @noRd
.prod3_conditional_z <- function(x, y, m, R) {
  Rxy <- R[1:2, 1:2]
  Rxy_inv <- solve(Rxy)
  beta <- R[3, 1:2] %*% Rxy_inv
  cond_mean <- m[3] + beta[1] * (x - m[1]) + beta[2] * (y - m[2])
  cond_var <- 1 - as.numeric(beta %*% R[1:2, 3])
  cond_var <- max(cond_var, .Machine$double.eps)
  list(mean = as.numeric(cond_mean), sd = sqrt(cond_var))
}

#' Bivariate normal density for (X, Y) in standardised correlation scale
#'
#' @noRd
.prod3_bivariate_density <- function(x, y, m, R, Rxy_inv, det_Rxy) {
  z <- c(x - m[1], y - m[2])
  exp(-0.5 * as.numeric(t(z) %*% Rxy_inv %*% z)) /
    (2 * pi * sqrt(max(det_Rxy, .Machine$double.eps)))
}

#' Integrand for the product-of-three-normals CDF
#'
#' Computes `P(X*Y*Z <= q | X=x, Y=y) * f(x,y)` using the dimension-reduction
#' formula from the prod3 algorithm.
#'
#' @noRd
.prod3_integrand_2d <- function(arg, q_std, m, R, Rxy_inv, det_Rxy) {
  x <- arg[1L]
  y <- arg[2L]

  eps <- 1e-12
  if (abs(x) < eps || abs(y) < eps) {
    # Axes are discontinuity lines of measure zero; the value returned here
    # does not affect the integral.  Use the common limit for q != 0.
    if (q_std > 0) {
      g <- 1
    } else if (q_std < 0) {
      g <- 0
    } else {
      g <- 0.5
    }
    return(g * .prod3_bivariate_density(x, y, m, R, Rxy_inv, det_Rxy))
  }

  cond <- .prod3_conditional_z(x, y, m, R)
  z <- (q_std / (x * y) - cond$mean) / cond$sd

  if (x * y > 0) {
    g <- stats::pnorm(z)
  } else {
    g <- 1 - stats::pnorm(z)
  }

  g * .prod3_bivariate_density(x, y, m, R, Rxy_inv, det_Rxy)
}

#' Cumulative Distribution Function for the Product of Three Normal Variables
#'
#' Computes `P(X1 * X2 * X3 <= q)` where `(X1, X2, X3)` follows a trivariate
#' normal distribution with mean vector `mean` and covariance matrix `cov`.
#' The implementation uses the conditional-expectation dimension-reduction
#' double integral described in Tofighi (2026).
#'
#' @param q Numeric scalar quantile.
#' @param mean Numeric vector of means of length 3.
#' @param cov 3x3 covariance matrix.
#' @param method Integration method. Currently only `"hcubature"` is
#'   supported.
#' @param tol Numeric tolerance passed to the integration routine.
#'
#' @return Probability `P(X1 * X2 * X3 <= q)` as a numeric scalar in `[0, 1]`.
#' @export
#' @examples
#' Sigma <- diag(3)
#' p_prod3(q = 0, mean = c(0, 0, 0), cov = Sigma)
p_prod3 <- function(q, mean, cov, method = "hcubature", tol = 1e-6) {
  checkmate::assert_number(q, finite = TRUE)
  checkmate::assert_numeric(mean, finite = TRUE, len = 3)
  checkmate::assert_matrix(cov, mode = "numeric", nrows = 3, ncols = 3)
  method <- match.arg(method, "hcubature")
  checkmate::assert_number(tol, lower = 0)

  # Symmetrise covariance
  cov <- (cov + t(cov)) / 2

  # Symmetry shortcut for zero-mean distributions
  if (all(abs(mean) < .Machine$double.eps^0.5) && q == 0) {
    return(0.5)
  }

  sds <- sqrt(pmax(diag(cov), 0))

  # Degenerate cases: reduce to the two-variable product-normal problem ----
  if (sds[1L] < .Machine$double.eps) {
    x1 <- mean[1L]
    if (abs(x1) < .Machine$double.eps) {
      return(as.numeric(q >= 0))
    }
    return(pprodnormal(q / x1,
      mu.x = mean[2L], mu.y = mean[3L],
      se.x = sds[2L], se.y = sds[3L],
      rho = cov[2L, 3L] / max(sds[2L] * sds[3L], .Machine$double.eps),
      lower.tail = x1 > 0
    ))
  }
  if (sds[2L] < .Machine$double.eps) {
    x2 <- mean[2L]
    if (abs(x2) < .Machine$double.eps) {
      return(as.numeric(q >= 0))
    }
    return(pprodnormal(q / x2,
      mu.x = mean[1L], mu.y = mean[3L],
      se.x = sds[1L], se.y = sds[3L],
      rho = cov[1L, 3L] / max(sds[1L] * sds[3L], .Machine$double.eps),
      lower.tail = x2 > 0
    ))
  }
  if (sds[3L] < .Machine$double.eps) {
    x3 <- mean[3L]
    if (abs(x3) < .Machine$double.eps) {
      return(as.numeric(q >= 0))
    }
    return(pprodnormal(q / x3,
      mu.x = mean[1L], mu.y = mean[2L],
      se.x = sds[1L], se.y = sds[2L],
      rho = cov[1L, 2L] / max(sds[1L] * sds[2L], .Machine$double.eps),
      lower.tail = x3 > 0
    ))
  }

  # Standardise to correlation scale
  R <- cov / outer(sds, sds)
  R <- (R + t(R)) / 2
  m <- mean / sds
  q_std <- q / prod(sds)

  # Precompute bivariate (X, Y) quantities
  Rxy <- R[1:2, 1:2]
  Rxy_inv <- solve(Rxy)
  det_Rxy <- det(Rxy)

  # Guard against numerical non-positive-definiteness
  if (det_Rxy <= 0) {
    warning("Standardised (X, Y) covariance is numerically singular; regularising.")
    Rxy <- Rxy + diag(1e-8, 2)
    Rxy_inv <- solve(Rxy)
    det_Rxy <- det(Rxy)
  }

  integrand <- function(arg) {
    .prod3_integrand_2d(arg, q_std = q_std, m = m, R = R,
                        Rxy_inv = Rxy_inv, det_Rxy = det_Rxy)
  }

  res <- cubature::hcubature(
    f = integrand,
    lowerLimit = c(-Inf, -Inf),
    upperLimit = c(Inf, Inf),
    tol = tol,
    fDim = 1L,
    vectorInterface = FALSE
  )

  p <- res$integral
  min(max(p, 0), 1)
}

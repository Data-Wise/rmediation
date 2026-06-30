#' @importFrom cubature hcubature
#' @importFrom stats dnorm pnorm
NULL

#' Bivariate normal density for (X, Y) in standardized correlation scale
#'
#' @noRd
.prod3_bivariate_density <- function(x, y, m, Rxy_inv, det_Rxy) {
  z <- c(x - m[1], y - m[2])
  exp(-0.5 * as.numeric(t(z) %*% Rxy_inv %*% z)) /
    (2 * pi * sqrt(max(det_Rxy, .Machine$double.eps)))
}

#' Integrand for the product-of-three-normals CDF
#'
#' Computes `P(X*Y*Z <= q | X=x, Y=y) * f(x,y)` using the dimension-reduction
#' formula from the prod3 algorithm.  The conditional-moment coefficients
#' (`beta`, `cond_sd`) are precomputed once by [pprodnormal3()] and passed in, so no
#' linear solve is performed per integrand evaluation.
#'
#' @noRd
.prod3_integrand_2d <- function(arg, q_std, m, beta, cond_sd, Rxy_inv, det_Rxy) {
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
    return(g * .prod3_bivariate_density(x, y, m, Rxy_inv, det_Rxy))
  }

  cond_mean <- m[3L] + beta[1L] * (x - m[1L]) + beta[2L] * (y - m[2L])
  z <- (q_std / (x * y) - cond_mean) / cond_sd

  if (x * y > 0) {
    g <- stats::pnorm(z)
  } else {
    g <- 1 - stats::pnorm(z)
  }

  g * .prod3_bivariate_density(x, y, m, Rxy_inv, det_Rxy)
}

#' @noRd
.p_prod3_degenerate <- function(q, fixed_val, other_idx, mean, sds, cov) {
  pprodnormal(q / fixed_val,
    mu.x = mean[other_idx[1L]], mu.y = mean[other_idx[2L]],
    se.x = sds[other_idx[1L]], se.y = sds[other_idx[2L]],
    rho = cov[other_idx[1L], other_idx[2L]] /
      max(sds[other_idx[1L]] * sds[other_idx[2L]], .Machine$double.eps),
    lower.tail = fixed_val > 0
  )
}

#' Cumulative Distribution Function for the Product of Three Normal Variables
#'
#' Computes `P(X1 * X2 * X3 <= q)` where `(X1, X2, X3)` follows a trivariate
#' normal distribution with mean vector `mean` and covariance matrix `cov`.
#' `Z` is marginalized analytically through the conditional Gaussian structure
#' `Z | (X, Y)`, and the remaining two-dimensional integral is evaluated with
#' adaptive cubature (dimension reduction; see Tofighi, 2026).
#'
#' @param q Numeric scalar quantile.
#' @param mean Numeric vector of means of length 3.
#' @param cov 3x3 covariance matrix. Must be positive-definite, except that a
#'   single zero-variance component is permitted (the problem then reduces to
#'   the two-variable product-normal case). Perfect correlation between two
#'   components (`|rho| = 1`) or an indefinite matrix is rejected.
#' @param method Integration method. Currently only `"hcubature"` is
#'   supported.
#' @param tol Numeric tolerance passed to the integration routine; must be
#'   strictly positive.
#' @param ... Additional arguments (unused; present for the `p_prod3`
#'   deprecated alias).
#'
#' @return Probability `P(X1 * X2 * X3 <= q)` as a numeric scalar in `[0, 1]`.
#' @note Numerical accuracy can degrade as the standardized `(X, Y)`
#'   correlation approaches `+-1` (the bivariate block becomes ill-conditioned).
#'   For a fully degenerate point mass (all variances zero) with zero means,
#'   `q == 0` returns `0.5` by the mid-distribution convention rather than `0`
#'   or `1`.
#' @export
#' @examples
#' Sigma <- diag(3)
#' pprodnormal3(q = 0, mean = c(0, 0, 0), cov = Sigma)
pprodnormal3 <- function(q, mean, cov, method = "hcubature", tol = 1e-6) {
  checkmate::assert_number(q, finite = TRUE)
  checkmate::assert_numeric(mean, finite = TRUE, len = 3)
  checkmate::assert_matrix(cov, mode = "numeric", nrows = 3, ncols = 3)
  method <- match.arg(method, "hcubature")
  checkmate::assert_number(tol, finite = TRUE)
  if (tol <= 0) {
    stop("'tol' must be strictly positive.")
  }

  # Symmetrise covariance
  cov <- (cov + t(cov)) / 2

  sds <- sqrt(pmax(diag(cov), 0))

  # Degenerate cases: reduce to the two-variable product-normal problem ----
  if (sds[1L] < .Machine$double.eps) {
    x1 <- mean[1L]
    if (abs(x1) < .Machine$double.eps) {
      return(if (q == 0) 0.5 else as.numeric(q > 0))
    }
    return(.p_prod3_degenerate(q, x1, c(2L, 3L), mean, sds, cov))
  }
  if (sds[2L] < .Machine$double.eps) {
    x2 <- mean[2L]
    if (abs(x2) < .Machine$double.eps) {
      return(as.numeric(q >= 0))
    }
    return(.p_prod3_degenerate(q, x2, c(1L, 3L), mean, sds, cov))
  }
  if (sds[3L] < .Machine$double.eps) {
    x3 <- mean[3L]
    if (abs(x3) < .Machine$double.eps) {
      return(as.numeric(q >= 0))
    }
    return(.p_prod3_degenerate(q, x3, c(1L, 2L), mean, sds, cov))
  }

  # Full positive-definiteness check. The single zero-variance degenerate cases
  # above are handled separately; here all variances are > 0, so a non-PD `cov`
  # (indefinite, or perfect pairwise correlation) is malformed -- it would
  # otherwise produce a negative Var(Z | X, Y) and a non-convergent integral.
  # Reject cleanly rather than hang or surface a raw Lapack error.
  eigs <- eigen(cov, symmetric = TRUE, only.values = TRUE)$values
  if (min(eigs) <= sqrt(.Machine$double.eps) * max(eigs)) {
    stop(
      "'cov' must be positive-definite (smallest eigenvalue = ",
      format(min(eigs), digits = 4),
      "); perfect correlation between two components (|rho| = 1) or an ",
      "indefinite matrix is not supported by the dimension-reduction method."
    )
  }

  # Symmetry shortcut for zero-mean distributions (guarded by PD check above)
  if (all(abs(mean) < .Machine$double.eps^0.5) && q == 0) {
    return(0.5)
  }

  # Standardise to correlation scale
  R <- cov / outer(sds, sds)
  R <- (R + t(R)) / 2
  m <- mean / sds
  q_std <- q / prod(sds)

  # Precompute the bivariate (X, Y) quantities ONCE (not per integrand call).
  # Solve R_xy * beta = Cov(XY, Z) by Cholesky (chol + forward/back
  # substitution) instead of forming an explicit inverse: for the SPD block
  # this is better conditioned, kappa(U) = sqrt(kappa(R_xy)). R_xy is
  # positive-definite by the check above.
  Rxy <- R[1:2, 1:2]
  U <- chol(Rxy) # upper-triangular, U^T U = R_xy
  beta <- as.numeric(backsolve(U, forwardsolve(t(U), R[1:2, 3])))
  cond_sd <- sqrt(max(1 - sum(beta * R[1:2, 3]), .Machine$double.eps))
  Rxy_inv <- chol2inv(U)
  det_Rxy <- prod(diag(U))^2

  integrand <- function(arg) {
    .prod3_integrand_2d(arg,
      q_std = q_std, m = m, beta = beta, cond_sd = cond_sd,
      Rxy_inv = Rxy_inv, det_Rxy = det_Rxy
    )
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

#' @export
#' @rdname pprodnormal3
p_prod3 <- function(...) pprodnormal3(...)

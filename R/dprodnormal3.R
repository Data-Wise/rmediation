#' Density of the Product of Three Normal Variables
#'
#' Exact density of \eqn{X_1 X_2 X_3} when \eqn{(X_1, X_2, X_3)} is trivariate
#' normal with mean `mean` and covariance `cov`, the density counterpart of
#' [pprodnormal3()]. No closed form is known for the general case (Gaunt, 2022),
#' so the density is a two-dimensional integral: conditioning on \eqn{X_1 = x}
#' makes \eqn{(X_2, X_3)} bivariate normal, whose product has the density of
#' [dprodnormal()], and
#' \deqn{f(v) = \int \phi(x; \mu_1, \sigma_1^2)\, f_{X_2 X_3 \mid x}(v / x)\, / |x|\, dx.}
#' The inner density is the Rohatgi/Glen integral used by [dprodnormal()]
#' (conditional means and the partial correlation are computed per \eqn{x}).
#'
#' The density has a logarithmic singularity at exactly `0` (returned as
#' `Inf`), as for [dprodnormal()]. Unlike [pprodnormal3()], zero-variance
#' components are not supported: a point mass has no density.
#'
#' @param x Numeric vector of quantiles.
#' @param mean Numeric vector of means of length 3.
#' @param cov 3x3 covariance matrix; must be positive definite.
#' @param log Logical; return the log density.
#' @return Numeric vector of densities, the length of `x`.
#' @seealso [pprodnormal3()] for the CDF, [dprodnormal()] for two factors.
#' @references Gaunt, R. E. (2022). On the product of three normal random
#'   variables. See also the references of [dprodnormal()].
#' @export
#' @examples
#' Sigma <- matrix(c(1, .3, .2, .3, 1, .1, .2, .1, 1), 3)
#' dprodnormal3(c(0.1, 0.5, 1), mean = c(0.5, 0.4, 0.3), cov = Sigma)
dprodnormal3 <- function(x, mean, cov, log = FALSE) {
  checkmate::assert_numeric(x, any.missing = FALSE, min.len = 1)
  checkmate::assert_numeric(mean, finite = TRUE, len = 3)
  checkmate::assert_matrix(cov, mode = "numeric", nrows = 3, ncols = 3)
  checkmate::assert_flag(log)
  cov <- (cov + t(cov)) / 2
  .assert_cov3(cov)
  eigs <- eigen(cov, symmetric = TRUE, only.values = TRUE)$values
  if (min(eigs) <= sqrt(.Machine$double.eps) * max(eigs)) {
    stop(
      "'cov' must be positive definite for a density (smallest eigenvalue = ",
      format(min(eigs), digits = 4), "); a zero-variance component or perfect correlation ",
      "leaves a point mass or a lower-dimensional distribution with no 3-D density.",
      call. = FALSE
    )
  }

  sds <- sqrt(diag(cov))
  R <- cov / outer(sds, sds)
  m <- mean / sds
  scale <- prod(sds)

  dens <- vapply(x, function(xx) {
    if (!is.finite(xx)) {
      return(0)
    }
    if (xx == 0) {
      return(Inf)
    }
    .dprod3_std(xx / scale, m, R) / scale
  }, numeric(1))

  if (log) base::log(dens) else dens
}

# Density of X1 X2 X3 for unit variances, mean m and correlation matrix R at v (see
# dprodnormal3()). Same +/- 10 sd window around the conditioning variable and split at 0 as
# .dprod_integral().
.dprod3_std <- function(v, m, R) {
  r12 <- R[1L, 2L]
  r13 <- R[1L, 3L]
  s2 <- sqrt(1 - r12^2)
  s3 <- sqrt(1 - r13^2)
  rho <- (R[2L, 3L] - r12 * r13) / (s2 * s3) # partial correlation of X2, X3 given X1
  g <- function(x) {
    vapply(x, function(xx) {
      a <- (m[2L] + r12 * (xx - m[1L])) / s2
      b <- (m[3L] + r13 * (xx - m[1L])) / s3
      inner <- .dprod_integral(v / (xx * s2 * s3), a, b, rho) / (s2 * s3)
      stats::dnorm(xx - m[1L]) * inner / abs(xx)
    }, numeric(1))
  }
  lo <- m[1L] - 10
  hi <- m[1L] + 10
  breaks <- sort(unique(c(lo, if (lo < 0 && hi > 0) 0, hi)))
  sum(vapply(seq_len(length(breaks) - 1L), function(i) {
    stats::integrate(g, breaks[i], breaks[i + 1L], subdivisions = 200L, rel.tol = 1e-8, abs.tol = 1e-300)$value
  }, numeric(1)))
}

#' Quantile Function for the Product of Three Normal Variables
#'
#' Computes the quantile `q` with `P(X1 * X2 * X3 <= q) = p` (or `> q`, for
#' `lower.tail = FALSE`) where `(X1, X2, X3)` follows a trivariate normal
#' distribution with mean vector `mean` and covariance matrix `cov`. It inverts
#' [pprodnormal3()] by root-finding, bracketed by the delta-method interval, and
#' is the same routine behind [dist_quantile()] for a [ProductNormal3] object.
#'
#' @param p Numeric vector of probabilities in `[0, 1]`, no missing values. `0` and `1`
#'   return `-Inf` and `Inf` (reversed for `lower.tail = FALSE`).
#' @param mean Numeric vector of means of length 3.
#' @param cov 3x3 covariance matrix, as for [pprodnormal3()].
#' @param lower.tail Logical; if `TRUE` (default) `p` is `P(X1 * X2 * X3 <= q)`,
#'   otherwise `P(X1 * X2 * X3 > q)`. The upper tail is inverted through the directly
#'   integrated upper tail of [pprodnormal3()], so a small upper-tail `p` is resolved.
#' @param tol Positive tolerance used for both the CDF evaluation and the root-finder
#'   (default `1e-6`). It is absolute, so for a probability `p` use a `tol` well below
#'   `p`; [pprodnormal3()] explains why.
#' @return A numeric vector the same length and names as `p`. Three zero-variance
#'   components give a point mass, whose quantile is `prod(mean)` for any `p` strictly
#'   between 0 and 1.
#' @seealso [pprodnormal3()] for the CDF, [qprodnormal()] for two factors,
#'   [dist_quantile()] for the object interface.
#' @examples
#' qprodnormal3(c(0.025, 0.5, 0.975), mean = c(1, 1, 1), cov = diag(3))
#' # an upper-tail probability of 1e-8, resolved with a matching tolerance
#' qprodnormal3(1e-8, mean = c(1, 1, 1), cov = diag(3), lower.tail = FALSE, tol = 1e-12)
#' @export
qprodnormal3 <- function(p, mean, cov, lower.tail = TRUE, tol = 1e-6) {
  checkmate::assert_numeric(p, lower = 0, upper = 1, any.missing = FALSE, min.len = 1L)
  checkmate::assert_numeric(mean, finite = TRUE, len = 3L)
  checkmate::assert_matrix(cov, mode = "numeric", nrows = 3L, ncols = 3L)
  checkmate::assert_flag(lower.tail)
  checkmate::assert_number(tol, finite = TRUE)
  if (tol <= 0) {
    stop("'tol' must be strictly positive.")
  }
  cov <- (cov + t(cov)) / 2
  .assert_cov3(cov)
  out <- vapply(p, .qprodnormal3_one,
    FUN.VALUE = numeric(1),
    mean = mean, cov = cov, lower.tail = lower.tail, tol = tol
  )
  names(out) <- names(p)
  out
}

# Factor R with t(R) %*% R == V for a positive semi-definite V. chol() when it works, so draws
# under a fixed seed are identical to before; an eigen factor when V is singular (se = 0 or
# rho = +/-1), where chol() stops with "leading minor ... not positive".
.chol_psd <- function(V) {
  tryCatch(
    chol(V),
    error = function(e) {
      ev <- eigen(V, symmetric = TRUE)
      if (any(ev$values < -sqrt(.Machine$double.eps) * max(abs(ev$values), 1))) {
        stop("The covariance matrix is not positive semi-definite.", call. = FALSE)
      }
      diag(sqrt(pmax(ev$values, 0)), nrow(V)) %*% t(ev$vectors)
    }
  )
}

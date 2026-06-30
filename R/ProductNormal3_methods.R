#' @importFrom S7 method
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
    p_prod3(qq,
      mean = object@mu, cov = object@Sigma,
      method = object@method, tol = tol
    )
  }, FUN.VALUE = numeric(1))

  if (!lower.tail) {
    p <- 1 - p
  }

  p
}

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

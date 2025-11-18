#' @keywords internal
validate_prodnormal_params <- function(mu.x, mu.y, se.x, se.y, rho, n.mc, alpha = NULL, p = NULL) {
  if (!is.numeric(mu.x)) {
    stop("Argument mu.x must be numeric!")
  }
  if (!is.numeric(mu.y)) {
    stop("Argument mu.y must be numeric!")
  }
  if (!is.numeric(se.x)) {
    stop("Argument se.x must be numeric!")
  }
  if (!is.numeric(se.y)) {
    stop("Argument se.y must be numeric!")
  }
  if (!is.numeric(rho)) {
    stop("Argument rho  must be numeric!")
  }
  if (rho <= -1 || rho >= 1) {
    stop("rho must be between -1 and 1!")
  }
  if (!is.numeric(n.mc) || is.null(n.mc)) {
    n.mc <- 1e5
  } # sets n.mc to default

  if (!is.null(alpha)) {
    if (!is.numeric(alpha)) {
      stop("Argument alpha  must be numeric!")
    }
    if (alpha <= 0 || alpha >= 1) {
      stop("alpha must be between 0 and 1!")
    }
  }

  if (!is.null(p)) {
    if (!is.numeric(p)) {
      stop("Argument p must be numeric!")
    }
    if (p <= 0 || p >= 1) {
      stop("p must be between 0 and 1!")
    }
  }
  return(n.mc) # Return n.mc as it might have been set to default
}
pprodnormalMC <-
  function(q, mu.x, mu.y, se.x, se.y, rho = 0, lower.tail = TRUE, n.mc = 1e5) {
    exact <- .degenerate_pprod(q, mu.x, mu.y, se.x, se.y, lower.tail)
    if (!is.null(exact)) {
      return(list(p = exact, error = 0 * exact))
    }
    mu.x <- mu.x / se.x
    mu.y <- mu.y / se.y
    q <- q / (se.x * se.y)
    mean.v <- c(mu.x, mu.y)
    var.mat <- matrix(c(1, rho, rho, 1), 2)
    a_b <- matrix(rnorm(2 * n.mc), ncol = n.mc)
    a_b <- crossprod(.chol_psd(var.mat), a_b) + mean.v
    a_b <- t(a_b)
    ab <- a_b[, 1] * a_b[, 2]
    # one shared sample for every q, so the estimates are mutually consistent and monotone
    percentile <- vapply(q, function(qq) sum(ab < qq) / n.mc, numeric(1))
    error <- vapply(q, function(qq) sd(ab < qq) / n.mc, numeric(1))
    if (!lower.tail) {
      percentile <- 1 - percentile
    }
    return(list(p = percentile, error = error))
  }

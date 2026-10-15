qprodnormalMeeker <-
  function(p, mu.x, mu.y, se.x, se.y, rho = 0, lower.tail = TRUE) {
    .assert_positive_se(se.x, se.y)
    max.iter <- 1000
    eps <- 1 # initial value for precision
    mu.a <- mu.x / se.x # Rescaling distribution of a so that SD of a is 1
    mu.b <- mu.y / se.y # Rescaling distribution of b so that SD of b is 1
    se.ab <- sqrt(1 + mu.a^2 + mu.b^2 + 2 * mu.a * mu.b * rho + rho^2)
    s.a.on.b <- sqrt(1 - rho^2) # SD of b conditional on a
    l0 <- mu.a * mu.b - 6 * se.ab
    u0 <- mu.a * mu.b + 6 * se.ab
    # Both tails are solved directly and increasing in z: F(z) - p for the lower tail,
    # p - (1 - F(z)) for the upper, so a far upper tail is not lost to 1 - F cancellation.
    fx <- if (lower.tail == FALSE) {
      function(z) p - .dop_cdf(z, mu.a, mu.b, rho, lower.tail = FALSE)$value
    } else {
      function(z) .dop_cdf(z, mu.a, mu.b, rho)$value - p
    }
    # converge <- TRUE
    p.l <- fx(l0)
    p.u <- fx(u0)
    iter <- 0
    while (p.l > 0) {
      iter <- iter + 1
      l0 <- l0 - 0.5 * se.ab
      p.l <- fx(l0)
      if (iter > max.iter) {
        stop("Numerical algorithm does not work in type='dop'! please use type='MC'.\n")
        # return(list(q=NA,error=NA))
      }
    }

    iter <- 0 # Reset iteration counter
    while (p.u < 0) {
      iter <- iter + 1
      u0 <- u0 + 0.5 * se.ab
      p.u <- fx(u0)
      if (iter > max.iter) {
        stop("Numerical algorithm does not work in type='dop'! please use type='MC'.\n")
        # return(list(q=NA,error=NA))
      }
    }

    res <- uniroot(fx, c(l0, u0), tol = 1e-12) # default tol (1.2e-4) is too coarse in a tail
    new <- res$root
    new <- new * se.x * se.y
    error.new <- res$estim.prec
    return(list(q = new, error = error.new)) # returns quantile corresponding to p
  }

pprodnormalMeeker <- function(q, mu.x, mu.y, se.x, se.y, rho = 0, lower.tail = TRUE) {
  mu.a <- mu.x / se.x
  mu.b <- mu.y / se.y
  q <- q / (se.x * se.y)
  ans <- .dop_cdf(q, mu.a, mu.b, rho)
  # Quadrature can overshoot 1 by rounding (observed 1 + 1.6e-15), which made the upper tail
  # negative.
  percentile <- min(max(ans$value, 0), 1)
  error <- ans$abs.error
  if (!lower.tail) {
    percentile <- 1 - percentile
  }
  return(list(p = percentile, error = error))
}

# P(A * B <= z) for the standardized pair (A, B): B ~ N(mu.b, 1), A | B ~ N(mu.a + rho (B - mu.b),
# 1 - rho^2) (Meeker & Escobar, 1995, p. 273). Shared by pprodnormalMeeker() and
# qprodnormalMeeker().
#
# integrate() over (-Inf, Inf) misses the unit-sd peak of dnorm(x - mu.b) when |mu.b| is large
# (standardized mean >= ~20 returned ~1e-7 where the answer is ~0.5) and is wrong by up to 4e-6
# absolute in far tails. So integrate over +/- 10 sd of the peak (mass left out < 2e-23), split at
# the jump of sign(x) when 0 lies inside, and tighten the tolerance: the integrand is step-like
# near x = 0, where the default tolerance missed up to 2.7e-3. Issue #60,
# planning/GRILL-dop-large-mean-60-2026-10-14.md.
.dop_cdf <- function(z, mu.a, mu.b, rho) {
  s.a.on.b <- sqrt(1 - rho^2)
  gx <- function(x) {
    mu.a.on.b <- mu.a + rho * (x - mu.b)
    pnorm(sign(x) * (z / x - mu.a.on.b) / s.a.on.b) * dnorm(x - mu.b)
  }
  lo <- mu.b - 10
  hi <- mu.b + 10
  breaks <- sort(unique(c(lo, if (lo < 0 && hi > 0) 0, hi)))
  parts <- lapply(seq_len(length(breaks) - 1L), function(i) {
    integrate(gx,
      lower = breaks[i], upper = breaks[i + 1L],
      subdivisions = 2000L, rel.tol = 1e-10, abs.tol = 1e-13
    )
  })
  list(
    value = sum(vapply(parts, function(a) a$value, numeric(1))),
    abs.error = sum(vapply(parts, function(a) a$abs.error, numeric(1)))
  )
}

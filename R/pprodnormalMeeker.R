pprodnormalMeeker <- function(q, mu.x, mu.y, se.x, se.y, rho = 0, lower.tail = TRUE) {
  .assert_positive_se(se.x, se.y)
  mu.a <- mu.x / se.x
  mu.b <- mu.y / se.y
  q <- q / (se.x * se.y)
  # The requested tail is integrated directly: 1 - lower cancels below ~1e-10 and cannot
  # resolve a far upper tail at all.
  ans <- .dop_cdf(q, mu.a, mu.b, rho, lower.tail = lower.tail)
  # Quadrature can overshoot [0, 1] by rounding (observed 1 + 1.6e-15), which made the upper
  # tail negative.
  percentile <- min(max(ans$value, 0), 1)
  error <- ans$abs.error
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
# near x = 0, where the default tolerance missed up to 2.7e-3. The absolute tolerance is
# negligible so far-tail probabilities are resolved relatively; the +/-10 sd window leaves out
# at most 1.5e-23 of mass, which is the floor on resolvable probabilities. Issue #60,
# planning/GRILL-dop-large-mean-60-2026-10-14.md.
.dop_cdf <- function(z, mu.a, mu.b, rho, lower.tail = TRUE) {
  s.a.on.b <- sqrt(1 - rho^2)
  gx <- function(x) {
    mu.a.on.b <- mu.a + rho * (x - mu.b)
    # P(A x <= z | x) is pnorm(+u) for x > 0 and pnorm(-u) for x < 0; the upper tail
    # P(A x > z | x) is the same with the sign flipped.
    sgn <- if (lower.tail) sign(x) else -sign(x)
    u <- sgn * (z / x - mu.a.on.b)
    # |rho| = 1 makes the conditional a point mass: a step in u (0/0 otherwise, at u = 0)
    pr <- if (s.a.on.b > 0) pnorm(u / s.a.on.b) else (u > 0) + 0.5 * (u == 0)
    pr * dnorm(x - mu.b)
  }
  lo <- mu.b - 10
  hi <- mu.b + 10
  breaks <- sort(unique(c(lo, if (lo < 0 && hi > 0) 0, hi)))
  parts <- lapply(seq_len(length(breaks) - 1L), function(i) {
    integrate(gx,
      lower = breaks[i], upper = breaks[i + 1L],
      subdivisions = 2000L, rel.tol = 1e-10, abs.tol = 1e-300
    )
  })
  list(
    value = sum(vapply(parts, function(a) a$value, numeric(1))),
    abs.error = sum(vapply(parts, function(a) a$abs.error, numeric(1)))
  )
}

# The DOP integral standardizes by se.x and se.y, so a zero standard error divides by zero and
# surfaced as "non-finite function value". Say what to do instead.
.assert_positive_se <- function(se.x, se.y) {
  if (se.x <= 0 || se.y <= 0) {
    stop(
      "type = 'dop' needs positive standard errors (se.x = ", format(se.x), ", se.y = ",
      format(se.y), "); use type = 'asymp' or type = 'mc' for a degenerate product.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}

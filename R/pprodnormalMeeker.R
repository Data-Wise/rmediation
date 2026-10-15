pprodnormalMeeker <- function(q, mu.x, mu.y, se.x, se.y, rho = 0, lower.tail = TRUE) {
  exact <- .degenerate_pprod(q, mu.x, mu.y, se.x, se.y, lower.tail)
  if (!is.null(exact)) {
    return(list(p = exact, error = 0 * exact))
  }
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
# the jump of sign(x) when 0 lies inside (and at the roots of Meeker & Escobar's quadratic), and tighten the tolerance: the integrand is step-like
# near x = 0, where the default tolerance missed up to 2.7e-3. The absolute tolerance is
# negligible so far-tail probabilities are resolved relatively; the +/-10 sd window leaves out
# at most 1.5e-23 of mass, which is the floor on resolvable probabilities. Issue #60,
# planning/GRILL-dop-large-mean-60-2026-10-14.md.
.dop_cdf <- function(z, mu.a, mu.b, rho, lower.tail = TRUE) {
  if (abs(rho) == 1) {
    return(.dop_cdf_collinear(z, mu.a, mu.b, rho, lower.tail))
  }
  s.a.on.b <- sqrt(1 - rho^2)
  # P(A x <= z | x) is pnorm(+u) for x > 0 and pnorm(-u) for x < 0, with u = z/x - E[A | x];
  # the upper tail P(A x > z | x) is the same with the sign flipped. Writing u as
  # -rho (x - r1)(x - r2) / x, where r1, r2 are the real roots of rho x^2 + c x - z = 0
  # (c = mu.a - rho mu.b; Meeker & Escobar 1994's quadratic), removes the cancellation between
  # z/x and E[A | x] that is the dominant noise when the means are large. The roots are also
  # where u changes sign, so they are breakpoints.
  roots <- .quad_roots(rho, mu.a - rho * mu.b, z)
  gx <- function(x) {
    u <- if (is.null(roots)) {
      z / x - (mu.a + rho * (x - mu.b))
    } else {
      -rho * (x - roots[1L]) * (x - roots[2L]) / x
    }
    sgn <- if (lower.tail) sign(x) else -sign(x)
    pnorm(sgn * u / s.a.on.b) * dnorm(x - mu.b)
  }
  lo <- mu.b - 10
  hi <- mu.b + 10
  inside <- if (is.null(roots)) numeric() else roots[roots > lo & roots < hi]
  breaks <- sort(unique(c(lo, if (lo < 0 && hi > 0) 0, inside, hi)))
  parts <- lapply(seq_len(length(breaks) - 1L), function(i) {
    .integrate_relaxing(gx, breaks[i], breaks[i + 1L])
  })
  list(
    value = sum(vapply(parts, function(a) a$value, numeric(1))),
    abs.error = sum(vapply(parts, function(a) a$abs.error, numeric(1)))
  )
}

# Real roots of rho x^2 + cc x - z = 0 in increasing order, computed without cancellation
# (q = -(cc + sign(cc) sqrt(D)) / 2; r1 = q / rho, r2 = -z / q), or NULL when rho = 0 or D < 0.
.quad_roots <- function(rho, cc, z) {
  D <- cc^2 + 4 * rho * z
  if (rho == 0 || D < 0) {
    return(NULL)
  }
  q <- -0.5 * (cc + if (cc >= 0) sqrt(D) else -sqrt(D))
  if (q == 0) {
    return(c(0, 0))
  }
  sort(c(q / rho, -z / q))
}

# integrate() at rel.tol 1e-10, relaxed to 1e-8 and 1e-6 only when QUADPACK reports roundoff or
# bad integrand behavior: with means near 3e5 and |rho| near 1 the inputs themselves carry about
# 1e-9 relative noise, so 1e-10 is not attainable, and a value good to 1e-8 beats an error. The
# returned abs.error reports the accuracy actually reached.
.integrate_relaxing <- function(f, lower, upper) {
  for (tol in c(1e-10, 1e-8, 1e-6)) {
    res <- tryCatch(
      integrate(f, lower, upper, subdivisions = 2000L, rel.tol = tol, abs.tol = 1e-300),
      error = function(e) e
    )
    if (!inherits(res, "error")) {
      return(res)
    }
    if (!grepl("roundoff|bad integrand", conditionMessage(res))) {
      stop(res)
    }
  }
  stop(res)
}

# |rho| = 1: A = mu.a + rho (B - mu.b), so A B = rho B^2 + c B with c = mu.a - rho mu.b and
# B ~ N(mu.b, 1). A B <= z exactly between the real roots of rho B^2 + c B - z (rho = 1) or
# outside them (rho = -1); no real roots means never (rho = 1) or always (rho = -1). This is
# Meeker & Escobar's (1994) treatment of |rho| = 1; a step integrand cannot be integrated
# accurately without knowing where the step is.
.dop_cdf_collinear <- function(z, mu.a, mu.b, rho, lower.tail) {
  r <- .quad_roots(rho, mu.a - rho * mu.b, z)
  between <- if (is.null(r)) {
    0
  } else {
    d <- r - mu.b
    if (d[1L] >= 0) {
      pnorm(d[1L], lower.tail = FALSE) - pnorm(d[2L], lower.tail = FALSE)
    } else if (d[2L] <= 0) {
      pnorm(d[2L]) - pnorm(d[1L])
    } else {
      1 - pnorm(d[1L]) - pnorm(d[2L], lower.tail = FALSE)
    }
  }
  outside <- if (is.null(r)) 1 else pnorm(r[1L] - mu.b) + pnorm(r[2L] - mu.b, lower.tail = FALSE)
  below <- if (rho > 0) between else outside # P(A B <= z)
  above <- if (rho > 0) outside else between
  list(value = if (lower.tail) below else above, abs.error = 0)
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

# CDF of X * Y when a standard error is zero, so the standardizing integral does not apply. A
# fixed factor c makes the product c * Y (a scaled normal, or a point mass if c = 0); both fixed
# makes it a constant. rho is irrelevant: a constant is uncorrelated with everything. Returns
# NULL when both standard errors are positive. A point mass has the right-continuous CDF:
# P(XY <= q) = 1 at q = c and P(XY > q) = 0 there.
.degenerate_pprod <- function(q, mu.x, mu.y, se.x, se.y, lower.tail = TRUE) {
  if (se.x > 0 && se.y > 0) {
    return(NULL)
  }
  if (se.x == 0 && se.y > 0) {
    c0 <- mu.x
    m <- mu.y
    s <- se.y
  } else if (se.y == 0 && se.x > 0) {
    c0 <- mu.y
    m <- mu.x
    s <- se.x
  } else {
    c0 <- mu.x * mu.y
    m <- 0
    s <- 0
  }
  if (s == 0 || c0 == 0) {
    at <- if (s == 0) c0 else 0
    return(as.numeric(if (lower.tail) q >= at else q < at))
  }
  # c * Y <= q is Y <= q / c for c > 0 and Y >= q / c for c < 0
  pnorm((q / c0 - m) / s, lower.tail = xor(lower.tail, c0 < 0))
}

#' @importFrom cubature hcubature
#' @importFrom stats dnorm pnorm qnorm
NULL

#' Bivariate normal density for (X, Y) in standardized correlation scale
#'
#' @noRd
.prod3_bivariate_density <- function(x, y, m, Rxy_inv, det_Rxy) {
  z <- c(x - m[1], y - m[2])
  exp(-0.5 * as.numeric(t(z) %*% Rxy_inv %*% z)) /
    (2 * pi * sqrt(max(det_Rxy, .Machine$double.eps)))
}

#' Integrand for the product-of-three-normals CDF
#'
#' Computes `P(X*Y*Z <= q | X=x, Y=y) * f(x,y)` using the dimension-reduction
#' formula from the prod3 algorithm.  The conditional-moment coefficients
#' (`beta`, `cond_sd`) are precomputed once by [pprodnormal3()] and passed in, so no
#' linear solve is performed per integrand evaluation.
#'
#' @noRd
.prod3_integrand_2d <- function(arg, q_std, m, beta, cond_sd, Rxy_inv, det_Rxy) {
  x <- arg[1L]
  y <- arg[2L]

  eps <- 1e-12
  if (abs(x) < eps || abs(y) < eps) {
    # Axes are discontinuity lines of measure zero; the value returned here
    # does not affect the integral.  Use the common limit for q != 0.
    if (q_std > 0) {
      g <- 1
    } else if (q_std < 0) {
      g <- 0
    } else {
      g <- 0.5
    }
    return(g * .prod3_bivariate_density(x, y, m, Rxy_inv, det_Rxy))
  }

  cond_mean <- m[3L] + beta[1L] * (x - m[1L]) + beta[2L] * (y - m[2L])
  z <- (q_std / (x * y) - cond_mean) / cond_sd

  if (x * y > 0) {
    g <- stats::pnorm(z)
  } else {
    g <- 1 - stats::pnorm(z)
  }

  g * .prod3_bivariate_density(x, y, m, Rxy_inv, det_Rxy)
}

#' Vectorized form of [.prod3_integrand_2d()] for fixed-grid quadrature
#'
#' Identical mathematics, evaluated on whole node vectors at once so the
#' tensor-product rule does not pay R's per-call overhead 65,000+ times.
#' Parity with the scalar form is asserted in the test suite; the two must not
#' be allowed to drift.
#'
#' @noRd
.prod3_integrand_vec <- function(x, y, q_std, m, beta, cond_sd,
                                 Rxy_inv, det_Rxy) {
  dx <- x - m[1L]
  dy <- y - m[2L]
  quad <- Rxy_inv[1L, 1L] * dx^2 +
    2 * Rxy_inv[1L, 2L] * dx * dy +
    Rxy_inv[2L, 2L] * dy^2
  dens <- exp(-0.5 * quad) / (2 * pi * sqrt(max(det_Rxy, .Machine$double.eps)))

  xy <- x * y
  cond_mean <- m[3L] + beta[1L] * dx + beta[2L] * dy
  z <- (q_std / xy - cond_mean) / cond_sd
  g <- ifelse(xy > 0, stats::pnorm(z), 1 - stats::pnorm(z))

  # Axes are discontinuity lines of measure zero (see .prod3_integrand_2d()).
  on_axis <- abs(x) < 1e-12 | abs(y) < 1e-12
  if (any(on_axis)) {
    g[on_axis] <- if (q_std > 0) 1 else if (q_std < 0) 0 else 0.5
  }

  g * dens
}

#' Gauss-Legendre node cache
#'
#' Cached across calls: `dist_quantile()` and `confint()` invert the CDF by
#' root-finding, so the eigendecomposition would otherwise be recomputed dozens
#' of times per interval.
#'
#' @noRd
.prod3_gl_cache <- new.env(parent = emptyenv())

#' Gauss-Legendre nodes and weights on `[-1, 1]` via Golub-Welsch
#'
#' @noRd
.prod3_gauss_legendre <- function(n) {
  key <- as.character(n)
  hit <- .prod3_gl_cache[[key]]
  if (!is.null(hit)) {
    return(hit)
  }
  i <- seq_len(n - 1L)
  b <- i / sqrt(4 * i^2 - 1)
  jacobi <- matrix(0, n, n)
  jacobi[cbind(i, i + 1L)] <- b
  jacobi[cbind(i + 1L, i)] <- b
  e <- eigen(jacobi, symmetric = TRUE)
  ord <- order(e$values)
  out <- list(x = e$values[ord], w = 2 * e$vectors[1L, ord]^2)
  assign(key, out, envir = .prod3_gl_cache)
  out
}

#' Tensor-product Gauss-Legendre over the four single-signed cells
#'
#' The integrand switches branch on `sign(x * y)`, so it has a kink along both
#' coordinate axes. Splitting the domain there first makes every cell
#' single-signed and kink-free, which a fixed-grid rule *requires*: an
#' unpartitioned grid does not merely lose accuracy, it can return a value
#' outside `[0, 1]` entirely (2.11 at n = 128, rho = 0.999).
#'
#' `bound` comes from [.prod3_bound()] rather than being a tuned constant --
#' see there for why that distinction matters.
#'
#' The split point stays at 0 even when the standardized mean is further than
#' `bound` from it (`|m| > bound`), and this is deliberate. In that case
#' `cell()` receives reversed limits, so its weights are negative and it
#' contributes `-integral(0, m - bound)`; added to the second cell's
#' `+integral(0, m + bound)` the total telescopes to
#' `integral(m - bound, m + bound)` -- exactly the truncation box
#' [.prod3_bound()] guarantees. Every node still lies on one side of the axis,
#' so the single-signed property the method depends on is preserved rather than
#' broken. Verified against Monte Carlo out to a standardized mean of 20,
#' including in combination with rho = 0.999; see the regression test.
#'
#' Do not "fix" this by clamping the split point into the box: that would
#' change which region is integrated.
#'
#' @noRd
.prod3_gauss_cells <- function(n, pars, bound) {
  gl <- .prod3_gauss_legendre(n)
  cell <- function(a, b) {
    list(pts = (b - a) / 2 * gl$x + (a + b) / 2, wts = (b - a) / 2 * gl$w)
  }
  cells_x <- list(cell(pars$m[1L] - bound, 0), cell(0, pars$m[1L] + bound))
  cells_y <- list(cell(pars$m[2L] - bound, 0), cell(0, pars$m[2L] + bound))

  total <- 0
  for (cx in cells_x) {
    for (cy in cells_y) {
      xx <- rep(cx$pts, times = n)
      yy <- rep(cy$pts, each = n)
      ww <- rep(cx$wts, times = n) * rep(cy$wts, each = n)
      total <- total + sum(ww * .prod3_integrand_vec(
        xx, yy,
        q_std = pars$q_std, m = pars$m, beta = pars$beta,
        cond_sd = pars$cond_sd, Rxy_inv = pars$Rxy_inv,
        det_Rxy = pars$det_Rxy
      ))
    }
  }
  total
}

#' Truncation bound with a provable tail-mass guarantee
#'
#' The integrand is a conditional probability (bounded by 1) times a bivariate
#' normal density, so truncating each standardized margin at `m +- bound`
#' discards at most `4 * pnorm(-bound)` of the integral. The bound is chosen so
#' that ceiling sits an order of magnitude below `tol`.
#'
#' This is derived rather than tuned on purpose. Truncation error is a *bias*,
#' and bias is invisible to the self-consistency check in
#' [.prod3_integrate_gauss()]: at `bound = 4` successive rules agree to 1.7e-14
#' while the answer is 3.2e-05 wrong -- the same "converges to a stable but
#' incorrect value" signature as the `hcubature()` failure this method replaces.
#' A hand-tuned bound would reintroduce exactly that defect.
#'
#' Wider is not safer either: a fixed node budget spread over a wider box
#' resolves the ridge less well, so the bound is capped.
#'
#' @noRd
.prod3_bound <- function(tol) {
  target <- max(tol, .Machine$double.eps) / 40
  min(max(6, -stats::qnorm(target)), 12)
}

#' Adaptive Gauss-Legendre driven by self-consistency
#'
#' Doubles the node count until successive rules agree to `tol`. The gap
#' `|I(n) - I(2n)|` is a genuine error estimate for *discretization* error --
#' unlike `hcubature()`'s reported error, which is satisfied at the very
#' configurations where the answer is worst. Truncation error is handled
#' separately and by construction in [.prod3_bound()], because this check
#' cannot see it.
#'
#' @noRd
.prod3_integrate_gauss <- function(pars, tol, nodes = NULL,
                                   max_nodes = 2048L, bound = NULL) {
  if (is.null(bound)) {
    bound <- .prod3_bound(tol)
  }
  if (!is.null(nodes)) {
    return(list(
      value = .prod3_gauss_cells(nodes, pars, bound),
      error = NA_real_, nodes = nodes
    ))
  }

  n <- 128L
  prev <- .prod3_gauss_cells(n, pars, bound)
  repeat {
    n <- 2L * n
    cur <- .prod3_gauss_cells(n, pars, bound)
    err <- abs(cur - prev)
    if (err < tol || n >= max_nodes) {
      if (err >= tol) {
        warning(
          "Gauss-Legendre quadrature did not reach tol = ", format(tol),
          " at the node cap (", max_nodes, "); successive rules still differ ",
          "by ", format(err, digits = 3), ". The covariance is severely ",
          "ill-conditioned. Treat the result as approximate.",
          call. = FALSE
        )
      }
      return(list(value = cur, error = err, nodes = n))
    }
    prev <- cur
  }
}

#' @noRd
.p_prod3_degenerate <- function(q, fixed_val, other_idx, mean, sds, cov) {
  pprodnormal(q / fixed_val,
    mu.x = mean[other_idx[1L]], mu.y = mean[other_idx[2L]],
    se.x = sds[other_idx[1L]], se.y = sds[other_idx[2L]],
    rho = cov[other_idx[1L], other_idx[2L]] /
      max(sds[other_idx[1L]] * sds[other_idx[2L]], .Machine$double.eps),
    lower.tail = fixed_val > 0
  )
}

#' Cumulative Distribution Function for the Product of Three Normal Variables
#'
#' Computes `P(X1 * X2 * X3 <= q)` where `(X1, X2, X3)` follows a trivariate
#' normal distribution with mean vector `mean` and covariance matrix `cov`.
#' `Z` is marginalized analytically through the conditional Gaussian structure
#' `Z | (X, Y)`, and the remaining two-dimensional integral is evaluated with
#' adaptive cubature (dimension reduction; see Tofighi, 2026).
#'
#' @param q Numeric scalar quantile.
#' @param mean Numeric vector of means of length 3.
#' @param cov 3x3 covariance matrix. Must be positive-definite, except that a
#'   single zero-variance component is permitted (the problem then reduces to
#'   the two-variable product-normal case). Perfect correlation between two
#'   components (`|rho| = 1`) or an indefinite matrix is rejected.
#' @param method Integration method. `"gauss"` (default) is tensor-product
#'   Gauss-Legendre quadrature on a domain partitioned at the coordinate axes,
#'   with the node count escalated until successive rules agree to `tol`.
#'   `"hcubature"` is the adaptive method used before version 1.7.0; it is
#'   retained for cross-checking and backward comparison, but is **not
#'   recommended** when the `(X, Y)` block is ill-conditioned (see Note).
#' @param tol Numeric tolerance passed to the integration routine; must be
#'   strictly positive.
#' @param nodes Optional integer: force a fixed number of Gauss-Legendre nodes
#'   per dimension instead of escalating adaptively. Ignored when
#'   `method = "hcubature"`. Mainly useful for reproducing a specific rule or
#'   for cross-checking a result at two node counts.
#' @param diagnostics Logical. If `TRUE`, the returned value carries `"error"`
#'   and `"nodes"` attributes. Defaults to `FALSE` so the return value stays a
#'   bare numeric for existing callers.
#'
#'   What `"error"` means depends on `method`, and the two are **not
#'   comparable**:
#'   * `method = "gauss"`: the gap between the last two quadrature rules, a
#'     genuine convergence estimate for discretization error. It does not see
#'     truncation error, which is instead bounded by construction. It is `NA`
#'     when `nodes` is supplied, because a single fixed rule produces no
#'     successive-rule gap to measure; to check convergence at a fixed rule,
#'     evaluate at `nodes` and `2 * nodes` and compare.
#'   * `method = "hcubature"`: that integrator's *own* reported error estimate,
#'     always present and never `NA` (`nodes` is ignored on this path). Treat it
#'     with suspicion. It is satisfied at exactly the configurations where the
#'     result is badly wrong (see Note), which is why it cannot be used to
#'     detect the failure this method was replaced over.
#' @param ... Additional arguments (unused; present for the `p_prod3`
#'   deprecated alias).
#'
#' @return Probability `P(X1 * X2 * X3 <= q)` as a numeric scalar in `[0, 1]`.
#' @note For a fully degenerate point mass (all variances zero) with zero means,
#'   `q == 0` returns `0.5` by the mid-distribution convention rather than `0`
#'   or `1`.
#'
#'   Before version 1.7.0 the default integrator was `"hcubature"`, which
#'   returns materially wrong values on ill-conditioned covariance matrices --
#'   at `rho = 0.999` the error reaches 24% at `q = 0.5` and 92% in relative
#'   terms in the lower tail, silently and with no diagnostic. The default is
#'   now `"gauss"`, which agrees with `"hcubature"` to roughly `1e-6` on
#'   well-conditioned input and remains accurate where `"hcubature"` fails.
#'   Results from the two methods therefore differ slightly on benign input and
#'   substantially on ill-conditioned input; the latter is the correction.
#' @seealso [pprodnormal()] and [qprodnormal()] for the two-variable product-
#'   normal CDF/quantile; [ProductNormal3] for the corresponding S7 class.
#' @section Note:
#' `p_prod3()` is a superseded alias for `pprodnormal3()`, kept for backward
#' compatibility; use `pprodnormal3()` in new code.
#' @export
#' @examples
#' Sigma <- diag(3)
#' pprodnormal3(q = 0, mean = c(0, 0, 0), cov = Sigma)
pprodnormal3 <- function(q, mean, cov, method = c("gauss", "hcubature"),
                         tol = 1e-6, nodes = NULL, diagnostics = FALSE) {
  checkmate::assert_number(q, finite = TRUE)
  checkmate::assert_numeric(mean, finite = TRUE, len = 3)
  checkmate::assert_matrix(cov, mode = "numeric", nrows = 3, ncols = 3)
  method <- match.arg(method)
  checkmate::assert_flag(diagnostics)
  if (!is.null(nodes)) {
    checkmate::assert_int(nodes, lower = 8, upper = 4096)
    nodes <- as.integer(nodes)
  }
  checkmate::assert_number(tol, finite = TRUE)
  if (tol <= 0) {
    stop("'tol' must be strictly positive.")
  }

  # Symmetrize covariance
  cov <- (cov + t(cov)) / 2

  sds <- sqrt(pmax(diag(cov), 0))

  # Degenerate cases: reduce to the two-variable product-normal problem ----
  if (sds[1L] < .Machine$double.eps) {
    x1 <- mean[1L]
    if (abs(x1) < .Machine$double.eps) {
      return(if (q == 0) 0.5 else as.numeric(q > 0))
    }
    return(.p_prod3_degenerate(q, x1, c(2L, 3L), mean, sds, cov))
  }
  if (sds[2L] < .Machine$double.eps) {
    x2 <- mean[2L]
    if (abs(x2) < .Machine$double.eps) {
      return(as.numeric(q >= 0))
    }
    return(.p_prod3_degenerate(q, x2, c(1L, 3L), mean, sds, cov))
  }
  if (sds[3L] < .Machine$double.eps) {
    x3 <- mean[3L]
    if (abs(x3) < .Machine$double.eps) {
      return(as.numeric(q >= 0))
    }
    return(.p_prod3_degenerate(q, x3, c(1L, 2L), mean, sds, cov))
  }

  # Full positive-definiteness check. The single zero-variance degenerate cases
  # above are handled separately; here all variances are > 0, so a non-PD `cov`
  # (indefinite, or perfect pairwise correlation) is malformed -- it would
  # otherwise produce a negative Var(Z | X, Y) and a non-convergent integral.
  # Reject cleanly rather than hang or surface a raw Lapack error.
  eigs <- eigen(cov, symmetric = TRUE, only.values = TRUE)$values
  if (min(eigs) <= sqrt(.Machine$double.eps) * max(eigs)) {
    stop(
      "'cov' must be positive-definite (smallest eigenvalue = ",
      format(min(eigs), digits = 4),
      "); perfect correlation between two components (|rho| = 1) or an ",
      "indefinite matrix is not supported by the dimension-reduction method."
    )
  }

  # Symmetry shortcut for zero-mean distributions (guarded by PD check above)
  if (all(abs(mean) < .Machine$double.eps^0.5) && q == 0) {
    return(0.5)
  }

  # Standardize to correlation scale
  R <- cov / outer(sds, sds)
  R <- (R + t(R)) / 2
  m <- mean / sds
  q_std <- q / prod(sds)

  # Precompute the bivariate (X, Y) quantities ONCE (not per integrand call).
  # Solve R_xy * beta = Cov(XY, Z) by Cholesky (chol + forward/back
  # substitution) instead of forming an explicit inverse: for the SPD block
  # this is better conditioned, kappa(U) = sqrt(kappa(R_xy)). R_xy is
  # positive-definite by the check above.
  Rxy <- R[1:2, 1:2]
  U <- chol(Rxy) # upper-triangular, U^T U = R_xy
  beta <- as.numeric(backsolve(U, forwardsolve(t(U), R[1:2, 3])))
  cond_sd <- sqrt(max(1 - sum(beta * R[1:2, 3]), .Machine$double.eps))
  Rxy_inv <- chol2inv(U)
  det_Rxy <- prod(diag(U))^2

  pars <- list(
    q_std = q_std, m = m, beta = beta, cond_sd = cond_sd,
    Rxy_inv = Rxy_inv, det_Rxy = det_Rxy
  )

  if (method == "gauss") {
    res <- .prod3_integrate_gauss(pars, tol = tol, nodes = nodes)
    return(.prod3_finalize(res$value, res$error, res$nodes, diagnostics))
  }

  integrand <- function(arg) {
    .prod3_integrand_2d(arg,
      q_std = q_std, m = m, beta = beta, cond_sd = cond_sd,
      Rxy_inv = Rxy_inv, det_Rxy = det_Rxy
    )
  }

  res <- cubature::hcubature(
    f = integrand,
    lowerLimit = c(-Inf, -Inf),
    upperLimit = c(Inf, Inf),
    tol = tol,
    fDim = 1L,
    vectorInterface = FALSE
  )

  .prod3_finalize(res$integral, res$error, NA_integer_, diagnostics)
}

#' Clamp to `[0, 1]` and optionally attach convergence diagnostics
#'
#' Diagnostics are opt-in so the default return stays a bare numeric: attaching
#' attributes unconditionally would change `print()` output and trip
#' attribute-sensitive comparisons in existing user code.
#'
#' @noRd
.prod3_finalize <- function(value, error, nodes, diagnostics) {
  p <- min(max(value, 0), 1)
  if (diagnostics) {
    attr(p, "error") <- error
    attr(p, "nodes") <- nodes
  }
  p
}

#' @export
#' @rdname pprodnormal3
p_prod3 <- function(...) pprodnormal3(...)

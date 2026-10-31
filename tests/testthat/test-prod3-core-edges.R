# Edge branches of R/prod3_core.R that the main product-normal3 tests miss.

.prod3_test_pars <- function(q_std) {
  corr <- matrix(c(1, .3, .2, .3, 1, .1, .2, .1, 1), 3, 3)
  chol_xy <- chol(corr[1:2, 1:2])
  beta <- as.numeric(
    backsolve(chol_xy, forwardsolve(t(chol_xy), corr[1:2, 3]))
  )
  list(
    q_std = q_std, m = c(0.4, 0.2, 0.1), beta = beta,
    cond_sd = sqrt(max(1 - sum(beta * corr[1:2, 3]), .Machine$double.eps)),
    Rxy_inv = chol2inv(chol_xy), det_Rxy = prod(diag(chol_xy))^2
  )
}

test_that("integrands give the one-sided limit times density on an axis", {
  # g is 1, 0 or 0.5 by the sign of q_std; the axes have measure zero but
  # the integrand must agree between the scalar and vector forms.
  for (case in list(list(q = 0.7, g = 1), list(q = -0.7, g = 0),
                    list(q = 0, g = 0.5))) {
    p <- .prod3_test_pars(case$q)
    x <- c(0, 0.5, 0.7)
    y <- c(0.3, 0, 0.4)
    vec <- do.call(.prod3_integrand_vec, c(list(x = x, y = y), p))
    for (i in 1:2) {
      scalar <- do.call(.prod3_integrand_2d, c(list(arg = c(x[i], y[i])), p))
      expected <- case$g * .prod3_bivariate_density(
        x[i], y[i], p$m, p$Rxy_inv, p$det_Rxy
      )
      expect_equal(scalar, expected, tolerance = 1e-12)
      expect_equal(vec[i], expected, tolerance = 1e-12)
    }
  }
})

test_that("Gauss quadrature warns when it hits the node cap above tol", {
  p <- .prod3_test_pars(0.5)
  expect_warning(
    res <- .prod3_integrate_gauss(p, tol = 1e-15, max_nodes = 128L),
    "reached the node cap"
  )
  expect_equal(res$nodes, 256L)
  expect_gt(res$error, 1e-15)
})

test_that("a zero-variance 2nd or 3rd component at mean 0 is a point mass", {
  # X2 (or X3) is identically 0, so the product is 0: P(prod <= q) = 1{q >= 0}.
  for (zero in 2:3) {
    sigma <- diag(c(1, 1, 1))
    sigma[zero, zero] <- 0
    mu <- c(0.5, 0.3, 0.2)
    mu[zero] <- 0
    expect_equal(as.numeric(pprodnormal3(0.2, mu, sigma)), 1)
    expect_equal(as.numeric(pprodnormal3(-0.2, mu, sigma)), 0)
    expect_equal(as.numeric(pprodnormal3(0, mu, sigma)), 1)
  }
})

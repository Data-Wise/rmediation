# pprodnormal3(lower.tail = FALSE): the upper tail is integrated directly, not as 1 - p.

# Independent oracle for independent factors: P(X1 * W > q) with W = X2 * X3, a
# one-dimensional integral over the exact density of W (dprodnormal) and normal tails.
upper_oracle <- function(q, m = c(1, 1, 1), s = c(1, 1, 1)) {
  f <- function(w) {
    dprodnormal(w, m[2], m[3], s[2], s[3], rho = 0) *
      ifelse(w > 0,
        stats::pnorm((q / w - m[1]) / s[1], lower.tail = FALSE),
        stats::pnorm((q / w - m[1]) / s[1])
      )
  }
  integrate(f, 0, 60, rel.tol = 1e-12, subdivisions = 2000)$value +
    integrate(f, -60, 0, rel.tol = 1e-12, subdivisions = 2000)$value
}

test_that("the upper tail matches the independent oracle, far into the tail", {
  cases <- list(
    list(q = 5, tol = 1e-10, rel = 1e-7),
    list(q = 30, tol = 1e-10, rel = 1e-7),
    list(q = 100, tol = 1e-14, rel = 1e-6)
  )
  for (k in cases) {
    got <- pprodnormal3(k$q, rep(1, 3), diag(3), tol = k$tol, lower.tail = FALSE)
    expect_equal(got, upper_oracle(k$q), tolerance = k$rel)
  }
  # 1 - p cannot resolve this value at the default tolerance; the direct integral can.
  far <- pprodnormal3(100, rep(1, 3), diag(3), tol = 1e-14, lower.tail = FALSE)
  expect_gt(far, 0)
  expect_lt(far, 1e-9)
})

test_that("lower and upper tails sum to one for correlated and sign-mixed inputs", {
  R <- matrix(c(1, .5, .3, .5, 1, -.2, .3, -.2, 1), 3)
  sds <- c(.2, .3, .25)
  Sigma <- R * outer(sds, sds)
  for (mean in list(c(.5, .25, -.15), c(0, 0, 0), c(-.4, .3, .2))) {
    for (q in c(-.2, -.01, 0, .05, .2)) {
      lo <- pprodnormal3(q, mean, Sigma, tol = 1e-8)
      up <- pprodnormal3(q, mean, Sigma, tol = 1e-8, lower.tail = FALSE)
      expect_equal(lo + up, 1, tolerance = 1e-7)
    }
  }
})

test_that("the default lower tail is unchanged", {
  R <- matrix(c(1, .5, .3, .5, 1, -.2, .3, -.2, 1), 3)
  Sigma <- R * outer(c(.2, .3, .25), c(.2, .3, .25))
  recorded <- c(0.025832942383111537, 0.67625832721085422, 0.95985136301523211, 0.99776098534662527)
  expect_equal(pprodnormal3(c(-.2, 0, .05, .2), c(1, .5, -.3) * .5, Sigma), recorded, tolerance = 1e-12)
  expect_identical(
    pprodnormal3(.05, c(.5, .25, -.15), Sigma),
    pprodnormal3(.05, c(.5, .25, -.15), Sigma, lower.tail = TRUE)
  )
  expect_equal(pprodnormal3(c(-1, 0, 2), c(0, 0, 0), diag(3)),
    c(0.073308076170429406, 0.5, 0.97349822866428537),
    tolerance = 1e-12
  )
})

test_that("degenerate and point-mass inputs give the exact upper tail", {
  # one zero-variance factor: reduces to the two-factor product
  S2 <- diag(c(0, 1, 2))
  for (fixed in c(2, -2)) {
    for (q in c(-3, 0, 4)) {
      up <- pprodnormal3(q, c(fixed, 1, .5), S2, lower.tail = FALSE)
      expect_equal(up, pprodnormal(q / fixed, 1, .5, 1, sqrt(2), 0, lower.tail = fixed < 0), tolerance = 1e-8)
      lo <- pprodnormal3(q, c(fixed, 1, .5), S2)
      expect_equal(lo + up, 1, tolerance = 1e-12)
    }
  }
  # two zero-variance factors: a scaled normal
  S1 <- diag(c(0, 0, 4))
  expect_equal(pprodnormal3(5, c(2, -3, 1), S1, lower.tail = FALSE), stats::pnorm((5 / -6 - 1) / 2))
  expect_equal(pprodnormal3(5, c(2, 3, 1), S1, lower.tail = FALSE), stats::pnorm((5 / 6 - 1) / 2, lower.tail = FALSE))
  # three zero-variance factors: a point mass, right-continuous
  S0 <- matrix(0, 3, 3)
  expect_identical(pprodnormal3(6, c(1, 2, 3), S0, lower.tail = FALSE), 0)
  expect_identical(pprodnormal3(5.9, c(1, 2, 3), S0, lower.tail = FALSE), 1)
  expect_identical(pprodnormal3(0, c(0, 2, 3), S0, lower.tail = FALSE), 0)
  # zero-mean symmetry shortcut keeps 0.5 in both tails
  expect_identical(pprodnormal3(0, c(0, 0, 0), diag(3), lower.tail = FALSE), 0.5)
})

test_that("lower.tail works with vectors, names and diagnostics", {
  q <- c(lo = 2, hi = 40)
  got <- pprodnormal3(q, rep(1, 3), diag(3), tol = 1e-10, lower.tail = FALSE, diagnostics = TRUE)
  expect_identical(names(got), c("lo", "hi"))
  expect_length(attr(got, "nodes"), 2L)
  expect_equal(
    as.numeric(got),
    c(pprodnormal3(2, rep(1, 3), diag(3), tol = 1e-10, lower.tail = FALSE),
      pprodnormal3(40, rep(1, 3), diag(3), tol = 1e-10, lower.tail = FALSE)
    )
  )
  expect_error(pprodnormal3(1, rep(1, 3), diag(3), lower.tail = NA))
  expect_error(pprodnormal3(c(1, 2), rep(1, 3), diag(3), lower.tail = "yes"))
})

test_that("hcubature agrees with gauss on the upper tail, and the integrands agree", {
  gauss <- pprodnormal3(4, c(.5, 1, 1), diag(c(.5, 1, 1)), tol = 1e-8, lower.tail = FALSE)
  cub <- pprodnormal3(4, c(.5, 1, 1), diag(c(.5, 1, 1)),
    method = "hcubature", tol = 1e-6, lower.tail = FALSE
  )
  expect_equal(cub, gauss, tolerance = 1e-4)

  pars <- list(m = c(.7, 1.1), beta = c(.2, -.1), cond_sd = .9, Rxy_inv = solve(matrix(c(1, .3, .3, 1), 2)))
  det_Rxy <- det(matrix(c(1, .3, .3, 1), 2))
  xs <- c(-1.2, .4, 2.1)
  ys <- c(.6, -.8, 1.4)
  for (lt in c(TRUE, FALSE)) {
    scalar <- vapply(seq_along(xs), function(i) {
      RMediation:::.prod3_integrand_2d(c(xs[i], ys[i]), 1.3, pars$m, pars$beta, pars$cond_sd,
        pars$Rxy_inv, det_Rxy,
        lower_tail = lt
      )
    }, numeric(1))
    vec <- RMediation:::.prod3_integrand_vec(xs, ys, 1.3, pars$m, pars$beta, pars$cond_sd,
      pars$Rxy_inv, det_Rxy,
      lower_tail = lt
    )
    expect_equal(vec, scalar, tolerance = 1e-12)
  }
})

# Checks against Meeker & Escobar (1994), "An algorithm to compute the cdf of the product of two
# normal random variables", Commun. Statist.-Simula. 23(1), 271-280.
#  - |rho| = 1: they solve rho x^2 + c x - z = 0 (discriminant D = c^2 + 4 rho z) and sum normal
#    probabilities at the roots. The oracle below is written independently of the package.
#  - Their stated test domain: means in {-3e5, 0, 3e5}, rho up to +/-0.99999, z in E(z) +/- 4 sd,
#    for which they report no integrator errors.

me_collinear <- function(z, mx, my, rho) {
  cc <- my - rho * mx
  D <- cc^2 + 4 * rho * z
  if (D < 0) {
    return(if (rho > 0) 0 else 1)
  }
  r <- sort((-cc + c(-1, 1) * sqrt(D)) / (2 * rho))
  inside <- pnorm(r[2] - mx) - pnorm(r[1] - mx)
  if (rho > 0) inside else 1 - inside
}

test_that("|rho| = 1 matches the article's closed form (160 combinations)", {
  g <- expand.grid(mx = c(-2, 0, 0.7, 3), my = c(-1.5, 0, 1, 2.5), rho = c(-1, 1), z = c(-3, -0.4, 0.2, 1, 6))
  for (i in seq_len(nrow(g))) {
    with(g[i, ], {
      expect_equal(pprodnormal(z, mx, my, 1, 1, rho), me_collinear(z, mx, my, rho),
        tolerance = 1e-12, info = paste(mx, my, rho, z)
      )
      expect_equal(pprodnormal(z, mx, my, 1, 1, rho, lower.tail = FALSE), 1 - me_collinear(z, mx, my, rho),
        tolerance = 1e-12, info = paste("upper", mx, my, rho, z)
      )
    })
  }
})

test_that("the case that used to stop with 'probably divergent' is exact", {
  expect_equal(pprodnormal(0.2, 0.7, 2.5, 1, 1, 1), me_collinear(0.2, 0.7, 2.5, 1), tolerance = 1e-12)
})

test_that("|rho| = 1 upper tail keeps far-tail precision", {
  # A = B ~ N(0.5, 1) (rho = 1, equal means), so AB = B^2 and P(B^2 > z) is closed form; at z = 200
  # it is ~1e-45, far below what 1 - lower could resolve
  z <- 200
  exact <- pnorm(sqrt(z) - 0.5, lower.tail = FALSE) + pnorm(-sqrt(z) - 0.5)
  expect_lt(exact, 1e-40)
  expect_equal(pprodnormal(z, 0.5, 0.5, 1, 1, 1, lower.tail = FALSE), exact, tolerance = 1e-10)
})

test_that("the article's test domain evaluates without error and tracks the normal limit", {
  rhos <- c(-0.99999, -0.9, 0, 0.9, 0.99999)
  means <- c(-3e5, 0, 3e5)
  for (mx in means) for (my in means) for (rho in rhos) {
    sdz <- sqrt(mx^2 + my^2 + 1 + rho^2 + 2 * rho * mx * my)
    for (k in c(-4, -2, 0, 2, 4)) {
      z <- mx * my + rho + k * sdz
      p <- expect_no_error(pprodnormal(z, mx, my, 1, 1, rho))
      expect_true(is.finite(p) && p >= 0 && p <= 1, info = paste(mx, my, rho, k))
      if (mx != 0 && my != 0) {
        expect_lt(abs(p - pnorm(k)), 5e-4, label = paste(mx, my, rho, k))
      }
    }
  }
})

test_that("evaluation order is symmetric: swapping the factors changes nothing", {
  for (rho in c(-0.99999, 0.3, 0.99999)) {
    expect_equal(
      pprodnormal(-9e10 + 1342, -3e5, 3e5, 1, 1, rho),
      pprodnormal(-9e10 + 1342, 3e5, -3e5, 1, 1, rho),
      tolerance = 1e-6
    )
  }
})

test_that("planted defect: the |rho| = 1 branch and the roundoff fallback are both needed", {
  skip_if_not_installed("testthat", "3.2.0")
  # without the exact branch the step-integrand error returns
  testthat::local_mocked_bindings(.dop_cdf_collinear = function(...) stop("collinear branch removed"))
  expect_error(pprodnormal(0.2, 0.7, 2.5, 1, 1, 1), "collinear branch removed")
})

test_that(".quad_roots handles the double root at the origin, no real roots, and rho = 0", {
  expect_identical(.quad_roots(1, 0, 0), c(0, 0)) # D = 0 and c = 0: rho x^2 = 0
  expect_null(.quad_roots(1, 0, -1)) # D < 0
  expect_null(.quad_roots(0, 2, 1)) # linear case is not a quadratic
  r <- .quad_roots(0.5, -3, 2) # 0.5 x^2 - 3 x - 2 = 0
  expect_equal(0.5 * r^2 - 3 * r - 2, c(0, 0), tolerance = 1e-12)
  expect_true(!is.unsorted(r))
})

test_that(".integrate_relaxing retries on roundoff reports and rethrows anything else", {
  calls <- 0L
  f_once <- function(x) {
    calls <<- calls + 1L
    if (calls == 1L) stop("roundoff error was detected")
    dnorm(x)
  }
  res <- .integrate_relaxing(f_once, -8, 8)
  expect_equal(res$value, 1, tolerance = 1e-8) # first tolerance failed, a later one succeeded
  expect_gt(calls, 1L)
  expect_error(.integrate_relaxing(function(x) stop("something else"), 0, 1), "something else")
  expect_error(.integrate_relaxing(function(x) stop("extremely bad integrand behaviour"), 0, 1), "bad integrand")
})

# dprodnormal(): analytic density of XY for bivariate normal (X, Y). Oracles:
#  - d/dz of the existing CDF pprodnormal() (finite difference);
#  - the closed form f(z) = exp(rho z/(1 - rho^2)) K0(|z|/(1 - rho^2)) / (pi sqrt(1 - rho^2)) for
#    zero means and unit variances (Nadarajah & Pogany 2016, Thm 2.1; Gaunt 2019), vs the
#    general integral (Rohatgi; Glen 2004), which share no code;
#  - exact identities (integrates to 1, sign/permutation/scaling).

D <- function(z, mx = 0.5, my = 0.3, sx = 0.2, sy = 0.4, rho = 0.3, ...) dprodnormal(z, mx, my, sx, sy, rho, ...)

test_that("the density is the derivative of the CDF (nonzero means, correlation)", {
  h <- 1e-5
  for (rho in c(-0.7, 0, 0.5)) {
    for (z in c(-0.1, 0.12, 0.3)) {
      num <- (pprodnormal(z + h, 0.5, 0.3, 0.2, 0.4, rho) - pprodnormal(z - h, 0.5, 0.3, 0.2, 0.4, rho)) / (2 * h)
      expect_equal(D(z, rho = rho), num, tolerance = 1e-6, info = paste("rho", rho, "z", z))
    }
  }
})

test_that("the zero-mean closed form and the general integral agree to near machine precision", {
  for (rho in c(0, 0.6, -0.8)) {
    for (z in c(1e-10, 1e-4, 0.01, 1, 5, 10)) {
      expect_equal(
        .dprod_bessel(z, rho), .dprod_integral(z, 0, 0, rho),
        tolerance = 1e-9, info = paste("rho", rho, "z", z)
      )
    }
  }
})

test_that("dprodnormal with zero means uses a path that equals the integral", {
  expect_equal(D(0.7, 0, 0, 1, 1, 0.4), .dprod_integral(0.7, 0, 0, 0.4), tolerance = 1e-9)
})

test_that("the density integrates to 1", {
  for (args in list(c(0.5, 0.3, 0.2, 0.4, 0.3), c(0, 0, 1, 1, 0.5), c(2, -1, 0.5, 0.5, -0.6))) {
    f <- function(z) dprodnormal(z, args[1], args[2], args[3], args[4], args[5])
    pts <- c(-Inf, 0, Inf)
    tot <- sum(vapply(1:2, function(i) stats::integrate(f, pts[i], pts[i + 1], rel.tol = 1e-8, subdivisions = 1000L)$value, 0))
    expect_equal(tot, 1, tolerance = 1e-6)
  }
})

test_that("sign, permutation and scaling identities hold", {
  z <- 0.15
  expect_equal(D(z, 0.5, 0.3, 0.2, 0.4, 0.3), D(-z, -0.5, 0.3, 0.2, 0.4, -0.3), tolerance = 1e-9)
  expect_equal(D(z, 0.5, 0.3, 0.2, 0.4, 0.3), D(z, 0.3, 0.5, 0.4, 0.2, 0.3), tolerance = 1e-9)
  # Z -> cZ scales the density by 1/c
  expect_equal(D(3 * z, 1.5, 0.3, 0.6, 0.4, 0.3), D(z) / 3, tolerance = 1e-9)
})

test_that("the density is vectorized over z and non-negative", {
  z <- c(-0.2, 0.05, 0.4)
  expect_equal(D(z), vapply(z, D, numeric(1)), tolerance = 1e-12)
  expect_true(all(D(seq(-1, 1, length.out = 41)) >= 0))
})

test_that("the log density is log of the density and finite far in the tail", {
  z <- c(-0.2, 0.4)
  expect_equal(D(z, log = TRUE), log(D(z)), tolerance = 1e-12)
  expect_true(is.finite(D(50, 0, 0, 1, 1, 0, log = TRUE)))
  expect_equal(D(200, 0, 0, 1, 1, 0), 0)
})

test_that("the density is infinite at exactly z = 0 (the product's log singularity)", {
  expect_equal(D(0), Inf)
  expect_equal(D(0, 0, 0, 1, 1, 0), Inf)
  expect_equal(D(0, log = TRUE), Inf)
  expect_gt(D(1e-12, 0, 0, 1, 1, 0), D(1e-6, 0, 0, 1, 1, 0)) # grows toward 0 like log(1/|z|)
})

test_that("invalid arguments are rejected", {
  expect_error(dprodnormal(0.1, 0.5, 0.3, 0, 0.4), "positive standard errors")
  expect_error(dprodnormal(0.1, 0.5, 0.3, 0.2, 0.4, rho = 1), "rho")
  expect_error(dprodnormal(0.1, 0.5, 0.3, 0.2, 0.4, rho = -1), "rho")
  expect_error(dprodnormal(NA_real_, 0.5, 0.3, 0.2, 0.4))
  expect_error(dprodnormal(numeric(0), 0.5, 0.3, 0.2, 0.4))
})

test_that("default se and rho match pprodnormal's", {
  expect_equal(dprodnormal(0.4, 0.5, 0.3), dprodnormal(0.4, 0.5, 0.3, 1, 1, 0))
})

test_that("the density is 0 at infinite arguments", {
  d <- dprodnormal(c(-Inf, Inf), mu.x = 0.3, mu.y = 0.4, se.x = 0.1, se.y = 0.2)
  expect_identical(d, c(0, 0))
  expect_identical(dprodnormal(Inf, 0.3, 0.4, log = TRUE), -Inf)
})

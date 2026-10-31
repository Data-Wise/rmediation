# Degenerate corners of dprodnormal() and qprodnormal(): point masses (se = 0) and |rho| = 1.
# Oracles never call the functions under test: dnorm/qnorm of the exact scaled normal, and a
# closed-form CDF of the quadratic a * b in one standard normal z, inverted with uniroot().

# If X is (nearly) fixed at mu.x, XY ~ Normal(mu.x * mu.y, (mu.x * se.y)^2); if Y is, swap roles.
# `fixed` names the (near-)degenerate factor.
dqpm_normal_limit <- function(mu.x, mu.y, se.x, se.y, fixed) {
  if (fixed == "x") c(mu.x * mu.y, abs(mu.x) * se.y) else c(mu.x * mu.y, abs(mu.y) * se.x)
}

# P(XY <= q) when X = mu.x + se.x * z and Y = mu.y + rho * se.y * z, rho = +1 or -1:
# XY = c0 + c1 z + c2 z^2 with c2 = rho * se.x * se.y; the event is read off the roots with pnorm.
dqpm_cdf_rho1 <- function(q, mu.x, mu.y, se.x, se.y, rho) {
  c2 <- rho * se.x * se.y
  c1 <- mu.x * rho * se.y + mu.y * se.x
  c0 <- mu.x * mu.y - q
  disc <- c1^2 - 4 * c2 * c0
  if (disc <= 0) {
    return(if (c2 > 0) 0 else 1)
  }
  r <- sort((-c1 + c(-1, 1) * sqrt(disc)) / (2 * c2))
  inside <- stats::pnorm(r[2]) - stats::pnorm(r[1])
  if (c2 > 0) inside else 1 - inside
}

dqpm_invert <- function(p, mu.x, mu.y, se.x, se.y, rho) {
  c2 <- rho * se.x * se.y
  vertex <- mu.x * mu.y - (mu.x * rho * se.y + mu.y * se.x)^2 / (4 * c2)
  stats::uniroot(
    function(q) dqpm_cdf_rho1(q, mu.x, mu.y, se.x, se.y, rho) - p,
    c(vertex - 10, vertex + 10),
    tol = 1e-13
  )$root
}

test_that("a nearly degenerate X or Y reproduces the exact scaled normal (density and quantile)", {
  p <- c(0.025, 0.5, 0.975)
  # c(mu.x, mu.y, se.x, se.y, fixed factor)
  cfgs <- list(
    list(0.3, 0.4, 1e-3, 0.1, "x"), list(0.3, 0.4, 0.1, 1e-3, "y"),
    list(-0.3, 0.4, 1e-3, 0.1, "x"), list(0.3, -0.4, 0.1, 1e-3, "y")
  )
  for (cfg in cfgs) {
    mom <- dqpm_normal_limit(cfg[[1]], cfg[[2]], cfg[[3]], cfg[[4]], cfg[[5]])
    x <- mom[1] + mom[2] * c(-2, -0.5, 0.5, 2)
    expect_equal(dprodnormal(x, cfg[[1]], cfg[[2]], cfg[[3]], cfg[[4]]), dnorm(x, mom[1], mom[2]), tolerance = 5e-3)
    expect_equal(qprodnormal(p, cfg[[1]], cfg[[2]], cfg[[3]], cfg[[4]]), qnorm(p, mom[1], mom[2]), tolerance = 5e-3)
  }
  # the quantile stays on the normal to ~1e-8 at se = 1e-6
  for (cfg in list(list(0.3, 0.4, 1e-6, 0.1, "x"), list(0.3, 0.4, 0.1, 1e-6, "y"))) {
    mom <- dqpm_normal_limit(cfg[[1]], cfg[[2]], cfg[[3]], cfg[[4]], cfg[[5]])
    expect_equal(qprodnormal(p, cfg[[1]], cfg[[2]], cfg[[3]], cfg[[4]]), qnorm(p, mom[1], mom[2]), tolerance = 1e-8)
  }
})

test_that("type = 'dop' rejects an exact zero se in dprodnormal() and qprodnormal()", {
  msg <- "positive standard errors"
  expect_error(dprodnormal(0.1, 0.3, 0.4, se.x = 0, se.y = 0.1), msg)
  expect_error(dprodnormal(0.1, 0.3, 0.4, se.x = 0.1, se.y = 0), msg)
  expect_error(dprodnormal(0.12, 0.3, 0.4, se.x = 0, se.y = 0), msg)
  expect_error(qprodnormal(0.5, 0.3, 0.4, se.x = 0, se.y = 0.1, type = "dop"), msg)
  expect_error(qprodnormal(0.5, 0.3, 0.4, se.x = 0.1, se.y = 0, type = "dop"), msg)
  expect_error(qprodnormal(0.5, 0.3, 0.4, se.x = 0, se.y = 0, type = "dop"), msg)
})

test_that("type = 'MC' returns the point mass mu.x * mu.y for every p when both se are 0", {
  set.seed(7)
  p <- c(0.001, 0.025, 0.5, 0.975, 0.999)
  expect_equal(qprodnormal(p, 0.3, 0.4, 0, 0, type = "MC"), rep(0.12, 5), tolerance = 1e-12)
  expect_equal(qprodnormal(p, -0.3, 0.4, 0, 0, type = "MC"), rep(-0.12, 5), tolerance = 1e-12)
})

test_that("type = 'MC' with one zero se matches the scaled normal within Monte Carlo error", {
  skip_on_cran()
  set.seed(11)
  p <- c(0.025, 0.5, 0.975)
  for (cfg in list(list(0.3, 0.4, 0, 0.1, "x"), list(0.3, 0.4, 0.1, 0, "y"))) {
    mom <- dqpm_normal_limit(cfg[[1]], cfg[[2]], cfg[[3]], cfg[[4]], cfg[[5]])
    got <- qprodnormal(p, cfg[[1]], cfg[[2]], cfg[[3]], cfg[[4]], type = "MC", n.mc = 2e5)
    expect_equal(got, qnorm(p, mom[1], mom[2]), tolerance = 3e-3)
  }
})

test_that("qprodnormal() at rho = +1 and -1 inverts the closed-form quadratic CDF", {
  p <- c(0.025, 0.5, 0.975)
  cfgs <- list(c(0.3, 0.4, 0.1, 0.2), c(-0.3, 0.4, 0.1, 0.2), c(0.5, 0.3, 0.2, 0.4), c(0.05, -0.2, 0.3, 0.3))
  for (rho in c(1, -1)) {
    for (cfg in cfgs) {
      want <- vapply(p, function(pp) dqpm_invert(pp, cfg[1], cfg[2], cfg[3], cfg[4], rho), numeric(1))
      got <- qprodnormal(p, cfg[1], cfg[2], cfg[3], cfg[4], rho = rho)
      expect_equal(got, want, tolerance = 1e-6)
      # the upper tail is the lower tail at 1 - p
      up <- qprodnormal(p, cfg[1], cfg[2], cfg[3], cfg[4], rho = rho, lower.tail = FALSE)
      expect_equal(up, rev(want), tolerance = 1e-6)
    }
  }
})

test_that("the local rho = +-1 CDF oracle is itself sound (known-answer checks)", {
  # mu = 0, se = 1, rho = 1: XY = z^2, so P(XY <= q) = 2 * pnorm(sqrt(q)) - 1
  expect_equal(dqpm_cdf_rho1(1.7, 0, 0, 1, 1, 1), 2 * pnorm(sqrt(1.7)) - 1, tolerance = 1e-14)
  # rho = -1: XY = -z^2, so P(XY <= q) = 1 - (2 * pnorm(sqrt(-q)) - 1) for q < 0
  expect_equal(dqpm_cdf_rho1(-1.7, 0, 0, 1, 1, -1), 2 - 2 * pnorm(sqrt(1.7)), tolerance = 1e-14)
  expect_equal(dqpm_cdf_rho1(-1, 0, 0, 1, 1, 1), 0)
  expect_equal(dqpm_cdf_rho1(1, 0, 0, 1, 1, -1), 1)
})

test_that("dprodnormal() at |rho| = 1 stops with the documented message", {
  expect_error(dprodnormal(0.1, 0.3, 0.4, 0.1, 0.2, rho = 1), "needs -1 < rho < 1")
  expect_error(dprodnormal(0.1, 0.3, 0.4, 0.1, 0.2, rho = -1), "needs -1 < rho < 1")
})

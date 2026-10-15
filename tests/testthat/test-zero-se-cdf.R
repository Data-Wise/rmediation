# A zero standard error makes a factor a constant, so X * Y is a scaled normal (or a point mass).
# Codex adversarial review: pprodnormal(type = "MC") returned 0 / 0.0012 for the case below
# (exact 0.2524925) and the DOP error told callers to use MC.

test_that("one fixed factor: the CDF is the scaled-normal CDF, for dop, MC and all", {
  exact <- pnorm((0.1 / 0.3 - 0.4) / 0.1)
  expect_equal(exact, 0.2524925, tolerance = 1e-6)
  for (type in c("dop", "MC")) {
    expect_equal(pprodnormal(0.1, 0.3, 0.4, se.x = 0, se.y = 0.1, type = type), exact, tolerance = 1e-12)
    expect_equal(pprodnormal(0.1, 0.4, 0.3, se.x = 0.1, se.y = 0, type = type), exact, tolerance = 1e-12)
  }
  both <- pprodnormal(0.1, 0.3, 0.4, se.x = 0, se.y = 0.1, type = "all")
  expect_equal(unname(unlist(both)), c(exact, exact), tolerance = 1e-12)
})

test_that("upper tail, vector q and a negative fixed factor", {
  q <- c(-0.2, 0, 0.05, 0.3)
  lo <- pprodnormal(q, 0.3, 0.4, se.x = 0, se.y = 0.1)
  up <- pprodnormal(q, 0.3, 0.4, se.x = 0, se.y = 0.1, lower.tail = FALSE)
  expect_equal(lo + up, rep(1, 4), tolerance = 1e-12)
  expect_equal(lo, pnorm((q / 0.3 - 0.4) / 0.1), tolerance = 1e-12)
  # c < 0 reverses the inequality; reflection: P(-0.3 Y <= q) = P(0.3 Y >= -q)
  neg <- pprodnormal(q, -0.3, 0.4, se.x = 0, se.y = 0.1)
  expect_equal(neg, pprodnormal(-q, 0.3, 0.4, se.x = 0, se.y = 0.1, lower.tail = FALSE), tolerance = 1e-12)
  expect_equal(neg, pnorm((q / -0.3 - 0.4) / 0.1, lower.tail = FALSE), tolerance = 1e-12)
})

test_that("a zero fixed factor and two fixed factors give step functions", {
  for (type in c("dop", "MC")) {
    expect_equal(pprodnormal(c(-1, 1), 0, 0.4, se.x = 0, se.y = 0.1, type = type), c(0, 1))
    expect_equal(pprodnormal(c(0.05, 0.12, 0.2), 0.3, 0.4, se.x = 0, se.y = 0, type = type), c(0, 1, 1))
  }
  expect_equal(pprodnormal(0.2, 0.3, 0.4, se.x = 0, se.y = 0, lower.tail = FALSE), 0)
  # P(XY > q) is 0 at q = c and 1 just below it; the CDF at the atom is 1 (Codex review)
  expect_equal(pprodnormal(0.12, 0.3, 0.4, se.x = 0, se.y = 0), 1)
  expect_equal(pprodnormal(0.12, 0.3, 0.4, se.x = 0, se.y = 0, lower.tail = FALSE), 0)
  expect_equal(pprodnormal(0.1199, 0.3, 0.4, se.x = 0, se.y = 0, lower.tail = FALSE), 1)
})

test_that("the degenerate CDF is the limit of the positive-se CDF", {
  eps <- 1e-7
  expect_equal(
    pprodnormal(0.1, 0.3, 0.4, se.x = eps, se.y = 0.1),
    pprodnormal(0.1, 0.3, 0.4, se.x = 0, se.y = 0.1), tolerance = 1e-4
  )
})

test_that("the positive-se path is unchanged", {
  expect_null(RMediation:::.degenerate_pprod(0.1, 0.3, 0.4, 0.1, 0.1))
})

# Output-shape contract for the functions that downstream code indexes by
# position or by element name. Manuscript scripts in the research repos use
# `medci(...)[[1]]`, `$\`95% CI\``, `$MC.Error`, `pprodnormal3(q, mean, cov, tol)`
# and the `memory_exp` dataset. A rename or reorder here breaks them one line
# after the call, with no error at the call itself. If one of these tests must
# change, treat it as a breaking API change: deprecate first (NEWS + lifecycle).
# See planning/BRAINSTORM-impact-plan-2026-11-04.md (local) for the inventory.

test_that("medci() element names and order are stable for every single type", {
  fits <- list(
    dop = medci(0.3, 0.4, 0.1, 0.12, type = "dop"),
    asymp = medci(0.3, 0.4, 0.1, 0.12, type = "asymp"),
    MC = medci(0.3, 0.4, 0.1, 0.12, type = "MC", n.mc = 2000)
  )
  expect_identical(names(fits$dop), c("95% CI", "Estimate", "SE"))
  expect_identical(names(fits$asymp), c("95% CI", "Estimate", "SE"))
  expect_identical(names(fits$MC), c("95% CI", "Estimate", "SE", "MC.Error"))
  for (r in fits) {
    # [[1]] is the interval and is the same object as the named element
    expect_type(r[[1]], "double")
    expect_length(r[[1]], 2L)
    expect_identical(r[[1]], r[["95% CI"]])
  }
})

test_that("medci() interval label follows alpha", {
  expect_identical(names(medci(0.3, 0.4, 0.1, 0.12, type = "dop", alpha = 0.10))[1], "90% CI")
  expect_identical(names(medci(0.3, 0.4, 0.1, 0.12, type = "dop", alpha = 0.01))[1], "99% CI")
})

test_that("medci() accepts both 'MC' and 'mc' with identical shape and values", {
  set.seed(15)
  upper <- medci(0.3, 0.4, 0.1, 0.12, type = "MC", n.mc = 2000)
  set.seed(15)
  lower <- medci(0.3, 0.4, 0.1, 0.12, type = "mc", n.mc = 2000)
  expect_identical(names(upper), names(lower))
  expect_equal(upper, lower)
})

test_that("medci(type = 'all') groups the three methods by fixed names", {
  r <- medci(0.3, 0.4, 0.1, 0.12, type = "all", n.mc = 2000)
  expect_identical(names(r), c("Distribution of Product", "Monte Carlo", "Asymptotic Normal"))
  expect_identical(names(r[["Distribution of Product"]]), c("95% CI", "Estimate", "SE"))
  expect_identical(names(r[["Monte Carlo"]]), c("95% CI", "Estimate", "SE", "MC.Error"))
  expect_identical(names(r[["Asymptotic Normal"]]), c("95% CI", "Estimate", "SE"))
})

test_that("medci() keeps its documented leading argument names and order", {
  expect_identical(
    names(formals(medci))[1:7],
    c("mu.x", "mu.y", "se.x", "se.y", "rho", "alpha", "type")
  )
  expect_true("n.mc" %in% names(formals(medci)))
})

test_that("pprodnormal3() keeps q, mean, cov first and tol as a named argument", {
  expect_identical(names(formals(pprodnormal3))[1:3], c("q", "mean", "cov"))
  expect_true("tol" %in% names(formals(pprodnormal3)))
})

test_that("memory_exp keeps the shape the manuscripts rely on", {
  utils::data("memory_exp", package = "RMediation", envir = environment())
  expect_identical(dim(memory_exp), c(369L, 5L))
  expect_identical(names(memory_exp), c("study", "repetition", "recall", "imagery", "x"))
})

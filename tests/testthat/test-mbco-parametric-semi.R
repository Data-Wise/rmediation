# Nested-model fixture shared by both tests below: a 2-variable RAM path
# model (x -> y) fit under H1 (path free) and H0 (path fixed at 0). This
# exercises mbco_parametric()/.mbco_semi() with real fitted MxModel objects
# rather than the empty placeholder models used in test-s7-mbco.R /
# test-mbco-legacy.R, which only ever reach the dispatch/validation layer.
#
# "Number of Threads" is forced to 1: OpenMx's internal parametric bootstrap
# (mxCompare(..., boot = TRUE) -> mxGenerateData()) failed with "Cannot
# bootstrap null model" on CI's multi-core Linux/Windows/macOS runners while
# passing locally, where OpenMx defaults to 1 thread. Multi-threaded fitting
# changes floating-point summation order in the optimizer backend, which is a
# known source of platform-dependent numerical divergence; pinning to 1
# thread removes that variable so the fixture behaves identically everywhere.
OpenMx::mxOption(NULL, "Number of Threads", 1)

.mbco_fit_h0_h1 <- function(n = 500, seed = 123) {
  set.seed(seed)
  x <- rnorm(n)
  y <- 0.5 * x + rnorm(n)
  dat <- data.frame(x = x, y = y)

  h1 <- OpenMx::mxModel(
    "H1",
    type = "RAM",
    manifestVars = c("x", "y"),
    OpenMx::mxPath(from = "x", to = "y", arrows = 1, free = TRUE, values = 0.3),
    OpenMx::mxPath(from = c("x", "y"), arrows = 2, free = TRUE, values = 1),
    OpenMx::mxPath(from = "one", to = c("x", "y"), free = TRUE, values = 0),
    OpenMx::mxData(dat, type = "raw")
  )
  h1_fit <- OpenMx::mxRun(h1, silent = TRUE, suppressWarnings = TRUE)

  h0 <- OpenMx::mxModel(
    h1_fit,
    name = "H0",
    OpenMx::mxPath(from = "x", to = "y", arrows = 1, free = FALSE, values = 0)
  )
  h0_fit <- OpenMx::mxRun(h0, silent = TRUE, suppressWarnings = TRUE)

  list(h0 = h0_fit, h1 = h1_fit)
}

.mbco_test_optim <- function() {
  if (OpenMx::imxHasNPSOL()) "NPSOL" else "SLSQP"
}

test_that("mbco_parametric returns a valid chi-square test structure", {
  skip_if_not_installed("OpenMx")

  models <- .mbco_fit_h0_h1()
  res <- mbco_parametric(
    h0 = models$h0,
    h1 = models$h1,
    R = 5L,
    optim = .mbco_test_optim()
  )

  expect_type(res, "list")
  expect_named(res, c("chisq", "df", "p"))
  expect_gte(res$chisq, 0)
  expect_equal(res$df, 1)
  expect_gte(res$p, 0)
  expect_lte(res$p, 1)
})

test_that(".mbco_semi returns a valid chi-square test structure", {
  skip_if_not_installed("OpenMx")

  models <- .mbco_fit_h0_h1()
  res <- .mbco_semi(
    h0 = models$h0,
    h1 = models$h1,
    R = 5L,
    optim = .mbco_test_optim()
  )

  expect_type(res, "list")
  expect_named(res, c("chisq", "df", "p"))
  expect_gte(res$chisq, 0)
  expect_equal(res$df, 1)
  expect_gte(res$p, 0)
  expect_lte(res$p, 1)
})

test_that(".mbco_semi rejects a factor/character manifest variable", {
  skip_if_not_installed("OpenMx")

  models <- .mbco_fit_h0_h1()
  # Inject a factor column that .mbco_semi will pick up via h1$manifestVars
  # once we swap in data containing a non-numeric manifest variable.
  bad_data <- data.frame(
    x = factor(rep(c("a", "b"), length.out = 200)),
    y = rnorm(200)
  )
  h1_bad <- OpenMx::mxModel(models$h1, OpenMx::mxData(bad_data, type = "raw"))

  expect_error(
    .mbco_semi(h0 = models$h0, h1 = h1_bad, R = 5L, optim = .mbco_test_optim()),
    "factor or character"
  )
})

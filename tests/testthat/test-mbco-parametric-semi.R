# Nested-model fixture shared by all three tests below: a 2-variable RAM path
# model (x -> y) fit under H1 (path free) and H0 (path fixed at 0). This
# exercises mbco_parametric()/.mbco_semi() with real fitted MxModel objects
# rather than the empty placeholder models used in test-s7-mbco.R /
# test-mbco-legacy.R, which only ever reach the dispatch/validation layer.
#
# H0 and H1 are each built from scratch via mxModel(), never derived from an
# already-run model. Deriving H0 as mxModel(h1_fit, name = "H0", ...) mutates
# a model that carries run state -- OpenMx flags this ("MxModel 'H1' was
# modified since it was run") -- and that stale state made
# mxCompare(..., boot = TRUE)'s internal mxGenerateData() call fail with
# "Cannot bootstrap null model" on CI's Linux/Windows/macOS runners:
# assertModelRunAndFresh() rejects a model whose structure changed after it
# was run. Building every model independently, always from raw mxModel(),
# avoids that stale run-state entirely.
.mbco_build_model <- function(name, path_free, data) {
  OpenMx::mxModel(
    name,
    type = "RAM",
    manifestVars = c("x", "y"),
    OpenMx::mxPath(from = "x", to = "y", arrows = 1, free = path_free, values = 0.3),
    OpenMx::mxPath(from = c("x", "y"), arrows = 2, free = TRUE, values = 1),
    OpenMx::mxPath(from = "one", to = c("x", "y"), free = TRUE, values = 0),
    OpenMx::mxData(data, type = "raw")
  )
}

.mbco_fit_h0_h1 <- function(n = 200, seed = 123) {
  set.seed(seed)
  x <- rnorm(n)
  y <- 0.5 * x + rnorm(n)
  dat <- data.frame(x = x, y = y)

  h1_fit <- OpenMx::mxRun(.mbco_build_model("H1", TRUE, dat), silent = TRUE, suppressWarnings = TRUE)
  h0_fit <- OpenMx::mxRun(.mbco_build_model("H0", FALSE, dat), silent = TRUE, suppressWarnings = TRUE)

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

  # .mbco_semi() never calls mxCompare(..., boot = TRUE) -- its own
  # bootstrap loop is hand-rolled below the factor/character check -- so
  # unlike the mbco_parametric() fixture above, mutating an already-run
  # model to swap in bad_data (without re-running) is safe here: mxCompare()
  # only needs cached fit statistics from the original run, and the factor
  # check reads h1$data$observed, which reflects the swapped-in data.
  models <- .mbco_fit_h0_h1()
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

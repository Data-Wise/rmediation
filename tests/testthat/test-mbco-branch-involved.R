# Slice 1 of tasks/plan-35-probe.md: .mbco_involved() finds the free parameters an equality
# constraint depends on by perturbing each one and re-evaluating the constraint, at the FULL
# model's estimates (at the null's own solution a zero path hides the others: a*b does not move
# with b when a = 0).

src <- readLines(test_path("test-mbco-constraint-guard.R"))
eval(parse(text = src[3:39])) # .guard_med_model(), .guard_fits(): free paths "a", "b", "cp"

test_that("a product constraint depends on both factors", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  expect_setequal(RMediation:::.mbco_involved(f$h0, f$h1, "ind_eq0"), c("a", "b"))
})

test_that("the null-solution trap: a h0 sitting at a = 0 still reports both factors", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  at_zero <- OpenMx::omxSetParameters(f$h0, labels = c("a", "b"), values = c(0, 0.3))
  expect_setequal(RMediation:::.mbco_involved(at_zero, f$h1, "ind_eq0"), c("a", "b"))
})

test_that("a linear constraint depends on its one parameter", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  lin <- OpenMx::mxModel(f$h1, name = "lin", OpenMx::mxConstraint(b == 0, name = "b_eq0"))
  expect_identical(RMediation:::.mbco_involved(lin, f$h1, "b_eq0"), "b")
})

test_that("other constraint shapes: a == b, a three-way product, a constant", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  eq <- OpenMx::mxModel(f$h1, name = "eq", OpenMx::mxConstraint(a == b, name = "a_eq_b"))
  expect_setequal(RMediation:::.mbco_involved(eq, f$h1, "a_eq_b"), c("a", "b"))
  tri <- OpenMx::mxModel(f$h1, name = "tri",
    OpenMx::mxAlgebra(a * b * cp, name = "abc"),
    OpenMx::mxConstraint(abc == 0, name = "abc_eq0")
  )
  expect_setequal(RMediation:::.mbco_involved(tri, f$h1, "abc_eq0"), c("a", "b", "cp"))
  const <- OpenMx::mxModel(f$h1, name = "const",
    OpenMx::mxAlgebra(sum(1, 2), name = "k"),
    OpenMx::mxConstraint(k == 3, name = "k_eq3")
  )
  expect_length(RMediation:::.mbco_involved(const, f$h1, "k_eq3"), 0L)
})

test_that("an unknown constraint name is an error", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  expect_error(RMediation:::.mbco_involved(f$h0, f$h1, "nope"), "nope")
})

test_that("the user's models are not modified", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  before <- OpenMx::omxGetParameters(f$h0)
  RMediation:::.mbco_involved(f$h0, f$h1, "ind_eq0")
  expect_identical(OpenMx::omxGetParameters(f$h0), before)
})

test_that("planted defect: evaluating at the null's own solution misses a factor", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("testthat", "3.2.0")
  f <- .guard_fits(1)
  at_zero <- OpenMx::omxSetParameters(f$h0, labels = c("a", "b"), values = c(0, 0.3))
  testthat::local_mocked_bindings(
    .mbco_probe_point = function(h0, h1) h0, # the defect: evaluate where the null sits
    .package = "RMediation"
  )
  got <- RMediation:::.mbco_involved(at_zero, f$h1, "ind_eq0")
  expect_failure(expect_setequal(got, c("a", "b")))
  expect_identical(got, "a") # only the zero factor moves the constraint
})

test_that("planted defect: a detection threshold that is too large finds nothing", {
  skip_if_not_installed("OpenMx")
  f <- .guard_fits(1)
  expect_length(RMediation:::.mbco_involved(f$h0, f$h1, "ind_eq0", tol = 1e6), 0L)
})

# Known-answer fixture for MBCO linear nulls on `memory_exp` (OpenMx RAM, x -> {repetition, imagery} -> recall).
# Answers are mxCompare() diffLL values, also medfit's S19 known answers. A later SEMFit route is
# compared against these numbers. See rmediation#35 for the Rd example's shifted labels.

oracle_a1 <- 221.045546 # diffLL, null a1 == 0
oracle_b1 <- 0.083100   # diffLL, null b1 == 0; also the min-of-two answer for a1 * b1 == 0
oracle_tol <- 1e-6

test_that("memory_exp RAM fixture carries the intended path labels", {
  skip_if_not_installed("OpenMx")
  A <- .memory_exp_ram("labels")$A$labels
  expect_identical(A["repetition", "x"], "a1")
  expect_identical(A["imagery", "x"], "a2")
  expect_identical(A["recall", "x"], "cp")
  expect_identical(A["recall", "repetition"], "b1")
  expect_identical(A["recall", "imagery"], "b2")
})

test_that("linear nulls reproduce the known diffLL values (df = 1)", {
  skip_if_not_installed("OpenMx")
  o <- .memory_exp_oracle()

  lrt_a1 <- .mx_lrt(o$full, o$null_a1)
  lrt_b1 <- .mx_lrt(o$full, o$null_b1)

  expect_lt(abs(lrt_a1[["diffLL"]] - oracle_a1), oracle_tol)
  expect_lt(abs(lrt_b1[["diffLL"]] - oracle_b1), oracle_tol)
  expect_identical(unname(lrt_a1[["df"]]), 1)
  expect_identical(unname(lrt_b1[["df"]]), 1)
})

test_that("the min-of-two statistic is 0.083100; the larger diffLL is the wrong branch", {
  skip_if_not_installed("OpenMx")
  o <- .memory_exp_oracle()
  diff_ll <- c(
    a1 = .mx_lrt(o$full, o$null_a1)[["diffLL"]],
    b1 = .mx_lrt(o$full, o$null_b1)[["diffLL"]]
  )

  expect_lt(abs(min(diff_ll) - oracle_b1), oracle_tol)
  # Planted defect: taking the larger diffLL reports 221.05 and must be rejected.
  expect_gt(abs(max(diff_ll) - oracle_b1), 100)
})

test_that("a fixed-at-zero parameter gives the same diffLL as the constraint null", {
  skip_if_not_installed("OpenMx")
  o <- .memory_exp_oracle()
  base <- .memory_exp_ram("fixed")
  for (lab in c("a1", "b1")) {
    fixed <- .mx_fit(OpenMx::omxSetParameters(
      base, labels = lab, free = FALSE, values = 0, name = paste0(lab, "_fixed")
    ))
    expected <- if (lab == "a1") oracle_a1 else oracle_b1
    expect_lt(abs(.mx_lrt(o$full, fixed)[["diffLL"]] - expected), oracle_tol, label = lab)
  }
})

test_that("control: the ?mbco example as written (shifted labels) does not match the oracle", {
  skip_if_not_installed("OpenMx")
  rd_base <- .memory_exp_ram_rd_shifted()
  A <- rd_base$A$labels
  expect_identical(A["repetition", "x"], "a2")
  expect_identical(A["imagery", "x"], "cp")
  expect_identical(A["recall", "x"], "a1")

  # As in the Rd, the null is built from the unfitted model, then both are fitted.
  rd_null <- .mx_fit(OpenMx::mxModel(
    rd_base, name = "Null Model 1", OpenMx::mxConstraint(ind1 == 0, name = "ind1_eq0_constr")
  ))
  rd_full <- .mx_fit(rd_base)
  rd_diff_ll <- .mx_lrt(rd_full, rd_null)[["diffLL"]]

  expect_lt(abs(rd_diff_ll - 0.060332), oracle_tol)
  # The shifted-label answer is not the correct one, so a passing oracle test proves the labels are right.
  expect_gt(abs(rd_diff_ll - oracle_b1), 1e-3)
})

test_that("mbco() accepts fitted RAM models and returns the oracle statistics (asymp)", {
  skip_if_not_installed("OpenMx")
  o <- .memory_exp_oracle()

  res_a1 <- mbco(o$null_a1, o$full, type = "asymp")
  expect_s3_class(res_a1, "RMediation::MBCOResult")
  expect_lt(abs(res_a1@statistic - oracle_a1), oracle_tol)
  expect_identical(res_a1@df, 1)
  expect_identical(res_a1@type, "asymp")

  res_b1 <- mbco(o$null_b1, o$full, type = "asymp")
  expect_lt(abs(res_b1@statistic - oracle_b1), oracle_tol)
  expect_identical(res_b1@df, 1)
})

test_that("mbco() rejects non-MxModel inputs with a named error", {
  skip_if_not_installed("OpenMx")
  model <- OpenMx::mxModel("any")
  expect_error(mbco(list(), model), "h0 must be an MxModel")
  expect_error(mbco(model, list()), "h1 must be an MxModel")
})

# Slice 1 of the B+E plan (tasks/plan-34-be.md): MBCOResult gets an optional `refit`
# property recording that h0 was refit at a tighter feasibility tolerance. NULL means
# no refit, so every existing construction is unchanged.

.refit_info <- function() {
  list(tolerance = 1e-8, statistic_before = 0, statistic_after = 0.4745)
}

test_that("an MBCOResult built the old way has refit NULL", {
  res <- MBCOResult(statistic = 4.2, df = 1, p_value = 0.04, type = "asymp")
  expect_null(res@refit)
  expect_null(res$refit)
  expect_null(res[["refit"]])
})

test_that("the refit slot round-trips and is exposed by $, [[ and names", {
  res <- MBCOResult(
    statistic = 0.4745, df = 1, p_value = 0.49, type = "asymp",
    refit = .refit_info()
  )
  expect_identical(res@refit, .refit_info())
  expect_identical(res$refit, .refit_info())
  expect_identical(res[["refit"]], .refit_info())
  expect_true("refit" %in% names(res))
  # legacy aliases still work
  expect_equal(res$chisq, 0.4745)
  expect_equal(res$p, 0.49)
})

test_that("the refit slot is validated", {
  mk <- function(r) MBCOResult(statistic = 1, df = 1, p_value = 0.3, type = "asymp", refit = r)
  expect_error(mk("yes"))
  expect_error(mk(list(tolerance = 1e-8)), "tolerance.*statistic_before.*statistic_after")
  expect_error(
    mk(list(tolerance = "a", statistic_before = 0, statistic_after = 1)),
    "numeric"
  )
  expect_error(
    mk(list(tolerance = 1e-8, statistic_before = NA_real_, statistic_after = 1)),
    "finite"
  )
})

test_that("print and summary show a refit line only when a refit happened", {
  plain <- MBCOResult(statistic = 4.2, df = 1, p_value = 0.04, type = "asymp")
  refit <- MBCOResult(
    statistic = 0.4745, df = 1, p_value = 0.49, type = "asymp",
    refit = .refit_info()
  )
  expect_false(any(grepl("refit", capture.output(print(plain)), ignore.case = TRUE)))
  expect_false(any(grepl("refit", capture.output(summary(plain)), ignore.case = TRUE)))
  out <- capture.output(print(refit))
  expect_true(any(grepl("h0 was refit", out)))
  expect_true(any(grepl("1e-08", out)))
  expect_true(any(grepl("0.4745", out)))
  expect_true(any(grepl("h0 was refit", capture.output(summary(refit)))))
})

test_that("planted defect: printing the refit line for a plain result is caught", {
  skip_if_not_installed("testthat", "3.2.0")
  plain <- MBCOResult(statistic = 4.2, df = 1, p_value = 0.04, type = "asymp")
  # a result whose refit is an empty list must not print a refit line either
  expect_error(MBCOResult(statistic = 1, df = 1, p_value = 0.3, type = "asymp", refit = list()))
  expect_false(any(grepl("h0 was refit", capture.output(print(plain)))))
})

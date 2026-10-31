# Slice 1 of tasks/plan-35.md: MBCOResult gets an optional `branch` property naming the
# single-path null that gave the reported result (set by mbco_product_null()). NULL means
# the result did not come from a product-null comparison.

test_that("an MBCOResult built the old way has branch NULL", {
  res <- MBCOResult(statistic = 4.2, df = 1, p_value = 0.04, type = "asymp")
  expect_null(res@branch)
  expect_null(res$branch)
  expect_null(res[["branch"]])
})

test_that("the branch slot round-trips and is exposed by $, [[ and names", {
  res <- MBCOResult(statistic = 0.0831, df = 1, p_value = 0.77, type = "asymp", branch = "b1")
  expect_identical(res@branch, "b1")
  expect_identical(res$branch, "b1")
  expect_identical(res[["branch"]], "b1")
  expect_true("branch" %in% names(res))
  expect_equal(res$chisq, 0.0831)
})

test_that("the branch slot is validated", {
  mk <- function(b) MBCOResult(statistic = 1, df = 1, p_value = 0.3, type = "asymp", branch = b)
  expect_error(mk(1))
  expect_error(mk(c("a", "b")), "single")
  expect_error(mk(NA_character_), "single")
  expect_error(mk(""), "single")
})

test_that("branch and refit coexist and are validated independently", {
  ri <- list(tolerance = 1e-8, statistic_before = 0, statistic_after = 0.4745)
  res <- MBCOResult(
    statistic = 0.4745, df = 1, p_value = 0.49, type = "asymp",
    refit = ri, branch = "a"
  )
  expect_identical(res@refit, ri)
  expect_identical(res@branch, "a")
  expect_error(MBCOResult(
    statistic = 1, df = 1, p_value = 0.3, type = "asymp",
    refit = list(tolerance = 1e-8), branch = "a"
  ), "tolerance")
})

test_that("print and summary show the branch only when set", {
  plain <- MBCOResult(statistic = 4.2, df = 1, p_value = 0.04, type = "asymp")
  br <- MBCOResult(statistic = 0.0831, df = 1, p_value = 0.77, type = "asymp", branch = "b1")
  expect_false(any(grepl("branch", capture.output(print(plain)), ignore.case = TRUE)))
  expect_false(any(grepl("branch", capture.output(summary(plain)), ignore.case = TRUE)))
  expect_true(any(grepl("product null.*b1", capture.output(print(br)))))
  expect_true(any(grepl("product null.*b1", capture.output(summary(br)))))
})

# Slice 3 of tasks/plan-35.md: mbco_product_null() forwards `...` to mbco(), so the bootstrap
# types work through it; p is the maximum over the single-path branches.

src <- readLines(test_path("test-mbco-constraint-guard.R"))
eval(parse(text = src[3:39])) # .guard_med_model(), .guard_fits(): free paths "a" and "b"

.pn_collect <- function(expr) {
  seen <- character()
  value <- withCallingHandlers(expr, warning = function(w) {
    seen <<- c(seen, class(w)[1L])
    invokeRestart("muffleWarning")
  })
  list(value = value, classes = seen)
}

test_that("parametric and semi go through the helper; p equals the max over branches (same seed)", {
  skip_if_not_installed("OpenMx")
  h1 <- .guard_fits(1)$h1
  nulls <- RMediation:::.mbco_product_models(h1, c("a", "b"))
  fits <- lapply(nulls, RMediation:::.mbco_run_null)
  for (type in c("parametric", "semi")) {
    set.seed(5)
    out <- .pn_collect(mbco_product_null(h1, c("a", "b"), type = type, R = 3L))
    res <- out$value
    set.seed(5)
    manual <- lapply(fits, function(h0) suppressWarnings(mbco(h0, h1, type = type, R = 3L)))
    p <- vapply(manual, function(r) r@p_value, numeric(1))
    expect_identical(res@type, type)
    expect_equal(res@p_value, max(p), info = type)
    expect_identical(res@branch, c("a", "b")[which.max(p)], info = type)
    expect_gte(res@p_value, 0)
    expect_lte(res@p_value, 1)
    # the helper adds no constraints, so neither the guard nor the refit fires
    expect_false(any(c("RMediation_constraint_violation", "RMediation_h0_refit") %in% out$classes),
      info = type
    )
  }
})

test_that("arguments for mbco() are forwarded and invalid ones are rejected by mbco()", {
  skip_if_not_installed("OpenMx")
  h1 <- .guard_fits(1)$h1
  expect_error(mbco_product_null(h1, c("a", "b"), type = "bogus"))
  expect_error(mbco_product_null(h1, c("a", "b"), alpha = 2))
  expect_error(mbco_product_null(h1, c("a", "b"), R = -1L, type = "parametric"))
})

test_that("global OpenMx options are restored after a bootstrap run through the helper", {
  skip_if_not_installed("OpenMx")
  h1 <- .guard_fits(1)$h1
  before <- getOption("mxOptions")
  suppressWarnings(mbco_product_null(h1, c("a", "b"), type = "parametric", R = 3L))
  expect_identical(getOption("mxOptions"), before)
})

# Coverage for the lavaan branch of ci() and the empirical cdf() in
# R/external_methods.R (uncovered lines 10, 47, 57-58, 70-71, 78, 110-121,
# 135 in the 2026-11-08 covr run). Each test can fail: values are compared
# against an independently computed result or a known answer.
#
# The non-product `:=` fallback runs a Monte Carlo interval whatever `type`
# the caller asked for; it now warns when `type` was given explicitly. A `:=`
# that cannot be resolved loses only its own entry, with a warning.

.lav_fit <- function(extra = "") {
  skip_if_not_installed("lavaan")
  set.seed(1)
  n <- 300
  d <- data.frame(x = rnorm(n))
  d$m <- 0.5 * d$x + rnorm(n)
  d$y <- 0.4 * d$m + 0.2 * d$x + rnorm(n)
  lavaan::sem(
    paste0("m ~ a*x\n y ~ b*m + c*x\n ab := a*b\n", extra),
    data = d
  )
}

test_that(".parse_product_string splits products and rejects other syntax", {
  expect_identical(.parse_product_string("a*b"), c("a", "b"))
  expect_identical(.parse_product_string(" a * b * c "), c("a", "b", "c"))
  expect_null(.parse_product_string("a+b"))
  expect_null(.parse_product_string("a*(b)"))
  expect_null(.parse_product_string("a*b-c"))
})

test_that("ci() rejects non-lavaan objects with a classed message", {
  expect_error(ci(list(1)), "No method defined for class: list")
})

test_that("ci(lavaan) returns NULL with a warning when nothing is defined", {
  skip_if_not_installed("lavaan")
  set.seed(1)
  d <- data.frame(x = rnorm(60))
  d$m <- d$x + rnorm(60)
  fit <- lavaan::sem("m ~ x", data = d)
  expect_warning(
    res <- ci(fit),
    "No defined parameters"
  )
  expect_null(res)
})

test_that("ci(lavaan) alpha= and level= agree and widen the interval correctly", {
  fit <- .lav_fit()
  by_level <- ci(fit, level = 0.90, type = "dop")
  by_alpha <- ci(fit, alpha = 0.10, type = "dop")
  expect_equal(by_alpha$ab, by_level$ab)

  wide <- ci(fit, level = 0.99, type = "dop")$ab$CI
  narrow <- ci(fit, level = 0.80, type = "dop")$ab$CI
  expect_lt(diff(narrow), diff(by_level$ab$CI))
  expect_lt(diff(by_level$ab$CI), diff(wide))
})

test_that("ci(lavaan, quant =) honors an explicit alpha over level", {
  fit <- .lav_fit()
  set.seed(7)
  by_alpha <- ci(fit, quant = ~ a * b, alpha = 0.10, type = "asymp")
  set.seed(7)
  by_level <- ci(fit, quant = ~ a * b, level = 0.90, type = "asymp")
  expect_equal(by_alpha$Estimate, by_level$Estimate)
  expect_equal(unname(by_alpha[[1]]), unname(by_level[[1]]))
})

test_that("non-product `:=` uses Monte Carlo and warns when `type` was chosen", {
  fit <- .lav_fit("tot := a*b + c\n a_only := a")
  for (tp in c("dop", "asymp")) {
    set.seed(11)
    # one warning per non-product label (`tot`, `a_only`)
    pat <- sprintf("using a Monte Carlo interval instead of type = \"%s\"", tp)
    expect_warning(
      expect_warning(res <- ci(fit, type = tp, n.mc = 2000), pat),
      pat
    )
    # the product case honors `type`: no MC error
    expect_false("MCError" %in% names(res$ab))
    # non-product cases run .ci_core(type = "MC"): MC error is present
    expect_true("MCError" %in% names(res$tot))
    expect_true("MCError" %in% names(res$a_only))
    expect_length(res$tot[[1]], 2L)
  }
  # explicit type = "MC" and the untouched default stay quiet
  set.seed(11)
  expect_no_warning(ci(fit, type = "MC", n.mc = 2000))
  set.seed(11)
  expect_no_warning(ci(fit, n.mc = 2000))

  # the MC estimate is close to the plug-in value a*b + c
  est <- lavaan::parameterEstimates(fit)
  pe <- est$est[est$lhs == "tot" & est$op == ":="]
  set.seed(11)
  expect_equal(ci(fit, n.mc = 20000)$tot$Estimate, pe, tolerance = 0.02)
})

test_that("a `:=` built from another `:=` warns and keeps the other results", {
  # `ab*c` parses as a product, but `ab` is not an estimated coefficient, so
  # it reaches the Monte Carlo fallback, which cannot resolve `ab`. Only that
  # label is lost; the valid `ab` interval is still returned.
  fit <- .lav_fit("abc := ab*c")
  expect_warning(
    res <- ci(fit, n.mc = 2000),
    "No interval for defined parameter 'abc'"
  )
  expect_named(res, c("ab", "abc"))
  expect_null(res$abc)
  expect_length(res$ab$CI, 2L)
})

test_that("cdf(numeric) is the empirical CDF", {
  x <- c(1, 2, 3, 4)
  expect_equal(cdf(x, 2.5), 0.5)
  expect_equal(cdf(x, c(0, 4, 10)), c(0, 1, 1))
})

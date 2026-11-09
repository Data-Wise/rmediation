# Coverage for the lavaan branch of ci() and the empirical cdf() in
# R/external_methods.R (uncovered lines 10, 47, 57-58, 70-71, 78, 110-121,
# 135 in the 2026-11-08 covr run). Each test can fail: values are compared
# against an independently computed result or a known answer.
#
# The non-product `:=` fallback runs a Monte Carlo interval whatever `type`
# the caller asked for; it warns when `type` was given explicitly. A `:=` that
# refers to another `:=` is expanded first; products of three or more
# coefficients take Monte Carlo (the exact and asymptotic intervals exist for two
# factors only). A `:=` that cannot be resolved loses only its own entry, with a
# warning.

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

test_that("a `:=` built from another `:=` is resolved, nested equals flat for every type", {
  nested <- .lav_fit("abc := ab*c")  # ab := a*b comes first in both fits, so the
  flat <- .lav_fit("abc := a*b*c")   # random-number sequence is the same
  for (tp in c("dop", "asymp", "MC", "prodclin", "all")) {
    set.seed(5)
    rn <- suppressWarnings(ci(nested, type = tp, n.mc = 2000))
    set.seed(5)
    rf <- suppressWarnings(ci(flat, type = tp, n.mc = 2000))
    expect_false(is.null(rn$abc), info = tp)
    expect_length(rn$abc[[1]], 2L)
    expect_equal(rn$abc, rf$abc, info = tp) # same classification, same interval
  }
})

test_that("three or more factors warn when type is explicit and stay quiet otherwise", {
  fit <- .lav_fit("flat := a*b*c")
  expect_warning(
    ci(fit, type = "dop", n.mc = 2000),
    "product of 3 coefficients; using a Monte Carlo interval instead of type = \"dop\""
  )
  expect_no_warning(ci(fit, n.mc = 2000)) # default type: nothing was asked for
  expect_no_warning(ci(fit, type = "MC", n.mc = 2000))
  # a flat three-factor product no longer stops the call under dop (it did before)
  res <- suppressWarnings(ci(fit, type = "dop", n.mc = 2000))
  expect_true("MC.Error" %in% names(res$flat))
})

test_that("a nested alias of a two-factor product honors `type` like the flat product", {
  fit <- .lav_fit("alias := ab")
  for (tp in c("dop", "asymp")) {
    res <- ci(fit, type = tp)
    expect_equal(res$alias, res$ab, info = tp)
    expect_false("MC.Error" %in% names(res$alias)) # planted defect: ignoring `type` would add it
  }
})

test_that("a nested non-product resolves and uses Monte Carlo", {
  fit <- .lav_fit("tot2 := ab + c")
  set.seed(9)
  res <- suppressWarnings(ci(fit, type = "dop", n.mc = 2000))
  expect_true("MCError" %in% names(res$tot2))
  est <- lavaan::parameterEstimates(fit)
  ab <- est$est[est$lhs == "ab" & est$op == ":="]
  cc <- est$est[est$label == "c" & est$op == "~"]
  expect_equal(res$tot2$Estimate, ab + cc, tolerance = 0.05)
})

test_that("an unresolvable `:=` warns and keeps the other results", {
  fit <- .lav_fit("abc := ab*c")
  testthat::local_mocked_bindings(
    .expand_defined = function(rhs) {
      list(
        expr = list(ab = quote(a * b), abc = NULL),
        problem = c(ab = NA_character_, abc = "possibly a cycle")
      )
    }
  )
  expect_warning(
    res <- ci(fit, n.mc = 2000),
    "No interval for defined parameter 'abc'.*possibly a cycle"
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

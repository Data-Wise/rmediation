# ci() dispatches on its first argument, `object`; a call that names the estimates `mu` used to fail with
# `argument "object" is missing, with no default` (issue #179). It now says what to do.

test_that("naming the estimates mu gives a message that names the fix", {
  expect_error(
    ci(mu = c(a = .5, b = .4), Sigma = diag(c(.01, .01)), quant = ~ a * b, type = "MC"),
    "first argument.*by position"
  )
  expect_error(ci(Sigma = diag(2), quant = ~ a * b), "first argument")
})

test_that("the error is a clean message without the old wording", {
  msg <- tryCatch(ci(mu = c(a = .5, b = .4), Sigma = diag(2), quant = ~ a * b),
    error = function(e) conditionMessage(e)
  )
  expect_false(grepl("argument \"object\" is missing", msg, fixed = TRUE))
  expect_match(msg, "ci\\(c\\(a = ", fixed = FALSE)
})

test_that("the positional calls are unchanged", {
  set.seed(1)
  r <- ci(c(a = .5, b = .4), diag(c(.01, .01)), quant = ~ a * b, type = "MC", n.mc = 2000)
  expect_named(r, c("", "Estimate", "SE", "MCError", "p"))
  # `object =` by name is the generic's own argument and still works
  set.seed(1)
  r2 <- ci(object = c(a = .5, b = .4), Sigma = diag(c(.01, .01)), quant = ~ a * b, type = "MC", n.mc = 2000)
  expect_equal(r2, r)
  pn <- ProductNormal(mu = c(.5, .3), Sigma = diag(2) * .1)
  expect_named(ci(pn), c("CI", "Estimate", "SE"))
})

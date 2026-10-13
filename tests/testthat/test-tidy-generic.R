test_that("tidy() is an S3 generic that dispatches on class", {
  expect_true(is.function(tidy))
  expect_identical(class(tidy), "function")
  expect_true("UseMethod" %in% all.names(body(tidy)))
})

test_that("tidy() errors when no method exists for the object's class", {
  x <- structure(list(), class = "no_such_tidy_method")
  expect_error(tidy(x), "no applicable method")
})

test_that("tidy() dispatches to tidy.logLik and matches its documented output", {
  fit <- lm(mpg ~ wt, data = mtcars)
  logLik_fit <- logLik(fit)

  result <- tidy(logLik_fit)

  expect_s3_class(result, "data.frame")
  expect_named(result, c("term", "estimate", "df"))
  expect_equal(result$term, "logLikelihood")
  expect_equal(result$estimate, as.numeric(logLik_fit))
  expect_equal(result$df, attr(logLik_fit, "df"))
})

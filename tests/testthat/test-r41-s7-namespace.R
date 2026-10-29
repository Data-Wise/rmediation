test_that("namespace property access supports S7 and S4", {
  access <- eval(quote(function(x) {
    old <- x@value
    x@value <- old + 1
    x@value
  }), envir = asNamespace("RMediation"))
  cls <- S7::new_class("compatibility_probe", properties = list(value = S7::class_numeric))
  expect_identical(access(cls(value = 1)), 2)
  methods::setClass("compatibility_s4_probe", slots = c(value = "numeric"))
  withr::defer(methods::removeClass("compatibility_s4_probe"))
  s4 <- methods::new("compatibility_s4_probe", value = 1)
  expect_identical(access(s4), 2)
})

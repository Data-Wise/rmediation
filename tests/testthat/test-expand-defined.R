# Helpers behind ci(<lavaan>) for defined parameters (`:=`) that refer to other defined
# parameters: .expand_defined() and .product_factors() (tasks/plan-features-2026-11-08.md,
# T5 and T5b). Pure functions, no lavaan needed.

.dp <- function(e) deparse1(e)

test_that(".expand_defined substitutes a chain of definitions in dependency order", {
  r <- .expand_defined(c(abc = "ab*c", ab = "a*b"))
  expect_identical(.dp(r$expr$ab), "a * b")
  expect_identical(.dp(r$expr$abc), "a * b * c") # same product; deparse drops redundant parentheses
  expect_true(all(is.na(r$problem)))
  # a three-link chain, declared in reverse order
  r3 <- .expand_defined(c(z = "y*w", y = "x*v", x = "a*b"))
  expect_identical(.dp(r3$expr$z), "a * b * v * w")
})

test_that("substitution is by symbol, not by text", {
  # `tab` contains the label `ab`: only the symbol `ab` is replaced
  r <- .expand_defined(c(ab = "a*b", tab = "x*y", z = "tab*ab"))
  expect_identical(.dp(r$expr$z), "x * y * (a * b)")
  # a defined label that is also a function name leaves the call alone
  r2 <- .expand_defined(c(log = "p*q", w = "log(a)*log"))
  expect_identical(.dp(r2$expr$w), "log(a) * (p * q)")
})

test_that("operator precedence survives expansion", {
  r <- .expand_defined(c(s2 = "a+b", t2 = "s2*c"))
  expect_identical(.dp(r$expr$t2), "(a + b) * c")
  expect_equal(eval(r$expr$t2, list(a = 2, b = 3, c = 5)), 25) # not 2 + 3*5 = 17
})

test_that("the expanded expression has the value of the nested definition", {
  r <- .expand_defined(c(ab = "a*b", abc = "ab*c", s = "abc + ab"))
  vals <- list(a = 2, b = 3, c = 5)
  expect_equal(eval(r$expr$abc, vals), 30)
  expect_equal(eval(r$expr$s, vals), 36)
})

test_that("cycles, self-references and bad syntax are reported, not dropped", {
  r <- .expand_defined(c(x = "y+1", y = "x+1", z = "x*2", ok = "a*b"))
  expect_null(r$expr$x)
  expect_null(r$expr$y)
  expect_null(r$expr$z) # depends on an unresolvable label
  expect_match(r$problem[["x"]], "cycle")
  expect_match(r$problem[["z"]], "cannot be resolved")
  expect_identical(.dp(r$expr$ok), "a * b") # an unrelated label still resolves
  expect_named(r$expr, c("x", "y", "z", "ok"))
  self <- .expand_defined(c(x = "x*2"))
  expect_null(self$expr$x)
  bad <- .expand_defined(c(bad = "a*"))
  expect_null(bad$expr$bad)
  expect_match(bad$problem[["bad"]], "cannot parse")
})

test_that(".product_factors reads a product through * and parentheses", {
  expect_identical(.product_factors(quote(a * b)), c("a", "b"))
  expect_identical(.product_factors(quote((a * b) * c)), c("a", "b", "c"))
  expect_identical(.product_factors(quote(a * (b * c))), c("a", "b", "c"))
  expect_identical(
    .product_factors(quote((a * b) * c)), .product_factors(quote(a * b * c))
  )
  expect_identical(.product_factors(quote(a)), "a")
  expect_null(.product_factors(quote(a * b + c)))
  expect_null(.product_factors(quote(2 * a)))
  expect_null(.product_factors(quote(exp(a) * b)))
  expect_null(.product_factors(quote(-a * b)))
})

test_that(".parse_product_string behavior is unchanged", {
  expect_identical(.parse_product_string("a*b"), c("a", "b"))
  expect_null(.parse_product_string("a+b"))
})

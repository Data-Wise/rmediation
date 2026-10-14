# Plot branches of .ci_core() / confintMC() / confintAsymp(), drawn on a null pdf device.
# Assertions: the call succeeds, the returned numbers equal the plot = FALSE numbers (drawing
# must never change results), the device is left open and its margins restored, and the plot is
# actually recorded.

.mu <- c(a = 0.5, b = 0.4)
.S <- matrix(c(0.01, 0.002, 0.002, 0.02), 2)

.draw <- function(...) {
  grDevices::pdf(NULL)
  grDevices::dev.control("enable")
  on.exit(grDevices::dev.off(), add = TRUE)
  mar0 <- graphics::par("mar")
  set.seed(1)
  res <- .ci_core(.mu, .S, ~ a * b, n.mc = 2000, ..., plot = TRUE)
  expect_equal(graphics::par("mar"), mar0) # par(op) restored the margins
  list(res = res, recorded = grDevices::recordPlot())
}

.numbers <- function(res) {
  if ("MC" %in% names(res)) res <- res$MC
  unlist(res[c("Estimate", "SE")])
}

test_that("type = 'MC' plots and returns the same numbers as plot = FALSE", {
  out <- .draw(type = "MC")
  set.seed(1)
  ref <- .ci_core(.mu, .S, ~ a * b, n.mc = 2000, type = "MC", plot = FALSE)
  expect_equal(.numbers(out$res), .numbers(ref))
  expect_gt(length(out$recorded[[1]]), 0L)
})

test_that("type = 'MC' with plotCI draws the interval arrow without error", {
  expect_no_error(.draw(type = "MC", plotCI = TRUE))
})

test_that("type = 'asymp' plots and returns the same numbers as plot = FALSE", {
  out <- .draw(type = "asymp", plotCI = TRUE)
  ref <- .ci_core(.mu, .S, ~ a * b, type = "asymp", plot = FALSE)
  expect_equal(out$res$Estimate, ref$Estimate)
  expect_equal(out$res$SE, ref$SE)
  expect_gt(length(out$recorded[[1]]), 0L)
})

test_that("type = 'all' overlays asymptotic and MC and returns both", {
  out <- .draw(type = "all", plotCI = TRUE)
  expect_named(out$res, c("MC", "Asymptotic"))
  expect_equal(out$res$Asymptotic$Estimate, 0.2, tolerance = 1e-12)
})

test_that("H0 = TRUE draws the null reference distribution and reports its p value", {
  # With H0 the return is list(alternative, null); the null result carries its own p value.
  out <- .draw(type = "MC", H0 = TRUE)
  expect_length(out$res, 2L)
  expect_true(is.finite(out$res[[2]]$p))
  out0 <- .draw(type = "MC", H0 = TRUE, mu0 = c(a = 0, b = 0.4))
  expect_true(is.finite(out0$res[[2]]$p))
})

test_that("asymp with a zero-SE quantity reports it instead of plotting", {
  # d(a * b)/d(a, b) = 0 at the origin, so the delta-method SE is exactly 0
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  out <- capture.output(
    res <- .ci_core(c(a = 0, b = 0), .S, ~ a * b, type = "asymp", plot = TRUE)
  )
  expect_equal(as.numeric(res$SE), 0)
  expect_match(paste(out, collapse = " "), "SE = 0")
})

test_that("type = 'all' with a zero-SE asymptotic part notes it and still returns", {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  set.seed(1)
  out <- capture.output(
    res <- .ci_core(c(a = 0, b = 0), .S, ~ a * b, type = "all", n.mc = 2000, plot = TRUE)
  )
  expect_equal(as.numeric(res$Asymptotic$SE), 0)
  expect_match(paste(out, collapse = " "), "near zero")
})

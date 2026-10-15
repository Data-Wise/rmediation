# The plot block of medci() (R/medci.R). It draws the product distribution on a null pdf
# device. Assertions: it succeeds, the returned interval equals the plot = FALSE interval for
# the deterministic types (the plot consumes RNG draws, so MC is compared structurally), and a
# plot is actually recorded on the device.

.medci_plot <- function(..., type = "dop") {
  grDevices::pdf(NULL)
  grDevices::dev.control("enable")
  on.exit(grDevices::dev.off(), add = TRUE)
  set.seed(1)
  res <- medci(..., type = type, n.mc = 2000, plot = TRUE)
  list(res = res, recorded = grDevices::recordPlot())
}

test_that("plot = TRUE draws when the product's range straddles zero, with the same dop interval", {
  # mu.xy +/- 6 se.xy contains 0
  out <- .medci_plot(mu.x = 0.3, mu.y = 0.4, se.x = 0.1, se.y = 0.1)
  ref <- medci(0.3, 0.4, 0.1, 0.1, type = "dop", plot = FALSE)
  expect_equal(out$res, ref)
  expect_gt(length(out$recorded[[1]]), 0L)
})

test_that("plot = TRUE draws when the range lies entirely above zero (separate axis branch)", {
  # mu.xy = 12, se.xy ~ 0.6: min1 > 0
  out <- .medci_plot(mu.x = 3, mu.y = 4, se.x = 0.1, se.y = 0.1)
  ref <- medci(3, 4, 0.1, 0.1, type = "dop", plot = FALSE)
  expect_equal(out$res, ref)
  expect_gt(length(out$recorded[[1]]), 0L)
})

test_that("plot = TRUE draws when the range lies entirely below zero", {
  out <- .medci_plot(mu.x = -3, mu.y = 4, se.x = 0.1, se.y = 0.1)
  ref <- medci(-3, 4, 0.1, 0.1, type = "dop", plot = FALSE)
  expect_equal(out$res, ref)
})

test_that("plotCI = TRUE overlays the interval and still returns the same interval", {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  set.seed(1)
  # arrows(length = ) takes one value; passing par("cin") * abs(par("tcl")) (length 2) warned
  expect_no_warning(
    res <- medci(0.3, 0.4, 0.1, 0.1, type = "asymp", n.mc = 2000, plot = TRUE, plotCI = TRUE)
  )
  expect_equal(res, medci(0.3, 0.4, 0.1, 0.1, type = "asymp", plot = FALSE))
})

test_that("plot = TRUE works with a correlation and with type = 'mc' and 'all'", {
  expect_no_error(.medci_plot(0.3, 0.4, 0.1, 0.1, rho = 0.5))
  expect_no_error(.medci_plot(0.3, 0.4, 0.1, 0.1, rho = -0.5))
  mc <- .medci_plot(0.3, 0.4, 0.1, 0.1, type = "mc")
  expect_named(mc$res, c("95% CI", "Estimate", "SE", "MC.Error"))
  all <- .medci_plot(0.3, 0.4, 0.1, 0.1, type = "all")
  expect_named(all$res, c("Distribution of Product", "Monte Carlo", "Asymptotic Normal"))
})

test_that("the dop estimate with a correlation is mu.x * mu.y + rho * se.x * se.y", {
  res <- medci(0.3, 0.4, 0.1, 0.1, rho = 0.5, type = "dop")
  expect_equal(unname(res$Estimate), 0.3 * 0.4 + 0.5 * 0.1 * 0.1)
})

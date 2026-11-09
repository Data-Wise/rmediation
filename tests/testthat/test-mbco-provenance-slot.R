# Slice T1 of tasks/plan-features-2026-11-08.md: MBCOResult gets an optional `provenance`
# property (what produced the result). NULL means nothing was recorded. The seed is never
# recorded (it cannot be recovered after the fact).

.prov <- function(...) {
  base <- list(
    rmediation = "1.9.0", openmx = "2.21.8", medfit = NULL, r = "4.6.2",
    type = "asymp", R = NULL, rng_kind = c("Mersenne-Twister", "Inversion", "Rejection"),
    time = "2026-11-08 19:50:00 MST"
  )
  utils::modifyList(base, list(...), keep.null = TRUE)
}
.mk <- function(pv) {
  MBCOResult(statistic = 1, df = 1, p_value = 0.3, type = "asymp", provenance = pv)
}

test_that("an MBCOResult built the old way has provenance NULL", {
  res <- MBCOResult(statistic = 4.2, df = 1, p_value = 0.04, type = "asymp")
  expect_null(res@provenance)
  expect_null(res$provenance)
  expect_null(res[["provenance"]])
})

test_that("names() keeps the nine existing names in order and appends provenance last", {
  res <- MBCOResult(statistic = 4.2, df = 1, p_value = 0.04, type = "asymp")
  old_nine <- c(
    "chisq", "p", "statistic", "df", "p_value", "type", "refit", "branch", "dropped"
  )
  expect_identical(names(res)[1:9], old_nine)
  expect_identical(names(res)[10], "provenance")
  expect_length(names(res), 10L)
})

test_that("provenance round-trips and is exposed by @, $ and [[", {
  pv <- .prov()
  res <- .mk(pv)
  expect_identical(res@provenance, pv)
  expect_identical(res$provenance, pv)
  expect_identical(res[["provenance"]], pv)
  expect_null(res@provenance$medfit)
})

test_that("provenance coexists with refit, branch and dropped", {
  ri <- list(tolerance = 1e-8, statistic_before = 0, statistic_after = 0.4745)
  res <- MBCOResult(
    statistic = 0.4745, df = 1, p_value = 0.49, type = "asymp",
    refit = ri, branch = "a", dropped = 2L, provenance = .prov()
  )
  expect_identical(res@refit, ri)
  expect_identical(res@branch, "a")
  expect_identical(res@dropped, 2L)
  expect_identical(res@provenance$type, "asymp")
})

test_that("a malformed provenance list is rejected and names the problem", {
  expect_error(.mk(list(rmediation = "1.9.0")), "named exactly")
  expect_error(.mk(c(.prov(), extra = 1)), "named exactly")
  expect_error(.mk(.prov(rmediation = "")), "rmediation")
  expect_error(.mk(.prov(r = NA_character_)), "\\$r")
  expect_error(.mk(.prov(openmx = 2)), "openmx")
  expect_error(.mk(.prov(R = 1.5)), "\\$R")
  expect_error(.mk(.prov(R = -1)), "\\$R")
  expect_error(.mk(.prov(rng_kind = NA_character_)), "rng_kind")
  expect_error(.mk("not a list"))
})

test_that("valid optional entries pass", {
  expect_no_error(.mk(.prov(R = 999L)))
  expect_no_error(.mk(.prov(openmx = NULL)))
  expect_no_error(.mk(.prov(medfit = "0.16.0")))
})

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

# ---- T2: mbco() fills provenance ---------------------------------------------------------

test_that(".mbco_provenance records recoverable facts and never invents a version", {
  pv <- .mbco_provenance("asymp")
  expect_identical(pv$rmediation, as.character(utils::packageVersion("RMediation")))
  expect_identical(pv$r, as.character(getRversion()))
  expect_identical(pv$type, "asymp")
  expect_null(pv$R)
  expect_identical(pv$rng_kind, RNGkind())
  expect_match(pv$time, "^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2} ")
  # a package that is not loaded is NULL, not "" or "unknown"
  expect_identical(
    pv$openmx,
    if (isNamespaceLoaded("OpenMx")) as.character(utils::packageVersion("OpenMx")) else NULL
  )
  expect_identical(.mbco_provenance("semi", R = 40)$R, 40L)
  # the seed is deliberately absent
  expect_false(any(grepl("seed", names(pv), ignore.case = TRUE)))
})

test_that("mbco(type = 'asymp') on OpenMx fits records provenance and leaves the test values alone", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("mvtnorm")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  res <- mbco(f$null_b1, f$full, type = "asymp")
  expect_s7_class(res, MBCOResult)
  pv <- res@provenance
  expect_identical(pv$type, "asymp")
  expect_null(pv$R)
  expect_identical(pv$openmx, as.character(utils::packageVersion("OpenMx")))
  expect_identical(pv$rmediation, as.character(utils::packageVersion("RMediation")))
  # provenance is metadata only: the statistic is the OpenMx LRT
  obs <- .mbco_compare(f$null_b1, f$full)$diffLL[2]
  expect_equal(res@statistic, obs)
})

test_that("a bootstrap mbco() records its type and R", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("mvtnorm")
  f <- .memory_exp_oracle()
  saved <- getOption("mxOptions")
  on.exit(options(mxOptions = saved), add = TRUE)
  obs <- .mbco_compare(f$null_b1, f$full)$diffLL[2]
  # every replicate converges; the statistic alternates around the observed one
  mock <- function(h0, h1, data, x) if (x %% 2L == 1L) obs - 1 else obs + 1
  testthat::local_mocked_bindings(.mbco_replicate_statistic = mock)
  res <- mbco(f$null_b1, f$full, type = "parametric", R = 40L, optim = "SLSQP")
  expect_identical(res@provenance$type, "parametric")
  expect_identical(res@provenance$R, 40L)
})

test_that("the SEMFit route records provenance with medfit loaded", {
  skip_if_not_installed("medfit")
  skip_if(utils::packageVersion("medfit") < "0.8.0", "SEMFit route needs medfit >= 0.8.0")
  fits <- .semfit_mbco_fits()
  res <- mbco(fits$b1, fits$full, type = "asymp")
  pv <- res@provenance
  expect_identical(pv$type, "asymp")
  expect_null(pv$R)
  expect_identical(pv$medfit, as.character(utils::packageVersion("medfit")))
})

# ---- T3: print and summary show provenance ----------------------------------------------

test_that("print and summary show a trailing provenance block only when set", {
  plain <- MBCOResult(statistic = 4.2, df = 1, p_value = 0.04, type = "asymp")
  with_pv <- MBCOResult(
    statistic = 4.2, df = 1, p_value = 0.04, type = "semi", provenance = .prov(R = 40L, type = "semi")
  )
  p0 <- capture.output(print(plain))
  p1 <- capture.output(print(with_pv))
  expect_false(any(grepl("Provenance", p0)))
  # the provenance block is appended: every earlier line of a result without it is a prefix
  # of the same result printed with it (type differs, so compare on a matching type)
  with_pv_same <- MBCOResult(
    statistic = 4.2, df = 1, p_value = 0.04, type = "asymp", provenance = .prov()
  )
  p2 <- capture.output(print(with_pv_same))
  expect_identical(p2[seq_along(p0)], p0)
  expect_true(any(grepl("^Provenance:", p2)))
  expect_true(any(grepl("RMediation 1.9.0, OpenMx 2.21.8, R 4.6.2", p2, fixed = TRUE)))
  expect_true(any(grepl("type = semi, R = 40", p1, fixed = TRUE)))
  expect_true(any(grepl("Seed: not recorded", p2)))
  s0 <- capture.output(summary(plain))
  s2 <- capture.output(summary(with_pv_same))
  expect_false(any(grepl("Provenance", s0)))
  expect_identical(s2[seq_along(s0)], s0)
  expect_true(any(grepl("^Provenance:", s2)))
})

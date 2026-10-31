# Verification harness for issue #84 (not part of the package check; `^scripts$` is Rbuildignored).
# Runs the known-answer and the planted-defect checks for every optimizer available locally and
# prints the OpenMx and RMediation versions, the optimizer, the statistic and the warning classes.
# Known answer: seed 20261103, dataset 1 of the script in OpenMx/OpenMx#433 (x -> m1 -> y, labels
# b1 and b2, ind == 0, all starts 0). Exit status 1 when any check fails.
#
# Run from the package root:  Rscript scripts/verify-constraint-dropped.R

suppressMessages({
  library(OpenMx)
  pkgload::load_all(".", quiet = TRUE)
})
mxOption(NULL, "Standard Errors", "No")

fit_pair <- function(optimizer) {
  mxOption(NULL, "Default optimizer", optimizer)
  set.seed(20261103)
  d <- data.frame(x = rnorm(100), m1 = rnorm(100), y = rnorm(100))
  man <- c("x", "m1", "y")
  base <- mxModel("c",
    type = "RAM", manifestVars = man,
    mxPath("one", man, free = TRUE, values = 0),
    mxPath("x", "m1", free = TRUE, values = 0, labels = "b1"),
    mxPath("m1", "y", free = TRUE, values = 0, labels = "b2"),
    mxPath(man, arrows = 2, free = TRUE, values = 1),
    mxData(d, type = "raw")
  )
  run <- function(m) suppressWarnings(mxRun(m, silent = TRUE))
  h1 <- run(base)
  h0 <- run(mxModel(base,
    name = "h0",
    mxAlgebra(b1 * b2, name = "ind"), mxConstraint(ind == 0, name = "ind0")
  ))
  list(h1 = h1, h0 = h0)
}

collect <- function(expr) {
  classes <- character()
  value <- withCallingHandlers(expr, warning = function(w) {
    classes <<- c(classes, class(w)[1L])
    invokeRestart("muffleWarning")
  })
  list(value = value, classes = classes)
}

m2ll <- function(m) as.numeric(m$output$Minus2LogLikelihood)
ok_all <- TRUE
check <- function(label, ok) {
  cat(sprintf("  [%s] %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) ok_all <<- FALSE
}

cat("OpenMx", as.character(packageVersion("OpenMx")), "| RMediation",
    as.character(packageVersion("RMediation")), "(working tree)\n")
cat("Input: set.seed(20261103); data.frame(x = rnorm(100), m1 = rnorm(100), y = rnorm(100))\n")
cat("Model: x -> m1 -> y, labels b1 and b2, constraint ind == 0 with ind = b1 * b2, all starts 0\n")

optimizers <- c(if (imxHasNPSOL()) "NPSOL", "CSOLNP", "SLSQP")
for (opt in optimizers) {
  cat("\n== optimizer:", opt, "==\n")
  f <- fit_pair(opt)
  cat(sprintf("h0 fit: -2LL %.4f, h1 fit: -2LL %.4f, b1*b2 at h0 = %.5f\n",
              m2ll(f$h0), m2ll(f$h1), prod(omxGetParameters(f$h0)[c("b1", "b2")])))
  if (abs(m2ll(f$h0) - m2ll(f$h1)) > 1e-6) {
    cat("  SKIP: this optimizer enforced the constraint at the zero start (no #433 behavior)\n")
    next
  }
  out <- collect(mbco(f$h0, f$h1))
  cat("mbco(h0, h1): statistic", format(round(out$value@statistic, 4)),
      "| statistic_before", format(round(out$value@refit$statistic_before, 4)), "\n")
  cat("warning classes:", paste(out$classes, collapse = ", "), "\n")
  pn <- mbco_product_null(f$h1, c("b1", "b2"))
  cat("mbco_product_null(h1, c('b1','b2')): statistic", format(round(pn@statistic, 4)),
      "| branch", pn@branch, "\n")
  check("RMediation_constraint_dropped raised after RMediation_h0_refit",
        identical(out$classes[1:2], c("RMediation_h0_refit", "RMediation_constraint_dropped")))
  check("repaired statistic equals mbco_product_null() within 1e-4",
        abs(out$value@statistic - pn@statistic) < 1e-4)
  check("repaired statistic is 0.0878 within 1e-3 (pinned, OpenMx 2.22.11)",
        abs(out$value@statistic - 0.0878) < 1e-3)

  planted <- testthat::with_mocked_bindings(
    collect(mbco(f$h0, f$h1)),
    .mbco_report_dropped = function(refit) invisible(NULL),
    .package = "RMediation"
  )
  cat("planted defect (check removed): warning classes:",
      paste(planted$classes, collapse = ", "), "\n")
  check("planted defect: the class is absent, so the known-answer check above would fail",
        !"RMediation_constraint_dropped" %in% planted$classes)
}

cat("\n", if (ok_all) "ALL CHECKS PASSED" else "SOME CHECKS FAILED", "\n", sep = "")
quit(status = if (ok_all) 0L else 1L)

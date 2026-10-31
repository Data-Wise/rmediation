# Installed-package gate; run from the repository root.
# Usage: Rscript scripts/check-openmx-load.R LIB ORDER
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L, args[2] %in% c("RMediation", "OpenMx"))
.libPaths(c(args[1], .libPaths()))
loadNamespace(args[2])
loadNamespace(setdiff(c("RMediation", "OpenMx"), args[2]))
source("tests/testthat/helper-memory-exp-ram.R")
f <- .memory_exp_oracle()
saved <- getOption("mxOptions")
for (type in c("asymp", "parametric", "semi")) {
  set.seed(484)
  result <- RMediation::mbco(f$null_b1, f$full,
    type = type, R = 1L, optim = "SLSQP"
  )
  stopifnot(
    abs(result@statistic - .083100) < 1e-6, result@df == 1,
    is.finite(result@p_value), result@p_value >= 0, result@p_value <= 1,
    identical(getOption("mxOptions"), saved)
  )
  if (type == "asymp") {
    expected_p <- stats::pchisq(result@statistic, 1, lower.tail = FALSE)
    stopifnot(abs(result@p_value - expected_p) < 1e-12)
  }
  for (h1 in list(f$full, f$null_b1)) {
    set.seed(485)
    seed <- .Random.seed
    msg <- tryCatch({
      suppressWarnings(RMediation::mbco(f$full, h1,
        type = type, R = 1L, optim = "SLSQP"
      ))
      "NO ERROR"
    }, error = conditionMessage)
    stopifnot(
      grepl("h0 must be more restricted than h1", msg, fixed = TRUE),
      identical(.Random.seed, seed), identical(getOption("mxOptions"), saved)
    )
  }
}
cat("PASS installed OpenMx load first:", args[2], "\n")

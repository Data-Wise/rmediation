# Installed-package gate in a fresh process with a controlled library.
# Usage: Rscript scripts/check-semfit-load.R LIB MODE ORDER
# MODE: none, old, new; ORDER: RMediation, medfit. LIB excludes OpenMx.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(
  length(args) == 3L, args[2] %in% c("none", "old", "new"),
  args[3] %in% c("RMediation", "medfit")
)
.libPaths(args[1], include.site = FALSE)
stopifnot(!requireNamespace("OpenMx", quietly = TRUE))
if (args[3] == "medfit" && args[2] != "none") loadNamespace("medfit")
loadNamespace("RMediation")
if (args[2] == "none") {
  stopifnot(!requireNamespace("medfit", quietly = TRUE))
  stopifnot(length(RMediation::ci(RMediation::ProductNormal(
    mu = c(.5, .3), Sigma = diag(2) * .1
  ))) > 0L)
} else {
  version <- utils::packageVersion("medfit")
  stopifnot(if (args[2] == "new") version >= "0.8.0" else version < "0.8.0")
  d <- as.data.frame(RMediation::memory_exp)
  d$x <- as.numeric(d$x) - 1
  obj <- medfit::fit_mediation(recall ~ x + repetition, repetition ~ x,
    data = d, treatment = "x", mediator = "repetition"
  )
  stopifnot(length(RMediation::ci(obj, type = "asymp")) > 0L)
  if ("SEMFit" %in% getNamespaceExports("medfit")) {
    syntax <- paste("repetition ~ a1*x", "imagery ~ a2*x",
      "recall ~ cp*x + b1*repetition + b2*imagery",
      sep = "\n"
    )
    full <- medfit::fit_sem(syntax, d)
    null <- medfit::fit_sem(paste(syntax, "b1 == 0", sep = "\n"), d)
    if (args[2] == "new") {
      result <- RMediation::mbco(null, full)
      stopifnot(
        abs(result@statistic - 0.083100) < 1e-6, result@df == 1,
        result@type == "asymp"
      )
    } else {
      msg <- tryCatch(
        {
          RMediation::mbco(null, full)
          "NO ERROR"
        },
        error = conditionMessage
      )
      stopifnot(grepl("requires medfit >= 0.8.0", msg, fixed = TRUE))
    }
  }
}
cat(
  "PASS installed load gate:",
  args[2], "load first:", args[3], "without OpenMx\n"
)

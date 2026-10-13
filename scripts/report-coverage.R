# Usage: Rscript scripts/report-coverage.R OUTPUT_DIR [COVERAGE_RDS]
# A saved covr object avoids rerunning the suite when formatting a report.
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) %in% 1:2)
if (!requireNamespace("covr", quietly = TRUE)) stop("covr is required")
out <- args[1]
dir.create(out, recursive = TRUE, showWarnings = FALSE)
cov <- if (length(args) == 2L) readRDS(args[2]) else covr::package_coverage()
saveRDS(cov, file.path(out, "coverage.rds"))
lines <- covr::tally_coverage(cov, by = "line")
expressions <- covr::tally_coverage(cov, by = "expression")
summary <- function(x) {
  result <- aggregate(
    cbind(covered = as.integer(x$value > 0), total = rep(1L, nrow(x))),
    list(file = x$filename), sum
  )
  result$percent <- 100 * result$covered / result$total
  result[order(result$percent, result$file), ]
}
utils::write.csv(summary(lines), file.path(out, "lines.csv"), row.names = FALSE)
utils::write.csv(summary(expressions), file.path(out, "expressions.csv"),
  row.names = FALSE
)
utils::write.csv(lines[lines$value == 0, ],
  file.path(out, "uncovered-lines.csv"),
  row.names = FALSE
)
versions <- vapply(c("covr", "medfit", "OpenMx", "testthat"), function(pkg) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    as.character(utils::packageVersion(pkg))
  } else {
    "absent"
  }
}, character(1))
sha <- system2("git", c("rev-parse", "HEAD"), stdout = TRUE)
dirty <- length(system2("git", c("status", "--porcelain"), stdout = TRUE)) > 0L
writeLines(c(
  paste("Commit:", sha), paste("R:", getRversion()),
  paste("Working tree dirty:", dirty),
  paste(names(versions), versions, sep = ": "),
  paste("Line coverage:", covr::percent_coverage(cov)),
  paste("Expression coverage:", covr::percent_coverage(cov, by = "expression")),
  if (length(args) == 2L) {
    paste(
      "Saved object:", normalizePath(args[2]),
      "(report environment only; verify original measurement provenance)"
    )
  } else {
    "Fresh measurement at reported commit/environment"
  }
), file.path(out, "metadata.txt"))
cat("Line coverage:", covr::percent_coverage(cov), "\n")

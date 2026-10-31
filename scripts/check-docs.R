# Docs-currency check: regenerate the roxygen output (Rd and NAMESPACE) in a throwaway copy of the package and fail
# when the committed `man/` or `NAMESPACE` differs from what the roxygen comments in `R/` generate. Nothing in the
# working tree is written. Exit status 1 on stale docs or when roxygen cannot run (a check that ran nothing fails).
#
# Compared exactly: every file under man/. Compared as a sorted set of non-blank lines: NAMESPACE (roxygen versions
# reorder lines, e.g. a conditional importFrom). Ignored: DESCRIPTION, so a roxygen version bump is not a failure.
#
# Run from the package root:  Rscript scripts/check-docs.R [package_root]

args <- commandArgs(trailingOnly = TRUE)
root <- normalizePath(if (length(args)) args[[1L]] else ".", mustWork = TRUE)
if (!file.exists(file.path(root, "DESCRIPTION"))) stop("no DESCRIPTION in ", root)

work <- tempfile("check-docs-")
dir.create(work)
on.exit(unlink(work, recursive = TRUE), add = TRUE)
copy <- file.path(work, "pkg")
dir.create(copy)
for (f in setdiff(list.files(root, all.files = TRUE, no.. = TRUE), c(".git", ".worktrees"))) {
  file.copy(file.path(root, f), copy, recursive = TRUE)
}

res <- tryCatch(
  suppressMessages(roxygen2::roxygenise(copy, roclets = c("rd", "namespace"))),
  error = function(e) e
)
if (inherits(res, "error")) {
  cat("[FAIL] roxygen could not run: ", conditionMessage(res), "\n", sep = "")
  quit(status = 1L)
}

problems <- character()

rd <- function(dir) sort(list.files(file.path(dir, "man"), recursive = TRUE))
before <- rd(root)
after <- rd(copy)
if (length(before) == 0L) problems <- c(problems, "man/ is empty or missing: nothing to compare")
for (f in setdiff(after, before)) problems <- c(problems, sprintf("man/%s would be created (missing from the repo)", f))
for (f in setdiff(before, after)) problems <- c(problems, sprintf("man/%s is stale (roxygen no longer generates it)", f))
for (f in intersect(before, after)) {
  a <- readLines(file.path(root, "man", f), warn = FALSE)
  b <- readLines(file.path(copy, "man", f), warn = FALSE)
  if (!identical(a, b)) problems <- c(problems, sprintf("man/%s differs from the roxygen output", f))
}

ns <- function(dir) {
  x <- readLines(file.path(dir, "NAMESPACE"), warn = FALSE)
  sort(unique(x[nzchar(trimws(x))]))
}
if (!identical(ns(root), ns(copy))) {
  only_repo <- setdiff(ns(root), ns(copy))
  only_gen <- setdiff(ns(copy), ns(root))
  problems <- c(problems, sprintf(
    "NAMESPACE differs from the roxygen output (repo only: %d line(s), generated only: %d line(s))",
    length(only_repo), length(only_gen)
  ))
}

cat(sprintf("Docs currency: %d Rd file(s) compared, roxygen2 %s\n", length(before), as.character(utils::packageVersion("roxygen2"))))
if (length(problems)) {
  cat(paste0("  [FAIL] ", problems, "\n"), sep = "")
  cat("Docs currency: STALE (run devtools::document() and commit man/ and NAMESPACE, not the DESCRIPTION version bump)\n")
  quit(status = 1L)
}
cat("  [PASS] man/ and NAMESPACE match the roxygen output\n")
cat("Docs currency: CURRENT\n")

# CI policy check: expensive GitHub workflows run for `main` and releases only; PRs to and pushes to `dev` start
# none of them (the local gate is scripts/check-local.sh). Exit status 1 on any violation.
#
# Run from the package root:  Rscript scripts/check-ci-policy.R
# Needs the `yaml` package. A missing workflow file or a workflow with no `on:` block is a violation, not a skip.

expensive <- c("R-CMD-check.yaml", "semfit-mbco.yaml", "test-coverage.yaml", "pkgdown.yaml")
required_context <- "ubuntu-latest (release)" # the required status check on `main`

violations <- character()
bad <- function(msg) violations <<- c(violations, msg)

triggers <- function(file) {
  d <- yaml::read_yaml(file.path(".github/workflows", file))
  on <- d[["on"]]
  if (is.null(on)) on <- d[["TRUE"]] # YAML 1.1 reads a bare `on:` key as TRUE
  if (is.null(on)) stop(file, ": no `on:` block")
  on
}
branches <- function(on, event) as.character(unlist(on[[event]]$branches))

for (f in expensive) {
  if (!file.exists(file.path(".github/workflows", f))) {
    bad(sprintf("%s: workflow file is missing", f))
    next
  }
  on <- triggers(f)
  for (event in c("push", "pull_request")) {
    if ("dev" %in% branches(on, event)) {
      bad(sprintf("%s: `%s` triggers on dev; expensive checks run for main and releases only", f, event))
    }
  }
  if (!"workflow_dispatch" %in% names(on)) {
    bad(sprintf("%s: no workflow_dispatch escape hatch", f))
  }
}

# `main` requires one status check; its trigger must survive, or main becomes unmergeable.
if ("R-CMD-check.yaml" %in% expensive && file.exists(".github/workflows/R-CMD-check.yaml")) {
  on <- triggers("R-CMD-check.yaml")
  if (!"main" %in% branches(on, "pull_request")) {
    bad("R-CMD-check.yaml: no pull_request trigger on main (required check would never start)")
  }
  wf <- yaml::read_yaml(".github/workflows/R-CMD-check.yaml")
  cfg <- wf$jobs[[1]]$strategy$matrix$config
  has_leg <- any(vapply(cfg, function(x) identical(x$os, "ubuntu-latest") && identical(as.character(x$r), "release"), NA))
  if (!has_leg) bad(sprintf("R-CMD-check.yaml: no matrix leg produces the required context '%s'", required_context))
}

cat(sprintf("CI policy: %d workflow(s) checked\n", length(expensive)))
if (length(violations)) {
  cat(paste0("  [FAIL] ", violations, "\n"), sep = "")
  cat("CI policy: FAILED\n")
  quit(status = 1L)
}
cat("  [PASS] no expensive workflow triggers on dev; main's required check still starts\n")
cat("CI policy: PASSED\n")

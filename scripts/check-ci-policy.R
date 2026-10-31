# CI policy check: expensive GitHub workflows run for `main` and releases only; PRs to and pushes to `dev` start
# none of them (the local gate is scripts/check-local.sh). Exit status 1 on any violation.
#
# Run from the package root:  Rscript scripts/check-ci-policy.R
# Needs the `yaml` package. A missing workflow file or a workflow with no `on:` block is a violation, not a skip.

expensive <- c("R-CMD-check.yaml", "semfit-mbco.yaml", "test-coverage.yaml", "pkgdown.yaml")
required_context <- "ubuntu-latest (release)" # the required status check on `main`

`%||%` <- function(a, b) if (is.null(a)) b else a

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

  # The R-devel leg installs hard dependencies only and runs with _R_CHECK_DEPENDS_ONLY_=true, so an unguarded
  # use of a Suggests package in an example or test fails there. The job env must read the per-leg value.
  dep <- function(x) if (is.null(x[["depends-only"]])) NA_character_ else as.character(x[["depends-only"]])
  devel <- Filter(function(x) identical(as.character(x$r), "devel"), cfg)
  if (!length(devel)) {
    bad("R-CMD-check.yaml: no R-devel leg to run the depends-only check on")
  } else if (!all(vapply(devel, function(x) identical(dep(x), "true"), NA))) {
    bad("R-CMD-check.yaml: the R-devel leg must set depends-only: 'true'")
  }
  if (!all(vapply(cfg, function(x) dep(x) %in% c("true", "false"), NA))) {
    bad("R-CMD-check.yaml: every matrix leg must set depends-only to 'true' or 'false'")
  }
  if (!identical(wf$jobs[[1]]$env[["_R_CHECK_DEPENDS_ONLY_"]], "${{ matrix.config.depends-only }}")) {
    bad("R-CMD-check.yaml: job env _R_CHECK_DEPENDS_ONLY_ must be ${{ matrix.config.depends-only }}")
  }

  # The issue #84 gate (scripts/verify-constraint-not-enforced.R) runs as one step of the Ubuntu release leg: it
  # needs OpenMx, so a missing OpenMx fails the job; it takes about 2 s; it has no path filter (a filter that
  # misses a file would skip it silently) and no continue-on-error (a failing gate must fail the job).
  steps <- wf$jobs[[1]]$steps
  is_gate <- vapply(steps, function(x) grepl("verify-constraint-not-enforced.R", x$run %||% "", fixed = TRUE), NA)
  if (sum(is_gate) != 1L) {
    bad(sprintf("R-CMD-check.yaml: expected exactly one step running the issue #84 gate, found %d", sum(is_gate)))
  } else {
    gate <- steps[is_gate][[1]]
    cond <- gate[["if"]] %||% ""
    if (!(grepl("ubuntu-latest", cond, fixed = TRUE) && grepl("release", cond, fixed = TRUE))) {
      bad("R-CMD-check.yaml: the issue #84 gate step must be limited to the ubuntu-latest release leg")
    }
    if (isTRUE(gate[["continue-on-error"]]) || identical(gate[["continue-on-error"]], "true")) {
      bad("R-CMD-check.yaml: the issue #84 gate step must not set continue-on-error")
    }
  }
  for (event in names(on)) {
    if (is.list(on[[event]]) && any(c("paths", "paths-ignore") %in% names(on[[event]]))) {
      bad(sprintf("R-CMD-check.yaml: `%s` has a paths filter, which could skip the issue #84 gate silently", event))
    }
  }
}

# The one cheap exception on PRs to dev: the risk-tier check. It stays cheap only while it needs no R install and
# a short timeout, and it needs its script and its risk-file list.
rt <- ".github/workflows/risk-tier.yaml"
if (!file.exists(rt)) {
  bad("risk-tier.yaml: workflow file is missing")
} else {
  rwf <- yaml::read_yaml(rt)
  rjob <- rwf$jobs[[1]]
  uses <- vapply(rjob$steps, function(x) as.character(x$uses %||% ""), "")
  if (any(grepl("r-lib/actions", uses, fixed = TRUE))) bad("risk-tier.yaml: must not install R (r-lib/actions); it has to stay cheap")
  if (is.null(rjob[["timeout-minutes"]]) || as.numeric(rjob[["timeout-minutes"]]) > 10) {
    bad("risk-tier.yaml: timeout-minutes must be set and at most 10")
  }
  runs <- paste(vapply(rjob$steps, function(x) as.character(x$run %||% ""), ""), collapse = "\n")
  if (!grepl("scripts/risk_tier.py", runs, fixed = TRUE)) bad("risk-tier.yaml: no step runs scripts/risk_tier.py")
  rbr <- as.character(unlist((rwf[["on"]] %||% rwf[["TRUE"]])$pull_request$branches))
  if (!all(c("dev", "main") %in% rbr)) bad("risk-tier.yaml: must run on pull requests to dev and main")
}
for (f in c("scripts/risk_tier.py", ".github/risk-files.txt")) {
  if (!file.exists(f)) bad(sprintf("%s is missing (risk-tier needs it)", f))
}
if (file.exists(".github/risk-files.txt")) {
  globs <- trimws(readLines(".github/risk-files.txt", warn = FALSE))
  if (!length(globs[nzchar(globs) & !startsWith(globs, "#")])) bad(".github/risk-files.txt lists no risk files")
}

cat(sprintf("CI policy: %d workflow(s) checked\n", length(expensive)))
if (length(violations)) {
  cat(paste0("  [FAIL] ", violations, "\n"), sep = "")
  cat("CI policy: FAILED\n")
  quit(status = 1L)
}
cat("  [PASS] no expensive workflow triggers on dev; main's required check still starts; the R-devel leg runs depends-only; the issue #84 gate step is in place; risk-tier stays cheap\n")
cat("CI policy: PASSED\n")

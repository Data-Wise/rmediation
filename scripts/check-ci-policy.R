# CI policy check: expensive GitHub workflows run for `main` and releases only; PRs to and pushes to `dev` start
# none of them (the local gate is scripts/check-local.sh). Exit status 1 on any violation.
#
# Run from the package root:  Rscript scripts/check-ci-policy.R
# Needs the `yaml` package. A missing workflow file or a workflow with no `on:` block is a violation, not a skip.

expensive <- c("R-CMD-check.yaml", "semfit-mbco.yaml", "test-coverage.yaml", "pkgdown.yaml")
required_context <- "ubuntu-latest (release)" # the required status check on `main`
max_timeout <- 60L # minutes; slowest observed leg is about 8 minutes of wall time

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
  # A hung leg (an OpenMx source build, a stuck download) otherwise runs to GitHub's 6-hour default.
  wf_all <- yaml::read_yaml(file.path(".github/workflows", f))
  for (jn in names(wf_all$jobs)) {
    tm <- suppressWarnings(as.numeric(wf_all$jobs[[jn]][["timeout-minutes"]]))
    if (length(tm) == 0L || is.na(tm) || tm > max_timeout) {
      bad(sprintf("%s: job `%s` needs timeout-minutes of at most %d", f, jn, max_timeout))
    }
  }
}

# Workflows that run on PRs to main cancel superseded PR runs, but never a push or dispatch run: the post-merge
# push to main is the run that is verified before tagging. So `cancel-in-progress` must be an expression that is
# true only for pull_request events, not the literal `true`.
for (f in c("R-CMD-check.yaml", "semfit-mbco.yaml")) {
  if (!file.exists(file.path(".github/workflows", f))) next
  cc <- yaml::read_yaml(file.path(".github/workflows", f))$concurrency
  cip <- if (is.list(cc)) as.character(cc[["cancel-in-progress"]] %||% "") else ""
  if (!is.list(cc) || is.null(cc$group)) {
    bad(sprintf("%s: no top-level concurrency group (superseded PR runs keep running)", f))
  } else if (!grepl("pull_request", cip, fixed = TRUE)) {
    bad(sprintf("%s: concurrency cancel-in-progress must be limited to pull_request events (got '%s')", f, cip))
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

  # The issue #84 gate must NOT be a step here: a failing step fails the job, and this job's check
  # (`ubuntu-latest (release)`) is the one `main` requires, so a gate step would block the release on an
  # OpenMx behavior change. It lives in its own non-required workflow (issue-84-gate.yaml), checked below.
  steps <- wf$jobs[[1]]$steps
  if (any(vapply(steps, function(x) grepl("verify-constraint-not-enforced.R", x$run %||% "", fixed = TRUE), NA))) {
    bad("R-CMD-check.yaml: the issue #84 gate must not be a step of the required job; use issue-84-gate.yaml")
  }
}

# The issue #84 gate: its own workflow and job, so a red gate is visible but never the required check. It runs for
# main and releases only (and on dispatch), with no path filter and no continue-on-error, and it needs OpenMx.
gf <- ".github/workflows/issue-84-gate.yaml"
if (!file.exists(gf)) {
  bad("issue-84-gate.yaml: workflow file is missing")
} else {
  gwf <- yaml::read_yaml(gf)
  gon <- gwf[["on"]] %||% gwf[["TRUE"]]
  for (event in c("push", "pull_request")) {
    br <- branches(gon, event)
    if ("dev" %in% br) bad(sprintf("issue-84-gate.yaml: `%s` must not run on dev", event))
    if (!"main" %in% br) bad(sprintf("issue-84-gate.yaml: `%s` must run on main", event))
  }
  if (!"workflow_dispatch" %in% names(gon)) bad("issue-84-gate.yaml: needs workflow_dispatch")
  for (event in names(gon)) {
    if (is.list(gon[[event]]) && any(c("paths", "paths-ignore") %in% names(gon[[event]]))) {
      bad(sprintf("issue-84-gate.yaml: `%s` has a paths filter, which could skip the gate silently", event))
    }
  }
  gjob <- gwf$jobs[[1]]
  jname <- as.character(gjob$name %||% names(gwf$jobs)[1])
  if (identical(jname, required_context) || grepl(required_context, jname, fixed = TRUE)) {
    bad("issue-84-gate.yaml: the job name must differ from main's required check")
  }
  gruns <- vapply(gjob$steps, function(x) as.character(x$run %||% ""), "")
  gate_idx <- grep("verify-constraint-not-enforced.R", gruns, fixed = TRUE)
  if (length(gate_idx) != 1L) {
    bad(sprintf("issue-84-gate.yaml: expected exactly one step running the gate, found %d", length(gate_idx)))
  } else {
    g <- gjob$steps[[gate_idx]]
    if (isTRUE(g[["continue-on-error"]]) || identical(g[["continue-on-error"]], "true") ||
        isTRUE(gjob[["continue-on-error"]]) || identical(gjob[["continue-on-error"]], "true")) {
      bad("issue-84-gate.yaml: the gate must not set continue-on-error")
    }
    if (!is.null(g[["if"]])) bad("issue-84-gate.yaml: the gate step must be unconditional")
  }
  if (!any(grepl("OpenMx", vapply(gjob$steps, function(x) paste(unlist(x$with), collapse = " "), ""), fixed = TRUE))) {
    bad("issue-84-gate.yaml: OpenMx must be installed explicitly (a missing OpenMx must fail the job)")
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
cat("  [PASS] no expensive workflow triggers on dev; main's required check still starts; the R-devel leg runs depends-only; the issue #84 gate is its own non-required workflow; risk-tier stays cheap\n")
cat("CI policy: PASSED\n")

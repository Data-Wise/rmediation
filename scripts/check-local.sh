#!/bin/sh
# Fast local gate for an R package: quick tests, then R CMD check on a built tarball.
#
# Runs with NOT_CRAN=false, so skip_on_cran() simulation tests are skipped -- the same
# tier the pull-request CI job runs. GitHub CI stays the authority for main and releases (full
# matrix and the slow tests run there); this is the gate for PRs to dev.
#
# The tests already ran above, so R CMD check skips re-running them (--no-tests); it still
# checks the test dependencies statically. CI runs the installed-package tests.
# Vignettes are neither built nor checked here (--no-build-vignettes / --ignore-vignettes),
# so a quarto/knitr toolchain is not needed; CI and the pre-submission pass cover them.
#
# CI policy: GitHub runs the expensive checks (full matrix, coverage, medfit compatibility) for main and
# releases only; PRs to dev are gated here. This script therefore also runs scripts/check-ci-policy.R (workflow
# triggers), scripts/check-docs.R (roxygen output matches man/ and NAMESPACE) and
# scripts/verify-constraint-not-enforced.R (issue #84 gate, about 2 s) first, so the cheap checks fail fast
# before the tests.
#
# Usage:  scripts/check-local.sh [--tests-only] [--no-gate] [--depends-only]
#   --tests-only    the cheap checks and the tests only, no R CMD check
#   --no-gate       skip the issue #84 verify script (needs OpenMx; a missing OpenMx otherwise fails)
#   --no-docs       skip the docs-currency check (needs roxygen2)
#   --depends-only  R CMD check with _R_CHECK_DEPENDS_ONLY_=true, so unguarded Suggests use fails. The check
#                   runs with --no-tests, so this exercises package load and examples only.
# Background:  scripts/check-local.sh >/dev/null 2>&1 &   then   tail -f "$LOG"
# Exit status: 0 = pass (notes allowed), 1 = test failure or check ERROR/WARNING.

set -u

tests_only=0
run_gate=1
run_docs=1
depends_only=0
for arg in "$@"; do
  case "$arg" in
    --tests-only) tests_only=1 ;;
    --no-gate) run_gate=0 ;;
    --no-docs) run_docs=0 ;;
    --depends-only) depends_only=1 ;;
    *) echo "check-local: unknown argument: $arg" >&2; exit 2 ;;
  esac
done

root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
pkg=$(sed -n 's/^Package: *//p' "$root/DESCRIPTION")
[ -n "$pkg" ] || { echo "check-local: no DESCRIPTION in $root" >&2; exit 2; }

tmp=${TMPDIR:-/tmp}
LOG="${tmp%/}/${pkg}-check-local.log"
work=$(mktemp -d "${tmp%/}/${pkg}-check-local.XXXXXX")
trap 'rm -rf "$work"' EXIT

export NOT_CRAN=false
export _R_CHECK_FORCE_SUGGESTS_=false

: > "$LOG"
echo "check-local: $pkg (NOT_CRAN=false), log: $LOG"

echo "== CI policy ==" >> "$LOG"
if ! ( cd "$root" && Rscript scripts/check-ci-policy.R ) >> "$LOG" 2>&1; then
  echo "check-local: FAIL (CI policy) -- see $LOG"
  exit 1
fi

if [ "$run_docs" -eq 1 ]; then
  echo "== docs currency ==" >> "$LOG"
  if ! ( cd "$root" && Rscript scripts/check-docs.R ) >> "$LOG" 2>&1; then
    echo "check-local: FAIL (docs currency: run devtools::document()) -- see $LOG"
    exit 1
  fi
fi

if [ "$run_gate" -eq 1 ]; then
  echo "== issue #84 gate ==" >> "$LOG"
  if ! ( cd "$root" && Rscript scripts/verify-constraint-not-enforced.R ) >> "$LOG" 2>&1; then
    echo "check-local: FAIL (issue #84 gate) -- see $LOG"
    exit 1
  fi
fi

t0=$(date +%s)
echo "== tests ==" >> "$LOG"
( cd "$root" && Rscript -e 'devtools::test(stop_on_failure = TRUE)' ) >> "$LOG" 2>&1
test_status=$?
t1=$(date +%s)

if [ "$test_status" -ne 0 ]; then
  echo "check-local: FAIL (tests, $((t1 - t0))s) -- see $LOG"
  exit 1
fi
if [ "$tests_only" -eq 1 ]; then
  echo "check-local: PASS (tests only, $((t1 - t0))s)"
  exit 0
fi

echo "== R CMD build / check ==" >> "$LOG"
( cd "$work" && R CMD build --no-manual --no-build-vignettes "$root" ) >> "$LOG" 2>&1
tarball=""
for f in "$work"/"$pkg"_*.tar.gz; do [ -f "$f" ] && tarball=$f && break; done
[ -n "$tarball" ] || { echo "check-local: FAIL (build) -- see $LOG"; exit 1; }

if [ "$depends_only" -eq 1 ]; then
  _R_CHECK_DEPENDS_ONLY_=true R CMD check --no-manual --ignore-vignettes --no-tests --output="$work" "$tarball" >> "$LOG" 2>&1
else
  R CMD check --no-manual --ignore-vignettes --no-tests --output="$work" "$tarball" >> "$LOG" 2>&1
fi
check_log="$work/$pkg.Rcheck/00check.log"
t2=$(date +%s)
status=$(grep '^Status:' "$check_log" 2>/dev/null | head -n 1)

case "$status" in
  *ERROR*|*WARNING*|"")
    cp "$check_log" "${LOG%.log}-00check.log" 2>/dev/null
    echo "check-local: FAIL (check, tests $((t1 - t0))s, check $((t2 - t1))s) ${status:-no Status line}"
    echo "check-local: see ${LOG%.log}-00check.log"
    exit 1 ;;
esac
echo "check-local: PASS (tests $((t1 - t0))s, check $((t2 - t1))s) $status"

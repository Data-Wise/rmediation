#!/bin/sh
# Fast local gate for an R package: quick tests, then R CMD check on a built tarball.
#
# Runs with NOT_CRAN=false, so skip_on_cran() simulation tests are skipped -- the same
# tier the pull-request CI job runs. GitHub CI stays the authority (full matrix and the
# slow tests run there on push to main/dev); this catches the cheap failures first.
#
# The tests already ran above, so R CMD check skips re-running them (--no-tests); it still
# checks the test dependencies statically. CI runs the installed-package tests.
# Vignettes are neither built nor checked here (--no-build-vignettes / --ignore-vignettes),
# so a quarto/knitr toolchain is not needed; CI and the pre-submission pass cover them.
#
# Usage:  scripts/check-local.sh [--tests-only]
# Background:  scripts/check-local.sh >/dev/null 2>&1 &   then   tail -f "$LOG"
# Exit status: 0 = pass (notes allowed), 1 = test failure or check ERROR/WARNING.

set -u

tests_only=0
[ "${1:-}" = "--tests-only" ] && tests_only=1

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

R CMD check --no-manual --ignore-vignettes --no-tests --output="$work" "$tarball" >> "$LOG" 2>&1
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

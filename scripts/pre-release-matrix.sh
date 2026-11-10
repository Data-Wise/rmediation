#!/bin/sh
# Run the full cross-platform CI on `dev` BEFORE the version bump and the release PR (issue #178).
#
# scripts/check-local.sh runs on one machine (macOS for the maintainer), and PRs to dev start only the cheap
# `risk-tier` check by design (see "CI Policy" in CLAUDE.md), so the first Linux and Windows run of a release
# was the release PR itself. That is how the 1.11.0 rounding bug (#174) surfaced late. This script dispatches
# the same workflows on demand, waits, and prints each job's result.
#
# Usage:  scripts/pre-release-matrix.sh [--ref BRANCH] [--timeout MINUTES] [--dry-run]
#   --ref BRANCH       branch to run on (default: dev)
#   --timeout MINUTES  give up waiting after this long (default: 75)
#   --dry-run          print what would run; dispatch nothing
# Runs: R-CMD-check (ubuntu release and devel, windows, macos) and lint, both with workflow_dispatch.
# Needs the GitHub CLI (`gh`), authenticated. Uses CI minutes, so run it once per release, after the last
# feature PR has merged to the branch.
# Exit status: 0 = every job succeeded, 1 = a job failed or the wait timed out, 2 = usage or setup error.

ref=dev
timeout_min=75
dry=0
while [ $# -gt 0 ]; do
  case "$1" in
    --ref) ref=${2:-}; shift 2 ;;
    --timeout) timeout_min=${2:-}; shift 2 ;;
    --dry-run) dry=1; shift ;;
    -h | --help) sed -n '2,17p' "$0"; exit 0 ;;
    *) echo "pre-release-matrix: unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ -n "$ref" ] || { echo "pre-release-matrix: --ref needs a branch name" >&2; exit 2; }
case "$timeout_min" in '' | *[!0-9]*) echo "pre-release-matrix: --timeout needs whole minutes" >&2; exit 2 ;; esac

workflows="R-CMD-check.yaml lint.yaml"

if [ "$dry" = 1 ]; then
  echo "pre-release-matrix (dry run): would run on ref '$ref', waiting up to ${timeout_min} min:"
  for wf in $workflows; do echo "  gh workflow run $wf --ref $ref"; done
  echo "  then poll each run until it completes and print every job's result"
  exit 0
fi

command -v gh >/dev/null 2>&1 || { echo "pre-release-matrix: the GitHub CLI (gh) is required" >&2; exit 2; }
sha=$(gh api "repos/{owner}/{repo}/commits/$ref" -q .sha 2>/dev/null) ||
  { echo "pre-release-matrix: cannot read branch '$ref' (is gh authenticated?)" >&2; exit 2; }
echo "pre-release-matrix: $ref is at $sha"
start=$(date -u +%Y-%m-%dT%H:%M:%SZ)

for wf in $workflows; do
  gh workflow run "$wf" --ref "$ref" >/dev/null ||
    { echo "pre-release-matrix: could not dispatch $wf (it needs a workflow_dispatch trigger)" >&2; exit 2; }
  echo "pre-release-matrix: dispatched $wf"
done

# Find each dispatched run: same workflow, same head commit, created after the dispatch.
find_run() {
  gh run list --workflow "$1" --branch "$ref" --event workflow_dispatch --limit 10 \
    --json databaseId,headSha,createdAt \
    -q "[.[] | select(.headSha == \"$sha\" and .createdAt >= \"$start\")] | first | .databaseId // empty"
}

deadline=$(($(date +%s) + timeout_min * 60))
status=0
for wf in $workflows; do
  id=""
  while [ -z "$id" ]; do
    id=$(find_run "$wf")
    [ -n "$id" ] && break
    [ "$(date +%s)" -lt "$deadline" ] || { echo "pre-release-matrix: $wf did not start" >&2; exit 1; }
    sleep 10
  done
  while :; do
    state=$(gh run view "$id" --json status -q .status)
    [ "$state" = completed ] && break
    [ "$(date +%s)" -lt "$deadline" ] || { echo "pre-release-matrix: timed out waiting for $wf (run $id)" >&2; exit 1; }
    sleep 30
  done
  echo "== $wf (run $id)"
  gh run view "$id" --json jobs -q '.jobs[] | "  \(.name): \(.conclusion)"'
  bad=$(gh run view "$id" --json jobs -q '[.jobs[] | select(.conclusion != "success" and .conclusion != "skipped")] | length')
  [ "$bad" = 0 ] || status=1
done

if [ "$status" = 0 ]; then
  echo "pre-release-matrix: PASS on $ref ($sha). Record the run in .STATUS, then bump the version."
else
  echo "pre-release-matrix: FAIL on $ref ($sha). Fix on a branch, merge to $ref, and run again before bumping." >&2
fi
exit "$status"

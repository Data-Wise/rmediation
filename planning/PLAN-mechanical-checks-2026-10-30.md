# PLAN: mechanical checks for RMediation, CI policy first (2026-10-30)

Status: ACTIVE. Owner: the maintainer. Origin: issue #84 follow-up, a read-only comparison with medfit's
checks (Codex review, partial), and a grill (decisions G1-G9 below). Supersedes the draft spec that lived outside
the repository.

## Objective

Give RMediation mechanical checks, so a change to an MBCO or distribution file cannot merge on green CI alone while
skipping oracle, known-answer and planted-defect evidence, without paying for expensive GitHub CI on every PR.

## CI policy (the rule everything else follows)

- Code coverage and every expensive GitHub check (full R-CMD-check matrix, `semfit-mbco`, `test-coverage`,
  `pkgdown`) run only for merge to `main` and for releases, and on `workflow_dispatch`.
- PRs to `dev` and pushes to `dev` start none of them. They are gated locally: `scripts/check-local.sh` and
  rforge (`/rforge:r:cycle`: document, test, check).
- One cheap exception is allowed on PRs to `dev` (G9): the risk-tier script (T4), shell or Python, no R install,
  under about 10 seconds.
- `main` requires the status check `ubuntu-latest (release)`; that trigger and job name must not change.
- `scripts/check-ci-policy.R` enforces this policy mechanically and runs inside `check-local.sh`.
- Docs generator (G10): `scripts/check-docs.R` regenerates roxygen output in a throwaway copy and fails when `man/` or
  `NAMESPACE` is stale. It lives in the local gate, not in a git hook (a hook would run roxygen on every commit and
  can be skipped with `--no-verify`), not in harness agents (none exist until T7), and not in `dev` CI (G8).
  `man/` is compared exactly, `NAMESPACE` as a sorted set (roxygen versions reorder lines), `DESCRIPTION` ignored.

Trade-off accepted: a macOS-only, Windows-only or medfit-compatibility failure is first seen at the `dev`->`main`
PR, not at the feature PR.

## Tasks, in order

| # | Task | Where it runs | Status |
|---|---|---|---|
| T-1 | CI policy: main-only triggers, `check-ci-policy.R`, `check-docs.R`, `check-local.sh` gate and `--depends-only` | local + main CI | this PR |
| T3 | DEPENDS_ONLY: `_R_CHECK_DEPENDS_ONLY_=true` on the existing ubuntu-devel hard-deps leg (per-leg `depends-only` matrix value, enforced by `check-ci-policy.R`) | main CI, `check-local.sh --depends-only` | done in the T3 PR. Advisory by placement: the leg runs only on `main` PRs and is not a required check, so G1's 3-clean-runs rule needs three `main` PRs |
| T5 | #84 gate in main CI as a step in the existing ubuntu release leg (2 s, no path filter, no continue-on-error; enforced by `check-ci-policy.R`) | main CI, `check-local.sh` | merged in #99, but CORRECTED 2026-10-30: the gate is a step of the job `ubuntu-latest (release)`, which is `main`'s required check, so a red gate blocks the merge (it is NOT advisory by placement, contrary to the #99 description). MOVED by T5b to its own non-required workflow `issue-84-gate.yaml` (job `issue-84-gate`; not a step of `R-CMD-check`); enforced by `check-ci-policy.R`; see `planning/PLAN-github-release-1.8.0-2026-10-30.md`, R6 |
| T4 | risk-tier: PR-body checklist script (`scripts/risk_tier.py`, stdlib Python, tests in `scripts/test_risk_tier.py`); known-answer and planted-defect items cite a test file present in the diff; cheap exception on `dev` PRs (`.github/workflows/risk-tier.yaml`, `.github/risk-files.txt`, `.github/PULL_REQUEST_TEMPLATE.md`) | PRs to `dev` and `main` | done in the T4 PR. Risk-file list extended after the author's decision: 30 of 43 `R/` files (the five first patterns missed the DOP, `medci` and bootstrap code; `R/dop*.R` matched nothing and was dropped); `scripts/test_risk_tier.py` fails on a dead pattern or an uncovered core file |
| T1-T2 | lint: `.lintr` (120 columns), cosmetic cleanup only, advisory; runs on dispatch/push, never on `dev` PRs | dispatch | deferred until T3/T5/T4 each have 3 clean runs |
| T7 | slimmed orchestrator (implementer, QA, gates), Active-plan pointer in `CLAUDE.md` | local | deferred, depends on T4 and T5 |

Dropped: PR coverage (#86 removed it on purpose).

## Decisions (grill and author directives)

| # | Decision |
|---|---|
| G1 | An advisory check graduates to required after 3 consecutive clean runs on real PRs; the author flips it. A session hands over `gh-require-check.sh --dry-run` and never applies branch protection. A `.STATUS` line per check: `YYYY-MM-DD <check> run N/3: pass\|fail (PR #nn)`, a fail resets the count. |
| G2 | risk-tier: the known-answer and planted-defect items must name a `tests/testthat/` file present in `git diff --name-only`; `n/a` needs a reason; docs-only and rename PRs get an explicit exemption; release PRs from `dev` are exempt. |
| G3 | The #84 gate fails when every optimizer skips (done in #95). Message: "OpenMx may have fixed #433; update or retire this gate". |
| G4 | Lint is cosmetic only (about 57 findings: line length and indentation); `return_linter`, `commented_code_linter`, `object_usage_linter`, `seq_linter` stay off until triaged; neutrality shown by `git diff -w` and unchanged test counts. |
| G5 | PR coverage is dropped. |
| G6 | Order: T3, T5, T4 first (each can fail on a real defect); lint and T7 deferred. |
| G7 | The #84 gate runs without a path filter (a filter that misses a file skips it silently). |
| G8 | Author directive: coverage and expensive checks only for `main` and releases; everything else local (rforge, `check-local.sh`). |
| G9 | One cheap exception on `dev` PRs: the risk-tier script (no R install, about 10 s). |
| G10 | The docs generator check lives in `check-local.sh` (local gate), chosen over a git hook, the harness and `dev` CI. Measured on clean `origin/dev` (roxygen2 8.1.1): `man/` 0 differences; `NAMESPACE` one reordered line; `DESCRIPTION` version bump only. Planted defects (hand-edited Rd; edited roxygen comment without regenerating) both fail. |

## Boundaries

- Always: US English; conventional commits; test the check (it must be able to fail) before relying on it; counts
  and a failing-then-passing transcript in every PR body.
- Ask first: making any check required (the author applies it); touching branch protection; changing the `main`
  required context; anything in medfit.
- Never: a check that passes when it ran nothing (#95); `continue-on-error` around the checked command; blanket lint
  exclusions to reach zero.

## Known limits

- `check-local.sh --depends-only` runs `R CMD check --no-tests`, so it exercises package load and examples only; a
  planted unguarded `OpenMx::` call must sit in code that path runs (an example).
- Codex's review of medfit's checks arrived with about 116 lines cut; its table rows 1-3 and 9+ and its risk-file
  list are unrecovered. The risk-file list for T4 is a proposal: `R/mbco*.R`, `R/prod3_core.R`, `R/dop*.R`,
  `R/pprodnormal*.R`, `R/ci*.R`.
- medfit's revdep workflow can fail open (`continue-on-error: true`); do not copy that pattern.

## Open questions

1. Are `R/ci*.R` and `R/pprodnormal*.R` risk files for T4?
2. T7: one Claude copy only, with the Active-plan pointer in `CLAUDE.md`?

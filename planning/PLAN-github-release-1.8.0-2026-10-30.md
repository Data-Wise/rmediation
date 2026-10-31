# PLAN: path to the GitHub release (2026-10-30)

Status: ACTIVE. Decisions R1-R6 come from a grill with the maintainer on 2026-10-30. Nothing here is implemented.
Related: issue #88 (release the OpenMx#433 defenses), draft PR #46 (superseded, see R2), #84 and #92 (left open for
their author), `planning/PLAN-mechanical-checks-2026-10-30.md` (the CI policy and the checks this release depends on).

## Goal

Publish `dev` as a GitHub release so users get the OpenMx#433 defenses (`mbco()` guard with refit, the wrong-branch
probe, `mbco_product_null()`, the `RMediation_constraint_not_enforced` warning). CRAN stays at 1.6.1 and the CRAN
submission hold stays active: nothing in this plan submits to CRAN, and `devtools::submit_cran()` is never started.

## Facts (checked 2026-10-30)

- `main` and CRAN: 1.6.1. `dev`: `DESCRIPTION` says 1.7.0, `NEWS.md` heads the unreleased section "1.7.1". Tags: v1.7.0
  (pre-release, 2026-08-17), v1.6.1 ("Latest"). `dev` is 160 commits ahead of `main`.
- Exports since 1.6.1: added `dprodnormal`, `dprodnormal3`, `mbco_product_null`, `ml_omitted_confounder`; removed
  `medci_prototype` (it shipped on CRAN, so NEWS carries a `Removed` entry).
- `main` is 3 commits ahead of `dev` (two "Merge pull request" commits and `e9b6d6e`, a navbar change). A dry merge
  (`git merge-tree origin/main origin/dev`) is clean, so no pre-sync of `main` into `dev` is needed.
- `main` requires one status check, `ubuntu-latest (release)`. The pkgdown workflow deploys on every push to `main`.
- The README installs "From GitHub (Development)" with `ref = "dev"`.

## Decisions

| # | Decision |
|---|---|
| R1 | Release number **1.8.0** (four new exports and one documented removal make it a minor bump). `DESCRIPTION` 1.7.0 becomes 1.8.0, the NEWS heading "1.7.1 (development version)" becomes "1.8.0", and every string that says 1.7.1 is updated (NEWS, `.STATUS`, `CLAUDE.md`, issue #88). The v1.7.0 tag is not touched. |
| R2 | Release from `dev` as is, **SEMFit MBCO route included** (experimental, needs medfit 0.8.0, version-gated with a clear error). No divergent release branch; draft PR #46 (`release/1.7.1`, route removed) is superseded and closed, not merged. Consequence: a later CRAN candidate must remove or finish the route, so the CRAN version will be a later number. |
| R3 | The merge to `main` auto-publishes the pkgdown site. Let it publish, and make the README say plainly that CRAN is stable 1.6.1 and the GitHub release is 1.8.0, with the GitHub install pointing at the tag (`ref = "v1.8.0"`). |
| R4 | The GitHub release is a **pre-release**, as v1.7.0 was. "Latest" stays v1.6.1 (CRAN). Flipping it to Latest is a separate decision when the CRAN question is settled. |
| R5 | One `workflow_dispatch` dry run of `R-CMD-check` on `dev` before the release PR: T3 (depends-only) and the matrix have never run on GitHub with this much new code, so failures are found off the critical path and fixed on `dev`. This is the one expensive run the author approved. |
| R6 | The #84 gate moves out of the required job into its own **non-required** job (`issue-84-gate`, minimal R setup: OpenMx, testthat, pkgload; `main` PRs only). See the correction below. |

## Correction to the mechanical-checks plan (T5)

PR #99 added the gate as a step of the job named `ubuntu-latest (release)` and its description said a red step
"cannot block a merge, because `main` requires only `ubuntu-latest (release)`". That was wrong: the step is inside the
required job, so a failing gate fails the required check and blocks the `main` merge. That contradicts G1 (new checks
stay advisory until three clean runs, then the author flips them) and G3 ("red while advisory blocks nothing"; an
OpenMx fix of #433 would have blocked releases). R6 fixes it. Until it lands, the gate is effectively required.

## Path, in order

| Step | What | Where | Gate |
|---|---|---|---|
| 1 | **T5b**: move the gate to a separate non-required job; update `check-ci-policy.R` (one gate job, not in the required job, no `continue-on-error`, no path filter) and the `CLAUDE.md`/`.STATUS`/plan text | PR to `dev` | policy check red first; planted defects; ask before merge. DONE in the T5b PR (branch `feature/gate-job`) |
| 2 | **Version bump to 1.8.0**: `DESCRIPTION`, NEWS heading, sweep of "1.7.1" strings; README install note and `ref = "v1.8.0"` | PR to `dev` | `check-local.sh`; grep for the old strings returns only history |
| 3 | **Dry run**: `gh workflow run R-CMD-check -r dev`, then read every leg | dispatch on `dev` | author's approval already given (R5); fix findings on `dev` |
| 4 | **Release PR** `dev` -> `main`, merge commit (not squash), risk-tier exempt (release PR) | PR to `main` | required `ubuntu-latest (release)` green; read every other leg; Codecov patch coverage counts all work since `main`, so triage it, do not assume |
| 5 | The author merges to `main` (release merges are not done from a session) | GitHub | pkgdown deploys; check the site |
| 6 | **Tag and release**: tag `v1.8.0` on `main`, GitHub **pre-release** with notes drawn from NEWS | GitHub | verify tag, notes, and that "Latest" is still v1.6.1 |
| 7 | **Close out**: close PR #46 as superseded; comment on #88 with the outcome; leave #84, #88 and #92 for their author | GitHub | none |

Never: start a CRAN submission; merge to `main` from a session; force-push `main`; apply branch protection; skip the
dry run; call the gate advisory while it sits in the required job.

## Not yet decided (not grilled)

- Policy when non-required checks are red on the release PR (Codecov patch coverage, the R-devel leg): default is
  to triage each, fix on `dev` where cheap, and record any waiver in the release PR body.
- Whether the release notes quote NEWS verbatim or a shorter summary.
- Whether to record the CRAN-version consequence of R2 in issue #88.

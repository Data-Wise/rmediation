# GRILL: SEMFit-pair MBCO dependency and release policy

Date: 2026-10-12. Target: `PLAN-semfit-mbco-2026-10-12.md` (merged via PR #41, `d29685f`).
Scope: when and how the `mbco(h0, h1)` SEMFit route ships. Supersedes nothing in the plan;
the plan's "dependency/release policy requires a separate decision" item is resolved here.

## Decisions

| # | Branch | Decision | Overrode recommendation? |
|---|---|---|---|
| 1 | Ship gating | **Hold the route out of the release until medfit 0.8.0 is on CRAN** | Yes (recommended: ship now, Suggests unchanged) |
| 2 | Hold method | ~~Gate the whole release on medfit 0.8.0~~ **SUPERSEDED by Branch 3 revision (2026-10-12)** | No |
| 3 | Fallback | ~~No fallback date~~ **REVISED 2026-10-12: decouple.** The v1.7.x fix (with #36) ships alone when the gauss hold lifts; the SEMFit route is held out of that tarball and follows in a later minor once medfit 0.8.0 is on CRAN | Revised after finding medfit has no CRAN date |
| 4 | At release | **Raise Suggests to `medfit >= 0.8.0` once it is on CRAN** | Yes (recommended: keep `>= 0.2.0`) |
| 5 | Scaffolding | **Keep the runtime version gate and its tests; drop only the CRAN-0.3.2 CI job** | No |

## Consequences to carry forward

- Branch 3 (revised): the v1.7.x fix and PR #36 ship together, gated only by the maintainer hold
  (no submission or `dev->main` without explicit go-ahead) and release mechanics. medfit's undated
  CRAN hold no longer gates them.
- **Hold mechanism decided 2026-10-12: Option 1, a release branch** cut from `dev` that omits the
  route; `dev` keeps it. (Rejected: unregistering in `R/mbco_semfit.R` - ships inert code, failing or
  skipped tests, and Rd text describing a route that errors.) Finding from a dry run of
  `git revert --no-commit d29685f` (aborted, tree clean): PR #41 is one squash commit touching 16
  files, but a plain revert **conflicts in 5 files** - `R/00_classes.R`, `man/mbco.Rd`, `NEWS.md`,
  `.STATUS`, `planning/PLAN-semfit-mbco-2026-10-12.md` - because later PRs #42-#45 edited the same
  regions. So the branch needs hand-removal of the route hunks, not a mechanical revert. Route-only
  files that delete cleanly: `R/mbco_semfit.R`, `tests/testthat/{helper-semfit-mbco,test-mbco-semfit,
  test-mbco-semfit-mutations}.R`, `.github/workflows/semfit-mbco.yaml`, `scripts/check-semfit-load.R`,
  `scripts/prepare-semfit-library.R`. Hunks to cut by hand: `R/00_classes.R`, `R/ci_medfit.R`,
  `man/mbco.Rd`, `NEWS.md`, `README.md`, `inst/WORDLIST`, `.github/workflows/test-coverage.yaml`.
- Branch 4 drops older-medfit support for existing `ci()` medfit methods when it takes effect
  (the later minor that ships the route). Suggests minimums are not enforced at runtime, so the
  version gate (Branch 5) stays live.
- Do not add `Remotes` and do not raise Suggests now; both wait for medfit on CRAN.

## Part 2: the `method="gauss"` default and the version (same session)

| # | Branch | Decision |
|---|---|---|
| A | What the gauss-default hold protects | **Reproducibility of downstream results.** Gate = revdep check, then lift |
| B | Is existing mitigation enough? | **Yes; the hold on the default is lifted.** Evidence: CRAN reverse dependencies of RMediation = none (`tools::package_dependencies(reverse=TRUE)`, 2026-10-12); no sibling-repo callers of `pprodnormal3`/`ProductNormal3` found; mitigation = NEWS states the change, `method="hcubature"` retained. This is a decision on the default only, not authorization to submit |
| C | Version sent to CRAN | **1.7.1.** The public `v1.7.0` pre-release tag stays untouched as history; CRAN goes 1.6.1 -> 1.7.1 with both NEWS sections |

Residual risk accepted: end-user scripts or archived results pinned to old `hcubature` values.
Reversing the default after CRAN would move numbers a second time.

## Release checklist (when medfit 0.8.0 appears on CRAN)

1. Verify the CRAN build exports what the adapter needs; re-run the CRAN-medfit CI job and confirm
   the SEMFit tests run with zero skips.
2. Raise `Suggests: medfit (>= 0.8.0)`; update the `semfit-mbco.yaml` jobs (drop the 0.3.2 job).
3. Full suite and strict `R CMD check --as-cran`; report pass counts.
4. (Applies to the later minor shipping the route.) The 1.7.1 bump and gauss default are decided
   in Part 2.

## Open questions

- **Answered 2026-10-12 (read-only look at medfit `.STATUS`, `crandb`):** medfit 0.8.0 is
  "not submitted to CRAN" and medfit records its own "continuing CRAN hold"; CRAN is 0.3.2
  (published 2026-07-23). No submission date exists, and releases 0.4.0-0.8.0 are all
  GitHub/r-universe only. Combined with Branch 3 (no fallback date), the RMediation release now
  has no end date. Revisit Branch 3 or ask the medfit maintainer hold's owner for a plan.
- Whether to revisit Branch 3 if the wait runs long (re-ask when PR #36 or the v1.7.0 fix is needed on CRAN).
- **2026-10-13 user hold:** CRAN submission waits until both RMediation and medfit are mature. This subsumes
  the earlier 'no submission without go-ahead' gate; "mature" is undefined, so it needs a definition
  before it can act as a trigger.
- **Definition of mature (user, 2026-10-13):** SEM features not experimental, and `fixed.x` and mean
  structure completed. Read-only status the same day: medfit native SEM and `SEMFit` still experimental;
  mean structure planned for medfit 0.9.0-0.11.0, not started; `fixed.x` is in medfit's planning specs
  (native-SEM Q3; mean-structure item 4: exogenous means freed vs lavaan's default `fixed.x = TRUE`), not in NEWS. Branch 4's trigger (medfit 0.8.0 on CRAN) is now necessary but not sufficient.
- **2026-10-13 Branch 3 revisited again:** ship the integrator fix alone? **No - keep holding it with the
  rest** (user choice, recommended). Reasons: second-submission ban risk; CRAN 1.6.1 harm limited to
  ill-conditioned covariance; mitigations live (v1.7.0 GitHub pre-release, pkgdown warning note, README
  `Requires RMediation >= 1.7.0`). `release/1.7.1` stays a ready-but-unsubmitted candidate.
- **2026-10-13 confirmed by user:** the `fixed.x` in the maturity definition is medfit's exogenous-moments
  item (native-SEM Q3, mean-structure item 4). The definition is complete: SEM features non-experimental,
  `fixed.x` and mean structure completed.

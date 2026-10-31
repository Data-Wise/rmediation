# Plan: Provider and product-distribution evidence handoffs

Filed 2026-10-20 after explicit user authorization to file the
research-workflow plans.
Status: proposed follow-up; filing only, not implementation or acceptance
evidence.

**Owner:** RMediation maintainer; medfit owns SEMFit behavior.
**Observed local identity:** `dev` at `bdccc29e9fb5`. This is a dated
checkout observation, not a release/installed-package assertion; recheck
before execution.

## Scope and holds

CRAN and release decisions remain governed by current .STATUS and explicit
per-instance authorization.
Preserve unrelated work, current scientific rules, active plans and
per-instance external-action gates.
No simulation, installation, manuscript revision, submission, release or
deployment ran for this filing.
This dated plan supplements existing plans; it does not replace their queue or
certify completion.

## Ordered tasks

### 1. Pin the API and dependency boundary

- [ ] Map the actual mbco/SEMFit and product-distribution routes used by
      companion work to source ref, dependency version, documentation and
      numerical evidence.
- **Acceptance:** OpenMx and medfit routes remain distinct; no bootstrap or
  unsupported inference is attributed to a route by name alone.
- **Verification:** Inspect current exports/help and existing tests;
  separately record installed/released identities if later inspected.
- **Dependency:** None; reconcile existing evidence first.
- **Scope:** one evidence record or bounded correction; split implementation
  if it exceeds five files.

### 2. Record numerical and proof scope separately

- [ ] Link exact anchors, finite-grid comparisons, convergence failures and
      unresolved proof/sign-off obligations for relevant product or MBCO
      claims.
- **Acceptance:** Agreement at selected nodes is not a universal error
  certificate or author proof; near-singular limitations and existing
  safeguards remain explicit.
- **Verification:** Use existing distribution/branch oracles; any later
  numerical change requires focused tests plus owning package checks.
- **Dependency:** Task 1; retain the existing project approval gates.
- **Scope:** one evidence record or bounded correction; split implementation
  if it exceeds five files.

### 3. Prepare bounded downstream evidence

- [ ] Give missingmed and medfit owners exact supported API/ref and test
      evidence without changing dependency policy or release state.
- **Acceptance:** No CRAN submission, visibility change or dependency-floor
  change is implied by this plan.
- **Verification:** Inspect relevant help/pkgdown for stale claims only when
  the scoped audit or correction is executed.
- **Dependency:** Task 2; retain the existing project approval gates.
- **Scope:** one evidence record or bounded correction; split implementation
  if it exceeds five files.

## Checkpoint and first action

- [ ] After tasks 1–2, reconcile evidence and unresolved decisions before
      beginning task 3.
- [ ] Record actual verification and remaining owner decisions; do not tick
      future execution from this filing.

**First action:** the named maintainer reads the existing evidence in task 1
and reconciles its
residual scope with the current owning plan. Stop if evidence conflicts or a
scientific/author
decision is unresolved; name that decision rather than silently changing the
plan.

## Coordination

- [Shared Savant enhancement plan][ref1] owns reusable command/skill work.
- [missingmed companion plan][ref2] owns its repository changes.
- [medfit companion plan][ref3] owns its repository changes.
- Future execution must follow this repository's instructions, tests, artifact
  checks and branch model.

[ref1]: </private/tmp/savant-simulation-completeness/tasks/plan-research-workflow-2026-10-20.md>
[ref2]: </Users/davood/projects/r-packages/active/missingmed/docs/PLAN-research-workflow-enhancements-2026-10-20.md>
[ref3]: </Users/davood/projects/r-packages/active/medfit/tasks/PLAN-research-workflow-enhancements-2026-10-20.md>

# Spec: `RMediation_constraint_dropped` warning (issue #84, R1-R3)

Gate note: the spec gate is satisfied by the user's decision on 2026-10-30 (option A, relayed by
the session that started this work) after the Codex review in `tasks/codex-review-84.md`.

## Objective

OpenMx (>= 2.19.1, OpenMx/OpenMx#433) silently drops an equality constraint whose Jacobian row is
zero at the starting values, so `b1*b2 == 0` started at `b1 = b2 = 0` returns the unconstrained
fit and `mxCompare()` reports LR = 0. `mbco()` on dev already repairs this through the violation
guard (`RMediation_h0_refit`, 0 -> 0.0878 on the known-answer case) but the warning never names
the cause. Add a classed warning so users and tests can recognize the symptom.

## Assumptions

1. `mbco()` only ever sees a **fitted** h0; OpenMx keeps no starting values after `mxRun`
   (checked: matrix values, `@output`, `summary()`, slots; Codex confirmed). The proposed
   predicate (`.mbco_involved()` empty at h0's own starts) is therefore not implementable, and
   `.mbco_involved()` is a finite-difference dependency heuristic, not a Jacobian test.
2. The only observable symptom is: a constraint of h0 is violated at the fitted solution and
   h0's -2LL equals h1's (`statistic_before` about 0). A tolerance-accepted violation
   (`.guard_fits(1)`, h0 started at h1's nonzero estimates) has the same symptom.

## Behavior

- **Trigger:** `.mbco_refit_h0()` ran and succeeded (`refit$model` not `NULL`) and
  `abs(refit$refit$statistic_before) < 1e-6`.
- **Signal:** warning of class `RMediation_constraint_dropped` (via `.mbco_signal()`), emitted
  right after `RMediation_h0_refit`, from the user's h0 state (the refit record already holds it).
- **Message (honest, neutral):** says the h0 fit is identical to h1's although a constraint was
  violated, so the constraint may not have been enforced; names OpenMx/OpenMx#433 (zero Jacobian
  at the starting values) and violation within the feasibility tolerance as possible causes;
  states that a fitted h0 cannot tell them apart; points to `mbco_product_null()` and `?mbco`.
- **Does not change:** the statistic, `refit` slot, `RMediation_h0_refit` (class, message,
  timing), `RMediation_h0_refit_failed`, `RMediation_constraint_branch`, any `type` path.
- Also fires for the tolerance fixture (same symptom); the message says so. Class name is the
  user's choice; Codex recommended a cause-neutral name (open item for the reviewer, see
  `tasks/codex-review-84.md`).

## Commands

```
Test one file:  Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-mbco-constraint-dropped.R")'
Full suite:     Rscript -e 'devtools::test()'
Lint:           Rscript -e 'lintr::lint_package()'
Document:       Rscript -e 'devtools::document()'
Harness:        Rscript scripts/verify-constraint-dropped.R
```

## Structure

- `R/mbco-compare.R`: helper `.mbco_report_dropped(refit)` next to `.mbco_signal()`.
- `R/mbco.R`: one call after the refit warning.
- `R/00_classes.R` (`?mbco` roxygen) and `man/mbco.Rd`; `NEWS.md`; `.STATUS`.
- `tests/testthat/test-mbco-constraint-dropped.R`; `scripts/verify-constraint-dropped.R` (not in
  the package build: `^scripts$` is in `.Rbuildignore`).

## Testing strategy

- Known answer, seed 20261103 dataset 1, zero-start h0 built from the unfitted model: class
  present, statistic positive and equal to `mbco_product_null()` within 1e-4, and pinned 0.0878
  (OpenMx 2.22.11, tolerance 1e-3; a regression pin, not a cross-optimizer oracle).
- Message wording assertions. Competing-history control: `.guard_fits(1)` raises the same class.
- Negatives: clean h0 raises nothing; a refit with `statistic_before` > 0 (mocked) does not
  raise the class.
- Planted defect: no-op the helper, `expect_failure()` on the class assertion, paired with the
  ordinary assertion in the known-answer test (Codex: `expect_failure` alone is not
  mutation-resistant).

## Boundaries

- Always: US English; tests before code; report counts.
- Ask first: renaming the class; merging into the refit warning; any change to existing classes.
- Never: claim detection of OpenMx#433 in docs; touch release/version strings (issue #88);
  edit medfit or mbco-lrt; merge without the user.

## Success criteria

New test fails without the change, passes with it; full suite green; lint clean; harness
transcript (every optimizer available locally, optimizer named per number) in the PR body.

## Open questions / known gaps

- `type = "parametric"` refits the observed h0 (refit precedes the type branch) but its
  bootstrap replicates are not refit (`mxCompare(boot = TRUE)`, unlike `.mbco_semi`). Follow-up,
  not in this change; docs must not imply bootstrap-wide protection.

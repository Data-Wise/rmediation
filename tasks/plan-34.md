# Plan: MBCO constraint-violation guard and docs (issue #34)

Date: 2026-10-14. Base: dev `85d45b3`. Spec of record: `planning/PLAN-34-mbco-feasibility-tolerance-2026-10-14.md` (decisions from
`planning/GRILL-mbco-feasibility-plan-2026-10-14.md`, Codex review addressed). This is the task plan; the coverage plan stays in
`tasks/plan.md`. Worktree and branch already exist: `~/.git-worktrees/rmediation/feature-mbco-tolerance` (`feature/mbco-tolerance`), no code yet.
CRAN, `dev` to `main` and the integrator holds remain; nothing here is a release.

## Scope (decided)

In: a classed warning when a fitted `MxConstraint` of `h0` or `h1` is violated (all three `type`s), and the docs that go with it.
Out, deferred to a separately gated plan: bootstrap-refit tolerance (B) and refitting `h0` for the observed statistic (E). No returned number changes.
Out, documented limit: a feasible fit of a product null can still sit on the wrong branch (issue #35); the guard cannot see it.

## Dependency graph

```text
.mbco_constraint_violation(model)        (new, pure function over a fitted MxModel)
        |
.mbco_compare(h0, h1)  (R/mbco-compare.R)   <- single call site for asymp, parametric and semi
        |
mbco() warnings reach all three types  --->  ?mbco Details + NEWS  (docs describe the shipped behavior)
```

`.mbco_compare()` is called by `mbco_asymp()`, `mbco_parametric()` and `.mbco_semi()`, so one wiring point covers every OpenMx type; the SEMFit route
does not use it and is unaffected. Constraint evaluation is proven by the T0 prototype (`@formula`, `mxEval(..., compute = FALSE)`, per-operator violation).

## Vertical slices

### Slice 1 — the guard, end to end for an equality constraint (type "asymp")
- Add `.mbco_constraint_violation(model)` returning, per constraint, the scaled violation `|lhs - rhs| / max(1, |lhs|, |rhs|)` for `==`.
- Call it for `h0` and `h1` inside `.mbco_compare()`; warn with class `RMediation_constraint_violation` naming the constraint, its violation and the two-fit route.
- Acceptance: the issue's reprex fitted at the default tolerance (seeds 1-3) warns; the same `h0` refitted with tolerance 1e-8 does not; the returned `MBCOResult` is identical with and without the guard (no number changes).
- Verify: new OpenMx-gated test file `tests/testthat/test-mbco-constraint-guard.R`; `devtools::test(filter = "mbco")`.

### Slice 2 — thresholds, inequalities and `h1`
- Inequality operators `<` and `>`: scaled violation of the wrong side only; slack inequalities never warn.
- Scaled threshold: a large-scale constraint with noise-level violation does not warn; the same relative violation on a unit-scale constraint does.
- `h1` carrying a violated constraint warns (and names `h1`).
- Acceptance: slack control silent (violation 0 in the T0 prototype); binding-infeasible inequality warns; threshold boundary at 1e-6 behaves as specified on both sides.
- Verify: same test file; planted defects below.

### Slice 3 — unevaluable constraints
- Wrap each constraint's evaluation so a failure is re-raised as an error naming the constraint ("could not evaluate constraint <name> for the violation check"); unsupported operators (`!= `, others) are skipped, not errors.
- Acceptance: a planted unevaluable constraint gives that error from `mbco()`; a model with no constraints is untouched.
- Verify: test with a constraint referencing an algebra that cannot be evaluated.

### Slice 4 — all types and planted defects
- The guard fires through `type = "parametric"` and `"semi"` (small `R`), proving the single wiring point covers them.
- Planted defects, each must fail a test: guard ignores constraints; threshold off by 1e4; guard checks only `h0`; guard uses the absolute (unscaled) violation.
- Acceptance: each mutant (via `testthat::local_mocked_bindings()` on `.mbco_constraint_violation` or `.mbco_compare`) breaks the named test.

### Slice 5 — docs and NEWS (describes what shipped in slices 1-4)
- `?mbco` Details (roxygen in `R/00_classes.R`): when the guard fires; the OpenMx default feasibility tolerance (0.05) and setting 1e-8 on `h0`; the two-fit route for `ab = 0`;
  the exact-statistic vs conservative-p-value wording (smaller -2LL is the exact constrained LRT statistic; its chi-square(1) p-value is conservative at a = b = 0, standard theory not verified here);
  the wrong-branch limit and issue #35; that an unevaluable constraint now errors.
- NEWS bullet: guard only; no returned number changes.
- Acceptance: `devtools::document()` clean (restore roxygen-version churn to `NAMESPACE`/`DESCRIPTION` if the installed roxygen differs from 8.0.0, as in PR #48); US English.
- Verify: `R CMD check --as-cran` 0 errors/0 warnings; `spelling::spell_check_package()` clean.

## Checkpoints

- **Checkpoint 1 (after slice 2):** reprex warns/silent as specified; no returned number differs from `dev` on the existing mbco tests; full `devtools::test()` counts reported against the `dev` baseline (696 passed, 0 failed, 10 skipped, 2 warnings, from PR #49).
- **Checkpoint 2 (after slice 4):** planted-defect evidence quoted (each mutant fails its test); all three `type`s covered.
- **Checkpoint 3 (before PR):** strict `R CMD check --as-cran --run-donttest --no-manual` on the built tarball, E2E transcript from a clean session (reprex warns at default tolerance, silent at 1e-8), docs rendered; then PR to `dev`, merge only on your instruction.

## Risks

- A new warning for scripts that already run; users can mute the class. The message must say what to do.
- An unevaluable constraint now errors (grill decision 5, user override); the message names it.
- Needs OpenMx; the new tests skip without it, as the existing mbco tests do.
- The T0 evidence is 12 simulated datasets on one model and one OpenMx version.

## Findings during implementation

- **Linear equalities are affected too (slice 1, 2026-10-14).** A linear `b == 0` fitted from the full model's estimates at the default tolerance ends with `b` = 0.015 to 0.041 (seeds 1-3, OpenMx status 0), so the guard also fires there. The grill's footprint reasoning ("the mbco() tests use linear constraints that fit exactly") was wrong in general; empirically no existing test newly warns (full suite: same 2 pre-existing warnings). This matches finding 4 of issue #35's comment (nulls refit from the full model's estimates can be infeasible).

## Open items

None blocking. Option B and E are a separate plan; issue #35's remainder rides on the SEMFit route.

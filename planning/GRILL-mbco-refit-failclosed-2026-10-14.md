# GRILL — failed-refit policy and violated h1 (Codex review findings, 2026-10-14)

Target: Codex adversarial review (dev vs main), finding "a failed refit falls back to a known invalid null fit", and the residual cases of the first Codex finding (violated null still yields a result). Three questions, each with a stated recommendation; all three recommended options chosen.

| Q | Topic | Decision |
|---|---|---|
| 1 | Failed refit of a violated `h0` | **Error**, naming the constraint. **Reverses Q4 of `GRILL-mbco-b-e-2026-10-14.md`** (fall back to the user's fit). No new argument. Rejected: keep the fallback; error only above a larger violation |
| 2 | Violated `h1` | **Keep warn-only** (`RMediation_constraint_violation`, label h1). Rejected: error, refit `h1` |
| 3 | Condition type | **Classed error `RMediation_h0_refit_failed`**, replacing the same-named warning; catchable by class. Rejected: plain `stop()`, error carrying the failed refit |

## Why Q1 was reversed (stated before the decision)

- No released behavior is preserved by the fallback: CRAN serves 1.6.1 (no guard, no refit) and 1.7.0 is a GitHub pre-release; CRAN submission is held.
- The failure is rare (the refit succeeded in all 300 runs of the 100-seed, three-type studies), so an error costs users almost nothing, while the fallback returns a known-wrong statistic (0 where the exact value is 0.4745).
- The message gives the remedy (refit at 1e-8 yourself, or use `mbco_product_null()`), so no opt-out argument is needed.

## Assumptions stated (not asked)

- "Failed" means the refit errors, does not converge (status outside 0/1) or leaves a constraint violated (the three cases of `.mbco_refit_h0()`).
- The error is raised in `mbco()` before the `type` branch, so it covers `asymp`, `parametric` and `semi` and fires before any bootstrap work.
- The earlier `RMediation_constraint_violation` warning for a failed-refit `h0` is no longer reached (the error comes first); the guard still warns for `h1`.
- Existing tests that expect the fallback (`test-mbco-refit-wiring.R`) change to expect the error; the guard tests that switch the refit off with `.guard_no_refit()` are unaffected.
- NEWS and `?mbco` say that a violated `h0` that cannot be repaired is now an error.

## Residual after this change

The only known path to a number from a known-invalid null is a feasible fit on the wrong branch of a product null (issue #35): addressed by `mbco_product_null()` and, once built, the warn-only probe (`tasks/plan-35-probe.md`).

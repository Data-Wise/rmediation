# Plan: wrong-branch probe, warn-only (#35 remainder)

Date: 2026-10-14. Base: `dev`. Decisions: `planning/GRILL-mbco-branch-probe-35-2026-10-14.md`. Evidence: `planning/RESEARCH-35-wrong-branch-probe-2026-10-14.md`. Earlier plans: `tasks/plan-34.md`, `tasks/plan-34-be.md`, `tasks/plan-35.md` (all shipped).

## Behavior

After the guard and the refit, `mbco()` probes each equality constraint of the `h0` it will use. If fixing an involved parameter at 0 (constraint dropped, feasibility rechecked) gives a converged, feasible fit with -2LL lower by more than 1e-4, it warns with class `RMediation_constraint_branch` naming the constraint, the parameter, the gap and `mbco_product_null()`. The result is unchanged. Above 5 involved parameters the probe is skipped with a note.

## Slices (tests first; each leaves the suite green)

1. **Involvement.** `.mbco_involved(h0, h1, label)`: free parameters a constraint depends on, found at the full model's estimates. Tests: `a*b` -> both; a linear `b == 0` -> `b` only; a constraint on a fixed algebra -> none; the null-solution trap (at `a = 0`) still finds both.
2. **Probe core.** `.mbco_branch_probe(h0, h1)`: per equality constraint returns the best valid candidate or `NULL`. Known answers: `memory_exp` unfitted-start null (221.05) -> flags `b1` with gap about 221.0; fitted-start right branch -> `NULL`; synthetic seeds at b = .4 flagged, b = 0 and .15 not. Planted defects: probing at the null's own solution (misses `b`), ignoring the feasibility recheck (flags an infeasible candidate); the gap threshold is tested through its argument. (Keeping the constraint while fixing was planned as a defect but did not fail under SLSQP: same 14 of 24 flags, so it is not tested as one.)
3. **Wire into `mbco()` for all three types**, once per call, after the refit. Classed warning with the agreed content; cap of 5 with a note; probe failures skipped silently; bootstrap types warn once; existing tests unaffected (suite counts vs the post-#53 baseline, 914 expectations).
4. **Docs and gates.** `?mbco` section, NEWS, `?mbco_product_null` cross-reference, spelling, `devtools::document()` with roxygen churn reverted, strict `R CMD check`. Checkpoint: repeat the sweep through the public `mbco()` (60 seeds each at b = 0, .15, .4, threshold 1e-4): all wrong-branch cases flagged, 0 false positives, plus `memory_exp`.
5. **PR to `dev`**; merge only on instruction.

## Risks

- Extra fits on every constrained `mbco()` call (bounded by the cap of 5).
- Detects only branches reachable by fixing one involved parameter at 0; does not prove a returned `h0` is optimal.
- Untested: several constraints at once, constraints with more than 3 involved parameters, NPSOL.

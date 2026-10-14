# GRILL — PLAN-34 (issue #34, MBCO feasibility tolerance)

**Target:** `planning/PLAN-34-mbco-feasibility-tolerance-2026-10-14.md`
**Date:** 2026-10-14. Interactive grill, one question at a time, `--no-refine`.

## Decisions

| # | Branch | Decision | Consequence |
|---|---|---|---|
| 1 | Weakest recommendation: option E (refit `h0` in bootstrap paths) | No. Build the guard (A) and docs (C) only; defer B (bootstrap tolerance) and E | No returned number changes; users are told, not silently corrected; bootstrap warnings/errors at the default tolerance remain |
| 2 | Riskiest assumption: absolute 1e-6 threshold is scale-dependent | Scaled violation: `|lhs - rhs| / max(1, |lhs|, |rhs|) > 1e-6` for equalities (inequalities: scaled violation of the wrong side) | Same meaning at every scale; the a*b case (0.033) is flagged, a tight-tolerance fit (1.65e-11) is not |
| 3 | Blast radius: how the guard surfaces | Classed warning (`RMediation_constraint_violation`) checking `h0` and `h1`; results are still returned; message names the constraint, its violation and the two-fit route | Existing scripts keep running but are flagged and can mute the class; footprint is only `mbco()` calls with a violated constraint (the one nonlinear-constraint test calls an internal helper, not `mbco()`) |
| 4 | Benefit honesty: "exact for ab = 0" in the docs | State both: the smaller -2LL is the exact constrained LRT statistic for ab = 0; its chi-square(1) p-value is conservative when both paths are 0 (intersection-union); mark the p-value statement as standard theory, not verified here | Accurate and defensible; slightly longer |
| 5 | Implementation regret: guard evaluation failure | User override of the recommendation: let the error propagate. Condition recorded: wrap the evaluation so the error names the constraint ("could not evaluate constraint <name> for the violation check"), and test it with a planted unevaluable constraint | Surfaces bad constraints early; adds a new way for an `mbco()` call that worked before to fail (models with exotic constraint formulas); a clear message is the mitigation |

## Follow-up 2026-10-14 (Codex adversarial review)

- **[medium] work order contradicted the scope** (T2 said A, B, C): accepted; T2, T1, T3 and the risks now say A and C only, with B and E in a separately gated follow-up. Decision 1 stands.
- **[high] a feasible fit can still be on the wrong product-null branch**: accepted as a documented limit, not new code. It is the remaining part of issue #35; the guard cannot see it, `MxConstraint@linear` cannot tell linear from nonlinear constraints (FALSE for both), and formula parsing was rejected as brittle. The warning text and `?mbco` will say so and point to the two-fit route. In 8 seeds of this plan's reprex the tight-tolerance fits matched the exact optimum, so the case was not reproduced here.

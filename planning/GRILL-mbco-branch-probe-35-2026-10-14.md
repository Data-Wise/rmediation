# GRILL — warn-only wrong-branch probe (#35 remainder, 2026-10-14)

Target: `planning/RESEARCH-35-wrong-branch-probe-2026-10-14.md` (option 1 of the three put to the maintainer). Three questions, each with a stated recommendation; all three recommended options chosen.

| Q | Topic | Decision |
|---|---|---|
| 1 | Trigger and cost | **Automatic** inside `mbco()` for an `h0` with an equality constraint, after the guard and the #52 refit; one extra fit per involved parameter; **cap at 5 involved parameters**, above which the probe is skipped with a note. No new argument. Rejected: no cap, opt-in argument, separate exported checker |
| 2 | Disclosure | **Classed warning only**, `RMediation_constraint_branch`; no new `MBCOResult` slot. Rejected: warning plus slot, error |
| 3 | Threshold | Flag when a valid candidate's -2LL is lower than the null's by more than **1e-4 absolute**. Rejected: 1e-6 (near the noise floor when branches tie), relative gap |

## Assumptions stated (not asked)

- The probe runs on the `h0` actually used, i.e. after the #52 refit; all three types, once per call (not per bootstrap replicate).
- Only equality constraints are probed; inequalities are skipped.
- Involved parameters are found by perturbing each free parameter by 1e-3 at the **full model's estimates** (not at the null's solution, where a zero path hides the others) and re-evaluating the constraint with `mxRun(useOptimizer = FALSE)`.
- Each candidate drops the constraint, fixes one involved parameter at 0, refits, and counts only if it converged and still satisfies the original constraint (violation <= 1e-6).
- The probe is advisory: any error or non-convergence inside it is skipped silently; it never changes a result or raises an error.
- With several equality constraints, probe each separately; one warning per flagged constraint, naming the best candidate.
- SLSQP only: NPSOL is unavailable in this build and CSOLNP is excluded by the maintainer.

## Consequence

No returned number changes; the guard (#51) and refit (#52) behavior is untouched. A correcting probe (option 2 of the earlier decision) stays unbuilt; this grill does not decide it.

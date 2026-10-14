# PLAN — issue #34: MBCO nonlinear-constraint nulls and OpenMx's feasibility tolerance

**Issue:** [#34](https://github.com/Data-Wise/rmediation/issues/34) (open; findings posted 2026-10-07)
**Status:** planned 2026-10-14, grilled the same day (`planning/GRILL-mbco-feasibility-plan-2026-10-14.md`, 5 decisions folded in below) and adversarially reviewed by Codex (2 findings, both addressed: work order reconciled, wrong-branch limit documented); T0 prototypes run 2026-10-14 (results below); worktree `~/.git-worktrees/rmediation/feature-mbco-tolerance` (branch `feature/mbco-tolerance`) created, no code yet.
**Scope:** OpenMx paths of `mbco()` only (`type = "asymp"`, `"parametric"`, `"semi"`). The SEMFit route is unaffected (it uses `anova()` on medfit fits).

## What is true now (verified 2026-10-14, OpenMx 2.22.11, scratch script)

Twelve simulated datasets (n = 300, a = 0.5, b = 0, so the null ab = 0 is true), model `X -> M -> Y` with `mxConstraint(ind == 0)`, `ind = a*b`:

| Run | Constraint violation `|ab|` at the solution | Gap to the exact LRT (min of the two single-path fits) |
|---|---|---|
| Default feasibility tolerance (0.05) | up to 0.0491 (all 12 non-zero) | statistic understated in 12 of 12; e.g. 0 vs 0.4745, 1.27 vs 4.60, 0.87 vs 3.30 |
| Global `mxOption(NULL, "Feasibility tolerance", 1e-8)` | at most 1.65e-11 | at most 1.9e-9 |
| Model-level `mxOption(model, ..., 1e-8)` | at most 1.65e-11 | at most 1.9e-9 |

- The issue reproduces; the earlier 100-seed result (T below exact in 100 of 100) is consistent.
- **A global setting reaches `mxRun()` on models with no option of their own.** That matters because `mbco_parametric()` and `.mbco_semi()` already set other options through `mxOption(NULL, ...)` and restore them with `on.exit(options(mxOptions = ...))`; the same mechanism can set the tolerance for every bootstrap refit.
- Tightening produced 3 OpenMx status-6 warnings across the 12 fits and 24 constrained refits I ran, so a tighter tolerance may cost some convergence. The effect on bootstrap runs is not measured yet.
- Issue proposal 1 (fix the `mbco()` example) is **moot**: PR #36 replaced the nonlinear example with one linear null per path.

## Options

| # | Change | Effect | Cost / risk |
|---|---|---|---|
| A | **Guard:** after validating inputs, evaluate each `MxConstraint` of `h0` at the fitted solution and warn when the violation exceeds 1e-6 (all three types) | Catches the failure directly, regardless of how the user fitted `h0`; the only option that covers `type = "asymp"` | Needs a generic way to evaluate an arbitrary constraint formula (prototype first); false warnings if a constraint is an inequality that is slack |
| B | **Bootstrap refits:** set the feasibility tolerance to 1e-8 in `mbco_parametric()` and `.mbco_semi()` via the existing `mxOption(NULL, ...)` block | Fixes the refits RMediation controls | Possible extra non-convergence; changes bootstrap results for nonlinear nulls; no new argument |
| C | **Docs:** `?mbco` Details recommend the two-fit route for ab = 0 (a fixed at 0, b fixed at 0, take the smaller -2LL) and tell users to tighten the tolerance on `h0` for nonlinear constraints | No behavior change; the route is exact for ab = 0 | Does not stop a user who ignores the docs |
| D | Expose a `feasibility` argument | Full user control | New public argument, locked once on CRAN |

**Recommendation: A + B + C, not D.** A is the only guard that works for `"asymp"`; B closes the part RMediation owns; C costs nothing. D adds API surface that can be added later if B proves too blunt.

## T0 results (2026-10-14, OpenMx 2.22.11, scratch scripts, not saved in the repo)

**1. Evaluating an arbitrary constraint (open question 1: answered).** An `MxConstraint` stores its expression in `@formula`
(e.g. `ind == 0`; `@alg1`, `@alg2` and `@relation` are `NA` until compiled). Evaluating `lhs` and `rhs` of the formula
with `mxEval(..., compute = FALSE)` on the fitted model and taking `lhs - rhs` works, with the violation defined per operator
(`==`: `|d|`; `<`: `max(d, 0)`; `>`: `max(-d, 0)`).
- Equality `ind == 0` fitted at the default tolerance: violation 0.0332 (flagged at a 1e-6 threshold).
- Two slack inequalities (`ind < 1`, `ind > -1`): violation 0 and 0 (no false warning).
- A binding inequality (`ind > 0.5` that the data cannot satisfy): violation 0.0311, OpenMx status 6 (flagged, appropriately).
- A model with no constraints: nothing to evaluate. Operators other than `==`, `<`, `>` return `NA` and would be skipped.

**2. Bootstrap behavior with a tighter global tolerance (open question 2: answered for this case).** Seeds 1-4, n = 300, a = .5, b = 0
(null true), `R = 60`, user's `h0` fitted at the default tolerance, then `mbco()` with the global tolerance set to 0.05 or 1e-8:

| Type | Tolerance 0.05 | Tolerance 1e-8 |
|---|---|---|
| `"semi"` | **error in 4 of 4 runs**: "Bootstrap replicate N did not converge" | 0 errors |
| `"parametric"` | 1 OpenMx warning per run (4 of 4) | 0 warnings |

- So tightening reduced non-convergence here; it did not add any. This is four seeds and one model; it is not a convergence guarantee.
- **The observed statistic is still wrong in every run** (0 instead of the exact 0.0376 to 0.4745, p = 1): `mbco()` takes the statistic from the user's already-fitted `h0`, which was fitted at the default tolerance, so a global setting inside `mbco()` cannot repair it. B alone therefore does not fix the reported result; it only fixes the bootstrap null distribution. This makes A (the guard) essential and raises a new option:

| # | Change | Effect | Cost / risk |
|---|---|---|---|
| E | In the bootstrap paths, refit `h0` on the original data at the tight tolerance before computing the observed statistic | Fixes the observed statistic for `"parametric"` and `"semi"` | RMediation then refits the user's `h0` (it never does today); `"asymp"` is still unfixable; needs a decision and tests |

**Updated recommendation:** A (guard, all types) + C (docs) first; B only together with E or with a clear NEWS note that the observed
statistic still comes from the user's fit. Decide E before coding B.

## Decisions (from the grill, 2026-10-14; these override the options above)

| Topic | Decision |
|---|---|
| Scope | Build the guard (A) and docs (C) only. **B and E are deferred**: no returned number changes. |
| Threshold | Equality: `|lhs - rhs| / max(1, |lhs|, |rhs|) > 1e-6`; inequalities: the same scaling applied to the wrong-side violation. |
| Form | Classed warning `RMediation_constraint_violation`, checking `h0` and `h1` in all three types (`"asymp"`, `"parametric"`, `"semi"`); results are still returned. The message names the constraint and its violation and points to the two-fit route. |
| Docs wording | The smaller -2LL is the exact constrained LRT statistic for ab = 0; its chi-square(1) p-value is conservative when both paths are 0 (intersection-union test; standard theory, not verified here). |
| Evaluation failures | **User override of the recommendation:** the error propagates. Condition: it is re-raised with the constraint's name ("could not evaluate constraint <name> for the violation check"), with a planted unevaluable constraint in the tests. Risk: an `mbco()` call that worked before can now fail for exotic constraint formulas. |

Plan step T2 therefore reads: implement A, then C (no B, no E). Tests (T1) additionally cover: the scaled threshold on a large-scale constraint, an inequality
slack control, the classed warning on `h1`, and the informative error.

## Open questions to settle before coding

1. **Constraint evaluation (blocks A).** How to evaluate `lhs - rhs` of an arbitrary `MxConstraint` at the solution: `mxEval()` worked for the named algebra `ind` in the prototype; a general `formula` needs its own prototype, including inequality constraints (violation only when on the wrong side).
2. **Bootstrap convergence (blocks B).** Does 1e-8 raise the non-convergence rate of the refits? Measure on the issue's reprex with `R = 200`, both types, against the current statistic and the exact LRT.
3. **Threshold.** 1e-6 is the issue's figure; confirm against the constraint scale (the violation can be large in relative terms for small parameters).
4. **Result change in B.** NEWS must say that bootstrap p-values for nonlinear constraints can change.

## Work order (when you ask for a branch)

| Step | Work | Gate |
|---|---|---|
| T0 | Prototype constraint evaluation (open question 1) and the bootstrap convergence run (question 2); record numbers in this file | done 2026-10-14 (see T0 results) |
| T1 | Tests first, OpenMx-gated: the issue's reprex (3 seeds) must warn with the default tolerance and not warn after tightening; inequality-slack control; scaled-threshold control on a large-scale constraint; warning on `h1`; informative error for an unevaluable constraint; planted defects (guard ignoring constraints; threshold off by 1e4; guard checking only `h0`) | tests red for the right reason |
| T2 | Implement A (guard), then C (docs). **B and E are not part of this work**; they move to a separately gated follow-up (own plan, own PR) | tests green |
| T3 | `devtools::test()` counts, `R CMD check --as-cran` 0/0/note, E2E transcript with the reprex (warning fires at the default tolerance, silent at 1e-8), NEWS (guard only; states that no returned number changes) | quote outputs in the PR |

## Risks

- ~~Behavior change for bootstrap users (B)~~: not in scope after the grill. B and E need their own plan and gate before any returned number changes.
- **The guard does not detect a feasible fit on the wrong product-null branch** (Codex review 2026-10-14; this is the remaining part of issue #35, not a tolerance failure). Mitigation is wording only: the warning text and `?mbco` say that a feasible fit of a product null (`a*b == 0`) may still sit on the larger-statistic branch, and point to the two-fit route. Not detected in code on purpose: `MxConstraint@linear` is `FALSE` for both a linear `a == 0` and a nonlinear `a*b == 0`, so it cannot separate them, and parsing arbitrary constraint formulas is the brittleness issue #35 already rejected. The real fix for that case is the two-fit route and the SEMFit route (`medfit::mbco_sem()`).
- An unevaluable constraint now raises an error from `mbco()` (grill decision 5, user override); the message names the constraint.
- The guard could warn on legitimate near-boundary solutions; threshold and the inequality case need tests.
- Needs OpenMx; tests are skipped without it, as the existing mbco tests are.

## Related

Issue #35 (wrong-branch product nulls) is a separate failure mode; this plan neither fixes nor claims to fix it. Evidence that the wrong-branch case exists: #35's comment (memory_exp: `a1 = 0` branch 221.05 vs `b1 = 0` branch 0.0831). In an 8-seed run of this plan's reprex (true null b = 0) tight-tolerance feasible fits matched the exact optimum in 8 of 8, so that scenario does not show it.

## Release

Feature PR to `dev`; ships with the next CRAN release (hold unchanged). The 1.7.1 candidate is not touched.

# PLAN — issue #34: MBCO nonlinear-constraint nulls and OpenMx's feasibility tolerance

**Issue:** [#34](https://github.com/Data-Wise/rmediation/issues/34) (open; findings posted 2026-10-07)
**Status:** planned 2026-10-14. Evidence below; nothing implemented, no branch yet.
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

## Open questions to settle before coding

1. **Constraint evaluation (blocks A).** How to evaluate `lhs - rhs` of an arbitrary `MxConstraint` at the solution: `mxEval()` worked for the named algebra `ind` in the prototype; a general `formula` needs its own prototype, including inequality constraints (violation only when on the wrong side).
2. **Bootstrap convergence (blocks B).** Does 1e-8 raise the non-convergence rate of the refits? Measure on the issue's reprex with `R = 200`, both types, against the current statistic and the exact LRT.
3. **Threshold.** 1e-6 is the issue's figure; confirm against the constraint scale (the violation can be large in relative terms for small parameters).
4. **Result change in B.** NEWS must say that bootstrap p-values for nonlinear constraints can change.

## Work order (when you ask for a branch)

| Step | Work | Gate |
|---|---|---|
| T0 | Prototype constraint evaluation (open question 1) and the bootstrap convergence run (question 2); record numbers in this file | numbers in hand |
| T1 | Tests first, OpenMx-gated: the issue's reprex (3 seeds) must warn with the default tolerance and not warn after tightening; inequality-slack control; planted defects (guard ignoring constraints; threshold off by 1e4) | tests red for the right reason |
| T2 | Implement A, then B, then C | tests green |
| T3 | `devtools::test()` counts, `R CMD check --as-cran` 0/0/note, E2E transcript with the reprex, NEWS | quote outputs in the PR |

## Risks

- Behavior change for bootstrap users (B). Mitigation: measure first, state it in NEWS.
- The guard could warn on legitimate near-boundary solutions; threshold and the inequality case need tests.
- Needs OpenMx; tests are skipped without it, as the existing mbco tests are.

## Release

Feature PR to `dev`; ships with the next CRAN release (hold unchanged). The 1.7.1 candidate is not touched.

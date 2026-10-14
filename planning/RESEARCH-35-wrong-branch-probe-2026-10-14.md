# RESEARCH — issue #35: how often is the wrong branch hit, and can a generic probe catch it? (2026-10-14)

OpenMx 2.22.11, optimizer **SLSQP** (the default here; NPSOL is not available in this build; CSOLNP deliberately not tested, per the maintainer). lavaan is not involved (only the medfit/SEMFit route uses it). Scratch scripts, not saved in the repo.

## 1. Reproduction on `memory_exp` (single constraint `ind1 == 0`, a1 strong, b1 about 0)

| Start of the null | a1 | b1 | diffLL | status | violation |
|---|---|---|---|---|---|
| unfitted model, default tolerance | 0.0000 | 0.0215 | **221.0455 (wrong branch)** | 0 | 2e-96 |
| unfitted model, tolerance 1e-8 | 0.0000 | 0.0215 | **221.0455 (wrong branch)** | 0 | 2e-96 |
| fitted full model, default tolerance | -3.8057 | 0.0127 | 0.0146 | 6 | 4.8e-2 (guard fires; since PR #52 refit at 1e-8) |
| fitted full model, tolerance 1e-8 | -3.8038 | -0.0000 | 0.0831 (correct) | 0 | 4e-23 |
| `mbco_product_null(full, c("a1","b1"))` | | | 0.0831 | | |

The wrong-branch fit is feasible (violation about 0), converged (status 0) and returns a clean `MBCOResult`, so neither the guard nor the refit of PR #52 can see it. The outcome depends on the start values.

## 2. Frequency (X -> M -> Y, n = 200, a = .5, b varied, null fitted from the unfitted start values at tolerance 1e-8, 60 seeds each)

| b | wrong branch (statistic above the exact min-of-two LRT by more than 1e-6) |
|---|---|
| 0 | 0 / 60 |
| 0.15 | 0 / 60 |
| 0.4 | **28 / 60** (e.g. 35.18 vs exact 23.59; 50.61 vs 35.58) |

Within this design the wrong branch appears when both paths are substantial and the model is started away from the optimum; a statistic is then overstated relative to the exact LRT. On `memory_exp` (b1 about 0) it also occurs and inflates the statistic from 0.08 to 221, so it can turn a non-rejection into a rejection. The sweep did not reproduce that near-null case, so the rates above are not a general frequency estimate.

## 3. A generic probe (no formula parsing)

1. Find the free parameters the constraint depends on by perturbing each by 1e-3 and re-evaluating the constraint (`mxRun(useOptimizer = FALSE)`) **at the full model's estimates**. Doing it at the null's own solution fails: at `a = 0` the constraint `a*b` does not move with `b`, so only `a` is found.
2. Drop the constraint, fix each involved parameter at 0 in turn, refit.
3. A candidate counts only if it satisfies the original constraint (checked numerically, violation <= 1e-6) and converged.
4. Flag when a valid candidate has a lower -2LL than the null by more than 1e-6.

Result: **28 / 28 wrong-branch cases flagged, 0 false positives in the 120 runs where the constraint fit was already optimal** (b = 0 and b = .15). Cost: one extra fit per involved parameter (two here). A first version that kept the constraint while fixing a path stalled (the constraint gradient vanishes) and flagged 0 / 28; it was discarded.

## 4. What this means for #35

- The earlier objection to detection ("detecting a product inside an arbitrary OpenMx constraint is brittle") applied to parsing the formula. The probe above evaluates the constraint numerically, so it does not parse; it works for any equality constraint where fixing one parameter at 0 satisfies it (products).
- It proves h0 is **not** the constrained optimum (a feasible candidate beats it); it does not prove a returned h0 *is* optimal, and it only searches candidates reachable by fixing one involved parameter at 0.
- Options if pursued (not decided): (a) warn only, class e.g. `RMediation_constraint_branch`, pointing to `mbco_product_null()`; (b) correct like PR #52 (use the better candidate, record it in a slot, warn), which changes returned numbers again and needs its own grill; (c) neither (the helper from PR #53 stands as the documented route).
- Untested: NPSOL (unavailable here), CSOLNP (excluded by the maintainer), models with several constraints, constraints involving more than 3 parameters, inequality constraints.

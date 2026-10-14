# GRILL — MBCO follow-ups B and E (2026-10-14)

Target: `planning/PROPOSAL-mbco-b-e-35-2026-10-14.md`. Seven questions, one at a time; each had a stated recommendation.

| Q | Topic | Decision | Recommended? |
|---|---|---|---|
| 1 | Scope | B+E in one plan; **#35 gets its own later plan** (new exported API is a separate decision) | yes |
| 2 | Trigger | Refit `h0` and tighten the bootstrap tolerance **only when the guard fires** (B2 + E2); clean fits and constraint-free models stay byte-identical | yes |
| 3 | `type = "asymp"` | Stays **warn-only**; never refits (parity with the SEMFit route) | yes |
| 4 | Refit failure | If the 1e-8 refit fails or still violates, **fall back to the user's fit**, keep the guard warning, add a note that a refit was attempted; never error | yes |
| 5 | Disclosure | **User override:** a **new `MBCOResult` slot** records the refit (recommendation was a classed warning with no slot) | no |
| 6 | Slot shape | **Slot and a classed warning `RMediation_h0_refit`** (old and new statistic, tolerance); slot is `NULL` when no refit | yes |
| 7 | Evidence gate | **100 seeds, `R = 200`**, criteria fixed now (below) before any code | yes |

## Conditions attached to the override (Q5)

- The slot is optional with a default, so existing `MBCOResult(...)` calls still construct; it is documented in `?MBCOResult` and shown by `print()`/`summary()`.
- A new slot on an exported S7 class is locked once on CRAN, so name and contents get one more review before merge (suggested contents: `tolerance`, `statistic_before`).
- The warning stays (Q6) so a reader of `p_value` alone still sees the change.

## Q7 pass criteria (fixed before running)

1. Non-convergence count at tolerance 1e-8 is no higher than at the default 0.05, for both `"parametric"` and `"semi"`.
2. The refit observed statistic is within 1e-6 of the exact two-fit LRT (min of the `a = 0` and `b = 0` fits) in at least 99 of 100 seeds.
3. A failure of either criterion re-scopes the plan; it is not coded around.

## Still open for the plan step

- Where the refit lives (`.mbco_compare()` vs the two bootstrap functions) and how `.mbco_semi()`'s covariance step sees the refit `h0`.
- Whether `type = "asymp"` should say, in the guard warning, that it will not refit.
- #35: separate plan; options W1-W5 stay in the PROPOSAL, no decision taken.

## Q7 result (T0 study, 2026-10-14, OpenMx 2.22.11, n = 300, a = .5, b = 0, seeds 1-100, R = 200)

Scratch script, not saved in the repo. User's `h0` fitted at the default tolerance; the bootstrap ran with the global tolerance set to 0.05 or 1e-8.

| Measure | Result |
|---|---|
| Observed statistic from the user's `h0` below the exact two-fit LRT by more than 1e-6 | 100 / 100 |
| Refit of `h0` at 1e-8: within 1e-6 of the exact LRT | **99 / 100** (max gap 1.5e-6, seed 59); max constraint violation after refit 7.5e-9 |
| `parametric`, tolerance 0.05: runs with an OpenMx warning / errors | 100 / 0 |
| `parametric`, tolerance 1e-8: runs with a warning / errors | 0 / 0 |
| `semi`, tolerance 0.05: errors | **100 / 100** |
| `semi`, tolerance 1e-8: errors | **19 / 100** |

**Criteria: both pass** (non-convergence at 1e-8 below that at 0.05 for both types; refit within 1e-6 in 99 of 100). The plan is not re-scoped.

**Finding the criteria did not anticipate:** `semi` at 1e-8 still stops in 19 of 100 runs (about 0.1% of replicates, since the run stops at the first failed one; a rerun of three failing seeds with another RNG stream passed, so it is replicate-level and stochastic). B+E reduces `semi` failures from 100% to about 19% on this model; it does not remove them. `.mbco_semi()` keeps its documented "stops at the first failed replicate" behavior, so the plan must say so, and a retry policy would be a separate decision.

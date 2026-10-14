# PROPOSAL — MBCO follow-ups after the guard (B, E, #35)

**Date:** 2026-10-14. **Context:** the guard (PR #51, dev `8e904bd`) only warns. Three failure modes remain; none changes a returned number yet.
**Standing constraints:** no CRAN submission, PR #46 stays draft, no `dev -> main`; no new exported API without a grill decision.

## What is still wrong (evidence in `PLAN-34-...md` and issue #35)

| Id | Failure | Affects | Today |
|---|---|---|---|
| B | Bootstrap refits of `h0` use OpenMx's default feasibility tolerance (0.05) | `type = "parametric"`, `"semi"` | T0: `semi` errored 4 of 4 at 0.05, 0 of 4 at 1e-8; `parametric` warned 4 of 4 vs 0 |
| E | The observed statistic comes from the user's already-fitted `h0` | all three types | Guard warns; statistic still understated (0 vs exact 0.4745 in the reprex) |
| #35 | A feasible `a*b == 0` fit can sit on the larger-statistic branch | all three types | Documented only; the guard cannot see it (a feasible point has zero violation) |

B and E interact: tightening only the bootstrap while the observed statistic stays understated gives an inconsistent test (exact null distribution against a deflated statistic).

## Options

### B (bootstrap tolerance)
| # | Option | Effect | Risk |
|---|---|---|---|
| B1 | Set 1e-8 inside the existing `mxOption(NULL, ...)` block of `mbco_parametric()` / `.mbco_semi()`, restored on exit | Fixes bootstrap refits; no new argument | Changes bootstrap p-values for nonlinear nulls; 4-seed convergence evidence only |
| B2 | B1 only when a constraint is present | No change for models without constraints | Slightly more code |
| B3 | New `feasibility` argument | User control | New public surface, locked once on CRAN |

### E (observed statistic)
| # | Option | Effect | Risk |
|---|---|---|---|
| E1 | Refit `h0` at 1e-8 from its own estimates in the bootstrap paths, then take the statistic | Consistent test for `parametric`/`semi` | RMediation starts refitting user models; `asymp` still unfixable |
| E2 | E1 only when the guard fires | Zero change on clean fits | Two code paths; refit can fail or move the fit |
| E3 | Refit in all three types, `asymp` included | One rule everywhere | Breaks "never refits" parity with the SEMFit route |
| E4 | Do nothing; guard plus docs are the contract | No behavior change | Users keep a deflated statistic after a warning |

### #35 (wrong branch)
| # | Option | Effect | Risk |
|---|---|---|---|
| W1 | Docs only (done in #36, #51) | Nothing new | Users who ignore docs get a wrong test |
| W2 | Exported helper, e.g. `mbco_product_null(h1, paths = c("a", "b"))`: builds the two linear nulls from the unfitted model by label, runs `mbco()` on each, returns the min statistic with df 1 | Exact, no formula parsing, user names the paths | New API (grill needed); duplicates what `medfit::mbco_sem()` does for SEMFit |
| W3 | Accept `h0 = list(null_a, null_b)` in `mbco()` and return the smaller statistic | Same math, no new function | Changes a generic's contract; S7 dispatch on `class_any` hides the shape; harder to document |
| W4 | Guard probe: for a nonlinear equality, refit with each referenced label fixed at 0 and warn if the min is smaller | Detects the wrong branch automatically | Brittle (the objection in #35); only valid for products |
| W5 | Wait for the medfit route to mature | No RMediation work | Leaves the OpenMx path exposed indefinitely |

## Recommendations

## Quick wins (< 30 min)
1. Record B/E/#35 as a decision tree in `.STATUS` — one line each so a later session does not re-derive them.

## Medium effort (1-2 hrs)
- [ ] One plan for **B2 + E2**: tighten and refit only when a constraint is violated, so clean fits and constraint-free models are byte-identical; extend the T0 convergence run to 100 seeds and `R = 200` before coding.

## Long-term (future sessions)
- [ ] **W2** only if the grill confirms users need the exact product test inside RMediation rather than via medfit; otherwise W1 plus the medfit route stand.

## Recommended next step
-> Grill B+E as one plan (B2 + E2). Reason: it removes the numeric error the guard only reports, without new API; #35 is a separate design question (new exported function) and should not be bundled.

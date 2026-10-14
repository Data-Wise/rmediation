# GRILL — PLAN-33 gap review (ml_omitted_confounder)

**Target:** `planning/PLAN-33-gap-review-2026-10-13.md` (spec: `planning/SPEC-33-ml-omitted-confounder.md`, issue #33)
**Date:** 2026-10-13. Interactive grill, one question at a time, `--no-refine`.

## Decisions

| # | Branch | Decision | Consequence |
|---|---|---|---|
| 1 | Riskiest assumption: unverified T1-T12 targets | Drop any target the paper does not confirm (or that cannot be checked); list it as unverified in SPEC-33 | Fewer known-answer tests, no invented oracle; validation leans on an independent numerical oracle |
| 2 | Weakest recommendation: independent review (step 3) | Keep it, run once after the paper check with the paper note in hand | One extra pass; reviewer can test claims against the paper |
| 3 | Benefit honesty: tolerance 0.0005 equals the rounding half-width | Tolerance 0.0005 + 1e-9 for paper endpoints, plus an independent oracle (grid endpoints recomputed from simulated-data regressions) | Small extra test; a paper mismatch is no longer fatal to validation |
| 4 | Reversibility: export of `ml_admissible()` (G7) | Reversed the plan's recommendation: keep it internal in v1 | Smaller public surface; can be exported later at no cost, whereas a CRAN export is locked |
| 5 | Workflow and blast radius: handling the fetched paper/supplement | User override of the recommendation: commit the supplement to the repo. Condition recorded: each download needs per-file approval (name, source, size); confirm the supplement's terms permit redistribution before committing; keep it outside the built package (build-ignored) unless the tests need it | Reproducible fixture; adds third-party material and a licensing check to the plan |
| 6 | G3: `r_za` semantics | Single numeric applies to both levels; list form sets levels separately; a level with no data is skipped; `print()` states the levels and `r_za` values used | Concise common case, visible in the output |
| 7 | G8: example grid | Measure at T6; use the default grid (step 0.01) in the example if it runs under about one second, else step 0.05 | No premature coarsening; one timing step |

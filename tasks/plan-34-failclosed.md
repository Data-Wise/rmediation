# Plan: fail closed when a violated h0 cannot be refit

Date: 2026-10-14. Base: `dev`. Decisions: `planning/GRILL-mbco-refit-failclosed-2026-10-14.md`. Context: `tasks/plan-34-be.md` (shipped in #52).

## Behavior

In `mbco()`, when `.mbco_refit_h0()` returns a failure (`model = NULL`), stop with a classed error `RMediation_h0_refit_failed` (class vector `c("RMediation_h0_refit_failed", "error", "condition")`): names the violated constraint(s), the reason (`refit$failure`), and the remedies (refit at 1e-8 yourself, or `mbco_product_null()`). No result is returned. A successful refit, a clean `h0` and the `h1` warning are unchanged.

## Slices (tests first)

1. **Behavior.** Change the failure test in `test-mbco-refit-wiring.R` to expect the classed error for each type (message names the constraint and the reason, mentions both remedies, no result); add: error class catchable via `tryCatch`; refit still succeeds -> unchanged; planted defect (code path that falls back) is caught. Implement in `R/mbco.R`. Acceptance: full suite vs the post-#54 baseline (917 expectations, 0 failed, 10 skipped, 2 warnings) with only the intended test changes.
2. **Docs and PR.** `?mbco` (replace the fallback paragraph), NEWS (the 1.7.1-dev refit bullet: a violated `h0` that cannot be repaired is an error), `devtools::document()` with roxygen churn reverted, spelling, strict `R CMD check`, E2E transcript (planted failing refit shows the error; the reprex still refits). PR to `dev`; merge only on instruction.

## Risks

- A call that returned a number on a failed refit now errors (accepted: no released behavior; rare).
- The error fires before bootstrap work, so no runtime cost on the failure path.

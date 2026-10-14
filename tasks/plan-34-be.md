# Plan: MBCO refit of a violated `h0` (B + E of issue #34)

Date: 2026-10-14. Base: `dev`. Decisions: `planning/GRILL-mbco-b-e-2026-10-14.md` (Q1-Q7, Q3 revisited). Evidence: Q7 result there. #35 is out of scope.
The finished guard plan is `tasks/plan-34.md`; the coverage plan is `tasks/plan.md`; this file touches neither.

## Behavior to build

When the guard finds `h0` violated (scaled > 1e-6), all three OpenMx types:
1. refit `h0` from its own estimates with model-level `"Feasibility tolerance"` 1e-8;
2. if the refit converges and the violation is <= 1e-6: use it for the observed statistic and the bootstrap; set `MBCOResult@refit`; warn `RMediation_h0_refit` (old and new statistic, tolerance);
3. else: keep the user's fit, keep the guard warning, add a note that a refit was attempted and failed (never an error);
4. a clean `h0` or no constraints: byte-identical to today (slot `NULL`).
`h1` is only checked, never refit. The SEMFit route is unchanged. No new argument.

## Open questions to settle inside the slices (do not assume)

- Does a bootstrap refit of `h0` inherit the model-level tolerance of the refit `h0`? If yes, B comes free from E and no global `mxOption` change is needed; if no, set 1e-8 in the existing `mxOption(NULL, ...)` block only when a refit happened. Measure in slice 2.
- Exact slot contents and name (suggested `refit`: `NULL` or a list with `tolerance`, `statistic_before`, `statistic_after`); one more review before merge (the slot is locked once on CRAN).

## Resolved in slice 2 (2026-10-14)

- **Inheritance: yes.** A refit `h0` carrying the model-level tolerance 1e-8 makes `mbco(type = "parametric")` emit no OpenMx warnings and `type = "semi"` run without error at the default global tolerance (seeds 1-3, `R = 10`; the user's own `h0` gave warnings in 100/100 and semi errors in 100/100 at `R = 200`). So **B needs no global `mxOption` change**; E alone supplies it. Slice 4 re-checks this at scale (100 seeds, `R = 200`).

## Slices (tests first, each leaves the suite green)

1. **Slot, backward compatible.** `MBCOResult` gets an optional `refit` property defaulting to `NULL`; `print`/`summary` show a refit line only when non-`NULL`; `$`/`[[`/`names` expose it. Acceptance: every existing `MBCOResult(...)` call and the SEMFit route are unchanged; new tests for construction without the slot, with it, and printing.
2. **Refit helper `.mbco_refit_h0()`** (in `R/mbco-compare.R`): returns the refit model and info, or `NULL`. Tests: reprex seeds 1-3 refit to within 1e-6 of the exact two-fit LRT (known-answer, the Codex regression test: 0 -> 0.4745 for seed 1); constraint-free and clean models return `NULL`; refit failure falls back; planted defects (never refits, refits `h1`, ignores the threshold) each fail a named test. Settle the inheritance question here.
3. **Wire into `mbco()` for all three types.** Refit once before the `type` branch so `.mbco_compare()`, `mbco_asymp()`, `mbco_parametric()` and `.mbco_semi()` see the same `h0`; attach the slot; emit the warning. Tests per type (`R = 3`), `h0` clean vs violated, options restored on exit.
4. **Checkpoint:** full suite vs the PR #51 baseline (761 expectations, 0 failed, 10 skipped, 2 warnings), then a repeat of the 100-seed study through the public `mbco()` (criterion: refit statistic within 1e-6 of exact in >= 99/100, `parametric` 0 warnings, `semi` failure rate reported, not hidden).
5. **Docs and NEWS.** `?mbco` (when it refits, fallback, slot, that `asymp` refits too, `semi` still stops at the first failed replicate, #35 limit), `?MBCOResult`, NEWS (a returned number now changes when the guard fires: say so plainly), `devtools::document()` with roxygen churn reverted, spelling, strict `R CMD check --as-cran`, E2E transcript.
6. **Checkpoint 3:** PR to `dev`; merge only on instruction.

## Risks

- A returned number changes for the first time, but only on fits the guard already flags; NEWS must state it.
- `semi` still errors in about 19% of runs at 1e-8 (T0); document it, no retry policy here.
- A new exported slot is permanent once on CRAN; CRAN submission is on hold, so the review window is open.
- Refit may move a fit onto the other branch of a product null; #35 stays open and is documented.

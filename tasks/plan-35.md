# Plan: `mbco_product_null()` (issue #35)

Date: 2026-10-14. Base: `dev`. Decisions: `planning/GRILL-mbco-product-null-35-2026-10-14.md`. Earlier plans: `tasks/plan-34.md`, `tasks/plan-34-be.md` (both finished), `tasks/plan.md` (unrelated coverage plan).

## Behavior

`mbco_product_null(h1, paths, ...)`: for each label in `paths`, copy the fitted `h1`, fix that parameter at 0, run `mbco(h0_i, h1, ...)`; return the `MBCOResult` of the branch with the largest p-value (first on ties) with `@branch` set to its label.

## Slices (tests first; each leaves the suite green)

1. **`branch` slot.** Optional `MBCOResult` property, `default = quote(NULL)` (S7 0.2.2 turns a bare `NULL` default into `list()`), validated as a single string; shown by `print()`/`summary()` only when set; exposed by `$`/`[[`/`names`. Acceptance: all existing constructions unchanged; new tests like `test-mbco-refit-slot.R`.
2. **Helper, `type = "asymp"`.** Validation errors (see the grill file). Known answers: `memory_exp` -> 0.0831, df 1, `@branch == "b1"`; synthetic seeds match the exact two-fit LRT; three paths (serial) work. Planted defects, each failing a named test: min p instead of max p (returns 221.05), ignoring a path, wrong df.
3. **Bootstrap types.** `type = "parametric"` and `"semi"` with small `R`: arguments forwarded, p = max over branches, options restored, `RMediation` refit machinery not triggered (no constraints).
4. **Docs and wiring.** New Rd, `_pkgdown.yml` reference entry, `?mbco` and the guard warning point to the helper, `?MBCOResult` documents `branch`, NEWS, README Key Functions row, `?mbco` example using `memory_exp`, spelling, `devtools::document()` with the roxygen 8.1.0 churn reverted (NAMESPACE export added by hand).
5. **Checkpoint and PR.** Full suite vs the post-#52 baseline (853 expectations, 0 failed, 10 skipped, 2 warnings), strict `R CMD check --as-cran --run-donttest --no-manual`, E2E transcript on `memory_exp` showing the single-constraint wrong branch (221.05) against the helper (0.0831); PR to `dev`; merge only on instruction.

## Risks

- A new export and a new slot are permanent once on CRAN (submission is held).
- Conservative p-value when more than one path is 0 (documented as standard theory, not verified).
- Bootstrap types run `R` replicates per branch, so cost scales with the number of paths.

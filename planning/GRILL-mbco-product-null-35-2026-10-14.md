# GRILL — issue #35, wrong branch of a product null (2026-10-14)

Target: `planning/PROPOSAL-mbco-b-e-35-2026-10-14.md` (options W1-W5). Three questions, each with a stated recommendation; all three recommended options chosen.

| Q | Topic | Decision |
|---|---|---|
| 1 | Approach | **W2:** an exported helper that takes explicit path labels. Rejected: W3 (list of `h0`; changes a generic's contract), W1 (docs only; silent wrong answers remain), W5 (wait for medfit) |
| 2 | Return value | The **`MBCOResult` of the binding branch (largest p-value)**, plus a new optional **`MBCOResult@branch`** slot (`NULL` by default, like `@refit`). Rejected: plain list of branches (user can pick the wrong one), attribute (lost, not printed) |
| 3 | Name and signature | **`mbco_product_null(h1, paths, ...)`**: `paths` = character labels (>= 2) of free parameters of the fitted `h1`; `...` forwarded to `mbco()` (`type`, `R`, `alpha`, ...) |

## Why the p-value is the maximum over branches

The product null is a union of single-path nulls (`a = 0` or `b = 0`, or any of `a1, a2, b` for a serial product). A test of a union rejects only if every single-path null is rejected (intersection-union test), so p = max over the branch p-values. For `type = "asymp"` that equals the smaller statistic with chi-square(1) (what `?mbco` already tells users to do by hand); for the bootstrap types it is the generalization. Conservative when more than one path is 0 (standard theory, not verified here).

## Assumptions stated (not asked; no concrete alternative worth a question)

- Each branch fixes one path at 0 in a copy of the fitted `h1` (`omxSetParameters(free = FALSE, values = 0)`). A fixed parameter is exact, so there is no feasibility-tolerance problem, and the refit machinery of #52 is not involved (no constraint).
- Errors, not warnings, for: `h1` not an `MxModel`, `paths` not a unique character vector of length >= 2, or a label that is not a free parameter of `h1`.
- Oracle: the `memory_exp` fixture (`a1 = 0` branch 221.0455, `b1 = 0` branch 0.0831, in `tests/testthat/test-mbco-memory-exp-oracle.R`) must return 0.0831 with df 1 and `@branch == "b1"`.
- OpenMx path only. The SEMFit route is unchanged; `medfit::mbco_sem()` already does this for medfit fits.
- `mbco()` itself is not changed to detect product constraints (the brittleness #35 rejected). The guard warning and `?mbco` point to the helper.

## Cost accepted

One new exported function and one more optional slot on `MBCOResult`, both locked once on CRAN. CRAN submission is on hold, so the review window is open.

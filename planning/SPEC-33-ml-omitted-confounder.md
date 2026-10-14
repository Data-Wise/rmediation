# SPEC-33 — `ml_omitted_confounder()` (multilevel omitted-confounder sensitivity)

**Issue:** [#33](https://github.com/Data-Wise/rmediation/issues/33) (its body is the draft spec; this file is the plan around it)
**Branch:** none yet. Create `feature/ml-omitted-confounder` off `dev` in a worktree when work starts (a separate instruction).
**Status:** planned 2026-10-13, nothing implemented. Release: lands on `dev` for 1.8.0; it is not in the 1.7.1 candidate, and CRAN submission is on hold.
**Created:** 2026-10-13

---

## Context

Add a sensitivity analysis for an omitted confounder Z of the mediator-outcome path in two-level (1-1-1)
mediation, after Tofighi & Kelley (2016, *Multivariate Behavioral Research* 51(1), 86-105). The issue gives
the model, API, known-answer targets T1-T12, validation rules and an implementer checklist. This plan adds
what the issue does not: a numerical check of its math, gaps to close before coding, and an ordered task list.

## Evidence (checked 2026-10-13, synthetic data, n = 200,000, one seed)

The numbers below are from a scratch script, not saved in the repo.

| Claim in the issue | Check | Result |
|---|---|---|
| `a = a* - d_MZ * d_ZA` | `lm(m ~ a)` vs `lm(m ~ a + z)`, `d_ZA = cov(z,a)/var(a)` | both sides 0.1260763 |
| `b = b* - d_YZ * s_ZM` | `lm(y ~ a + m)` vs `lm(y ~ a + m + z)` | both sides 0.1289833 |
| Coefficients as `solve()` on sub-blocks of the covariance matrix | `d_MZ`, `s_ZM`, `d_YZ` from `solve(V[x,x], V[x,y])` | match the `lm` coefficients |
| Screen `r' R^-1 r < 1` equals positive definiteness of the 4x4 | observed matrix and a planted bad `r` | 0.327 (PD) and 3.58 (not PD) |
| A per-coordinate screen (`|r| < 1`) is too weak | planted `r = (.9, .9, -.9)` passes `|r| < 1` | admitted, but not PD |

Grid size at the default settings is 30,603 rows per level, so cost is not a concern.

## Gaps to close before coding

1. **(Closed 2026-10-13, see PLAN-33.)** The fixture values were not in the issue. T1-T12 depend on the paper's between and within covariance
   estimates of (m, y, x) from the public supplement, and the issue names them without listing them. Without
   them T1-T12 cannot run. Get them from the supplement (needs your permission to download) or from you;
   record the source and the (m, y, x) order in the test file. Everything else can be built and tested on synthetic inputs first.
2. **The symmetry test needs a symmetric grid.** Flipping the sign of Z flips all three correlations, so the
   range at `-r_za` equals the range at `+r_za` only because the default `(r_zm, r_zy)` grid is symmetric about 0.
   Test it that way and say so; do not state it as a general identity.
3. **`r_za` per level.** The signature allows `r_za` as a list with `between` and `within`. Define what a
   single numeric means (applied to both levels) and what a missing level means (not computed).
4. **The within-level random-slope covariance term is set to zero** per the paper's illustration. State it in
   `?ml_omitted_confounder` and `print()`.
5. **Methods on base generics.** `print`, `summary`, `plot` and `as.data.frame` follow the
   `MBCOResult_methods.R` pattern; check it before writing the new methods file.

## Design decisions (from the issue, kept)

- Clean-room: `solve()` on sub-blocks of the 4x4 matrix of (A, M, Y, Z), rescaled by the SDs. Do not
  transcribe the supplement's closed form.
- S7 class `MLOmittedConfounder`, registered with `S7::S4_register()` in `R/zzz.R` and defined in `R/00_classes.R`
  beside `MBCOResult`.
- snake_case names (`ml_omitted_confounder`, `ml_admissible`), checkmate validation in the style of `R/utils_validation.R`,
  base graphics only, no new dependencies.
- Default screen `"pd"`: points failing `r' R^-1 r < 1` get `ab_adj = NA`.
- v1 out of scope: lavaan/Mplus extractors, other designs (2-1-1, 2-2-1, 1-1-2), several confounders,
  single-level partial-R2 methods, confidence bands.

## Implementation order (test first)

| Step | Work | Gate |
|---|---|---|
| T0 | Obtain fixture values; write `tests/testthat/test-ml-omitted-confounder.R` with T1-T12 and the controls below, all red | file runs, every test fails for the right reason |
| T1 | `ml_admissible()` and the coefficient helpers | identity and screen tests green |
| T2 | `ml_omitted_confounder()` core and grid, one level | positive control and range tests green |
| T3 | Both levels, `r_za` handling, `var_order` | order-trap and validation tests green |
| T4 | `MLOmittedConfounder` class, `print`, `summary`, `as.data.frame` | method tests green |
| T5 | `plot` (`heat`, `region`) | plot runs on a null device; one planted-boundary check |
| T6 | Synthetic roxygen example, NEWS bullet, pkgdown reference entry, `devtools::document()` | doc build clean |
| T7 | Gates: `devtools::test()` counts, `R CMD check --as-cran` 0/0/0, E2E transcript that reproduces T1-T12 from a clean session | quote outputs in the PR |

## Test plan (tolerances fixed in advance)

- **Known answers T1-T12:** `abs(x - target) <= 0.0005`, full grid, `screen = "none"`, targets as in the issue.
- **Positive control:** `r_zm = r_zy = 0` returns the unadjusted effect to 1e-12.
- **Planted defects** (each must fail a test): swapped `var_order` handling; screen weakened to `|r| < 1`; sign error in
  `a_adj`; `b_adj` using `s_ZM` from the wrong regression.
- **Symmetry:** equal ranges at `+r_za` and `-r_za` on a symmetric grid.
- **Validation:** at least 6 error tests (non-PD `R`, `|r| >= 1`, non-finite `a`/`b`, asymmetric `cov`, bad `cor` diagonal or `sd`, unknown `screen`, both levels NULL).

## Release plan

- Feature PR to `dev` only, merged on your instruction, with the E2E transcript and gate outputs in the body.
- Ships with the next CRAN release (1.8.0, a new export). Nothing here changes the 1.7.1 candidate or lifts the hold.
- Estimate: about 12-13 hours, per the issue.

## Open questions

- Source and permission for the supplement's covariance values (blocks T1-T12 only).
- Decided in the grill (`GRILL-ml-omitted-confounder-plan-2026-10-13.md`): `ml_admissible()` internal in v1; example grid measured at T6; single `r_za` applies to both levels with `print()` naming what was used; T1-T12 targets unconfirmed by the paper are dropped; paper endpoints use tolerance `0.0005 + 1e-9` plus an independent regression-based oracle; supplement may be committed after a redistribution check and per-file download approval.

- Fixture precision (2026-10-13): the supplement prints covariances to 3 decimals; T1-T12 reproduce within 0.0009 (10 of 12 within 0.0005). Use tolerance 0.001 for rounded-fixture tests and document why.

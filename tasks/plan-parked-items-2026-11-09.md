# Implementation Plan: the five parked items

Status: COMPLETE 2026-11-09 (T1 #167, T4 #168, T2 #169, T3 #170 merged; D2 recorded: `ml_admissible()` stays internal). Was: APPROVED 2026-11-09 (all five recommendations accepted). Read-only research on `dev` at `9bd02bd`; nothing implemented. The task list is `tasks/todo-parked-items-2026-11-09.md`. Saved under dated names because `tasks/plan.md` is a finished 2026-10-12 plan (0 unchecked tasks) and this repo keeps one dated file per plan.

## Overview

There are no open GitHub issues. The open work is the five items parked at the end of `tasks/plan-bugs-and-docs-2026-11-09.md`. Research changed what two of them are:

| Item | What the code shows | Plan |
|---|---|---|
| Undocumented `p` in the formula-route `ci()` result | `R/confintMC.R:13-14`: `p = 2*min(P(q>0), 1-P(q>0))`, a two-sided p-value read off the simulated sampling distribution of the estimate against 0. It is the "P Value" printed on the density plot. It saturates at 0 for any clearly nonzero effect (that is the `0` seen earlier) and is not a null-distribution test. | **T1**: document it, with that caveat. Do not drop it: removing it changes the output shape. |
| `pprodnormal3()` upper-tail precision | Only the lower CDF exists (no `lower.tail`). At `mean = c(1,1,1)`, `q = 30`, `1 - p` is 7.55e-05 and the CDF is accurate only to absolute `tol`, so tails below about 1e-8 cannot be resolved. `pprodnormal()` already solved this with a direct upper-tail integral (NEWS, #60). | **T2**: add `lower.tail = TRUE`, integrate the complement directly. Additive, default unchanged. |
| `qprodnormal3()` | No exported quantile function for three normals. The S7 `dist_quantile()` method already inverts the CDF by root-finding with a cache (`R/prod3_core.R:85`). | **T3**: export a function over that machinery, with `p` vectorized and `lower.tail`. Needs T2 for upper-tail quantiles. |
| Export `ml_admissible()` | It is an internal helper that returns the quadratic form `r' R^-1 r` (admissible when below 1), so the name misleads. Users already get an `admissible` column from `ml_omitted_confounder()`. | **D2**: recommend not exporting; record the decision. No code task. |
| Stale `cran-comments.md` | Describes 1.7.0 (Aug 2026), last touched 2026-08-22. It is a CRAN-candidate file and no candidate exists while the hold stands. | **T4**: add a one-line banner naming it stale; regenerate at the next CRAN candidate. |

## Dependency graph

```
T1 (ci p docs)        independent
T2 (lower.tail) ----> T3 (qprodnormal3)
T4 (banner)           independent
D2 (record only)      independent
```

T1, T2, T4 touch different files and can be done in any order; T3 waits for T2. One PR each, `dev` as base, squash.

## Architecture decisions

- **T2 stays additive.** `lower.tail = TRUE` is the default, so existing calls return identical values; a regression test pins that.
- **T2's independent oracle** is a one-dimensional integral for independent factors: `P(X1*W > q)` with `W = X2*X3` using `dprodnormal()` and `pnorm()` in `integrate()`. Monte Carlo cannot reach tails near 1e-10, so it is not the oracle there; it is used only for the mid-range.
- **T3 reuses the existing inversion** instead of a second root-finder, so the function and `dist_quantile()` cannot disagree.
- **Nothing is released by this plan.** T2 and T3 add exported API, so a release after them is 1.11.0 (user's call; the CRAN hold is unchanged).

## Tasks

### Phase 1: independent items

**T1: document the `p` element of the formula-route `ci()` result.** Scope S.
- Acceptance: `?ci` Value section lists `p`, says what it is (two-sided, sampling distribution of the estimate against 0), that it is 0 when all draws share a sign, and that it is not a null-distribution test (point to `mbco()`); the lavaan article's formula-route paragraph mentions it.
- Verify: new test pins `p == 2*min(mean(sim > 0), 1 - mean(sim > 0))` for a seeded run (independent recomputation from `attr`-free simulation), and `p == 0` for a large-effect case; planted defect (change `> 0` to `>= 1`) fails the test; `check-docs.R` current; `check_pkgdown()` clean.
- Files: `R/ci.R` (roxygen), `man/ci.Rd`, `tests/testthat/test-ci-*.R`, `vignettes/articles/indirect-effects-lavaan.Rmd`.

**T4: banner on `cran-comments.md`.** Scope XS.
- Acceptance: first line says the file describes 1.7.0 and must be regenerated at the next CRAN candidate; nothing else changes; `.STATUS` notes it.
- Verify: `git diff` shows one added line; file stays in `.Rbuildignore`.
- Files: `cran-comments.md`, `.STATUS`.

### Phase 2: `pprodnormal3()` tails

**T2: `lower.tail` for `pprodnormal3()`.** Scope M.
- Acceptance: `pprodnormal3(q, ..., lower.tail = FALSE)` integrates the complement directly; lower and upper sum to 1 within `tol` across the grid; the upper tail at `q = 30`, `mean = c(1,1,1)` matches the oracle to a relative error under 1e-6 and a tail near 1e-10 is nonzero and correct; default calls unchanged bit for bit; works with vector `q`, `diagnostics`, point masses, the `"hcubature"` cross-check path.
- Verify: known-answer against the oracle; additivity; regression pin on default output; planted defect (return the lower tail for `lower.tail = FALSE`) fails; full suite 0 failed; `check-local.sh` PASS; lintr clean.
- Files: `R/prod3_core.R`, `man/pprodnormal3.Rd`, `tests/testthat/test-prod3-*.R`, `NEWS.md`.

### Checkpoint: after T1, T4, T2
- [ ] Full suite 0 failed, `check-local.sh` PASS, lintr 0 findings, docs current, consumer smoke test (missingmed, medsim) unchanged.

### Phase 3: quantile function

**T3: export `qprodnormal3()`.** Scope M. Depends on T2.
- Acceptance: signature `qprodnormal3(p, mean, cov, lower.tail = TRUE, tol, ...)` consistent with `pprodnormal3()`; `p` vectorized with names kept; `p` outside [0,1] and non-finite rejected with a clear message; agrees with `dist_quantile(ProductNormal3(...))`; round trip `pprodnormal3(qprodnormal3(p)) == p` within `tol` for `p` from 1e-8 to 1 - 1e-8 and both tails.
- Verify: round-trip grid, agreement with the S7 method, boundary `p = 0, 1` (`-Inf`, `Inf`), planted defect (swap tails) fails; `pkgdown::check_pkgdown()` clean after adding it to the `_pkgdown.yml` reference index; NEWS, refcard row, `CLAUDE.md` function list updated.
- Files: `R/prod3_core.R` (or a new `R/qprodnormal3.R`), `NAMESPACE`, `man/`, tests, `_pkgdown.yml`, `NEWS.md`, `vignettes/articles/refcard.Rmd`, `CLAUDE.md`.

### Checkpoint: complete
- [ ] All acceptance criteria met; `.STATUS` and plan marked done; D2 recorded; no stale version strings.

## Decisions for you

1. **`p` element (T1):** document it (recommended) or drop it? Dropping changes the output shape that tests and consumers rely on.
2. **`ml_admissible()` (D2):** keep internal (recommended; its name misdescribes what it returns, and the grid already exposes `admissible`) or export it, which would mean renaming it first.
3. **`cran-comments.md` (T4):** banner (recommended), delete (git history keeps it), or leave alone.
4. **`qprodnormal3()` interface (T3):** argument names `mean` and `cov` to match `pprodnormal3()` (recommended) or `mu` and `Sigma` to match the S7 constructors.
5. **Release timing:** none of this ships until you say; a release after T2/T3 is 1.11.0.

## Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Direct upper-tail integral has its own cancellation near the lower boundary of the domain split | Med | Oracle test across both tails and the splitting-at-0 invariant noted in `CLAUDE.md`; read the explanatory comments in `R/prod3_core.R` before changing the cell logic |
| `p` documentation read as a valid hypothesis test | Low | Caveat stated in `?ci` and the article, pointer to `mbco()` |
| New export breaks the pkgdown reference index | Low | `check_pkgdown()` in the T3 acceptance |

## Open questions
- None blocking; the five decisions above only choose between stated options.

## Outcome notes (2026-11-09)

- T2 accuracy: the direct upper tail matches the independent oracle (rel 4.9e-9 at q = 30, tol 1e-10; 2.9e-9 at q = 100, tol 1e-14), but accuracy is the absolute `tol`, so a far tail needs a matching `tol`; this is documented, and the default `tol` was not changed.
- T3 also changed `dist_quantile()` on a `ProductNormal3` at the edges (`p = 0/1` give `-Inf/Inf`; a point mass gives `prod(mu)`), because both now share `.qprodnormal3_one()`.
- D2: `ml_admissible()` returns the quadratic form `r' R^-1 r`, not an admissibility flag; it stays internal and `ml_omitted_confounder()` already exposes `admissible`.
- Nothing released. The next release would be 1.11.0 (new exports `qprodnormal3()` and the `lower.tail` argument; decision 5, the user's call); CRAN hold unchanged.

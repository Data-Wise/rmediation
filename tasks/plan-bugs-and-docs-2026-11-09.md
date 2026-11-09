# Implementation Plan: bugs and website docs after 1.10.0 (2026-11-09)

Status: APPROVED 2026-11-09 (the user accepted the recommendation on all 7 open questions below). Implementation starts with T1; nothing is implemented when this file is written. Source: a read-only review on `dev` at `cc96a18`
(v1.10.0 is the latest GitHub release; CRAN serves 1.6.1; CRAN hold unchanged). There are no open issues or PRs, so the
bug list comes from probes and the parked items in `.STATUS`, not from a tracker. Existing `tasks/plan.md` is untouched.

## Overview

Three parts, in this order: fix the confirmed defects (small, test-first), reconcile the site and repo docs with what
1.10.0 actually does, then add the articles the site lacks. No release is planned here; the site deploys from `main`
only, so docs reach readers with the next real `dev`→`main` release (open question 6).

## Findings

### Bugs (confirmed by running code on `dev`)

| ID | Finding | Evidence | Severity |
|----|---------|----------|----------|
| B1 | `ci(<lavaan>)` stops with a "perfect correlation, not supported" error when a coefficient repeats inside a product of three or more (`ab := a*b*a`). Two factors (`a*a`) work. This is the same failure class #141 removed for distinct factors. | probe: `ab := a*b*a` → `ERROR: 'cov' must be positive-definite (smallest eigenvalue = 0)...`; `a*b*cp` works on both routes | medium: valid model, hard error, misleading message |
| B2 | `pprodnormal3()` accepts only one `q` (length 1); its siblings `pprodnormal()`, `dprodnormal()`, `qprodnormal()`, `dprodnormal3()` are vectorized. | probe: `pprodnormal3(c(-1,0,1,2), ...)` → `Assertion on 'q' failed: Must have length 1`; the four siblings return vectors | low-medium: API inconsistency |
| B3 | `DESCRIPTION` has `Date: 2026-10-31` (the 1.9.0 date); the 1.10.0 bump did not touch it. NEWS and CITATION say 2026-11-08; the release was published 2026-11-09. | `grep ^Date DESCRIPTION`; `gh release view` | low |
| B4 | `DESCRIPTION` carries hand-written `Author:`/`Maintainer:` next to `Authors@R` (noted as deferred in `.STATUS` 2026-08-22). They can drift. | `DESCRIPTION` lines 6-8 | low |

### Parked items (features or precision limits, not defects; each needs its own plan)

- P1 `qprodnormal3()` is not exported (`ci(ProductNormal3)` has a quantile internally).
- P2 `pprodnormal3()` has no `lower.tail`, so upper-tail probabilities come from `1 - F`; at `q = 60` (mean 1, unit
  covariance) that gives 1.29e-07 by cancellation. Exact tail digits are not available.
- P3 `ml_admissible()` is internal; export is undecided.

### Not bugs, but worth stating

- `ci(<lavaan>)` returns different shapes by route (`CI|Estimate|SE`, `|Estimate|SE|MCError|p`, `lower|upper`,
  `CI|...|MC.Error`). They are pinned by tests (#134) and intentional, but a user cannot learn them without reading code;
  this is a documentation gap (N2), not a code change (a change would be breaking).
- Defined parameters with a constant or sign (`-a*b`, `2*a*b`, `a*b/2`) take the Monte Carlo fallback silently when
  `type` is not given. Defensible; document it (N2). An exact route for a signed two-factor product is an enhancement.

### Docs to reconcile

| ID | Finding | Evidence |
|----|---------|----------|
| D1 | Quick Reference has `Changed in 1.9.0` only. No 1.10.0 section, no row for `ci(<lavaan>)` defined parameters, none for `@provenance`. | `vignettes/articles/refcard.Rmd` (70 lines) |
| D2 | The Reporting article installs `@v1.9.0` in both examples, but documents 1.10.0 features. | `reporting.Rmd` lines 17, 19, 22 |
| D3 | Roadmap says "the development version is 1.10.0"; 1.10.0 is released. | `roadmap.Rmd` line 10 |
| D4 | README never mentions `@provenance`. | `grep -c provenance README.md` = 0 |
| D5 | `AGENTS.md` has drifted from `CLAUDE.md` (37 differing lines; CLAUDE.md has the density and integrator notes AGENTS.md lacks); `CLAUDE.md` says "Last Updated 2026-10-30"; `GEMINI.md` is stale (v1.3.0.9000, last touched 2025-11-19; build-ignored). | `diff`, `git log` |
| D6 | `cran-comments.md` describes 1.7.0. It is a CRAN-candidate file, so it only matters when a candidate is cut. | head of the file |

Checked and fine: all 10 articles are in the navbar; `pkgdown::check_pkgdown()` reports no problems; the local-only
`planning/` clutter is untracked, so it is not a repo issue.

### New articles the site lacks

- N1 **What changed since CRAN 1.6.1.** CRAN users stay on 1.6.1 until the hold lifts; behavior changes are spread across
  NEWS 1.7.0-1.10.0 (the `97.5% CI` label fix, the Gauss default, density fixes, `:=` handling, provenance).
- N2 **Defined parameters in `ci(<lavaan>)`.** One table: factor count → route → output shape → warnings, with
  serial-mediation examples. Today this lives in Technical Notes section 7 and pieces of Getting Started.
- N3 **MBCO on medfit `SEMFit` models.** Only a cookbook section and a roadmap paragraph exist; the route has no article.
- N4 (optional) **Troubleshooting.** The error messages users meet (`type = 'dop'` needs positive SEs, non-PD
  covariance, OpenMx fit failures); could instead be a cookbook section.

## Architecture decisions

- **Bug fixes are test-first** (red test, then fix), one PR per task to `dev`, squash. Risk-file PRs (`R/ci*.R`,
  `R/pprodnormal*.R`) carry the evidence checklist from `.github/PULL_REQUEST_TEMPLATE.md`.
- **B1 routes a repeated-factor product to Monte Carlo with a warning** (recommended). A repeated coefficient is a power,
  not independent factors, so the exact three-factor interval does not apply; Monte Carlo handles duplicated columns.
- **B2 vectorizes over `q` with the same return type for length 1** (recommended): additive, no change for scalar calls.
- Docs PRs run `scripts/check-local.sh` (it lints now, #152) plus `pkgdown::check_pkgdown()`; edited articles are built
  against a scratch install of the branch (the installed RMediation is 1.6.1).
- No release, tag or CRAN step in this plan.

## Dependency graph

```
Phase 1 bugs:   T1 (B1)   T2 (B2)   T3 (B3+B4)      independent of each other
                   └──────────┴──────────┘
                              │
Phase 2 reconcile:  T4 (D1-D4)   T5 (D5)           T4 waits for T1/T2 so the refcard describes final behavior
                              │
Phase 3 articles:   T6 (N1)   T7 (N2)   T8 (N3)     T7 waits for T1; T6 waits for T4
```

## Task list

### Phase 1: bugs

- [ ] **T1: repeated factor in a product of three or more (B1).** Red tests first: `ab := a*b*a` and a four-factor
  repeat return a result (not an error), with a warning naming the repeat; distinct-factor behavior unchanged. Fix in
  the `.product_factors()` use in `R/external_methods.R`: if factors repeat and k >= 3, take the Monte Carlo route.
  Acceptance: no error for any repeat pattern; the `type = "MC"` result agrees with a direct simulation within MC error;
  NEWS bug-fix entry. Verify: the new tests fail on current `dev` and pass after; full suite 0 failed;
  `check-local.sh` PASS; a planted defect (restore the error) makes the new test fail. Files: `R/external_methods.R`,
  `tests/testthat/test-external-methods-lavaan.R`, `NEWS.md`. Scope: S.
- [ ] **T2: vectorize `pprodnormal3()` (B2, needs decision 1).** Acceptance: `pprodnormal3(c(-1,0,1,2), ...)` equals
  `sapply` of the scalar calls; length 1 unchanged; NA and non-finite `q` still rejected with the existing message;
  `diagnostics` behavior documented for vectors. Verify: known-answer against scalar calls, boundary (`q = 0`, `q < 0`),
  planted defect (return only the first element). Files: the file defining `pprodnormal3()`, its test file, `man/`,
  `NEWS.md`. Scope: S.
- [ ] **T3: `DESCRIPTION` hygiene (B3, B4).** Set `Date:`; remove `Author:`/`Maintainer:` only after `R CMD check` shows
  they are generated from `Authors@R` without a NOTE. Acceptance: `R CMD check` Status OK, `citation("RMediation")` and
  `CITATION.cff` unchanged apart from the date. Files: `DESCRIPTION`. Scope: XS.

### Checkpoint: bugs

- [ ] Full suite 0 failed; `scripts/check-local.sh` PASS; `lintr::lint_package()` 0 findings; consumer smoke test
  (missingmed, medsim) unchanged.

### Phase 2: reconcile

- [ ] **T4: refcard, roadmap, reporting, README (D1-D4).** Add `Changed in 1.10.0` and rows for `:=` and `@provenance`;
  set the Reporting examples to the current tag (and say once how to substitute it); fix the Roadmap sentence; add one
  README line for `@provenance`. Acceptance: every page's version, release-status and CRAN statements agree with
  `NEWS.md` and `.STATUS`. Verify: grep for stale version strings; build the four pages. Files: the four pages above.
  Scope: S.
- [ ] **T5: agent files (D5, needs decision 4).** Sync `AGENTS.md` with `CLAUDE.md` (same content, different header and
  addressee); delete or regenerate `GEMINI.md`; bump `CLAUDE.md` "Last Updated". Acceptance: `diff` shows only the
  header differences. Scope: S.

### Checkpoint: reconcile

- [ ] `pkgdown::check_pkgdown()` clean; the edited pages build against a scratch install; navbar unchanged.

### Phase 3: new articles (each one PR, navbar entry in `_pkgdown.yml`)

- [ ] **T6: N1, what changed since CRAN 1.6.1.** Each behavior change: version, before/after, who is affected, with a
  runnable example where one exists. Source of truth: NEWS 1.7.0-1.10.0, checked by running the examples.
- [ ] **T7: N2, defined parameters in `ci(<lavaan>)`.** The route table, output shapes, serial-mediation examples
  (`a1*d*b`, nested `:=`), the constant and sign note, and the repeated-factor rule from T1.
- [ ] **T8: N3, MBCO on `SEMFit` models.** Needs medfit >= 0.8.0, which is GitHub-only; chunks guarded with
  `eval = requireNamespace("medfit", quietly = TRUE)` and a version check so the site builds without it.
- [ ] **T9 (optional): N4, troubleshooting** (decision 5).

### Checkpoint: complete

- [ ] All acceptance criteria met; `.STATUS` updated; no stale "pre-release" or version strings; ready for a
  `dev`→`main` release when you choose (decision 6).

## Risks and mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| T1 changes what `ci(<lavaan>)` returns for repeated factors (error becomes a result) | Medium: behavior change | NEWS entry; same contract as #138 (error becomes result, warn when `type` was explicit) |
| T2 changes a documented signature's accepted input | Low: additive | scalar path untouched; test pins length-1 equality |
| Docs describe behavior that T1/T2 then change | Low | docs tasks depend on the code tasks |
| New articles run examples that need medfit/OpenMx | Medium: site build fails | guard chunks; build against scratch install before PR |
| Site shows old wording until a release | Low | decision 6; do not cut a docs-only release |

## Decisions (accepted 2026-11-09: each recommendation below is the decision)

1. **B2: vectorize `pprodnormal3()`?** Yes: it matches its four siblings and is additive. Alternative: document it as
   scalar-only.
2. **B1: repeated factors route to Monte Carlo with a warning?** Yes. Alternative: stop with a clear error message
   (smaller change, but a valid model still fails).
3. **Constants and signs (`-a*b`, `2*a*b`):** leave on the Monte Carlo route and document it (recommended); an exact
   signed two-factor route is a separate enhancement.
4. **`GEMINI.md`: delete or regenerate?** Delete: it is stale since 2025, build-ignored, and nothing reads it here.
   `AGENTS.md`: sync by hand now; a drift check script is optional.
5. **Which new articles?** N1 and N2 first, N3 after; N4 as a cookbook section instead of an article.
6. **Release timing.** Do the work first, then decide: T1 and T2 are code changes, so a release would be 1.10.1 or 1.11.0
   (your call). Do not cut a docs-only release for the wording fixes.
7. **Parked items P1-P3:** leave parked; each gets its own plan when you pick it up.

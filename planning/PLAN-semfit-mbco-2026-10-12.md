# Reviewed plan: additive SEMFit-pair MBCO

Date: 2026-10-12 (America/Denver). RMediation base: `origin/dev` at `679bfc0`.
Status: implementation authorized by the next "Do next" instruction on 2026-10-12;
implemented, reviewed and merged through PR #41 into dev as `d29685f`.

## Scope and evidence

Add `mbco(h0, h1, type = "asymp")` for two medfit `SEMFit` objects, returning
RMediation's existing `MBCOResult`. Preserve every OpenMx method and bootstrap
path. No OpenMx removal, lavaan cleanup, version bump, dependency change, or
release work is included in this documentation step.

This supersedes the stale implementation instructions in medfit's
`planning/specs/HANDOFF-rmediation-mbco-on-mbco_sem-2026-10-11.md` sections 1,
3 and 4; its revision banner, OpenMx oracle and clean-start warning remain
relevant. medfit 0.8.0 at tag `v0.8.0` (`37171ec`) supplies the prerequisites.

## Review findings and corrections

1. **Superseded route.** RMediation `R/00_classes.R` defines `mbco` with dispatch
   on both `h0` and `h1`; medfit `R/sem-anova.R` compares already-fitted models.
   Register `(SEMFit, SEMFit)` and call `stats::anova(h1, h0)`, not
   `mbco_sem(fit, a, b)`. Map the single comparison row's `Chisq diff`,
   `Df diff`, and `Pr(>Chisq)` into `MBCOResult`; do not hardcode df 1.
2. **Nesting and direction.** medfit sorts by model df, so reversed h0/h1
   arguments could silently change the intended hypothesis. The proposed adapter
   must require `h0@df > h1@df` before delegation. Preserve medfit's same-data,
   weighted-fit, convergence and parameter-table nesting checks. The analyst is
   responsible for substantive nesting; parameter-table inclusion alone does not
   prove it (`medfit/R/sem-anova.R`, `.sem_anova_nested`).
3. **Invalid boundary p-value.** medfit warns on an active tested bound/inequality
   but still computes a numeric chi-square p-value (`.sem_anova_warn_boundary`,
   `.sem_anova`). The proposed adapter should refuse that comparison with an
   informative error rather than wrap the invalid value in `MBCOResult`.
   Use a narrowly tested warning handler; propagate unrelated warnings. Do not
   call medfit internals or infer boundary state from arbitrary object fields.
4. **Optional dependency and registration.** `R/ci_medfit.R` registers existing
   medfit methods from `.onLoad()` (`R/zzz.R`); `DESCRIPTION` keeps medfit in
   Suggests >= 0.2.0. Version-gate only the new method at >= 0.8.0, preserving
   existing CI methods with older medfit. Add a clear unsupported-version error
   for SEMFit callers and test package load/dispatch with medfit absent, old and
   new; do not accidentally require OpenMx for the new route. Registration must
   also work when RMediation loads before medfit. The exact registration/error
   strategy is an implementation decision to test before relying on it.
5. **Release facts.** The original handoff incorrectly says RMediation 1.7.0 is
   on CRAN. RMediation `.STATUS` records a GitHub prerelease; main/CRAN are 1.6.1.
   medfit 0.8.0 is GitHub/r-universe only, while CRAN has 0.3.2. Preserve the
   maintainer hold and default-integrator decision. Do not add Remotes or raise
   the Suggests minimum in this documentation PR; dependency/release policy
   requires a separate decision before shipping the new route.

## Authorized API policy

- Keep the public h0/h1 meaning: h0 is restricted, h1 is full; two SEMFits only.
  Mixed OpenMx/SEMFit pairs must error clearly.
- Asymptotic comparisons only. Reject `type = "parametric"` and `"semi"` for
  SEMFits; existing OpenMx bootstrap routes remain available.
- Validate alpha as the existing method does. Reject unused dots and explicitly
  supplied OpenMx-only tuning arguments (`R`, `checkHess`, `checkSE`, `optim`,
  `precision`) so callers cannot assume they control a fit already made.
- Never refit in the adapter. Product-zero nulls are made by `medfit::fit_sem()`;
  medfit's `.sem_fit_branches()` selects the minimum-discrepancy branch from
  clean defaults. Preserve clean-start construction in OpenMx oracle helpers.
- General nested comparisons inherit medfit's documented limitations; a product
  null is one supported case, not a claim that every nonlinear null has a
  regular chi-square reference distribution.

## Verification evidence (review only)

Inspected RMediation `R/00_classes.R`, `R/mbco.R`, `R/mbco_asymp.R`, `R/zzz.R`,
`R/ci_medfit.R`, `DESCRIPTION`, and the existing `memory_exp` helper/oracle.
Inspected medfit `R/sem-anova.R`, `R/sem-fit.R`, `R/methods-sem.R` and its
anova/MBCO known-answer tests. This is an API/implementation-plan review, not a
new literature or theorem audit.

The installed medfit is 0.7.0: a direct product-null call errors as unsupported.
A fresh R process loading the local medfit 0.8.0 source with `pkgload::load_all()`
fit full and `a1*b1 == 0` models on `memory_exp`. `stats::anova(full, null)`
returned statistic **0.08309957**, df difference **1**, p-value **0.7731**,
selected branch **b1 == 0**, n **369**. No installed package was replaced.
This probes medfit, not a new RMediation method: that method does not exist yet.

The existing RMediation suite passed **450** expectations with **0** failures,
**0** skips and **2** warnings. Both warnings are `MxModel 'H1' was modified
since it was run.` in `test-mbco-parametric-semi.R`, the existing test
`.mbco_semi rejects a factor/character manifest variable`. No runtime files
changed. The documentation diff passes `git diff --check`; strict package check
was not rerun for these status/plan-only edits.

## Bounded implementation sequence

- [x] Establish optional-version/load-order dispatch tests; preserve current ci
      and OpenMx dispatch, including mixed-class error behavior.
- [x] Implement the asymptotic pair adapter and argument policy; compare both
      individual nulls to the existing OpenMx oracle (221.045546, 0.083100,
      absolute tolerance 1e-6) and the product null to their minimum.
- [x] Test reversed pairs, df other than 1, unsupported types/arguments, weighted
      fits, incompatible rows/models, boundary refusal and warning propagation.
- [x] Demonstrate planted defects fail: larger-branch selection, shifted labels,
      wrong df, missing boundary refusal and unsafe old-version dispatch.
      Reuse existing OpenMx controls rather than rebuilding competing fixtures.
- [x] Update Rd/NEWS and optional-dependency CI coverage: default CRAN medfit
      cannot exercise the new method, so add an explicit >= 0.8.0 test job or
      equivalent release gate. Run the full suite, strict check and meaningful
      no-medfit/old-medfit gates; report skips and pass counts.
- [x] Review and integrate via a feature PR to dev. No CRAN submission or
      dev-to-main release until separately authorized and dependency holds clear.

## Implementation evidence (2026-10-12)

- `R/mbco_semfit.R` registers the pair and mixed-class routes from the existing
  optional medfit registrar. `requireNamespace()` loads medfit before method
  registration in either namespace load order. Versions that export SEMFit but
  are older than 0.8.0 get a version error; medfit 0.3.2 still registers CI methods.
- Full suite with scratch medfit 0.8.0: 511 passed, 0 failed, 2 existing OpenMx
  warnings, 1 intentional old-version test skip. New adapter/mutation tests:
  61 passed; wrong branch, shifted labels, hardcoded df, missing boundary refusal
  and unsafe version dispatch all fail their corresponding assertions.
- Eight installed-package gates passed, with medfit absent, 0.3.2, 0.7.0 and
  0.8.0, each in both namespace load orders and without OpenMx. Installed global
  medfit remains 0.7.0. No DESCRIPTION dependency or package-version change.
- Strict full check (`--as-cran --run-donttest`, incoming and incoming-remote
  enabled): 0 errors, 0 warnings, 1 NOTE for the unchanged August Date field.
  The dependency-only/Suggests-only flavor with vignette rebuild enabled fails
  because it removes rmarkdown (an existing Suggests used by the unchanged
  vignettes). Code/examples flavor with `--ignore-vignettes` and
  `--no-build-vignettes`: 0 errors, 0 warnings, 1 NOTE covering the omitted
  vignette index and old Date. Full check rebuilt vignettes successfully.
- New-file lint: 0 findings. All 20 URLs passed. Spelling terms reviewed and
  legitimate package/method terms added to `inst/WORDLIST`.
- `pkgdown::build_reference(topics = "mbco", lazy = FALSE)` executed the guarded
  example. The scratch help page was inspected in the in-app browser: SEMFit
  details and example output are readable, statistic 0.0831, df 1, p 0.7731.
- `.github/workflows/semfit-mbco.yaml` adds absent, CRAN, tagged 0.7.0 and tagged
  0.8.0 jobs, each without OpenMx. Both installed namespace orders and adapter
  tests are gates. Existing OpenMx CI stays intact. The setup-r-dependencies
  extra-package interface follows the official r-lib actions documentation.
- Release and CRAN holds remain. Next: review the feature PR and all CI results
  before integrating into dev; a development integration does not authorize release.

## Integration evidence

PR #41 merged into dev as `d29685fe8840ac4d28877a1c1519b9e4a966227e` after review and all ten checks passed on `2eca828`. Coverage pins medfit v0.8.0 so the new adapter is measured; CRAN medfit skipped these tests and initially yielded zero patch coverage. All release holds remain.

## Release policy outcome (2026-10-13)

The SEMFit route is held out of the CRAN tarball and all CRAN submission is held by the user until the SEM
features are non-experimental and fixed.x and mean structure are completed in medfit. Decisions, hold
definition and medfit status: `GRILL-semfit-dependency-policy-2026-10-12.md` and `.STATUS`. The verified
releasable candidate is `release/1.7.1` (draft PR #46), unsubmitted.

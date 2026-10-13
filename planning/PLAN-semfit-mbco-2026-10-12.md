# Reviewed plan: additive SEMFit-pair MBCO

Date: 2026-10-12 (America/Denver). RMediation base: `origin/dev` at `679bfc0`.
Status: reviewed proposal; implementation not authorized or started.

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

## Proposed API policy for implementation approval

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

## Bounded implementation sequence (requires authorization)

- [ ] Establish optional-version/load-order dispatch tests; preserve current ci
      and OpenMx dispatch, including mixed-class error behavior.
- [ ] Implement the asymptotic pair adapter and argument policy; compare both
      individual nulls to the existing OpenMx oracle (221.045546, 0.083100,
      absolute tolerance 1e-6) and the product null to their minimum.
- [ ] Test reversed pairs, df other than 1, unsupported types/arguments, weighted
      fits, incompatible rows/models, boundary refusal and warning propagation.
- [ ] Demonstrate planted defects fail: larger-branch selection, shifted labels,
      wrong df, missing boundary refusal and unsafe old-version dispatch.
      Reuse existing OpenMx controls rather than rebuilding competing fixtures.
- [ ] Update Rd/NEWS and optional-dependency CI coverage: default CRAN medfit
      cannot exercise the new method, so add an explicit >= 0.8.0 test job or
      equivalent release gate. Run the full suite, strict check and meaningful
      no-medfit/old-medfit gates; report skips and pass counts.
- [ ] Review and integrate via a feature PR to dev. No CRAN submission or
      dev-to-main release until separately authorized and dependency holds clear.

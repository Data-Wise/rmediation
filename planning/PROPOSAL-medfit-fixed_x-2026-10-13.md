# Proposal: a `fixed_x` argument for medfit's native SEM, with per-variable selection

**Date:** 2026-10-13
**Status:** Grilled 2026-10-13 (`GRILL-medfit-fixed_x-2026-10-13.md`): Option C chosen; many-covariates use case (49x faster at 30
covariates in a benchmark); explicit-statement conflicts are an error; conditional logLik with comparisons refused across
fixed sets; default FALSE (revisit at 1.0); "fixed.x completed" for the CRAN hold = Option C shipped. Research only:
nothing implemented, nothing written in medfit.
**Trigger:** RMediation's CRAN hold is defined as "SEM features non-experimental AND `fixed.x` and mean
structure completed". medfit's reply (2026-10-13): `fixed.x` is a documented difference, not a feature, and no
`fixed.x` argument is planned. The maintainer wants an argument named `fixed_x` that can select which
exogenous variables are fixed.
**Evidence:** `planning/RESEARCH-medfit-fixed_x-selection-2026-10-13.md` (math, lavaan checks, design sketch).

## Current state (verified)

- The native engine always frees exogenous means (when mean structure is on), variances and covariances. That
  matches lavaan `fixed.x = FALSE`. NEWS, vignettes and `fit_sem()` help state this; lavaan oracles pass `fixed.x = FALSE`.
- `fit_sem()` has no `fixed_x` argument (`R/fit-sem.R`). The completed parameter table has a `fixed` column
  (`NA` = free, a number = fixed), and `.sem_complete()` (`R/sem-model.R`) adds the exogenous rows through
  `add(a, b, fixed = NA_real_)`. So the table machinery to fix a value already exists.
- Cannot be reproduced today: lavaan's `fixed.x = TRUE` parameter table, parameter count and conditional
  log-likelihood. The structural estimates and standard errors already agree (verified).
- The 0.9.0 mean-structure plan (G8 `anova()` fix, G10 tri-state `meanstructure`) touches the same degrees-of-freedom,
  log-likelihood and `anova()` code.

## Research: does the math support choosing which variables are fixed?

**Yes.** For a Gaussian path model whose exogenous observed variables have no incoming paths and whose moments
are free and not tied to structural parameters, the log-likelihood separates exactly into a conditional part
and an exogenous part. Consequences: fixing exogenous moments at their sample values leaves the structural
estimates and their standard errors unchanged (model-based and sandwich), and the same holds for any chosen
subset. Selection changes only the reported rows, the log-likelihood and AIC, and functions of exogenous moments.

| lavaan check (n = 500, complete data, normal ML) | Result |
|---|---|
| `fixed.x` TRUE vs FALSE, structural `a, b, cp, ab` | identical estimates and SEs |
| 7 subsets of {x, c1, c2} fixed | estimates within 7e-14, SEs within 1e-9, logLik unchanged |
| All fixed vs lavaan `fixed.x = TRUE` | SEs agree to 2e-17 |
| Robust SEs (`MLR`), skewed data | within 1e-13 |
| `fixed.x = TRUE`: `df` 1, chi-square 9.188694 | same as `FALSE`; logLik and AIC differ (conditional vs joint) |

**Where fixing does change results:** functions of exogenous moments (standardized `a` SE 0.0342 vs 0.0360);
models that tie an exogenous variance to a structural parameter (the separation fails); logLik/AIC/BIC across fixed sets.

**Two traps an implementation must avoid** (both reproduced in the checks):
1. Fixed exogenous moments must not count as restrictions: emulating by numeric fixed values moved `df` 1 -> 4 -> 7;
   real `fixed.x = TRUE` keeps `df = 1`. Otherwise `df`, `anova()` and `mbco()` are wrong.
2. The auto-pairing rule drops free exogenous covariances for variables that have explicit `~~` statements, so selection
   silently loses `c1 ~~ c2` (npar 10 instead of 11, SE off by 3e-4). The completion step must add free pairs itself.

## Options

### Option A: keep the documented difference (status quo)
**What:** No argument. The engine always uses `fixed.x = FALSE` semantics.
**Pro:** Zero work and zero risk to the 0.9.0 plan; structural results already match lavaan either way.
**Con:** Cannot reproduce lavaan's `fixed.x = TRUE` table, npar or conditional logLik; the maintainer's "fixed.x
completed" clause is met only in the weakest sense; no way to treat covariates as fixed while keeping a variable of interest random.

### Option B: `fixed_x = TRUE/FALSE` (all or nothing, lavaan parity)
**What:** A logical argument; `TRUE` fixes every exogenous observed variable.
**Pro:** Matches lavaan, so oracles are direct (`fixed.x = TRUE` gives table, npar, df, conditional logLik). Smallest surface.
**Con:** Does not give the per-variable control that was asked for; still needs the df and logLik correction.

### Option C: `fixed_x = FALSE | TRUE | <character vector of exogenous variable names>` (recommended)
**What:** As B, plus names to fix a chosen subset (their means, variances and every covariance touching them).
**Pro:** Covers the request. The extra machinery over B is validation and pairing, because B already needs
the df, logLik and fixed-row handling. Per-variable fixing has the same separation guarantee, so results for the structural
parameters are unchanged by the selection.
**Con:** Per-variable fixing has no lavaan oracle of its own (lavaan's `fixed.x` is all or nothing). The oracle is
lavaan with explicit numeric values plus a df/logLik correction (already prototyped), and OpenMx.

## Recommendation

**Option C, scheduled after the 0.9.0 G8 `anova()` nesting fix**, because it rewrites the same df, logLik and `anova()`
paths. Keep the default `FALSE` (0.8.0 results frozen by the T1 gate); document that lavaan defaults to `TRUE`.

Proposed semantics: names must be observed exogenous variables of the model; error if a selected variable's moment
is tied by a constraint, shared label or defined parameter to a structural parameter; fixed values from the
estimation sample after listwise deletion, ML denominator n (weighted when `weights` are used); free pairs among the
unselected variables are added explicitly; `df` unaffected; logLik conditional on the fixed block (as lavaan); fixed
rows carry no SE and leave `vcov`; `anova()` requires identical `fixed_x` sets and data on both fits.

## Quick Wins (< 30 min)
1. Name decision: `fixed_x` (snake_case, matching medfit) accepting `FALSE`, `TRUE` or variable names.
2. Decide the placement (0.9.0 after G8, a later 0.9.x, or after 0.11.0).

## Medium Effort (1-2 hrs)
- [ ] Spec amendment in medfit's planning style: argument, validation errors, bookkeeping rules above.
- [ ] Test plan with planted defects: fixed moments counted as restrictions (df), dropped free covariance, joint instead of conditional logLik, a non-exogenous or tied variable accepted.

## Long-term (future sessions)
- [ ] Implement in `.sem_complete()` (needs the data's moments passed in), `.sem_df()`, the logLik method, `anova()` and `fit_sem()`; oracles: lavaan `fixed.x = TRUE`, explicit-value lavaan for subsets, OpenMx.
- [ ] Extend the checks to weights and, once 0.9.0 exists, mean structure (exogenous means under `fixed_x`).

## Open questions (for the maintainer / medfit author)
- Which release carries it, and does it count toward "non-experimental"?
- Should `fixed_x = TRUE` become the default later (lavaan parity) or stay `FALSE`?
- Is a conditional logLik acceptable for AIC/BIC comparisons, given models must share the fixed set?

## Limits of the evidence
One simulated dataset, complete data, normal ML, lavaan as the only oracle (OpenMx not run). I did not run medfit's
tests or a prototype of the argument. Whether `fixed_x` counts toward RMediation's hold is the maintainer's call.

## Recommended Next Step
Pick Option C and the placement, then hand the spec amendment to the medfit session as a request. RMediation needs no change: `mbco(h0, h1)` is unaffected when both fits use the same `fixed_x`.

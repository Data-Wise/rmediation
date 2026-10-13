# RESEARCH: a `fixed_x` argument for medfit's native SEM, with per-variable selection

Date: 2026-10-13. Status: research only; nothing implemented, nothing written in medfit.
Scope: is a `fixed_x` argument feasible, and does the math support letting the user choose *which*
exogenous variables are fixed? Evidence: medfit `R/sem-model.R`, `R/fit-sem.R`, the 0.9.0 mean-structure
plan (read-only); lavaan checks in a scratch directory (one simulated complete-data normal-ML dataset,
n = 500; scripts not saved in either repo).

## Verdict

**Feasible, and the math supports per-variable selection**, under conditions listed below. The code change
is moderate: the completed parameter table already has a `fixed` column and `.sem_complete()` already
builds the exogenous rows. Three things need care: degrees of freedom, log-likelihood, and the pairing
rule for the remaining free exogenous covariances.

## Why the math works

For a Gaussian path model in which the exogenous observed variables `x` have no incoming paths and their
moments `phi = (mu_x, Sigma_xx)` are free and not tied to any structural parameter `theta`, the model
log-likelihood separates exactly: `l(theta, phi) = l_cond(theta) + l_x(phi)`.

1. `phi_hat` = the ML sample moments (denominator n). Fixing `phi` at those values leaves `theta_hat` unchanged.
2. The Hessian is block diagonal in `(theta, phi)` at every point, not only at the optimum. So the
   observed-information SEs of `theta` are identical whether `phi` is free or fixed.
3. The sandwich (`se_type = "sandwich"`) is unaffected too: `A` is block diagonal, so
   `(A^-1 B A^-1)_theta,theta = A_tt^-1 B_tt A_tt^-1`, which contains no `phi` term.
4. **Subsets:** fix a chosen set `F` (their means, variances and every covariance touching `F`) and leave
   the rest `E` free. The free `Sigma_EE` stays at its sample value (joint maximum), so steps 1 to 3 still
   hold. Selection changes the reported table and SEs of the exogenous rows, never `theta_hat` or `SE(theta)`.

## Evidence (lavaan; "fixing" = explicit numeric fixed values at the sample moments)

| Check | Result |
|---|---|
| `fixed.x` TRUE vs FALSE, structural params `a, b, cp, ab` | estimates identical; SEs identical to 1e-17 |
| Seven fixed subsets of {x, c1, c2} (none, each single, pairs, all) | max difference in estimates 7e-14; in SEs 1e-9; logLik change 0 to 5e-13 |
| Fixing all (explicit values) vs lavaan `fixed.x = TRUE` | SEs agree to 2e-17 |
| Robust SEs (`MLR`), skewed data, `fixed.x` TRUE vs FALSE | max SE difference 1e-13 (supports the sandwich argument) |
| `fixed.x = TRUE`: `npar` 8, `df` 1, `chisq` 9.188694; `FALSE`: `npar` 14, `df` 1, same `chisq` | chi-square and df unchanged; logLik/AIC differ (conditional vs joint) |

## Where fixing DOES change results (the conditions)

- **Functions of exogenous moments** (standardized estimates, anything using `Var(x)` or `mean(x)`):
  standardized `a` SE 0.03422 (`fixed.x = TRUE`) vs 0.03598 (`FALSE`). A fixed moment is a constant in the delta method.
- **Variation dependence broken:** tying an exogenous variance to a structural parameter (label equality
  `Var(c1) = Var(residual m)`) changed an SE (0.04568 vs 0.04556). `fixed_x` must reject such models for
  the variables involved, or the separation argument fails.
- **logLik / AIC / BIC:** `lavaan` reports the conditional logLik under `fixed.x = TRUE` (-1420.34 vs joint
  -3533.26). Models compared must use the same fixed set.
- **Missing data:** lavaan deletes rows missing an exogenous value when `fixed.x = TRUE`, even with
  `missing = "fiml"` (25 cases dropped in my test). medfit uses listwise deletion, so no new issue.

## Two traps found while testing (both matter for an implementation)

1. **Degrees of freedom.** Fixing exogenous moments by writing numeric fixed values (as I did for the
   emulation) makes lavaan count them as restrictions: `df` went 1 -> 4 -> 7. Real `fixed.x = TRUE` keeps
   `df = 1`. A medfit implementation must remove the fixed exogenous moments from the moment count as well as
   from the free count. Otherwise `df`, `anova()` and `mbco()` chi-squares are wrong.
2. **Silent covariance drop.** lavaan (and medfit's `.sem_complete()` comment says it mirrors this) only
   auto-pairs exogenous covariances among variables that have no explicit `~~` statement. My first
   "fix x only" run therefore lost the `c1 ~~ c2` covariance (npar 10 instead of 11, logLik -3556 vs -3533,
   SE off by 3e-4). With selection, the completion step must add the free exogenous pairs itself,
   independent of user statements.

## Sketch of the design (for the medfit author to accept or change)

- **Argument:** `fixed_x = FALSE` (snake_case, matching medfit). Default FALSE keeps 0.8.0 results; lavaan
  defaults to TRUE, which stays the documented difference. Accepts `FALSE`, `TRUE`, or a character vector of
  exogenous observed variable names.
- **Validation:** names must be observed exogenous variables of the model (not endogenous, latent or
  unknown); error if a selected variable's moment appears in a constraint, label or defined parameter that
  ties it to a structural parameter.
- **Semantics:** for each selected variable fix its variance and mean (when mean structure is on, 0.9.0),
  and every covariance with another exogenous variable. Fixed values come from the estimation sample after
  listwise deletion, ML denominator n (weighted if `weights` are used). Free pairs among the rest are added explicitly.
- **Bookkeeping:** `df` unchanged by fixed exogenous moments; logLik reported conditional on the fixed block
  (as lavaan); fixed rows have no SE and are dropped from `vcov`; `anova()` requires identical `fixed_x`
  sets (and data) on both fits.
- **Hook in the code:** `.sem_complete()` (R/sem-model.R, the `add(a, b, fixed = NA_real_)` helper and the
  exogenous loop around lines 83-90) needs the data's moments passed in; `.sem_df()` and the logLik method
  need the fixed-exogenous correction; `fit_sem()` gains the argument and validation.
- **Oracles:** lavaan `fixed.x = TRUE` for the all-fixed case; for subsets, lavaan with explicit numeric
  values plus a df/logLik correction (the scratch test above is that oracle); OpenMx for the cross-check.
- **Interaction with the 0.9.0 plan:** touches the same df, logLik and `anova()` code (T5, G8), so it should
  follow the G8 `anova()` nesting fix. Placement (0.9.0 vs a later 0.9.x) is the medfit author's call.
- **RMediation:** `mbco(h0, h1)` is unaffected when both fits use the same `fixed_x`: chi-square and df are
  identical either way (9.188694, df 1 in my check).

## Limits of this research

One simulated dataset, complete data, normal ML, lavaan as the only oracle (OpenMx not run). I did not run
medfit's own tests or its code with a `fixed_x` prototype. Per-variable fixing has no lavaan oracle of its own
(lavaan's `fixed.x` is all-or-nothing); the subset evidence is lavaan with explicit values. This is a request
to the medfit author, not a change anyone has accepted.

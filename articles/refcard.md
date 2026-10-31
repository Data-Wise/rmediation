# RMediation Quick Reference

One page: which function answers which question. Each row links to the
full help page.

## Choose by task

| I want to… | Use | Notes |
|----|----|----|
| a CI for `a*b` from estimates and standard errors | `medci(mu.x, mu.y, se.x, se.y, rho, type = "dop")` | `"dop"` is exact; `"MC"` samples; `"asymp"` is the delta method |
| a CI for any function of fitted parameters | [`ci()`](https://data-wise.github.io/rmediation/reference/ci.md) with a medfit `MediationData` / `SerialMediationData` object | [`ci_mediation_data()`](https://data-wise.github.io/rmediation/reference/ci_mediation_data.md), [`ci_serial_mediation_data()`](https://data-wise.github.io/rmediation/reference/ci_mediation_data.md) |
| a CI for a function of several parameters from a mean and covariance | [`qMC()`](https://data-wise.github.io/rmediation/reference/qMC.md), [`pMC()`](https://data-wise.github.io/rmediation/reference/pMC.md) with `quant = ~ a*b` | Monte Carlo; `p` and `q` are scalars |
| the CDF, quantile or density of `a*b` | [`pprodnormal()`](https://data-wise.github.io/rmediation/reference/pprodnormal.md), [`qprodnormal()`](https://data-wise.github.io/rmediation/reference/qprodnormal.md), [`dprodnormal()`](https://data-wise.github.io/rmediation/reference/dprodnormal.md) | two normals |
| the CDF or density of `a1*a2*b` | [`pprodnormal3()`](https://data-wise.github.io/rmediation/reference/pprodnormal3.md), [`dprodnormal3()`](https://data-wise.github.io/rmediation/reference/dprodnormal3.md) | three normals; pass `mean` and `cov` |
| test `H0: a*b = 0` with OpenMx | `mbco_product_null(h1, paths = c("a", "b"))` | exact: fixes one path at 0 per branch |
| test any equality constraint with OpenMx | `mbco(h0, h1, type = ...)` | see the warnings below |
| test with two medfit `SEMFit` fits | `mbco(h0, h1, type = "asymp")` | needs medfit \>= 0.8.0 |
| sensitivity to an omitted confounder | [`ml_omitted_confounder()`](https://data-wise.github.io/rmediation/reference/ml_omitted_confounder.md) | 1-1-1 multilevel mediation |

## `medci()` methods

| `type` | Method | Use when |
|----|----|----|
| `"dop"` | distribution of the product (exact) | the default for two paths |
| `"MC"` | Monte Carlo, `n.mc` draws | you want to compare, or need a flexible function |
| `"asymp"` | delta method (Sobel) | a quick approximation; not recommended for inference |

## `mbco()` types

| `type`         | Reference distribution                   | Cost          |
|----------------|------------------------------------------|---------------|
| `"asymp"`      | chi-squared                              | one fit pair  |
| `"semi"`       | semiparametric bootstrap, `R` replicates | `R` fit pairs |
| `"parametric"` | parametric bootstrap, `R` replicates     | `R` fit pairs |

## Changed in 1.9.0

`ci(type = "asymp")` now names its interval `95% CI` (it was `97.5% CI`)
at the default `alpha`. Index the result by position (`res[[1]]`) or by
the new name; the interval itself did not change (#123).

## Conditions to know

| Class | Kind | Meaning |
|----|----|----|
| `RMediation_constraint_violation` | warning | a constraint of h0 is violated at the fitted solution |
| `RMediation_constraint_not_enforced` | warning | h0 fit equals h1 fit although a constraint was violated; the constraint may not have been enforced (OpenMx#433 or a violation inside the feasibility tolerance) |
| `RMediation_h0_refit_failed` | error | a violated h0 could not be repaired by the refit |
| `RMediation_bootstrap_too_many_dropped` | error | more than 5% of bootstrap replicates did not converge |
| `RMediation_bootstrap_infeasible` | error | a replicate’s constraint violation could not be repaired |

## Bootstrap p-value rule

`p = mean(null > observed)`, taken over the kept replicates: strict `>`,
no `+1`. Replicates that did not converge are dropped, up to 5% of `R`;
the count is in `result@dropped`.

## Arguments

| Argument       | Meaning                                         |
|----------------|-------------------------------------------------|
| `mu.x`, `mu.y` | estimates of the two paths                      |
| `se.x`, `se.y` | their standard errors                           |
| `rho`          | correlation between the two estimates           |
| `alpha`        | one minus the confidence level (default `0.05`) |
| `n.mc`         | Monte Carlo draws (default `1e5`)               |

See
[Cookbook](https://data-wise.github.io/rmediation/articles/cookbook.md)
for worked recipes and [Technical
notes](https://data-wise.github.io/rmediation/articles/technical-notes.md)
for the reasoning behind the defaults.

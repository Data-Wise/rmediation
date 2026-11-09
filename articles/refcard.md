# RMediation Quick Reference

One page: which function answers which question. Each row links to the
full help page.

## Choose by task

| I want to… | Use | Notes |
|----|----|----|
| a CI for `a*b` from estimates and standard errors | `medci(mu.x, mu.y, se.x, se.y, rho, type = "dop")` | `"dop"` is exact; `"MC"` samples; `"asymp"` is the delta method |
| a CI for any function of fitted parameters | [`ci()`](https://data-wise.github.io/rmediation/reference/ci.md) with a medfit `MediationData` / `SerialMediationData` object | [`ci_mediation_data()`](https://data-wise.github.io/rmediation/reference/ci_mediation_data.md), [`ci_serial_mediation_data()`](https://data-wise.github.io/rmediation/reference/ci_mediation_data.md) |
| a CI for each `:=` in a `lavaan` fit | `ci(fit)` | the route depends on the form of the `:=`; see “Defined parameters” below |
| a CI for a function of several parameters from a mean and covariance | [`qMC()`](https://data-wise.github.io/rmediation/reference/qMC.md), [`pMC()`](https://data-wise.github.io/rmediation/reference/pMC.md) with `quant = ~ a*b` | Monte Carlo; `p` and `q` are scalars |
| the CDF, quantile or density of `a*b` | [`pprodnormal()`](https://data-wise.github.io/rmediation/reference/pprodnormal.md), [`qprodnormal()`](https://data-wise.github.io/rmediation/reference/qprodnormal.md), [`dprodnormal()`](https://data-wise.github.io/rmediation/reference/dprodnormal.md) | two normals |
| the CDF, quantile or density of `a1*a2*b` | [`pprodnormal3()`](https://data-wise.github.io/rmediation/reference/pprodnormal3.md), [`qprodnormal3()`](https://data-wise.github.io/rmediation/reference/qprodnormal3.md), [`dprodnormal3()`](https://data-wise.github.io/rmediation/reference/dprodnormal3.md) | three normals; pass `mean` and `cov`; since 1.11.0 [`pprodnormal3()`](https://data-wise.github.io/rmediation/reference/pprodnormal3.md) takes a vector of `q` and `lower.tail`, and [`qprodnormal3()`](https://data-wise.github.io/rmediation/reference/qprodnormal3.md) is new |
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

## Defined parameters in `ci(<lavaan>)`

`ci(fit)` returns one interval per `:=`. What you get depends on the
form of the definition; a `:=` that uses another `:=` is expanded first.

| Form | Interval | Result names |
|----|----|----|
| two coefficients (`a*b`) | honors `type` | `CI`, `Estimate`, `SE` |
| three different coefficients (`a*b*c`) | exact three-factor interval; ignores `type` | `lower`, `upper` |
| four or more coefficients | Monte Carlo | `CI`, `Estimate`, `SE`, `MC.Error` |
| any other formula (`a*b + c`, `exp(a)*b`) | Monte Carlo | an unnamed interval, then `Estimate`, `SE`, `MCError`, `p` |
| three or more with a repeated coefficient (`a*b*a`), from 1.11.0 | Monte Carlo | `CI`, `Estimate`, `SE`, `MC.Error` |

A warning says when your explicit `type` was overridden. A definition
that cannot be resolved gets a warning and a `NULL` entry; the other
intervals are still returned. See [Technical
Notes](https://data-wise.github.io/rmediation/articles/technical-notes.md),
section 7, for the reasoning.

## Changed in 1.10.0

- An
  [`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md)
  result carries `@provenance`: the RMediation, OpenMx, medfit and R
  versions, the test `type`, the bootstrap size `R`,
  [`RNGkind()`](https://rdrr.io/r/base/Random.html) and the run time.
  The seed is not recorded; call
  [`set.seed()`](https://rdrr.io/r/base/Random.html) and report it.
  [`names()`](https://rdrr.io/r/base/names.html) of an `MBCOResult`
  gains `"provenance"` last.
- [`ci()`](https://data-wise.github.io/rmediation/reference/ci.md) on a
  `lavaan` fit resolves a `:=` that uses another one, and no longer
  stops on a product of three or more coefficients (table above). It
  warns when you set `type` and a defined parameter is not a product of
  estimated coefficients.

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

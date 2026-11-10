# Testing an Indirect Effect with MBCO

[`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md)
tests a restriction on a fitted model with a likelihood-ratio test. This
page shows the whole path for one indirect effect: what is tested, which
route to use, a worked example, how to read the result, and what to do
with the warnings. It links to the
[Cookbook](https://data-wise.github.io/rmediation/articles/cookbook.md)
and the [Technical
Notes](https://data-wise.github.io/rmediation/articles/technical-notes.md)
for the details instead of repeating them.

## What MBCO tests

MBCO stands for model-based constrained optimization. You fit two nested
models to the same data:

- `h1`, the full model, with every path free;
- `h0`, the restricted model, with the restriction you want to test (for
  an indirect effect, one path or the product `a*b` fixed at 0).

`mbco(h0, h1)` returns the likelihood-ratio statistic and its p-value. A
small p-value is evidence against the restriction.

An indirect effect `a*b` is zero when `a = 0` or `b = 0`. That is a
union of two nulls, so a valid test rejects only if **every**
single-path null is rejected (an intersection-union test).
[`mbco_product_null()`](https://data-wise.github.io/rmediation/reference/mbco_product_null.md)
does exactly that; one nonlinear constraint `a*b == 0` does not, and can
land on the wrong branch (see below).

## Pick a route

| You have | Use | `type` | Reference distribution |
|----|----|----|----|
| OpenMx fits | `mbco(h0, h1)` | `"asymp"` | chi-squared |
| OpenMx fits | `mbco(h0, h1, type = "semi")` | `"semi"` | semiparametric bootstrap, `R` replicates |
| OpenMx fits | `mbco(h0, h1, type = "parametric")` | `"parametric"` | parametric bootstrap, `R` replicates |
| Two medfit `SEMFit` fits | `mbco(h0, h1)` | `"asymp"` only | chi-squared, no OpenMx, no refit |
| A product null with OpenMx | `mbco_product_null(full, paths = c("a", "b"))` | any OpenMx `type` | one single-path null per path; the result of the largest p-value |

The bootstrap types cost `R` fit pairs; `"asymp"` costs one. The
`SEMFit` route needs medfit 0.8.0 or later, supports no bootstrap and no
OpenMx fitting controls, and is shown in [Cookbook recipe
10](https://data-wise.github.io/rmediation/articles/cookbook.md).

## A worked example

The data are `memory_exp`: an experiment on instructions to use imagery
or repetition, with recall as the outcome. The full model has two
mediators, with paths `a1`, `a2` (from `x`) and `b1`, `b2` (to
`recall`).

``` r

d <- as.data.frame(memory_exp) # mxData() rejects tibbles
d$x <- as.numeric(d$x) - 1
manifests <- c("x", "repetition", "imagery", "recall")
model <- OpenMx::mxModel(
  "full", type = "RAM", manifestVars = manifests,
  OpenMx::mxPath("x", c("repetition", "imagery", "recall"), arrows = 1,
                 free = TRUE, values = 0.2, labels = c("a1", "a2", "cp")),
  OpenMx::mxPath("repetition", "recall", arrows = 1, free = TRUE, values = 0.2, labels = "b1"),
  OpenMx::mxPath("imagery", "recall", arrows = 1, free = TRUE, values = 0.2, labels = "b2"),
  OpenMx::mxPath(manifests, arrows = 2, free = TRUE, values = 0.8),
  OpenMx::mxPath("one", manifests, arrows = 1, free = TRUE, values = 0.1),
  OpenMx::mxData(d, type = "raw")
)
invisible(utils::capture.output(
  full <- suppressMessages(OpenMx::mxTryHard(model, checkHess = FALSE, silent = TRUE))
))
```

### Test the product `a1*b1 = 0`

``` r

res <- mbco_product_null(full, paths = c("a1", "b1"), type = "asymp")
res
#> MBCO Test Result
#> ================
#> Test type: asymp 
#> Chi-squared statistic: 0.0831 
#> Degrees of freedom: 1 
#> P-value: 0.7731 
#> Significance: ns (not significant)
#> Note: product null; binding single-path null: b1 = 0.
#> Provenance:
#>   Packages: RMediation 1.11.1, OpenMx 2.22.11, medfit 0.3.2, R 4.6.2 
#>   Test: type = asymp
#>   RNG: Mersenne-Twister / Inversion / Rejection 
#>   Run at: 2026-11-10 02:17:03 UTC 
#>   Seed: not recorded (call set.seed() yourself and report it)
```

The note under the result names the **binding branch**: the single-path
null (`a1 = 0` or `b1 = 0`) with the largest p-value. That branch is the
test of the indirect effect.

### Test one path

For a single path, build `h0` from the **unfitted** model and fit it
yourself:

``` r

null_b1 <- OpenMx::mxModel(model, name = "b1_eq0", OpenMx::mxConstraint(b1 == 0, name = "c"))
invisible(utils::capture.output(
  h0 <- suppressMessages(OpenMx::mxTryHard(null_b1, checkHess = FALSE, silent = TRUE))
))
mbco(h0, full, type = "asymp")
#> MBCO Test Result
#> ================
#> Test type: asymp 
#> Chi-squared statistic: 0.0831 
#> Degrees of freedom: 1 
#> P-value: 0.7731 
#> Significance: ns (not significant)
#> Provenance:
#>   Packages: RMediation 1.11.1, OpenMx 2.22.11, medfit 0.3.2, R 4.6.2 
#>   Test: type = asymp
#>   RNG: Mersenne-Twister / Inversion / Rejection 
#>   Run at: 2026-11-10 02:17:03 UTC 
#>   Seed: not recorded (call set.seed() yourself and report it)
```

Building `h0` from the unfitted model matters: a fitted `h0` keeps no
starting values, which is the information
[`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md)
needs to tell a dropped constraint from an accepted violation (next
section).

## Read the result

An [`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md)
result is an `MBCOResult`. Use the slots, or `$` and `[[`:

| Slot | Holds |
|----|----|
| `@statistic`, `@df`, `@p_value` | the likelihood-ratio statistic, its degrees of freedom and p-value |
| `@type` | `"asymp"`, `"semi"` or `"parametric"` |
| `@refit` | `NULL`, or the tighter tolerance and the statistic before and after, when `h0` had to be refit |
| `@branch` | the single-path null that gave the result, from [`mbco_product_null()`](https://data-wise.github.io/rmediation/reference/mbco_product_null.md); otherwise `NULL` |
| `@dropped` | bootstrap replicates that did not converge and were left out; `NULL` without a bootstrap |
| `@provenance` | what produced the result: package and R versions, `type`, `R`, [`RNGkind()`](https://rdrr.io/r/base/Random.html), run time |

``` r

res@p_value
#> [1] 0.7731401
res@branch
#> [1] "b1"
res@dropped    # NULL: no bootstrap here
#> NULL
names(res@provenance)
#> [1] "rmediation" "openmx"     "medfit"     "r"          "type"      
#> [6] "R"          "rng_kind"   "time"
```

The bootstrap p-value is `mean(null > observed)` over the kept
replicates: strict `>`, no `+1` (see [Technical
Notes](https://data-wise.github.io/rmediation/articles/technical-notes.md),
section 3). The seed is not recorded in `@provenance`, because it cannot
be recovered afterward: call
[`set.seed()`](https://rdrr.io/r/base/Random.html) before a bootstrap
and report the seed with the result.

## Warnings and errors that matter

| Class | Kind | What to do |
|----|----|----|
| `RMediation_constraint_violation` | warning | A constraint of `h0` is violated at the fitted solution. [`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md) refits at a tighter tolerance and uses that statistic; read `@refit`. |
| `RMediation_constraint_not_enforced` | warning | `h0` fit equals `h1` fit although a constraint was violated. OpenMx may have silently dropped the constraint ([OpenMx#433](https://github.com/OpenMx/OpenMx/issues/433)); for a product null, use [`mbco_product_null()`](https://data-wise.github.io/rmediation/reference/mbco_product_null.md). |
| `RMediation_h0_refit_failed` | error | The refit could not repair `h0`. No statistic is returned from a fit known to be invalid. |
| `RMediation_bootstrap_too_many_dropped` | error | More than 5% of replicates did not converge. Check the model, or raise `R`. |
| `RMediation_bootstrap_infeasible` | error | A replicate’s constraint violation could not be repaired. |

The full explanation, with the reasons, is in [Technical
Notes](https://data-wise.github.io/rmediation/articles/technical-notes.md),
sections 2 and 3, and the same table is on the [Quick
Reference](https://data-wise.github.io/rmediation/articles/refcard.md).

## See also

- [Cookbook](https://data-wise.github.io/rmediation/articles/cookbook.md):
  recipes 7 to 10 for the product null, the dropped-replicate count, and
  the `SEMFit` route.
- [Technical
  Notes](https://data-wise.github.io/rmediation/articles/technical-notes.md):
  the OpenMx constraint problem and the bootstrap p-value rule.
- [`?mbco`](https://data-wise.github.io/rmediation/reference/mbco.md),
  [`?mbco_product_null`](https://data-wise.github.io/rmediation/reference/mbco_product_null.md)
  and
  [`?MBCOResult`](https://data-wise.github.io/rmediation/reference/MBCOResult.md)
  for every argument and slot.

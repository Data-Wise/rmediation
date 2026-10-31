# RMediation Cookbook

Short, self-contained recipes. Each runs as written.

## 1. A CI for `a*b` from published estimates

``` r

medci(mu.x = 0.5, mu.y = 0.6, se.x = 0.08, se.y = 0.04, rho = 0, type = "dop")
#> $`95% CI`
#> [1] 0.2010806 0.4053620
#> 
#> $Estimate
#> [1] 0.3
#> 
#> $SE
#> [1] 0.05209837
```

Set `rho` to the correlation between the two estimates if you have it;
`0` is common when the predictor is randomized.

## 2. Compare the three methods

``` r

set.seed(1)
for (type in c("dop", "MC", "asymp")) {
  r <- medci(0.5, 0.6, 0.08, 0.04, type = type)
  cat(sprintf("%-6s [%.3f, %.3f]\n", type, r[["95% CI"]][1], r[["95% CI"]][2]))
}
#> dop    [0.201, 0.405]
#> MC     [0.201, 0.406]
#> asymp  [0.198, 0.402]
```

`"dop"` is exact. `"MC"` agrees up to Monte Carlo error. The
delta-method interval is symmetric and differs because the product is
skewed.

## 3. The distribution of the product

``` r

pprodnormal(0.2, mu.x = 0.5, mu.y = 0.6, se.x = 0.08, se.y = 0.04)
#> [1] 0.02371524
qprodnormal(c(0.025, 0.975), mu.x = 0.5, mu.y = 0.6, se.x = 0.08, se.y = 0.04)
#> [1] 0.2010806 0.4053620
dprodnormal(0.3, mu.x = 0.5, mu.y = 0.6, se.x = 0.08, se.y = 0.04)
#> [1] 7.67319
```

## 4. A serial indirect effect `a1*a2*b`

``` r

cv <- diag(c(0.05, 0.04, 0.03)^2) # covariance of the three path estimates
pprodnormal3(0.1, mean = c(0.4, 0.5, 0.6), cov = cv, diagnostics = TRUE)
#> [1] 0.1422054
#> attr(,"error")
#> [1] 1.387779e-16
#> attr(,"nodes")
#> [1] 256
dprodnormal3(0.1, mean = c(0.4, 0.5, 0.6), cov = cv)
#> [1] 13.0745
```

With `diagnostics = TRUE` the result carries the integration error and
the node count. Keep the default `method = "gauss"`; `"hcubature"` is
for cross-checking only (see the technical notes).

## 5. A CI for a function of several parameters

``` r

set.seed(1)
mu <- c(a = 0.5, b = 0.6)
S <- diag(c(0.08, 0.04)^2)
sapply(c(0.025, 0.975), function(p) qMC(p, mu = mu, Sigma = S, quant = ~ a * b))
#>      2.5%     97.5% 
#> 0.2009892 0.4051981
```

`quant` is a formula over the names of `mu`, so any function of the
parameters works.

## 6. An object interface

``` r

pn <- ProductNormal(mu = c(0.5, 0.6), Sigma = diag(c(0.08, 0.04)^2))
ci(pn)$CI
#> [1] 0.2010806 0.4053620
cdf(pn, 0.2)
#> [1] 0.02371524
```

## 7. Test `a*b = 0` with OpenMx

Fit the full model, then let
[`mbco_product_null()`](https://data-wise.github.io/rmediation/reference/mbco_product_null.md)
fix one path at zero per branch. This is exact; a single constraint
`a*b == 0` is not (see the technical notes).

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
mbco_product_null(full, paths = c("a1", "b1"), type = "asymp")
#> MBCO Test Result
#> ================
#> Test type: asymp 
#> Chi-squared statistic: 0.0831 
#> Degrees of freedom: 1 
#> P-value: 0.7731 
#> Significance: ns (not significant)
#> Note: product null; binding single-path null: b1 = 0.
```

The note under the result names the binding branch, the single-path null
with the largest p-value.

## 8. Read the dropped-replicate count

``` r

null_b1 <- OpenMx::mxModel(model, name = "b1_eq0", OpenMx::mxConstraint(b1 == 0, name = "c"))
invisible(utils::capture.output(
  h0 <- suppressMessages(OpenMx::mxTryHard(null_b1, checkHess = FALSE, silent = TRUE))
))
set.seed(1)
res <- mbco(h0, full, type = "semi", R = 40L)
res@p_value
#> [1] 0.75
res@dropped # replicates that did not converge and were dropped (at most 5% of R)
#> [1] 0
```

`@dropped` is `0` when every replicate converged and `NULL` for
`type = "asymp"`. If more than 5% fail, the call stops with class
`RMediation_bootstrap_too_many_dropped`.

## 9. A CI for a serial indirect effect from lm fits (medfit)

medfit extracts the path estimates and their covariance;
[`ci()`](https://data-wise.github.io/rmediation/reference/ci.md) turns
them into an interval. medfit is optional (`Suggests`).

``` r

set.seed(7)
n <- 800
X <- rnorm(n)
M1 <- 0.5 * X + rnorm(n)
M2 <- 0.6 * M1 + rnorm(n)
Y <- 0.7 * M2 + 0.2 * X + rnorm(n)
dat <- data.frame(X, M1, M2, Y)

mu <- medfit::extract_mediation(
  lm(M1 ~ X, dat), model_y = lm(Y ~ M2 + X, dat),
  treatment = "X", mediator = c("M1", "M2"),
  mediator_models = list(lm(M2 ~ M1, dat))
)
set.seed(1)
ci(mu, level = 0.95, type = "MC")$CI
#>     lower     upper 
#> 0.2005227 0.2888945
```

The true indirect effect is `0.5 * 0.6 * 0.7 = 0.21`. See
[`vignette("serial-mediation-with-medfit")`](https://data-wise.github.io/rmediation/articles/serial-mediation-with-medfit.md)
for the lavaan route.

## 10. Test a product null with two medfit SEM fits

[`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md)
compares two fitted `SEMFit` objects asymptotically, with no OpenMx. It
calls [`anova()`](https://rdrr.io/r/stats/anova.html) and never refits.
This route needs medfit 0.9.0 or later, so the chunk is shown, not run,
on the site.

``` r

d <- as.data.frame(memory_exp)
d$x <- as.numeric(d$x) - 1
syntax <- paste("repetition ~ a1*x", "imagery ~ a2*x",
                "recall ~ cp*x + b1*repetition + b2*imagery", sep = "\n")
full <- medfit::fit_sem(syntax, d, fixed_x = FALSE, meanstructure = NULL)
null <- medfit::fit_sem(paste(syntax, "a1*b1 == 0", sep = "\n"), d,
                        fixed_x = FALSE, meanstructure = NULL)
mbco(null, full) # statistic 0.0831, df 1 (the figure in the `?mbco` example)
```

Bootstrap types and OpenMx fitting controls are not supported for
`SEMFit` pairs.

## 11. How much could an omitted confounder change a two-level indirect effect?

``` r

R <- matrix(c(1, .3, .2, .3, 1, .4, .2, .4, 1), 3)
res <- ml_omitted_confounder(
  between = list(a = 0.3, b = 0.4, cor = R, sd = c(1, 1, 1)),
  r_za = c(0, 0.1)
)
res@ranges[, c("level", "r_za", "min", "max")]
#>     level r_za        min       max
#> 1 between  0.0 0.04882118 0.2760939
#> 2 between  0.1 0.04410733 0.3463230
```

The unadjusted between-cluster indirect effect is `0.3 * 0.4 = 0.12`.
Each row is the range of the adjusted effect over the grid of confounder
correlations with the mediator and outcome, at the stated correlation
with the treatment. See
[`vignette("omitted-confounder-sensitivity")`](https://data-wise.github.io/rmediation/articles/omitted-confounder-sensitivity.md).

## 12. A Monte Carlo interval for any function of estimates

[`pMC()`](https://data-wise.github.io/rmediation/reference/pMC.md) and
[`qMC()`](https://data-wise.github.io/rmediation/reference/qMC.md)
simulate the sampling distribution of a function given the estimates and
their covariance. Unlike
[`qprodnormal()`](https://data-wise.github.io/rmediation/reference/qprodnormal.md)
they accept any formula, and `p` must be a single value.

``` r

est <- c(b1 = 0.5, b2 = 0.6)
vcv <- diag(c(0.08, 0.04)^2)
set.seed(1)
pMC(0.2, mu = est, Sigma = vcv, quant = ~ b1 * b2)
#> [1] 0.02393
c(lower = qMC(0.025, mu = est, Sigma = vcv, quant = ~ b1 * b2),
  upper = qMC(0.975, mu = est, Sigma = vcv, quant = ~ b1 * b2))
#>  lower.2.5% upper.97.5% 
#>   0.2016349   0.4050232
```

For a plain product, the exact quantiles of
[`qprodnormal()`](https://data-wise.github.io/rmediation/reference/qprodnormal.md)
(recipe 3) avoid the simulation error.

## 13. Quantiles of a distribution object, and a medfit object directly

[`dist_quantile()`](https://data-wise.github.io/rmediation/reference/dist_quantile.md)
returns one quantile of a `ProductNormal` object (a single `p`;
`type = "MC"` simulates instead).

``` r

pn <- ProductNormal(mu = c(0.5, 0.6), Sigma = diag(c(0.08, 0.04)^2))
c(lower = dist_quantile(pn, 0.025), upper = dist_quantile(pn, 0.975))
#>     lower     upper 
#> 0.2010806 0.4053620
```

For a medfit serial object,
[`ci_serial_mediation_data()`](https://data-wise.github.io/rmediation/reference/ci_mediation_data.md)
is what [`ci()`](https://data-wise.github.io/rmediation/reference/ci.md)
dispatches to, so the two give the same interval (`mu` is the object
from recipe 9).

``` r

set.seed(1)
ci_serial_mediation_data(mu, level = 0.95, type = "MC")$CI
#>     lower     upper 
#> 0.2005227 0.2888945
```

For a two-path `MediationData` object the direct call is
[`ci_mediation_data()`](https://data-wise.github.io/rmediation/reference/ci_mediation_data.md).

## 14. Tidy a log-likelihood

[`tidy()`](https://data-wise.github.io/rmediation/reference/tidy.md)
turns a `logLik` into a one-row data frame with the estimate and its
degrees of freedom.

``` r

tidy(logLik(lm(mpg ~ wt, data = mtcars)))
#>            term  estimate df
#> 1 logLikelihood -80.01471  3
```

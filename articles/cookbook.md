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

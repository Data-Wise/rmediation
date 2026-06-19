# Serial Mediation with medfit

## Why this vignette

[**medfit**](https://data-wise.github.io/medfit/) is the model-fitting
layer of the mediationverse: it fits mediation models and extracts the
path coefficients and their covariance matrix into a tidy S7 object.
RMediation then computes a confidence interval for the (possibly serial)
indirect effect from that object.

This division of labour means you do **not** hand-build coefficient
vectors and covariance matrices yourself —
[`medfit::extract_mediation()`](https://data-wise.github.io/medfit/reference/extract_mediation.html)
produces them, and
[`RMediation::ci()`](https://data-wise.github.io/rmediation/reference/ci.md)
consumes them directly. This vignette shows the full
`fit → extract → ci()` workflow for a **serial** mediation chain
(`X → M1 → M2 → Y`), for both `lavaan` and `lm`/`glm` fits.

medfit is an *optional* dependency (`Suggests`): RMediation’s own
methods work without it, and the bridge functions error cleanly if it is
missing.

## A serial chain from a lavaan fit

We simulate a two-mediator chain with a known serial indirect effect
`a × d1 × b = 0.5 × 0.6 × 0.7 = 0.21`, fit it with `lavaan`, and let
medfit extract a `SerialMediationData` object.

``` r

set.seed(42)
n  <- 800
X  <- rnorm(n)
M1 <- 0.5 * X  + rnorm(n)
M2 <- 0.6 * M1 + rnorm(n)
Y  <- 0.7 * M2 + 0.2 * X + rnorm(n)
dat <- data.frame(X, M1, M2, Y)

model <- "M1 ~ a*X
          M2 ~ d1*M1
          Y  ~ b*M2 + cp*X"
fit <- lavaan::sem(model, data = dat)

# medfit extracts the named estimates + covariance RMediation expects.
mu <- medfit::extract_mediation(
  fit, treatment = "X", mediator = c("M1", "M2"), outcome = "Y"
)
class(mu)
#> [1] "medfit::SerialMediationData" "S7_object"
names(mu@estimates)
#> [1] "a"       "d1"      "b"       "cp"      "M1~~M1"  "M2~~M2"  "Y~~Y"   
#> [8] "c_prime"
```

The object carries the `a, d1, b, c_prime` name contract that
RMediation’s path resolver depends on. Pass it straight to
[`ci()`](https://data-wise.github.io/rmediation/reference/ci.md):

``` r

res <- ci(mu, level = 0.95, type = "MC")
res$Estimate
#> [1] 0.2085793
res$CI
#>     lower     upper 
#> 0.1695038 0.2510052
```

The point estimate sits near the true `0.21`, and the 95% Monte Carlo
interval brackets it.

## The same chain from lm/glm fits

When the mediators and outcome are fit as separate regressions, pass the
first mediator model positionally, the remaining mediator models via
`mediator_models`, and the outcome model via `model_y`. medfit assembles
a block-structured covariance (cross-equation covariances are zero by
construction, with `cov(b, c')` preserved).

``` r

set.seed(7)
n  <- 800
X  <- rnorm(n)
M1 <- 0.5 * X  + rnorm(n)
M2 <- 0.6 * M1 + rnorm(n)
Y  <- 0.7 * M2 + 0.2 * X + rnorm(n)
dat <- data.frame(X, M1, M2, Y)

mu_lm <- medfit::extract_mediation(
  lm(M1 ~ X, dat),
  model_y         = lm(Y ~ M2 + X, dat),
  treatment       = "X",
  mediator        = c("M1", "M2"),
  mediator_models = list(lm(M2 ~ M1, dat))
)

ci(mu_lm, level = 0.95, type = "MC")$CI
#>     lower     upper 
#> 0.2005082 0.2886113
```

Both fitting routes flow through the same
[`ci()`](https://data-wise.github.io/rmediation/reference/ci.md) call —
only the upstream model object differs.

## Graceful degradation without medfit

Because medfit is in `Suggests`, the bridge functions check for it at
runtime. If medfit is not installed, calling them errors with an
actionable message rather than failing obscurely:

``` r

# When medfit is NOT installed, the bridge stops with a clear message:
ci(mu)
#> Error: Package 'medfit' is required for this method.
```

## See also

- [`vignette("getting-started", package = "RMediation")`](https://data-wise.github.io/rmediation/articles/getting-started.md)
  — core CI methods.
- [medfit](https://data-wise.github.io/medfit/) — fitting and
  extraction.
- [`?ci`](https://data-wise.github.io/rmediation/reference/ci.md) — the
  generic that dispatches on medfit’s `MediationData` /
  `SerialMediationData` objects.

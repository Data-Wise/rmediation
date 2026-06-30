# Distribution Quantile Function

Compute quantiles for distribution objects. This function computes
quantiles for product normal distributions, not data quantiles (use
[`stats::quantile`](https://rdrr.io/r/stats/quantile.html) for data).

## Usage

``` r
dist_quantile(object, ...)
```

## Arguments

- object:

  A distribution object (e.g., ProductNormal).

- ...:

  Additional arguments passed to methods.

## Value

A numeric vector of quantiles for the supplied probabilities, as
returned by the dispatched method.

## Examples

``` r
pn <- ProductNormal(mu = c(0.5, 0.3), Sigma = diag(2) * 0.1)
dist_quantile(pn, p = 0.025)
#> [1] -0.1842996
```

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

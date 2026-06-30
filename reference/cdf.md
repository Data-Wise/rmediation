# Cumulative Distribution Function

Generic function for computing cumulative distribution function.

## Usage

``` r
cdf(object, ...)
```

## Arguments

- object:

  A distribution object.

- ...:

  Additional arguments passed to methods.

## Value

A numeric vector of cumulative probabilities for the supplied quantiles,
as returned by the dispatched method.

## Examples

``` r
pn <- ProductNormal(mu = c(0.5, 0.3), Sigma = diag(2) * 0.1)
cdf(pn, q = 0)
#> [1] 0.2088018
```

# Confidence Interval

Generic function for computing confidence intervals.

## Usage

``` r
ci(object, ...)
```

## Arguments

- object:

  A distribution object or numeric vector of means.

- ...:

  Additional arguments passed to methods.

## Value

A confidence interval (numeric vector of lower/upper bounds, or a list)
as returned by the dispatched method.

## Examples

``` r
pn <- ProductNormal(mu = c(0.5, 0.3), Sigma = diag(2) * 0.1)
ci(pn)
#> $CI
#> [1] -0.1842996  0.6573156
#> 
#> $Estimate
#> [1] 0.15
#> 
#> $SE
#> [1] 0.2097618
#> 
```

# Confidence Interval

Generic function for computing confidence intervals.

## Usage

``` r
ci(mu, ...)
```

## Arguments

- mu:

  A distribution object or numeric vector of means.

- ...:

  Additional arguments passed to methods.

## Value

A confidence interval (numeric vector of lower/upper bounds, or a list)
as returned by the dispatched method.

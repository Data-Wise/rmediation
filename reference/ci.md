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

## Details

For numeric estimates, pass them as the first argument by position,
followed by their covariance matrix:
`ci(c(a = .5, b = .4), Sigma, quant = ~ a * b)`. The estimates cannot be
named `mu`, because the generic dispatches on its first argument,
`object`. The other arguments are `Sigma` (a covariance matrix, or its
lower triangle by column), `quant` (a one-sided formula in the names of
the estimates), `alpha` (default 0.05), `type` (`"MC"`, `"asymp"` or
`"all"`), `n.mc`, `plot`, `plotCI`, `H0`, `mu0` and `Sigma0`.

For numeric vectors or lavaan fits with a formula quantity, the Monte
Carlo component reports MCError as the sampling standard error of the
simulated mean (SE / sqrt(n.mc)); this is not the error of the interval
endpoints. With H0 = TRUE, the Monte Carlo result contains the
alternative and null results. The type = "all" route preserves H0, mu0
and Sigma0 for its MC component; the asymptotic component remains the
interval at the supplied estimates.

## Examples

``` r
pn <- ProductNormal(mu = c(0.5, 0.3), Sigma = diag(2) * 0.1)
ci(pn)
#> $CI
#> [1] -0.1842979  0.6573154
#> 
#> $Estimate
#> [1] 0.15
#> 
#> $SE
#> [1] 0.2097618
#> 
```

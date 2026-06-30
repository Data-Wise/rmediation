# Enhanced ProductNormal constructor with better validation

Enhanced ProductNormal constructor with better validation

## Usage

``` r
ProductNormal2(mu, Sigma, validate = TRUE)
```

## Arguments

- mu:

  Numeric vector of means

- Sigma:

  Covariance matrix

- validate:

  Whether to run additional validation (default: TRUE)

## Examples

``` r
pn <- ProductNormal2(mu = c(0.5, 0.3), Sigma = diag(2) * 0.1)
```

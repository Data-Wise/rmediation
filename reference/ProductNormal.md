# ProductNormal Class

Represents the distribution of the product of normal random variables.

## Usage

``` r
ProductNormal(mu = integer(0), Sigma = integer(0))
```

## Arguments

- mu:

  Numeric vector of means.

- Sigma:

  Covariance matrix.

## Examples

``` r
pn <- ProductNormal(mu = c(0.5, 0.3), Sigma = diag(2) * 0.1)
```

# ProductNormal3 Class

Represents the distribution of the product of three normal random
variables. Intended for sequential indirect effects of the form
`a1 * a2 * b`, where `(a1, a2, b)` is asymptotically trivariate normal.

## Usage

``` r
ProductNormal3(mu = integer(0), Sigma = integer(0), method = character(0))
```

## Arguments

- mu:

  Numeric vector of means of length 3: `c(a1_hat, a2_hat, b_hat)`.

- Sigma:

  3x3 asymptotic covariance matrix of `(a1, a2, b)`.

- method:

  Integration method. Currently only `"hcubature"` is supported.

## Examples

``` r
obj <- ProductNormal3(
  mu = c(0.5, 0.3, 0.2),
  Sigma = diag(3),
  method = "hcubature"
)
obj
#> ProductNormal3 Distribution
#> Variables: a1 * a2 * b
#> Means: 0.5, 0.3, 0.2 
#> Covariance matrix:
#>      [,1] [,2] [,3]
#> [1,]    1    0    0
#> [2,]    0    1    0
#> [3,]    0    0    1
#> Integration method: hcubature 
cdf(obj, q = 1)
#> [1] 0.9057254
if (FALSE) { # \dontrun{
confint(obj, level = 0.95)
} # }
```

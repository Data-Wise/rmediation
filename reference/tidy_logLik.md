# Creates a data.frame for a log-likelihood object

Creates a data.frame for a log-likelihood object

## Usage

``` r
# S3 method for class 'logLik'
tidy(x, ...)
```

## Arguments

- x:

  x A log-likelihood object, typically returned by
  [logLik](https://rdrr.io/r/stats/logLik.html).

- ...:

  Additional arguments (not used)

## Value

A [data.frame](https://rdrr.io/r/base/data.frame.html) with columns:

- term:

  The term name

- estimate:

  The log-likelihood value

- df:

  The degrees of freedom

## See also

[`logLik`](https://rdrr.io/r/stats/logLik.html)

## Author

Davood Tofighi <dtofighi@gmail.com>

## Examples

``` r
fit <- lm(mpg ~ wt, data = mtcars)
logLik_fit <- logLik(fit)
tidy(logLik_fit)
#>            term  estimate df
#> 1 logLikelihood -80.01471  3
```

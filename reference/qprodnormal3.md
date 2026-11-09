# Quantile Function for the Product of Three Normal Variables

Computes the quantile `q` with `P(X1 * X2 * X3 <= q) = p` (or `> q`, for
`lower.tail = FALSE`) where `(X1, X2, X3)` follows a trivariate normal
distribution with mean vector `mean` and covariance matrix `cov`. It
inverts
[`pprodnormal3()`](https://data-wise.github.io/rmediation/reference/pprodnormal3.md)
by root-finding, bracketed by the delta-method interval, and is the same
routine behind
[`dist_quantile()`](https://data-wise.github.io/rmediation/reference/dist_quantile.md)
for a
[ProductNormal3](https://data-wise.github.io/rmediation/reference/ProductNormal3.md)
object.

## Usage

``` r
qprodnormal3(p, mean, cov, lower.tail = TRUE, tol = 1e-06)
```

## Arguments

- p:

  Numeric vector of probabilities in `[0, 1]`, no missing values. `0`
  and `1` return `-Inf` and `Inf` (reversed for `lower.tail = FALSE`).

- mean:

  Numeric vector of means of length 3.

- cov:

  3x3 covariance matrix, as for
  [`pprodnormal3()`](https://data-wise.github.io/rmediation/reference/pprodnormal3.md).

- lower.tail:

  Logical; if `TRUE` (default) `p` is `P(X1 * X2 * X3 <= q)`, otherwise
  `P(X1 * X2 * X3 > q)`. The upper tail is inverted through the directly
  integrated upper tail of
  [`pprodnormal3()`](https://data-wise.github.io/rmediation/reference/pprodnormal3.md),
  so a small upper-tail `p` is resolved.

- tol:

  Positive tolerance used for both the CDF evaluation and the
  root-finder (default `1e-6`). It is absolute, so for a probability `p`
  use a `tol` well below `p`;
  [`pprodnormal3()`](https://data-wise.github.io/rmediation/reference/pprodnormal3.md)
  explains why.

## Value

A numeric vector the same length and names as `p`. Three zero-variance
components give a point mass, whose quantile is `prod(mean)` for any `p`
strictly between 0 and 1.

## See also

[`pprodnormal3()`](https://data-wise.github.io/rmediation/reference/pprodnormal3.md)
for the CDF,
[`qprodnormal()`](https://data-wise.github.io/rmediation/reference/qprodnormal.md)
for two factors,
[`dist_quantile()`](https://data-wise.github.io/rmediation/reference/dist_quantile.md)
for the object interface.

## Examples

``` r
qprodnormal3(c(0.025, 0.5, 0.975), mean = c(1, 1, 1), cov = diag(3))
#> [1] -2.7142556  0.2704444  8.0329270
# an upper-tail probability of 1e-8, resolved with a matching tolerance
qprodnormal3(1e-8, mean = c(1, 1, 1), cov = diag(3), lower.tail = FALSE, tol = 1e-12)
#> [1] 73.10362
```

# Cumulative Distribution Function for the Product of Three Normal Variables

Computes `P(X1 * X2 * X3 <= q)` where `(X1, X2, X3)` follows a
trivariate normal distribution with mean vector `mean` and covariance
matrix `cov`. `Z` is marginalised analytically through the conditional
Gaussian structure `Z | (X, Y)`, and the remaining two-dimensional
integral is evaluated with adaptive cubature (dimension reduction; see
Tofighi, 2026).

## Usage

``` r
p_prod3(q, mean, cov, method = "hcubature", tol = 1e-06)
```

## Arguments

- q:

  Numeric scalar quantile.

- mean:

  Numeric vector of means of length 3.

- cov:

  3x3 covariance matrix. Must be positive-definite, except that a single
  zero-variance component is permitted (the problem then reduces to the
  two-variable product-normal case). Perfect correlation between two
  components (`|rho| = 1`) or an indefinite matrix is rejected.

- method:

  Integration method. Currently only `"hcubature"` is supported.

- tol:

  Numeric tolerance passed to the integration routine; must be strictly
  positive.

## Value

Probability `P(X1 * X2 * X3 <= q)` as a numeric scalar in `[0, 1]`.

## Note

Numerical accuracy can degrade as the standardised `(X, Y)` correlation
approaches `+-1` (the bivariate block becomes ill-conditioned). For a
fully degenerate point mass (all variances zero) with zero means,
`q == 0` returns `0.5` by the mid-distribution convention rather than
`0` or `1`.

## Examples

``` r
Sigma <- diag(3)
p_prod3(q = 0, mean = c(0, 0, 0), cov = Sigma)
#> [1] 0.5
```

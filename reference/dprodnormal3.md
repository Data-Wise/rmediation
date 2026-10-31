# Density of the Product of Three Normal Variables

Exact density of \\X_1 X_2 X_3\\ when \\(X_1, X_2, X_3)\\ is trivariate
normal with mean `mean` and covariance `cov`, the density counterpart of
[`pprodnormal3()`](https://data-wise.github.io/rmediation/reference/pprodnormal3.md).
No closed form is known for the general case (Gaunt, 2022), so the
density is a two-dimensional integral: conditioning on \\X_1 = x\\ makes
\\(X_2, X_3)\\ bivariate normal, whose product has the density of
[`dprodnormal()`](https://data-wise.github.io/rmediation/reference/dprodnormal.md),
and \$\$f(v) = \int \phi(x; \mu_1, \sigma_1^2)\\ f\_{X_2 X_3 \mid x}(v /
x)\\ / \|x\|\\ dx.\$\$ The inner density is the Rohatgi/Glen integral
used by
[`dprodnormal()`](https://data-wise.github.io/rmediation/reference/dprodnormal.md)
(conditional means and the partial correlation are computed per \\x\\).

## Usage

``` r
dprodnormal3(x, mean, cov, log = FALSE)
```

## Arguments

- x:

  Numeric vector of quantiles.

- mean:

  Numeric vector of means of length 3.

- cov:

  3x3 covariance matrix; must be positive definite.

- log:

  Logical; return the log density.

## Value

Numeric vector of densities, the length of `x`.

## Details

The density has a logarithmic singularity at exactly `0` (returned as
`Inf`), as for
[`dprodnormal()`](https://data-wise.github.io/rmediation/reference/dprodnormal.md).
Unlike
[`pprodnormal3()`](https://data-wise.github.io/rmediation/reference/pprodnormal3.md),
zero-variance components are not supported: a point mass has no density.

## References

Gaunt, R. E. (2022). On the product of three normal random variables.
See also the references of
[`dprodnormal()`](https://data-wise.github.io/rmediation/reference/dprodnormal.md).

## See also

[`pprodnormal3()`](https://data-wise.github.io/rmediation/reference/pprodnormal3.md)
for the CDF,
[`dprodnormal()`](https://data-wise.github.io/rmediation/reference/dprodnormal.md)
for two factors.

## Examples

``` r
Sigma <- matrix(c(1, .3, .2, .3, 1, .1, .2, .1, 1), 3)
dprodnormal3(c(0.1, 0.5, 1), mean = c(0.5, 0.4, 0.3), cov = Sigma)
#> [1] 0.8662498 0.2349625 0.1075559
```

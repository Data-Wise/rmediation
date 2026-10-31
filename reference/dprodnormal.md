# Density of the Product of Two Normal Random Variables

Evaluates the exact probability density function of \\XY\\, where \\(X,
Y)\\ is bivariate normal. It is the density companion to
[`pprodnormal`](https://data-wise.github.io/rmediation/reference/pprodnormal.md)
and
[`qprodnormal`](https://data-wise.github.io/rmediation/reference/qprodnormal.md)
and uses no Monte Carlo simulation.

## Usage

``` r
dprodnormal(x, mu.x, mu.y, se.x = 1, se.y = 1, rho = 0, log = FALSE)
```

## Arguments

- x:

  numeric vector of values at which to evaluate the density (the value
  of the product).

- mu.x, mu.y:

  means of \\X\\ and \\Y\\.

- se.x, se.y:

  standard deviations of \\X\\ and \\Y\\; must be positive.

- rho:

  correlation between \\X\\ and \\Y\\; must satisfy \\-1 \< \rho \< 1\\.
  The default is 0.

- log:

  logical; if `TRUE`, the logarithm of the density is returned.

## Value

A numeric vector of densities (or log densities), one per element of
`x`.

## Details

For general means and correlation the density is the one-dimensional
integral \\f(z) = \int f\_{X,Y}(x, z/x)\\\|x\|^{-1}\\dx\\ (Rohatgi; Glen
et al., 2004), evaluated by adaptive quadrature over the range that
carries the mass of the conditioning variable and split at the sign
change at zero. When both means are zero the closed form \$\$f(z) =
\frac{\exp\\\rho z/(1-\rho^2)\\\\
K_0\\\|z\|/(1-\rho^2)\\}{\pi\sqrt{1-\rho^2}}\$\$ (unit variances;
rescaled here) is used instead, with \\K_0\\ the modified Bessel
function of the second kind (Nadarajah and Pogany, 2016; Gaunt, 2019).
The two agree to near machine precision.

The density is infinite at exactly `x = 0` for every parameter setting
(a logarithmic singularity: \\XY\\ is near zero whenever either factor
is), so `dprodnormal(0, ...)` returns `Inf`. Plot it on a grid that
avoids 0 and clip the vertical axis.

## References

Craig, C. C. (1936). On the frequency function of xy. *Annals of
Mathematical Statistics*, **7**, 1–15.

Glen, A. G., Leemis, L. M. and Drew, J. H. (2004). Computing the
distribution of the product of two continuous random variables.
*Computational Statistics & Data Analysis*, **44**, 451–464.

Nadarajah, S. and Pogany, T. K. (2016). On the distribution of the
product of correlated normal random variables. *Comptes Rendus
Mathematique*, **354**, 201–204.

## See also

[`pprodnormal`](https://data-wise.github.io/rmediation/reference/pprodnormal.md),
[`qprodnormal`](https://data-wise.github.io/rmediation/reference/qprodnormal.md)

## Examples

``` r
dprodnormal(c(-0.1, 0.05, 0.3), mu.x = 0.5, mu.y = 0.3, se.x = 0.2, se.y = 0.4, rho = 0.3)
#> [1] 0.8608815 2.1079806 1.1210739

# the density integrates to the CDF
integrate(dprodnormal, 0.001, 0.3, mu.x = 0.5, mu.y = 0.3, se.x = 0.2, se.y = 0.4)$value
#> [1] 0.5488999
pprodnormal(0.3, 0.5, 0.3, 0.2, 0.4) - pprodnormal(0.001, 0.5, 0.3, 0.2, 0.4)
#> [1] 0.5488999
```

# Internal: Compute CI using Asymptotic method (Delta method)

Computes asymptotic confidence intervals using normal approximation
(Sobel test). The standard error is computed using Craig's (1936)
formula: \$\$SE = \sqrt{\sigma_y^2\mu_x^2 + \sigma_x^2\mu_y^2 +
2\mu_x\mu_y\rho\sigma_x\sigma_y + \sigma_x^2\sigma_y^2 +
\sigma_x^2\sigma_y^2\rho^2}\$\$ and the CI is \\Estimate \pm
z\_{1-\alpha/2} \times SE\\, where \\z\_{1-\alpha/2}\\ is the standard
normal quantile.

## Usage

``` r
.compute_ci_asymp(object, alpha = 0.05)
```

## Arguments

- object:

  ProductNormal object

- alpha:

  Significance level (default: 0.05)

## Value

List with CI, Estimate, SE

# Internal: Compute CI using Distribution of Product (Meeker & Escobar 1994)

Computes confidence intervals for the product of two normal random
variables using the exact distribution method. The point estimate is
\\\mu_x\mu_y + \sigma\_{xy}\\ and the standard error follows Craig
(1936): \$\$SE = \sqrt{\sigma_y^2\mu_x^2 + \sigma_x^2\mu_y^2 +
2\mu_x\mu_y\rho\sigma_x\sigma_y + \sigma_x^2\sigma_y^2 +
\sigma_x^2\sigma_y^2\rho^2}\$\$

## Usage

``` r
.compute_ci_dop(object, alpha = 0.05)
```

## Arguments

- object:

  ProductNormal object

- alpha:

  Significance level (default: 0.05)

## Value

List with CI, Estimate, SE

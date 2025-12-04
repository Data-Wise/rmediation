# Internal: Compute CI using Monte Carlo method

Internal: Compute CI using Monte Carlo method

## Usage

``` r
.compute_ci_mc(object, alpha = 0.05, n.mc = 1e+05)
```

## Arguments

- object:

  ProductNormal object

- alpha:

  Significance level (default: 0.05)

- n.mc:

  Monte Carlo sample size (default: 1e5)

## Value

List with CI, Estimate, SE, MC.Error

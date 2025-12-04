# Confidence Interval for MediationData Objects

Computes confidence intervals for the indirect effect from a medfit
MediationData object using RMediation's methods (DOP, Monte Carlo,
etc.).

## Usage

``` r
ci_mediation_data(mu, level = 0.95, type = "dop", n.mc = 1e+05, ...)

ci_serial_mediation_data(mu, level = 0.95, type = "MC", n.mc = 1e+05, ...)
```

## Arguments

- mu:

  A MediationData object from the medfit package

- level:

  Confidence level (default 0.95 for 95% CI)

- type:

  Type of CI method: "dop" (Distribution of Product), "MC" (Monte
  Carlo), or "asymp" (asymptotic normal)

- n.mc:

  Number of Monte Carlo samples (for type = "MC")

- ...:

  Additional arguments passed to underlying methods

## Value

A list with components:

- CI:

  The confidence interval (lower, upper)

- Estimate:

  Point estimate of indirect effect (a\*b)

- SE:

  Standard error of indirect effect

- type:

  Method used for CI computation

## Details

This method extracts the a and b path coefficients from the
MediationData object, along with their standard errors and covariance,
and computes confidence intervals using RMediation's methods.

### Method Options

- **"dop"**: Distribution of Product method. Uses the exact or
  approximate distribution of the product of two normal random
  variables. Recommended for most applications.

- **"MC"**: Monte Carlo simulation. Samples from the joint distribution
  of a and b to estimate the CI. Use `n.mc` to control precision.

- **"asymp"**: Asymptotic normal approximation using the delta method.
  Fast but may be inaccurate for small samples or non-normal
  distributions.

## See also

[`ci`](https://data-wise.github.io/rmediation/reference/ci.md) for the
generic function,
[`MediationData`](https://data-wise.github.io/medfit/reference/MediationData.html)
for the input class,
[`ProductNormal`](https://data-wise.github.io/rmediation/reference/ProductNormal.md)
for the underlying distribution class

## Examples

``` r
if (FALSE) { # \dontrun{
library(medfit)
library(RMediation)

# Fit mediation models
fit_m <- lm(M ~ X + C, data = mydata)
fit_y <- lm(Y ~ X + M + C, data = mydata)

# Extract mediation structure
med_data <- extract_mediation(fit_m, model_y = fit_y,
                               treatment = "X", mediator = "M")

# Compute CI using Distribution of Product
ci(med_data, type = "dop")

# Compute CI using Monte Carlo
ci(med_data, type = "MC", n.mc = 10000)
} # }
```

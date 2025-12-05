# Package index

## Core Functions

Main user-facing functions for mediation analysis confidence intervals
and hypothesis testing.

- [`medci()`](https://data-wise.github.io/rmediation/reference/medci.md)
  : Confidence Interval for the Mediated Effect
- [`ci()`](https://data-wise.github.io/rmediation/reference/ci.md) :
  Confidence Interval
- [`ci_mediation_data()`](https://data-wise.github.io/rmediation/reference/ci_mediation_data.md)
  [`ci_serial_mediation_data()`](https://data-wise.github.io/rmediation/reference/ci_mediation_data.md)
  : Confidence Interval for MediationData Objects
- [`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md) :
  Model-based Constrained Optimization (MBCO) Chi-squared Test

## Distribution Functions

Distribution functions for the product of two normal random variables.

- [`pprodnormal()`](https://data-wise.github.io/rmediation/reference/pprodnormal.md)
  : Percentile for the Distribution of Product of Two Normal Variables
- [`qprodnormal()`](https://data-wise.github.io/rmediation/reference/qprodnormal.md)
  : Quantile for the Distribution of Product of Two Normal Variables
- [`pMC()`](https://data-wise.github.io/rmediation/reference/pMC.md) :
  Probability (percentile) for the Monte Carlo Sampling Distribution of
  a nonlinear function of coefficients estimates
- [`qMC()`](https://data-wise.github.io/rmediation/reference/qMC.md) :
  Quantile for the Monte Carlo Sampling Distribution of a nonlinear
  function of coefficients estimates

## Datasets

Example datasets for demonstrating mediation analysis.

- [`memory_exp`](https://data-wise.github.io/rmediation/reference/memory_exp.md)
  : Memory Experiment Data Description from MacKinnon et al., 2018

## S7 Classes and Generics

Modern S7 object-oriented classes and generic functions for type-safe
mediation analysis.

- [`ProductNormal()`](https://data-wise.github.io/rmediation/reference/ProductNormal.md)
  : ProductNormal Class
- [`MBCOResult()`](https://data-wise.github.io/rmediation/reference/MBCOResult.md)
  : MBCO Result Class
- [`cdf()`](https://data-wise.github.io/rmediation/reference/cdf.md) :
  Cumulative Distribution Function
- [`dist_quantile()`](https://data-wise.github.io/rmediation/reference/dist_quantile.md)
  : Distribution Quantile Function

## Utility Functions

S3 methods, validation helpers, and utility functions.

- [`utils_validation`](https://data-wise.github.io/rmediation/reference/utils_validation.md)
  : Enhanced validation and utility functions for ProductNormal class
- [`ProductNormal2()`](https://data-wise.github.io/rmediation/reference/ProductNormal2.md)
  : Enhanced ProductNormal constructor with better validation
- [`ProductNormal_from_lavaan()`](https://data-wise.github.io/rmediation/reference/ProductNormal_from_lavaan.md)
  : Utility function to create ProductNormal from lavaan parameter
  estimates
- [`validate_ProductNormal()`](https://data-wise.github.io/rmediation/reference/validate_ProductNormal.md)
  : Additional validation for ProductNormal objects
- [`is_valid_for_computation()`](https://data-wise.github.io/rmediation/reference/is_valid_for_computation.md)
  : Method to check if ProductNormal object is properly specified for
  computation
- [`tidy()`](https://data-wise.github.io/rmediation/reference/tidy.md) :
  Tidy generic function
- [`tidy(`*`<logLik>`*`)`](https://data-wise.github.io/rmediation/reference/tidy_logLik.md)
  : Creates a data.frame for a log-likelihood object

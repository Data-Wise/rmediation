# Package index

## Core Functions

Main user-facing functions for mediation analysis confidence intervals
and hypothesis testing.

- [`medci()`](medci.md) : Confidence Interval for the Mediated Effect
- [`ci()`](ci.md) : CI for a nonlinear function of coefficients
  estimates
- [`mbco()`](mbco.md) : Model-based Constrained Optimization (MBCO)
  Chi-squared Test

## Distribution Functions

Distribution functions for the product of two normal random variables.

- [`pprodnormal()`](pprodnormal.md) : Percentile for the Distribution of
  Product of Two Normal Variables
- [`qprodnormal()`](qprodnormal.md) : Quantile for the Distribution of
  Product of Two Normal Variables
- [`pMC()`](pMC.md) : Probability (percentile) for the Monte Carlo
  Sampling Distribution of a nonlinear function of coefficients
  estimates
- [`qMC()`](qMC.md) : Quantile for the Monte Carlo Sampling Distribution
  of a nonlinear function of coefficients estimates

## Datasets

Example datasets for demonstrating mediation analysis.

- [`memory_exp`](memory_exp.md) : Memory Experiment Data Description
  from MacKinnon et al., 2018

## Utility Functions

S3 methods and helper functions.

- [`tidy(`*`<logLik>`*`)`](tidy_logLik.md) : Creates a data.frame for a
  log-likelihood object

# Internal: Compute CDF using Monte Carlo

Computes the cumulative distribution function \\P(XY \le q)\\ for the
product of normal random variables using Monte Carlo simulation. Works
for any number of variables.

## Usage

``` r
.compute_cdf_mc(object, q, n.mc = 1e+05)
```

## Arguments

- object:

  ProductNormal object

- q:

  Quantile value

- n.mc:

  Monte Carlo sample size

## Value

Probability \\P(XY \le q)\\

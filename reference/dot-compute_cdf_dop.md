# Internal: Compute CDF using Distribution of Product

Computes the cumulative distribution function \\P(XY \le q)\\ for the
product of two normal random variables using numerical integration
(Meeker & Escobar, 1994).

## Usage

``` r
.compute_cdf_dop(object, q)
```

## Arguments

- object:

  ProductNormal object

- q:

  Quantile value

## Value

Probability \\P(XY \le q)\\

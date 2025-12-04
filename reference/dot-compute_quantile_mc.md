# Internal: Compute quantile using Monte Carlo

Internal: Compute quantile using Monte Carlo

## Usage

``` r
.compute_quantile_mc(object, p, n.mc = 1e+05, lower.tail = TRUE)
```

## Arguments

- object:

  ProductNormal object

- p:

  Probability

- n.mc:

  Monte Carlo sample size

- lower.tail:

  Logical; if TRUE (default), probabilities are P(X \<= x)

## Value

Quantile value

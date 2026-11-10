# Internal: Compute quantile using Distribution of Product

Internal: Compute quantile using Distribution of Product

## Usage

``` r
.compute_quantile_dop(object, p, lower.tail = TRUE)
```

## Arguments

- object:

  ProductNormal object

- p:

  Probability, or a vector of probabilities

- lower.tail:

  Logical; if TRUE (default), probabilities are P(X \<= x)

## Value

A list with `q` (one quantile per element of `p`, names kept) and
`error`

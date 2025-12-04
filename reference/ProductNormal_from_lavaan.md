# Utility function to create ProductNormal from lavaan parameter estimates

Utility function to create ProductNormal from lavaan parameter estimates

## Usage

``` r
ProductNormal_from_lavaan(lavaan_model, param_names)
```

## Arguments

- lavaan_model:

  A fitted lavaan model object

- param_names:

  Names of parameters to include in the product (e.g., c("a", "b"))

## Value

A ProductNormal object

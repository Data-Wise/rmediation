# Internal: Compute quantile using Meeker & Escobar (1994) algorithm

Delegates to `qprodnormalMeeker()` so the S7 core and
[`medci()`](https://data-wise.github.io/rmediation/reference/medci.md)
share one integral (this function used to carry its own copy, which kept
the issue \#60 defect).

## Usage

``` r
.compute_quantile_dop_internal(
  p,
  mu.x,
  mu.y,
  se.x,
  se.y,
  rho = 0,
  lower.tail = TRUE
)
```

# MBCO Result Class

A class representing the results of a Model-Based Constrained
Optimization (MBCO) test.

## Usage

``` r
MBCOResult(
  statistic = integer(0),
  df = integer(0),
  p_value = integer(0),
  type = character(0),
  refit = NULL,
  branch = NULL,
  dropped = NULL
)
```

## Arguments

- statistic:

  Numeric test statistic value.

- df:

  Numeric degrees of freedom.

- p_value:

  Numeric p-value.

- type:

  Character string indicating the type of test.

- refit:

  `NULL` (default) when no refit happened, or a list with `tolerance`,
  `statistic_before` and `statistic_after` (all single finite numbers)
  when
  [`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md)
  refit a violated `h0` at a tighter feasibility tolerance.
  [`print()`](https://rdrr.io/r/base/print.html) and
  [`summary()`](https://rdrr.io/r/base/summary.html) show a note when it
  is set.

- branch:

  `NULL` (default), or the label of the single-path null that gave the
  reported result when the result comes from
  [`mbco_product_null()`](https://data-wise.github.io/rmediation/reference/mbco_product_null.md).

- dropped:

  `NULL` (default) for a result without a bootstrap, or a single
  non-negative whole number: the count of bootstrap replicates whose
  fits did not converge and were left out of the null distribution (`0`
  when none were). The p-value is taken over the remaining `R - dropped`
  replicates.

## Examples

``` r
res <- MBCOResult(statistic = 4.2, df = 1, p_value = 0.04, type = "asymp")
```

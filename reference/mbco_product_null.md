# MBCO test of a product null (a zero-product indirect effect)

Tests the null that a product of paths is zero (`a * b = 0`, or a serial
`a1 * a2 * b = 0`) with OpenMx. The null holds when any single path is
0, so it is a union of single-path nulls. `mbco_product_null()` fits one
null per path by fixing that path at 0 in a copy of the fitted full
model, runs
[`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md) on
each, and returns the result of the branch with the largest p-value,
because a test of a union rejects only if every single-path null is
rejected (an intersection-union test). For `type = "asymp"` this is the
smaller statistic with 1 degree of freedom.

## Usage

``` r
mbco_product_null(h1, paths, ...)
```

## Arguments

- h1:

  A fitted full `OpenMx` model.

- paths:

  Character vector of two or more labels of free parameters of `h1`, the
  paths whose product is tested.

- ...:

  Passed to
  [`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md)
  (`type`, `R`, `alpha`, `optim`, ...).

## Value

An
[MBCOResult](https://data-wise.github.io/rmediation/reference/MBCOResult.md)
for the binding branch, with the label of its single-path null in the
`branch` slot.

## Details

A single nonlinear constraint such as `ind == 0` can converge to the
branch with the larger statistic and give a wrong test; see
[`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md),
which warns when it detects this. Fixing a parameter is exact, so this
function avoids that and the feasibility tolerance problem. The p-value
is conservative when more than one path is 0 (standard
intersection-union theory, not verified here). Each branch fit must
converge (OpenMx status code 0 or 1); otherwise the function stops with
an error naming the branch. `h1` must have converged too (class
`RMediation_h1_nonconverged` otherwise): the null models start from its
estimates and every statistic is measured against its fit, so a p-value
from an unconverged `h1` would not be reliable.

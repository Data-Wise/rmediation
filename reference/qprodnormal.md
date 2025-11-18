# Quantile for the Distribution of Product of Two Normal Variables

Generates quantiles for the distribution of product of two normal random
variables

## Usage

``` r
qprodnormal(
  p,
  mu.x,
  mu.y,
  se.x,
  se.y,
  rho = 0,
  lower.tail = TRUE,
  type = "dop",
  n.mc = 1e+05
)
```

## Arguments

- p:

  probability

- mu.x:

  mean of \\x\\

- mu.y:

  mean of \\y\\

- se.x:

  standard error (deviation) of \\x\\

- se.y:

  standard error (deviation) of \\y\\

- rho:

  correlation between \\x\\ and \\y\\, where -1 \<`rho` \< 1. The
  default value is 0.

- lower.tail:

  logical; if `TRUE` (default), the probability is \\P\[X\*Y \< q\]\\;
  otherwise, \\P\[X\*Y \> q\]\\

- type:

  method used to compute confidence interval. It takes on the values
  `"dop"` (default), `"MC"`, `"asymp"` or `"all"`

- n.mc:

  when `type="MC"`, `n.mc` determines the sample size for the Monte
  Carlo method. The default sample size is 1E5.

## Value

An object of the type [`list`](https://rdrr.io/r/base/list.html) that
contains the following values:

- q:

  quantile corresponding to probability `p`

- error:

  estimate of the absolute error

## Details

This function returns a quantile and the associated error (accuracy)
corresponding the requested percentile (probability) `p` of the
distribution of product of mediated effect (product of two normal random
variables). To obtain a quantile using a specific method, the argument
`type` should be specified. The default method is `type="dop"`, which
uses the method described by Meeker and Escobar (1994) to evaluate the
CDF of the distribution of product of two normal variables. `type="MC"`
uses the Monte Carlo approach (Tofighi & MacKinnon, 2011). `type="all"`
prints quantiles using all three options. For the method `type="dop"`,
the error is the modulus of absolute error for the numerical integration
(for more information see Meeker and Escobar, 1994). For `type="MC"`,
the error refers to the Monte Carlo error.

## References

Tofighi, D. and MacKinnon, D. P. (2011). RMediation: An R package for
mediation analysis confidence intervals. *Behavior Research Methods*,
**43**, 692–700. doi:10.3758/s13428-011-0076-x

## See also

[`medci`](https://data-wise.github.io/rmediation/reference/medci.md)
[`RMediation-package`](https://data-wise.github.io/rmediation/reference/RMediation-package.md)

## Author

Davood Tofighi <dtofighi@gmail.com>

## Examples

``` r
## lower tail
qprodnormal(
  p = .1, mu.x = .5, mu.y = .3, se.x = 1, se.y = 1, rho = 0,
  lower.tail = TRUE, type = "all"
)
#> $`Distribution of Product`
#> [1] -0.9898408
#> 
#> $`Monte Carlo`
#> [1] -0.9970027
#> 
## upper tail
qprodnormal(
  p = .1, mu.x = .5, mu.y = .3, se.x = 1, se.y = 1, rho = 0,
  lower.tail = FALSE, type = "all"
)
#> $`Distribution of Product`
#> [1] 1.433771
#> 
#> $`Monte Carlo`
#> [1] 1.426408
#> 
```

# Confidence Interval for the Mediated Effect (PROTOTYPE S7 Wrapper)

Confidence Interval for the Mediated Effect (PROTOTYPE S7 Wrapper)

## Usage

``` r
medci_prototype(
  mu.x,
  mu.y,
  se.x,
  se.y,
  rho = 0,
  alpha = 0.05,
  type = "dop",
  plot = FALSE,
  plotCI = FALSE,
  n.mc = 1e+05,
  ...
)
```

## Arguments

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

- alpha:

  significance level for the confidence interval. The default value is
  .05.

- type:

  method used to compute confidence interval. It takes on the values
  `"dop"` (default), `"MC"`, `"asymp"` or `"all"`

- plot:

  when `TRUE`, plots the distribution of `n.mc` data points from the
  distribution of product of two normal random variables using the
  density estimates provided by the function
  [`density`](https://rdrr.io/r/stats/density.html). The default value
  is `FALSE`.

- plotCI:

  when `TRUE`, overlays a confidence interval with error bars on the
  plot for the mediated effect. Note that to obtain the CI plot, one
  must also specify `plot="TRUE"`. The default value is `FALSE`.

- n.mc:

  when `type="MC"`, `n.mc` determines the sample size for the Monte
  Carlo method. The default sample size is 1E5.

- ...:

  additional arguments to be passed on to the function.

# Quantile for the Monte Carlo Sampling Distribution of a nonlinear function of coefficients estimates

This function returns a quantile corresponding to the probability `p`.

## Usage

``` r
qMC(p, mu, Sigma, quant, n.mc = 1e+06, ...)
```

## Arguments

- p:

  probability.

- mu:

  a [vector](https://rdrr.io/r/base/vector.html) of means (e.g.,
  coefficient estimates) for the normal random variables. A user can
  assign a name to each mean value, e.g., `mu=c(b1=.1,b2=3)`; otherwise,
  the coefficient names are assigned automatically as follows:
  `b1,b2,...`.

- Sigma:

  either a covariance matrix or a
  [vector](https://rdrr.io/r/base/vector.html) that stacks all the
  columns of the lower triangle variance–covariance matrix one
  underneath the other.

- quant:

  quantity of interest, which is a nonlinear/linear function of the
  model parameters. Argument `quant` is a
  [formula](https://rdrr.io/r/stats/formula.html) that **must** start
  with the symbol "tilde" (`~`): e.g., `~b1*b2*b3*b4`. The names of
  coefficients must conform to the names provided in the argument `mu`
  or to the default names, i.e., `b1,b2,...`.

- n.mc:

  Monte Carlo sample size. The default sample size is 1e+6.

- ...:

  additional arguments.

## Value

scalar quantile value.

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
qMC(.05,
  mu = c(b1 = 1, b2 = .7, b3 = .6, b4 = .45), Sigma = c(.05, 0, 0, 0, .05, 0, 0, .03, 0, .03),
  quant = ~ b1 * b2 * b3 * b4
)
#>         5% 
#> 0.03754532 
```

# Probability (percentile) for the Monte Carlo Sampling Distribution of a nonlinear function of coefficients estimates

This function returns a probability corresponding to the quantile `q`.

## Usage

``` r
pMC(q, mu, Sigma, quant, lower.tail = TRUE, n.mc = 1e+05, ...)
```

## Arguments

- q:

  quantile

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

- lower.tail:

  logical; if `TRUE` (default), the probability is \\P\[quant \< q\]\\;
  otherwise, \\P\[quant \> q\]\\

- n.mc:

  Monte Carlo sample size (default: 1e5). Larger values provide more
  precision but take longer to compute.

- ...:

  additional arguments.

## Value

scalar probability value.

## References

Tofighi, D. and MacKinnon, D. P. (2011). RMediation: An R package for
mediation analysis confidence intervals. *Behavior Research Methods*,
**43**, 692–700. doi:10.3758/s13428-011-0076-x

## Author

Davood Tofighi <dtofighi@gmail.com>

## Examples

``` r
pMC(.2,
  mu = c(b1 = 1, b2 = .7, b3 = .6, b4 = .45), Sigma = c(.05, 0, 0, 0, .05, 0, 0, .03, 0, .03),
  quant = ~ b1 * b2 * b3 * b4
)
#> [1] 0.61953
```

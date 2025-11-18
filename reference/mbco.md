# Model-based Constrained Optimization (MBCO) Chi-squared Test

This function computes asymptotic MBCO chi-squared test for a smooth
function of model parameters including a function of indirect effects.

## Usage

``` r
mbco(
  h0 = NULL,
  h1 = NULL,
  R = 10L,
  type = "asymp",
  alpha = 0.05,
  checkHess = "No",
  checkSE = "No",
  optim = "SLSQP",
  precision = 1e-09
)
```

## Arguments

- h0:

  An `OpenMx` model estimated under a null hypothesis, which is a more
  constrained model

- h1:

  An `OpenMx` model estimated under an alternative hypothesis, which is
  a less constrained model. This is usually a model hypothesized by a
  researcher.

- R:

  The number of bootstrap draws.

- type:

  If 'asymp' (default), the asymptotic MBCO chi-squares test comparing
  fit of h0 and h1. If 'parametric', the parametric bootstrap MBCO
  chi-squared test is computed. If 'semi', the semi-parametric MBCO
  chi-squared is computed.

- alpha:

  Significance level with the default value of .05

- checkHess:

  If 'No' (default), the Hessian matrix would not be calculated.

- checkSE:

  if 'No' (default), the standard errors would not be calculated.

- optim:

  Choose optimizer available in OpenMx. The default optimizer is
  "SLSQP". Other optimizer choices are available. See
  [mxOption](https://rdrr.io/pkg/OpenMx/man/mxOption.html) for more
  details.

- precision:

  Functional precision. The default value is set to 1e-9. See
  [mxOption](https://rdrr.io/pkg/OpenMx/man/mxOption.html) for more
  details.

## Value

A [list](https://rdrr.io/r/base/list.html) that contains

- chisq:

  asymptotic chi-squared test statistic value

- `df`:

  chi-squared df

- p:

  chi-squared p-value computed based on the method specified by the
  argument `type`

## Author

Davood Tofighi <dtofighi@gmail.com>

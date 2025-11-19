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

## References

Tofighi, D., & Kelley, K. (2020). Indirect effects in sequential
mediation models: Evaluating methods for hypothesis testing and
confidence interval formation. *Multivariate Behavioral Research*,
**55**, 188–210.
[doi:10.1080/00273171.2019.1618545](https://doi.org/10.1080/00273171.2019.1618545)

Tofighi, D. (2020). Bootstrap Model-Based Constrained Optimization Tests
of Indirect Effects. *Frontiers in Psychology*, **10**, 2989.
[doi:10.3389/fpsyg.2019.02989](https://doi.org/10.3389/fpsyg.2019.02989)

## Author

Davood Tofighi <dtofighi@gmail.com>

## Examples

``` r
library(OpenMx)
#> OpenMx may run faster if it is compiled to take advantage of multiple cores.
data(memory_exp)
memory_exp$x <- as.numeric(memory_exp$x) - 1 # manually creating dummy codes
endVar <- c("x", "repetition", "imagery", "recall")
manifests <- c("x", "repetition", "imagery", "recall")
full_model <- mxModel(
  "memory_example",
  type = "RAM",
  manifestVars = manifests,
  mxPath(
    from = "x",
    to = endVar,
    arrows = 1,
    free = TRUE,
    values = .2,
    labels = c("a1", "a2", "cp")
  ),
  mxPath(
    from = "repetition",
    to = "recall",
    arrows = 1,
    free = TRUE,
    values = .2,
    labels = "b1"
  ),
  mxPath(
    from = "imagery",
    to = "recall",
    arrows = 1,
    free = TRUE,
    values = .2,
    labels = "b2"
  ),
  mxPath(
    from = manifests,
    arrows = 2,
    free = TRUE,
    values = .8
  ),
  mxPath(
    from = "one",
    to = endVar,
    arrows = 1,
    free = TRUE,
    values = .1
  ),
  mxAlgebra(a1 * b1, name = "ind1"),
  mxAlgebra(a2 * b2, name = "ind2"),
  mxCI("ind1", type = "both"),
  mxCI("ind2", type = "both"),
  mxData(observed = memory_exp, type = "raw")
)
#> Warning: Looks like there is a pre-existing one-headed path from 'x' to 'x'.
#> That path is now overwritten by a two-headed path between 'x' and 'x'.
#> To retain the one-headed path, either use 'dummy' latent variables, or directly modify the MxModel's 'A' matrix;
#> See the `mxPath()` help page for examples.
#> Be advised, this overwriting behavior may change in the future, so do not write scripts that rely upon it!
## Reduced  Model for indirect effect: a1*b1
null_model1 <- mxModel(
  model = full_model,
  name = "Null Model 1",
  mxConstraint(ind1 == 0, name = "ind1_eq0_constr")
)
full_model <- mxTryHard(full_model, checkHess = FALSE, silent = TRUE)
#> Beginning initial fit attemptFit attempt 0, fit=5637.33872082179, new current best! (was 86655.7966682804)Final run, for Hessian and/or standard errors and/or confidence intervals                                                                             
#> 
#>  Solution found!  Final fit=5637.3387 (started at 86655.797)  (1 attempt(s): 1 valid, 0 errors)
null_model1 <- mxTryHard(null_model1, checkHess = FALSE, silent = TRUE)
#> Beginning initial fit attemptFit attempt 0, fit=5637.39905321965, new current best! (was Inf)Final run, for Hessian and/or standard errors and/or confidence intervals                                                                         
#> 
#>  Solution found!  Final fit=5637.3991 (started at 86655.884)  (1 attempt(s): 1 valid, 0 errors)
mbco(null_model1, full_model)
#> $chisq
#> [1] 0.0603324
#> 
#> $df
#> [1] 1
#> 
#> $p
#> [1] 0.8059713
#> 
```

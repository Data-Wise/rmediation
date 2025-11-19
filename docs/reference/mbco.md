# Model-based Constrained Optimization (MBCO) Chi-squared Test

This function computes asymptotic MBCO chi-squared test for a smooth
function of model parameters including a function of indirect effects.

## Usage

``` r
mbco(h0, h1, ...)
```

## Arguments

- h0:

  An `OpenMx` model estimated under a null hypothesis, which is a more
  constrained model

- h1:

  An `OpenMx` model estimated under an alternative hypothesis, which is
  a less constrained model. This is usually a model hypothesized by a
  researcher.

- ...:

  Additional arguments.

## Value

An object of class `MBCOResult` containing

- statistic:

  asymptotic chi-squared test statistic value

- df:

  chi-squared df

- p_value:

  chi-squared p-value computed based on the method specified by the
  argument `type`

- type:

  The type of test performed

## Author

Davood Tofighi <dtofighi@gmail.com>

## Examples

``` r
if (FALSE) { # \dontrun{
data(memory_exp)
memory_exp$x <- as.numeric(memory_exp$x)-1 # manually creating dummy codes
endVar <- c('x', 'repetition', 'imagery', 'recall')
manifests <- c('x', 'repetition', 'imagery', 'recall')
full_model <- OpenMx::mxModel(
 "memory_example",
 type = "RAM",
 manifestVars = manifests,
 OpenMx::mxPath(
   from = "x",
   to = endVar,
   arrows = 1,
   free = TRUE,
   values = .2,
   labels = c("a1", "a2", "cp")
 ),
 OpenMx::mxPath(
   from = 'repetition',
  to = 'recall',
  arrows = 1,
   free = TRUE,
   values = .2,
   labels = 'b1'
 ),
 OpenMx::mxPath(
   from = 'imagery',
 to = 'recall',
 arrows = 1,
 free = TRUE,
 values = .2,
 labels = "b2"
),
OpenMx::mxPath(
 from = manifests,
 arrows = 2,
 free = TRUE,
 values = .8
),
OpenMx::mxPath(
 from = "one",
 to = endVar,
 arrows = 1,
 free = TRUE,
 values = .1
),
OpenMx::mxAlgebra(a1 * b1, name = "ind1"),
OpenMx::mxAlgebra(a2 * b2, name = "ind2"),
OpenMx::mxCI("ind1", type = "both"),
OpenMx::mxCI("ind2", type = "both"),
OpenMx::mxData(observed = memory_exp, type = "raw")
)
## Reduced  Model for indirect effect: a1*b1
null_model1 <- OpenMx::mxModel(
model= full_model,
name = "Null Model 1",
OpenMx::mxConstraint(ind1 == 0, name = "ind1_eq0_constr")
)
full_model <- OpenMx::mxTryHard(full_model, checkHess=FALSE, silent = TRUE )
null_model1 <- OpenMx::mxTryHard(null_model1, checkHess=FALSE, silent = TRUE )
mbco(null_model1,full_model)
} # }
```

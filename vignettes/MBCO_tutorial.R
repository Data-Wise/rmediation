## ---- echo = FALSE, message = FALSE--------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
   message = FALSE,
  strip.white = TRUE
)

## ----setup---------------------------------------------------------------
  library(RMediation)
  library(OpenMx)
  library(tidyverse)
  data("memory_exp")
  mxOption(NULL, "Default optimizer", "NPSOL")

## ----single_med_alt------------------------------------------------------
endVar <- c('imagery', 'recall') # name the endogenous variables
maniVar <-
  c('x', 'imagery', 'recall') # name the osbserved variables

single_med <- mxModel(
  "Model 1",
  type = "RAM",
  manifestVars = maniVar,
  #specify the manifest (oberved) variables
  mxPath(
    from = "x",
    to = endVar,
    arrows = 1,
    free = TRUE,
    values = .2,
    labels = c("b1", "b3") # specify the path from X to the M (Imagery) and Y (recall)
  ),
  mxPath(
    from = 'imagery',
    to = 'recall',
    arrows = 1,
    free = TRUE,
    values = .2,
    labels = "b2" # Specify the path from M to Y
  ),
  mxPath(
    from = maniVar,
    arrows = 2,
    free = TRUE,
    values = .8,
    labels = c("s2x", "s2em", "s2ey") # Specify (residial) variances for the observed variables
  ),
  mxPath(
    from = "one",
    to = endVar,
    arrows = 1,
    free = TRUE,
    values = .1, 
    labels = c("int1","int2") # Specify the intercepts for the endogenous variables
  ),
  mxAlgebra(b1 * b2, name = "ind"),
  # define the indirect effect and call it ind
  mxData(observed = memory_exp, type = "raw") # specify the data set for analysis
)
single_med <- mxRun(single_med) # run the single mediator null model
stat_Model1 <- summary(single_med) # saving the results
stat_Model1 # rinting resuslts of the full model

## ----single_med_null-----------------------------------------------------
## The  Model is obtained by contraining indirect effect: b1*b2 to zero
single_med_null <- mxModel(model = single_med,
                           name = "Model 2",
                           mxConstraint(ind == 0, name = "b1b2_equals_0")) # non-linear constraint
single_med_null <- mxRun(single_med_null)  # Run the model
stat_1M_null <-
  summary(single_med_null) # saving summary statatistics
stat_1M_null 

## ----mbco_1M-------------------------------------------------------------
anova(single_med_null, single_med) 

## ----stats_1M------------------------------------------------------------
logLik(single_med)  # computes LL for the alternative model
AIC(single_med) # computes AIC
BIC(single_med) # computes BIC

## ----MC_ci_1M------------------------------------------------------------
Mu <- coef(single_med) # path coefficient estimates
Sigma <- vcov(single_med) #covariance matrix of the parameter estimates
## MC CI for indirect effect a1*b1
mc_ci1 <- ci(mu = Mu,
Sigma = Sigma,
quant = ~ b1 * b2)
mc_ci <- unlist(mc_ci1)
cat(" Monte Carlo CI for b1*b2:\n")
knitr::kable(mc_ci)

## ----two_med_alt---------------------------------------------------------
endVar <- c('imagery', 'repetition', 'recall')
maniVar <- c('x', 'imagery', 'repetition', 'recall')
two_med <- mxModel(
  "Model 3",
  type = "RAM",
  manifestVars = maniVar,
  mxPath(
    from = "x",
    to = endVar,
    arrows = 1,
    free = TRUE,
    values = .2,
    labels = c("b1", "b3", "b5")
  ),
  mxPath(
    from = 'repetition',
    to = 'recall',
    arrows = 1,
    free = TRUE,
    values = .2,
    labels = 'b4'
  ),
  mxPath(
    from = 'imagery',
    to = 'recall',
    arrows = 1,
    free = TRUE,
    values = .2,
    labels = "b2"
  ),
  mxPath(
    from = maniVar,
    arrows = 2,
    free = TRUE,
    values = .8,
    labels = c("s2x", "s2em1", "s2em2", "s2ey")
  ),
  mxPath(
    from = 'imagery',
    to = 'repetition',
    arrows = 2,
    free = TRUE,
    values = .2,
    labels = "cov_m1m2"
  ),
  mxPath(
    from = "one",
    to = endVar,
    arrows = 1,
    free = TRUE,
    values = .1,
    labels = c("int1", "int2", "int3")
  ),
  mxAlgebra(b1 * b2, name = "ind1"),
  mxAlgebra(b3 * b4, name = "ind2"),
  mxData(observed = memory_exp, type = "raw")
)

two_med <- mxTryHard(two_med) # run the single mediator null model
stat_Model3 <- summary(two_med) # saving the results
stat_Model3 # rinting resuslts of the full model



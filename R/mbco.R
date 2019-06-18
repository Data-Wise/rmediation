#' Model-based Constrained Optimization (MBCO) Chi-squared Test
#'
#' This function computes asymptotic MBCO chi-squared test for a smooth function of model parameters including a function of indirect effects.
#'
#' @param h0 An \code{OpenMx} model estimated under a null hypothesis, which is a more constrained model
#' @param h1 An \code{OpenMx} model estimated under an alternative hypothesis, which is a less constrained model. This is usually a model hypothesized by a researcher.
#' @param R The number of bootstrap draws.
#' @param type If 'asymp' (default), the asymptotic MBCO chi-squares test comparing fit of h0 and h1. If 'parametric', the parametric bootstrap MBCO chi-squared test is computed. If 'semi', the semi-parametric MBCO chi-squared is computed.
#' @param alpha Signficance level with the default value of .05
#' @param checkHess If 'No' (default), the Hessian matrix would not be calculated.
#' @param checkSE if 'No' (default), the standard errors would not be calculated.
#' @param optim Choose optimizer availble in OpenMx. The default optimizer is "NPSOL". Other optimizer choices include "CSOLNP" and "SLSQP ". See \link{mxOption} for more dettails.
#' @param precision Functional precision. The default value is set to 1e-9. See \link{mxOption} for more dettails.
#'@export mbco
#'@author Davood Tofighi \email{dtofighi@@gmail.com}
#'@examples
#' data(memory_exp)
#' endVar <- c('x', 'repetition', 'imagery', 'recall')
#' manifests <- c('x', 'repetition', 'imagery', 'recall')
#'full_model <- mxModel(
#'  "memory_example",
#'  type = "RAM",
#'  manifestVars = manifests,
#'  mxPath(
#'    from = "x",
#'    to = endVar,
#'    arrows = 1,
#'    free = TRUE,
#'    values = .2,
#'    labels = c("a1", "a2", "cp")
#'  ),
#'  mxPath(
#'    from = 'repetition',
#'   to = 'recall',
#'   arrows = 1,
#'    free = TRUE,
#'    values = .2,
#'    labels = 'b1'
#'  ),
#'  mxPath(
#'    from = 'imagery',
#'  to = 'recall',
#'  arrows = 1,
#'  free = TRUE,
#'  values = .2,
#'  labels = "b2"
#'),
#'mxPath(
#'  from = manifests,
#'  arrows = 2,
#'  free = TRUE,
#'  values = .8
#'),
#'mxPath(
#'  from = "one",
#'  to = endVar,
#'  arrows = 1,
#'  free = TRUE,
#'  values = .1
#'),
#'mxAlgebra(a1 * b1, name = "ind1"),
#'mxAlgebra(a2 * b2, name = "ind2"),
#'mxCI("ind1", type = "both"),
#'mxCI("ind2", type = "both"),
#'mxData(observed = memory_exp, type = "raw")
#')
#' ## Reduced  Model for indirect effect: a1*b1
#'null_model1 <- mxModel(
#'model= full_model,
#'name = "Null Model 1",
#'mxConstraint(ind1 == 0, name = "ind1_eq0_constr")
#')
#' full_model <- mxTryHard(full_model, checkHess=FALSE, silent = TRUE )
#' null_model1 <- mxTryHard(null_model1, checkHess=FALSE, silent = TRUE )
#' mbco(null_model1,full_model)


mbco <- function(h0 = NULL,
                 h1 = NULL,
                 R = 10L,
                 type = "asymp",
                 alpha = .05,
                 checkHess = "No",
                 checkSE = "No",
                 optim = "NPSOL",
                 precision = 1e-9) {
  if (missing(h0))
    stop("'h0' argument be a MxModel object")

  if (missing(h1))
    stop("'h1' argument be a MxModel object")

  if (!all(sapply(c(h0, h1), is, "MxModel")))
    stop("The 'h0' and 'h1' argument must be MxModel objects")

  # OpenMx::mxOption(NULL, "Calculate Hessian", checkHess)
  # OpenMx::mxOption(NULL, "Standard Errors", checkSE)
  # OpenMx::mxOption(NULL, "Function precision", precision)
  # OpenMx::mxOption(NULL, "Default optimizer", optim)

  res <-
    if (type == 'asymp')
      #Asymptotic MBCO LRT
      mbco_asymp(h0 = h0, h1 = h1, alpha = alpha)
  else if (type == 'parametric')
    # Parametric bootstrap MBCO LRT
    mbco_parametric(
      h0 = h0,
      h1 = h1,
      R = R,
      alpha = alpha,
      checkHess = checkHess,
      checkSE = checkSE,
      optim = optim,
      precision = precision
    )
  else if (type == 'semi')
    # Semiparametric bootstrap MBCO LRT
    mbco_semi(
      h0 = h0,
      h1 = h1,
      R = R,
      alpha = alpha,
      checkHess = checkHess,
      checkSE = checkSE,
      optim = optim,
      precision = precision
    )

  return(res)
}
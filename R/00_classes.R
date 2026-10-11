#' @importFrom S7 new_class new_generic
NULL

#' ProductNormal Class
#'
#' Represents the distribution of the product of normal random variables.
#'
#' @param mu Numeric vector of means.
#' @param Sigma Covariance matrix.
#' @export
#' @examples
#' pn <- ProductNormal(mu = c(0.5, 0.3), Sigma = diag(2) * 0.1)
ProductNormal <- S7::new_class("ProductNormal",
  properties = list(
    mu = S7::class_numeric,
    Sigma = S7::class_numeric
  ),
  validator = function(self) {
    if (length(self@mu) < 2) {
      stop("mu must have at least 2 elements")
    }
    # Check if Sigma is a matrix or vector
    if (is.matrix(self@Sigma)) {
      if (nrow(self@Sigma) != ncol(self@Sigma)) {
        stop("Sigma must be a square matrix")
      }
      if (nrow(self@Sigma) != length(self@mu)) {
        stop("Dimensions of Sigma must match length of mu")
      }
      # Check positive semi-definiteness (simple check)
      eigen_vals <- eigen(self@Sigma, symmetric = TRUE, only.values = TRUE)$values
      if (any(eigen_vals < -1e-8)) {
        stop("Sigma must be positive semi-definite")
      }
    } else {
      # If Sigma is passed as a vector (e.g. just variances/SEs), we might want to enforce it being a matrix
      # For now, let's strictly require a matrix for the class property to be safe,
      # or allow the constructor to handle conversion.
      # The property definition `class_numeric` allows vector or matrix.
      # Let's enforce matrix in validator for consistency.
      if (!is.matrix(self@Sigma)) {
        stop("Sigma must be a matrix")
      }
    }
    NULL
  }
)

# Register S4 for compatibility with base generics
S7::S4_register(ProductNormal)

#' ProductNormal3 Class
#'
#' Represents the distribution of the product of three normal random variables.
#' Intended for sequential indirect effects of the form `a1 * a2 * b`, where
#' `(a1, a2, b)` is asymptotically trivariate normal.
#'
#' @param mu Numeric vector of means of length 3: `c(a1_hat, a2_hat, b_hat)`.
#' @param Sigma 3x3 asymptotic covariance matrix of `(a1, a2, b)`.
#' @param method Integration method passed to [pprodnormal3()]: `"gauss"`
#'   (default) or `"hcubature"`. See the Note in [pprodnormal3()] for why
#'   `"gauss"` became the default in version 1.7.0.
#' @export
#' @examples
#' obj <- ProductNormal3(
#'   mu = c(0.5, 0.3, 0.2),
#'   Sigma = diag(3)
#' )
#' obj
#' cdf(obj, q = 1)
#' \dontrun{
#' confint(obj, level = 0.95)
#' }
ProductNormal3 <- S7::new_class("ProductNormal3",
  properties = list(
    mu = S7::class_numeric,
    Sigma = S7::class_numeric,
    method = S7::new_property(S7::class_character, default = "gauss")
  ),
  validator = function(self) {
    if (length(self@mu) != 3) {
      stop("mu must have length 3")
    }
    if (!is.matrix(self@Sigma)) {
      stop("Sigma must be a matrix")
    }
    if (nrow(self@Sigma) != 3 || ncol(self@Sigma) != 3) {
      stop("Sigma must be a 3x3 matrix")
    }
    eigen_vals <- eigen(self@Sigma, symmetric = TRUE, only.values = TRUE)$values
    if (any(eigen_vals < -1e-8)) {
      stop("Sigma must be positive semi-definite")
    }
    if (length(self@method) != 1 ||
      !(self@method %in% c("gauss", "hcubature"))) {
      stop("method must be 'gauss' or 'hcubature'")
    }
    NULL
  }
)

# Register S4 for compatibility with base generics
S7::S4_register(ProductNormal3)

#' Cumulative Distribution Function
#'
#' Generic function for computing cumulative distribution function.
#'
#' @param object A distribution object.
#' @param ... Additional arguments passed to methods.
#' @return A numeric vector of cumulative probabilities for the supplied
#'   quantiles, as returned by the dispatched method.
#' @export
#' @examples
#' pn <- ProductNormal(mu = c(0.5, 0.3), Sigma = diag(2) * 0.1)
#' cdf(pn, q = 0)
cdf <- S7::new_generic("cdf", "object")

#' Distribution Quantile Function
#'
#' Compute quantiles for distribution objects. This function computes quantiles
#' for product normal distributions, not data quantiles (use \code{stats::quantile}
#' for data).
#'
#' @param object A distribution object (e.g., ProductNormal).
#' @param ... Additional arguments passed to methods.
#' @return A numeric vector of quantiles for the supplied probabilities, as
#'   returned by the dispatched method.
#' @export
#' @examples
#' pn <- ProductNormal(mu = c(0.5, 0.3), Sigma = diag(2) * 0.1)
#' dist_quantile(pn, p = 0.025)
dist_quantile <- S7::new_generic("dist_quantile", "object")

#' Confidence Interval
#'
#' Generic function for computing confidence intervals.
#'
#' @param object A distribution object or numeric vector of means.
#' @param ... Additional arguments passed to methods.
#' @return A confidence interval (numeric vector of lower/upper bounds, or a
#'   list) as returned by the dispatched method.
#' @export
#' @examples
#' pn <- ProductNormal(mu = c(0.5, 0.3), Sigma = diag(2) * 0.1)
#' ci(pn)
ci <- S7::new_generic("ci", "object")

# Note: print, summary, and show generics are NOT exported.
# S7 methods will register directly with base generics to avoid masking.

#' MBCO Result Class
#'
#' A class representing the results of a Model-Based Constrained Optimization (MBCO) test.
#'
#' @param statistic Numeric test statistic value.
#' @param df Numeric degrees of freedom.
#' @param p_value Numeric p-value.
#' @param type Character string indicating the type of test.
#' @export
#' @examples
#' res <- MBCOResult(statistic = 4.2, df = 1, p_value = 0.04, type = "asymp")
MBCOResult <- S7::new_class("MBCOResult",
  properties = list(
    statistic = S7::class_numeric,
    df = S7::class_numeric,
    p_value = S7::class_numeric,
    type = S7::class_character
  )
)

# Register S4 for compatibility with base generics
S7::S4_register(MBCOResult)

#' Model-based Constrained Optimization (MBCO) Chi-squared Test
#'
#' This function computes asymptotic MBCO chi-squared test for a smooth function of model parameters including a function of indirect effects.
#'
#' @details
#' **Testing a product null (\eqn{a b = 0}).** The null \eqn{ab = 0} holds when
#' \eqn{a = 0} or \eqn{b = 0}. A single nonlinear constraint such as
#' `ind == 0` can converge to either branch, and the optimizer may return the
#' branch with the larger statistic, which gives a wrong test. To test a product
#' of two paths, fit one linear null per path (`a == 0` and `b == 0`), run
#' `mbco()` on each, and report the smaller statistic with 1 degree of freedom
#' (see the example).
#'
#' Build each `h0` from the unfitted model. A constraint refit from the fitted
#' model's estimates can stop at an infeasible point and return a statistic of 0.
#'
#' @param h0 An \code{OpenMx} model estimated under a null hypothesis, which is a more constrained model
#' @param h1 An \code{OpenMx} model estimated under an alternative hypothesis, which is a less constrained model. This is usually a model hypothesized by a researcher.
#' @param ... Additional arguments.
#' @return An object of class \code{MBCOResult} containing \item{statistic}{asymptotic chi-squared test statistic value} \item{df}{chi-squared df} \item{p_value}{chi-squared p-value computed based on the method specified by the argument \code{type}} \item{type}{The type of test performed}
#' @author Davood Tofighi \email{dtofighi@@gmail.com}
#' @importFrom checkmate assert_class assert_count assert_number assert_choice
#' @export
#' @examples
#' \dontrun{
#' data(memory_exp)
#' memory_exp <- as.data.frame(memory_exp) # mxData() does not accept tibbles
#' memory_exp$x <- as.numeric(memory_exp$x) - 1 # manually creating dummy codes
#' endVar <- c("repetition", "imagery", "recall") # endogenous variables (not "x")
#' manifests <- c("x", "repetition", "imagery", "recall")
#' full_model <- OpenMx::mxModel(
#'   "memory_example",
#'   type = "RAM",
#'   manifestVars = manifests,
#'   OpenMx::mxPath(
#'     from = "x",
#'     to = endVar,
#'     arrows = 1,
#'     free = TRUE,
#'     values = .2,
#'     labels = c("a1", "a2", "cp")
#'   ),
#'   OpenMx::mxPath(
#'     from = "repetition",
#'     to = "recall",
#'     arrows = 1,
#'     free = TRUE,
#'     values = .2,
#'     labels = "b1"
#'   ),
#'   OpenMx::mxPath(
#'     from = "imagery",
#'     to = "recall",
#'     arrows = 1,
#'     free = TRUE,
#'     values = .2,
#'     labels = "b2"
#'   ),
#'   OpenMx::mxPath(
#'     from = manifests,
#'     arrows = 2,
#'     free = TRUE,
#'     values = .8
#'   ),
#'   OpenMx::mxPath(
#'     from = "one",
#'     to = manifests,
#'     arrows = 1,
#'     free = TRUE,
#'     values = .1
#'   ),
#'   OpenMx::mxAlgebra(a1 * b1, name = "ind1"),
#'   OpenMx::mxAlgebra(a2 * b2, name = "ind2"),
#'   OpenMx::mxCI("ind1", type = "both"),
#'   OpenMx::mxCI("ind2", type = "both"),
#'   OpenMx::mxData(observed = memory_exp, type = "raw")
#' )
#' ## H0: a1*b1 = 0 holds if a1 = 0 or b1 = 0. Fit one linear null per path and
#' ## report the smaller statistic (what medfit::mbco_sem() automates). A single
#' ## nonlinear null ind1 == 0 can converge to the wrong branch (rmediation#35).
#' ## Build each h0 from the unfitted model: a constraint refit from the fitted
#' ## model's estimates can stop at an infeasible point.
#' null_a1 <- OpenMx::mxModel(
#'   model = full_model,
#'   name = "Null a1 = 0",
#'   OpenMx::mxConstraint(a1 == 0, name = "a1_eq0_constr")
#' )
#' null_b1 <- OpenMx::mxModel(
#'   model = full_model,
#'   name = "Null b1 = 0",
#'   OpenMx::mxConstraint(b1 == 0, name = "b1_eq0_constr")
#' )
#' full_model <- OpenMx::mxTryHard(full_model, checkHess = FALSE, silent = TRUE)
#' null_a1 <- OpenMx::mxTryHard(null_a1, checkHess = FALSE, silent = TRUE)
#' null_b1 <- OpenMx::mxTryHard(null_b1, checkHess = FALSE, silent = TRUE)
#' res_a1 <- mbco(null_a1, full_model)
#' res_b1 <- mbco(null_b1, full_model)
#' res_a1
#' res_b1
#' ## Test of H0: a1*b1 = 0 (df = 1): the smaller of the two statistics
#' min(res_a1@statistic, res_b1@statistic)
#' }
mbco <- S7::new_generic("mbco", c("h0", "h1"))

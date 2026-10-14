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
#' @details
#' For numeric vectors or lavaan fits with a formula quantity, the Monte Carlo
#' component reports MCError as the sampling standard error of the simulated mean
#' (SE / sqrt(n.mc)); this is not the error of the interval endpoints. With
#' H0 = TRUE, the Monte Carlo result contains the alternative and null results.
#' The type = "all" route preserves H0, mu0 and Sigma0 for its MC component;
#' the asymptotic component remains the interval at the supplied estimates.
#'
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
    type = S7::class_character,
    # default must be quote(NULL): a bare NULL default is replaced by list()
    refit = S7::new_property(
      NULL | S7::class_list,
      default = quote(NULL)
    )
  ),
  validator = function(self) {
    r <- self@refit
    if (is.null(r)) {
      return(NULL)
    }
    need <- c("tolerance", "statistic_before", "statistic_after")
    if (!setequal(names(r), need)) {
      return("@refit must be NULL or a list with tolerance, statistic_before, statistic_after")
    }
    ok <- vapply(r[need], function(v) is.numeric(v) && length(v) == 1L, logical(1))
    if (!all(ok)) {
      return("@refit entries must be single numeric values")
    }
    if (!all(is.finite(unlist(r[need])))) {
      return("@refit entries must be finite")
    }
    NULL
  }
)

# Register S4 for compatibility with base generics
S7::S4_register(MBCOResult)

#' Multilevel Omitted-Confounder Sensitivity Result
#'
#' Result class returned by [ml_omitted_confounder()]. Use the `print`,
#' `summary`, `plot` and `as.data.frame` methods rather than constructing it
#' directly.
#'
#' @param grid Data frame of adjusted paths over the sensitivity grid.
#' @param ranges Data frame of the minimum and maximum adjusted indirect effect.
#' @param unadjusted Named numeric vector of unadjusted indirect effects.
#' @param screen Character string, `"pd"` or `"none"`.
#' @param inputs List of the validated inputs.
#' @param call The matched call.
#' @keywords internal
#' @noRd
MLOmittedConfounder <- S7::new_class("MLOmittedConfounder",
  properties = list(
    grid = S7::class_data.frame,
    ranges = S7::class_data.frame,
    unadjusted = S7::class_numeric,
    screen = S7::class_character,
    inputs = S7::class_list,
    call = S7::class_any
  )
)

S7::S4_register(MLOmittedConfounder)

#' Model-based Constrained Optimization (MBCO) Chi-squared Test
#'
#' This function computes asymptotic MBCO chi-squared test for a smooth function of model parameters including a function of indirect effects.
#'
#' @details
#' **Two medfit SEMFits (medfit >= 0.8.0).** Supply the already-fitted
#' restricted model as `h0` and the full model as `h1`. Only `type = "asymp"`
#' is supported; `alpha` is validated as for OpenMx. The adapter compares the
#' fits through `stats::anova(h1, h0)` and uses the degrees-of-freedom difference.
#' It never refits. Bootstrap types, mixed model classes, OpenMx-only fitting
#' controls (`R`, `checkHess`, `checkSE`, `optim`, `precision`) and unused dots
#' are rejected. This route does not require OpenMx.
#'
#' medfit checks convergence, identical data and observed variables, unweighted
#' fits, and parameter-table nesting. The analyst must establish substantive
#' nesting and a valid chi-square reference distribution; arbitrary nonlinear
#' restrictions do not necessarily have one. An active tested bound or inequality
#' at the null causes an error here because the ordinary chi-square p-value is
#' invalid. Other medfit warnings propagate.
#'
#' For a product-zero null, `medfit::fit_sem()` with `a*b == 0` fits one branch
#' per factor from clean starts and selects the smallest discrepancy. Pass that
#' fitted null and the full fit to `mbco()`. medfit is optional: this route needs
#' 0.8.0 or later (GitHub/r-universe); existing `ci()` integration needs only
#' 0.2.0. No change to the CRAN dependency minimum is implied.
#'
#' OpenMx comparisons require a finite nonnegative observed statistic and a
#' positive degrees-of-freedom difference: supply the restricted model as h0
#' and the full model as h1. Equal-df and reversed pairs error before bootstrap
#' sampling. These checks do not establish substantive model nesting.
#'
#' OpenMx bootstrap methods restore global options on success and error.
#' Set a seed before calling for reproducibility; bootstrap sampling consumes the
#' current RNG stream. The semiparametric method requires positive-definite sample
#' and null covariances and stops at the first failed refit or nonfinite replicate
#' statistic. It does not retry or discard failed replicates. Parametric results
#' require a finite nonnegative statistic, positive df, and a p-value in [0, 1].
#'
#' **Testing an OpenMx product null (\eqn{a b = 0}).** The null \eqn{ab = 0} holds when
#' \eqn{a = 0} or \eqn{b = 0}. A single nonlinear constraint such as
#' `ind == 0` can converge to either branch, and the optimizer may return the
#' branch with the larger statistic, which gives a wrong test. To test a product
#' of two paths, fit one linear null per path (`a == 0` and `b == 0`), run
#' `mbco()` on each, and report the smaller statistic with 1 degree of freedom
#' (see the example). The smaller statistic is the exact constrained
#' likelihood-ratio statistic for \eqn{ab = 0}. Its chi-square(1) p-value is
#' conservative when both paths are 0 (an intersection-union test; standard
#' theory, not verified here).
#'
#' Build each `h0` from the unfitted model. A constraint refit from the fitted
#' model's estimates can stop at an infeasible point and return a statistic of 0.
#'
#' **Constraint violation warning (OpenMx).** OpenMx accepts a constrained fit
#' whose constraints are violated by up to its `"Feasibility tolerance"`
#' (default 0.05), which can understate the statistic. Before comparing, `mbco()`
#' evaluates every equality and inequality constraint of `h0` and `h1` at the
#' fitted solution and signals a warning of class
#' `RMediation_constraint_violation` when the scaled violation,
#' `|lhs - rhs| / max(1, |lhs|, |rhs|)` for equalities and the wrong-side gap
#' for inequalities, exceeds 1e-6. The result is still returned and no number
#' changes. Refit with `mxOption(model, "Feasibility tolerance", 1e-8)`, or use
#' the two-fit route above for a product null. A constraint that cannot be
#' evaluated is an error naming it; constraints with other operators are
#' skipped. The guard does not detect a feasible fit of `a*b == 0` on the
#' larger-statistic branch (issue #35); only the two-fit route avoids that.
#'
#' @param h0 A fitted restricted \code{OpenMx} model or medfit \code{SEMFit} under the null hypothesis.
#' @param h1 A fitted full model of the same class as \code{h0}, under the alternative hypothesis.
#' @param ... Additional arguments.
#' @return An object of class \code{MBCOResult} containing \item{statistic}{asymptotic chi-squared test statistic value} \item{df}{chi-squared df} \item{p_value}{chi-squared p-value computed based on the method specified by the argument \code{type}} \item{type}{The type of test performed}
#' @author Davood Tofighi \email{dtofighi@@gmail.com}
#' @importFrom checkmate assert_class assert_count assert_number assert_choice
#' @export
#' @examples
#' if (requireNamespace("medfit", quietly = TRUE) &&
#'     utils::packageVersion("medfit") >= "0.8.0") {
#'   d <- as.data.frame(memory_exp)
#'   d$x <- as.numeric(d$x) - 1
#'   syntax <- paste("repetition ~ a1*x", "imagery ~ a2*x",
#'                   "recall ~ cp*x + b1*repetition + b2*imagery", sep = "\n")
#'   full <- medfit::fit_sem(syntax, d)
#'   null <- medfit::fit_sem(paste(syntax, "a1*b1 == 0", sep = "\n"), d)
#'   mbco(null, full) # statistic 0.0831, df 1
#' }
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

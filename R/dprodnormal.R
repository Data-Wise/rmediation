#' Density of the Product of Two Normal Random Variables
#'
#' Evaluates the exact probability density function of \eqn{XY}, where
#' \eqn{(X, Y)} is bivariate normal. It is the density companion to
#' \code{\link{pprodnormal}} and \code{\link{qprodnormal}} and uses no Monte
#' Carlo simulation.
#'
#' @param x numeric vector of values at which to evaluate the density (the
#'   value of the product).
#' @param mu.x,mu.y means of \eqn{X} and \eqn{Y}.
#' @param se.x,se.y standard deviations of \eqn{X} and \eqn{Y}; must be
#'   positive.
#' @param rho correlation between \eqn{X} and \eqn{Y}; must satisfy
#'   \eqn{-1 < \rho < 1}. The default is 0.
#' @param log logical; if \code{TRUE}, the logarithm of the density is
#'   returned.
#'
#' @details For general means and correlation the density is the
#'   one-dimensional integral \eqn{f(z) = \int f_{X,Y}(x, z/x)\,|x|^{-1}\,dx}
#'   (Rohatgi; Glen et al., 2004), evaluated by adaptive quadrature over the
#'   range that carries the mass of the conditioning variable and split at the
#'   sign change at zero. When both means are zero the closed form
#'   \deqn{f(z) = \frac{\exp\{\rho z/(1-\rho^2)\}\,
#'   K_0\{|z|/(1-\rho^2)\}}{\pi\sqrt{1-\rho^2}}}
#'   (unit variances; rescaled here) is used instead, with \eqn{K_0} the
#'   modified Bessel function of the second kind (Nadarajah and Pogany, 2016;
#'   Gaunt, 2019). The two agree to near machine precision.
#'
#'   The density is infinite at exactly \code{x = 0} for every parameter
#'   setting (a logarithmic singularity: \eqn{XY} is near zero whenever either
#'   factor is), so \code{dprodnormal(0, ...)} returns \code{Inf}. Plot it on a
#'   grid that avoids 0 and clip the vertical axis.
#'
#' @return A numeric vector of densities (or log densities), one per element of
#'   \code{x}.
#' @references Craig, C. C. (1936). On the frequency function of xy.
#'   \emph{Annals of Mathematical Statistics}, \bold{7}, 1--15.
#'
#'   Glen, A. G., Leemis, L. M. and Drew, J. H. (2004). Computing the
#'   distribution of the product of two continuous random variables.
#'   \emph{Computational Statistics & Data Analysis}, \bold{44}, 451--464.
#'
#'   Nadarajah, S. and Pogany, T. K. (2016). On the distribution of the product
#'   of correlated normal random variables. \emph{Comptes Rendus Mathematique},
#'   \bold{354}, 201--204.
#' @seealso \code{\link{pprodnormal}}, \code{\link{qprodnormal}}
#' @examples
#' dprodnormal(c(-0.1, 0.05, 0.3), mu.x = 0.5, mu.y = 0.3, se.x = 0.2, se.y = 0.4, rho = 0.3)
#'
#' # the density integrates to the CDF
#' integrate(dprodnormal, 0.001, 0.3, mu.x = 0.5, mu.y = 0.3, se.x = 0.2, se.y = 0.4)$value
#' pprodnormal(0.3, 0.5, 0.3, 0.2, 0.4) - pprodnormal(0.001, 0.5, 0.3, 0.2, 0.4)
#' @export
dprodnormal <- function(x, mu.x, mu.y, se.x = 1, se.y = 1, rho = 0, log = FALSE) {
  checkmate::assert_numeric(x, any.missing = FALSE, min.len = 1)
  checkmate::assert_number(mu.x, finite = TRUE)
  checkmate::assert_number(mu.y, finite = TRUE)
  checkmate::assert_number(se.x, lower = 0, finite = TRUE)
  checkmate::assert_number(se.y, lower = 0, finite = TRUE)
  checkmate::assert_number(rho, finite = TRUE)
  checkmate::assert_flag(log)
  .assert_positive_se(se.x, se.y)
  if (abs(rho) >= 1) {
    stop("The density needs -1 < rho < 1 (rho = ", format(rho),
         "): at |rho| = 1 XY is a function of one variable and has no bivariate-normal density.", call. = FALSE)
  }

  mu.a <- mu.x / se.x
  mu.b <- mu.y / se.y
  scale <- se.x * se.y
  zero_means <- mu.x == 0 && mu.y == 0

  dens <- vapply(x, function(xx) {
    if (!is.finite(xx)) {
      return(0)
    }
    if (xx == 0) {
      return(Inf)
    }
    z <- xx / scale
    f <- if (zero_means) .dprod_bessel(z, rho) else .dprod_integral(z, mu.a, mu.b, rho)
    f / scale
  }, numeric(1))

  if (log) base::log(dens) else dens
}

# Standardized zero-mean density (unit variances): Nadarajah & Pogany (2016) Thm 2.1. The
# exponent and the Bessel function are combined on the log scale for the far tail
# (besselK(expon.scaled = TRUE) = exp(x) * K0(x)).
.dprod_bessel <- function(z, rho) {
  w <- abs(z) / (1 - rho^2)
  exp(rho * z / (1 - rho^2) - w) * besselK(w, 0, expon.scaled = TRUE) / (pi * sqrt(1 - rho^2))
}

# Standardized general density: f(z) = int dnorm(x - mu.b) dnorm((z/x - m(x))/s) / (s |x|) dx with
# m(x) = mu.a + rho (x - mu.b), s = sqrt(1 - rho^2) (Rohatgi's integral in the conditioning
# variable's coordinates). Same window and split at 0 as .dop_cdf(); no sign(x) jump, but the
# 1/|x| factor is integrable only because dnorm(z/x ...) vanishes as x -> 0 for z != 0.
.dprod_integral <- function(z, mu.a, mu.b, rho) {
  s <- sqrt(1 - rho^2)
  g <- function(x) {
    dnorm(x - mu.b) * dnorm((z / x - (mu.a + rho * (x - mu.b))) / s) / (s * abs(x))
  }
  lo <- mu.b - 10
  hi <- mu.b + 10
  # For small |z| the integrand has a log-singular spike at x = 0 that decays like 1/|x| out to
  # |x| ~ 1: break the range at decades so integrate() resolves it instead of reporting
  # "probably divergent" (dprodnormal3() reaches small z through its inner integral).
  za <- abs(z)
  decades <- if (za > 0 && za < 1e-2) 10^seq(floor(log10(za)) - 1, 0) else numeric()
  decades <- c(-decades, decades)
  breaks <- sort(unique(c(lo, if (lo < 0 && hi > 0) 0, decades[decades > lo & decades < hi], hi)))
  sum(vapply(seq_len(length(breaks) - 1L), function(i) {
    integrate(g, breaks[i], breaks[i + 1L], subdivisions = 2000L, rel.tol = 1e-10, abs.tol = 1e-300)$value
  }, numeric(1)))
}

pkgname <- "RMediation"
source(file.path(R.home("share"), "R", "examples-header.R"))
options(warn = 1)
base::assign(".ExTimings", "RMediation-Ex.timings", pos = 'CheckExEnv')
base::cat("name\tuser\tsystem\telapsed\n", file=base::get(".ExTimings", pos = 'CheckExEnv'))
base::assign(".format_ptime",
function(x) {
  if(!is.na(x[4L])) x[1L] <- x[1L] + x[4L]
  if(!is.na(x[5L])) x[2L] <- x[2L] + x[5L]
  options(OutDec = '.')
  format(x[1L:3L], digits = 7L)
},
pos = 'CheckExEnv')

### * </HEADER>
library('RMediation')

base::assign(".oldSearch", base::search(), pos = 'CheckExEnv')
base::assign(".old_wd", base::getwd(), pos = 'CheckExEnv')
cleanEx()
nameEx("ci")
### * ci

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: ci
### Title: CI for a nonlinear function of coefficients estimates
### Aliases: ci
### Keywords: distribution regression

### ** Examples

ci(
  mu = c(b1 = 1, b2 = .7, b3 = .6, b4 = .45),
  Sigma = c(.05, 0, 0, 0, .05, 0, 0, .03, 0, .03),
  quant = ~ b1 * b2 * b3 * b4, type = "all", plot = TRUE, plotCI = TRUE
)
# An Example of Conservative Null Sampling Distribution
ci(c(b1 = .3, b2 = .4, b3 = .3), c(.01, 0, 0, .01, 0, .02),
  quant = ~ b1 * b2 * b3, type = "mc", plot = TRUE, plotCI = TRUE,
   H0 = TRUE, mu0 = c(b1 = .3, b2 = .4, b3 = 0)
)
# An Example of Less Conservative Null Sampling Distribution
ci(c(b1 = .3, b2 = .4, b3 = .3), c(.01, 0, 0, .01, 0, .02),
  quant = ~ b1 * b2 * b3, type = "mc", plot = TRUE, plotCI = TRUE,
  H0 = TRUE, mu0 = c(b1 = 0, b2 = .4, b3 = 0.1)
)



base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("ci", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("medci")
### * medci

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: medci
### Title: Confidence Interval for the Mediated Effect
### Aliases: medci
### Keywords: mediation

### ** Examples

## Example 1
res <- medci(
  mu.x = .2, mu.y = .4, se.x = 1, se.y = 1, rho = 0, alpha = .05,
  type = "dop", plot = TRUE, plotCI = TRUE
)
## Example 2
res <- medci(mu.x = .2, mu.y = .4, se.x = 1, se.y = 1, rho = 0,
 alpha = .05, type = "all", plot = TRUE, plotCI = TRUE)



base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("medci", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("pMC")
### * pMC

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: pMC
### Title: Probability (percentile) for the Monte Carlo Sampling
###   Distribution of a nonlinear function of coefficients estimates
### Aliases: pMC
### Keywords: distribution regression

### ** Examples

pMC(.2,
  mu = c(b1 = 1, b2 = .7, b3 = .6, b4 = .45), Sigma = c(.05, 0, 0, 0, .05, 0, 0, .03, 0, .03),
  quant = ~ b1 * b2 * b3 * b4
)



base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("pMC", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("pprodnormal")
### * pprodnormal

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: pprodnormal
### Title: Percentile for the Distribution of Product of Two Normal
###   Variables
### Aliases: pprodnormal

### ** Examples

pprodnormal(q = 0, mu.x = .5, mu.y = .3, se.x = 1, se.y = 1, rho = 0, type = "all")



base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("pprodnormal", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("qMC")
### * qMC

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: qMC
### Title: Quantile for the Monte Carlo Sampling Distribution of a
###   nonlinear function of coefficients estimates
### Aliases: qMC
### Keywords: distribution regression

### ** Examples

qMC(.05,
  mu = c(b1 = 1, b2 = .7, b3 = .6, b4 = .45), Sigma = c(.05, 0, 0, 0, .05, 0, 0, .03, 0, .03),
  quant = ~ b1 * b2 * b3 * b4
)



base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("qMC", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("qprodnormal")
### * qprodnormal

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: qprodnormal
### Title: Quantile for the Distribution of Product of Two Normal Variables
### Aliases: qprodnormal

### ** Examples

## lower tail
qprodnormal(
  p = .1, mu.x = .5, mu.y = .3, se.x = 1, se.y = 1, rho = 0,
  lower.tail = TRUE, type = "all"
)
## upper tail
qprodnormal(
  p = .1, mu.x = .5, mu.y = .3, se.x = 1, se.y = 1, rho = 0,
  lower.tail = FALSE, type = "all"
)



base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("qprodnormal", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
cleanEx()
nameEx("tidy_logLik")
### * tidy_logLik

flush(stderr()); flush(stdout())

base::assign(".ptime", proc.time(), pos = "CheckExEnv")
### Name: tidy.logLik
### Title: Creates a data.frame for a log-likelihood object
### Aliases: tidy.logLik

### ** Examples

fit <- lm(mpg ~ wt, data = mtcars)
logLik_fit <- logLik(fit)
tidy(logLik_fit)



base::assign(".dptime", (proc.time() - get(".ptime", pos = "CheckExEnv")), pos = "CheckExEnv")
base::cat("tidy_logLik", base::get(".format_ptime", pos = 'CheckExEnv')(get(".dptime", pos = "CheckExEnv")), "\n", file=base::get(".ExTimings", pos = 'CheckExEnv'), append=TRUE, sep="\t")
### * <FOOTER>
###
cleanEx()
options(digits = 7L)
base::cat("Time elapsed: ", proc.time() - base::get("ptime", pos = 'CheckExEnv'),"\n")
grDevices::dev.off()
###
### Local variables: ***
### mode: outline-minor ***
### outline-regexp: "\\(> \\)?### [*]+" ***
### End: ***
quit('no')

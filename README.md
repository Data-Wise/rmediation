# RMediation <img src="man/figures/logo.png" align="right" height="139" alt="RMediation website" />

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/RMediation)](https://CRAN.R-project.org/package=RMediation)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![R-CMD-check](https://github.com/data-wise/rmediation/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/data-wise/rmediation/actions/workflows/R-CMD-check.yaml)
[![Website Status](https://github.com/data-wise/rmediation/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/data-wise/rmediation/actions/workflows/pkgdown.yaml)
[![R-hub](https://github.com/data-wise/rmediation/actions/workflows/rhub.yaml/badge.svg)](https://github.com/data-wise/rmediation/actions/workflows/rhub.yaml)
[![Codecov](https://codecov.io/gh/data-wise/rmediation/graph/badge.svg)](https://codecov.io/gh/data-wise/rmediation)
<!-- badges: end -->

**RMediation** provides rigorous statistical methods for mediation analysis confidence intervals in observational and experimental designs. It addresses the known limitations of normal-theory confidence intervals (e.g., Sobel test) by implementing advanced methods that account for the non-normal distribution of the indirect effect.

## Features

- **Distribution of the Product (DOP):** Exact method for the product of two normal random variables using the Meeker & Escobar (1994) algorithm.
- **Monte Carlo Method:** Robust simulation-based intervals for any number of variables.
- **N-Variable Products:** Supports confidence intervals for products of 3 or more variables.
- **LRT-MBCO:** Likelihood Ratio Test via Model-Based Constrained Optimization for hypothesis testing of indirect effects.
- **Bootstrap Variants:** Parametric and semiparametric bootstrap methods for robust inference.
- **Modern S7 Architecture:** Type-safe `ProductNormal` and `MBCOResult` classes with validators and display methods.
- **lavaan Integration:** Auto-detects indirect effects in lavaan models (e.g., `ab := a*b`).
- **Zero Masking Warnings:** Clean namespace with no conflicts with base R functions.

## Mediationverse Ecosystem

**RMediation** is part of the **mediationverse** ecosystem for mediation analysis in R:

| Package | Purpose | Role |
|---------|---------|------|
| [**medfit**](https://data-wise.github.io/medfit/) | Model fitting, extraction, bootstrap | Foundation |
| [**probmed**](https://data-wise.github.io/probmed/) | Probabilistic effect size (P_med) | Application |
| **RMediation** (this) | Confidence intervals (DOP, MBCO) | Application |
| [**medrobust**](https://data-wise.github.io/medrobust/) | Sensitivity analysis | Application |
| [**medsim**](https://data-wise.github.io/medsim/) | Simulation infrastructure | Support |

**Resources:**
- [Ecosystem Coordination](https://github.com/data-wise/medfit/blob/main/planning/ECOSYSTEM.md) - Version compatibility and development guidelines
- [Development Roadmap](https://data-wise.github.io/mediationverse/articles/roadmap.html) - Timeline and milestones
- [Package Status Dashboard](https://github.com/data-wise/mediationverse/blob/main/STATUS.md) - Build status for all packages

## Installation

### Stable Release (CRAN)

Install the stable version from CRAN:

```r
install.packages("RMediation")
```

### Development Version (GitHub)

Install the latest development version:

```r
# Install remotes if needed
install.packages("remotes")

# Install from develop branch
remotes::install_github("Data-Wise/rmediation", ref = "develop")
```

## Quick Examples

### Using Summary Statistics

If you have estimates from a published paper or other software, compute CIs using coefficients and standard errors:

```r
library(RMediation)

# Single mediator: a = 0.5, b = 0.6, se.a = 0.08, se.b = 0.04
medci(mu.x = 0.5, mu.y = 0.6, se.x = 0.08, se.y = 0.04, rho = 0, type = "dop")
```

### Sequential Mediators

Compute CIs for indirect effects with multiple sequential mediators:

```r
library(RMediation)

# Two sequential mediators
ci(mu = c(b1 = 1, b2 = .7, b3 = .6, b4 = .45),
   Sigma = c(.05, 0, 0, 0, .05, 0, 0, .03, 0, .03),
   quant = ~ b1 * b2 * b3 * b4, type = "MC", plot = TRUE, plotCI = TRUE)
```

### Using the S7 ProductNormal Class

```r
library(RMediation)

# Create a ProductNormal distribution
mu <- c(0.5, 0.3)
Sigma <- matrix(c(0.01, 0.002, 0.002, 0.01), 2, 2)
pn <- ProductNormal(mu = mu, Sigma = Sigma)

# Compute confidence interval
ci(pn, level = 0.95, type = "dop")

# Display detailed information
print(pn)
summary(pn)
```

### N-Variable Products

Compute confidence intervals for products of 3 or more variables:

```r
library(RMediation)

# Three-way product: a1 * a2 * b
pn3 <- ProductNormal(
  mu = c(0.3, 0.4, 0.5),
  Sigma = diag(3)
)

# Compute CI using Monte Carlo method
ci(pn3, level = 0.95, type = "mc", n.mc = 1e5)
```

### Using lavaan Integration

```r
library(lavaan)
library(RMediation)

# Define mediation model
model <- '
  m ~ a*x
  y ~ b*m
  ab := a*b
'
fit <- sem(model, data = YourData)

# Auto-detect and compute CI for indirect effect
ci(fit)  # Automatically finds 'ab := a*b'
```

## Contributing

Contributions are welcome! If you encounter issues or have feature requests:

- [Report a Bug](https://github.com/data-wise/rmediation/issues)
- [Submit a Pull Request](https://github.com/data-wise/rmediation/pulls)

## Citation

If you use **RMediation** in your research, please cite:

> Tofighi, D., & MacKinnon, D. P. (2011). RMediation: An R package for mediation analysis confidence intervals. *Behavior Research Methods*, 43, 692-700. doi:10.3758/s13428-011-0076-x

> Tofighi, D., & Kelley, K. (2020). Improved inference in mediation analysis: Introducing the model-based constrained optimization procedure. *Psychological Methods*, 25(4), 496-515. doi:10.1037/met0000259

> Tofighi, D. (2020). Bootstrap Model-Based Constrained Optimization Tests of Indirect Effects. *Frontiers in Psychology*, 10, 2989. doi:10.3389/fpsyg.2019.02989

## License

RMediation is licensed under the [GPL-3.0](https://choosealicense.com/licenses/gpl-3.0/).

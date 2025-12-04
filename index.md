# RMediation

**RMediation** provides rigorous statistical methods for mediation
analysis in observational and experimental designs. It addresses the
known limitations of normal-theory confidence intervals (e.g., Sobel
test) by implementing advanced methods that account for the non-normal
distribution of the indirect effect.

## Key Capabilities

### 1. Rigorous Confidence Intervals

Compute accurate Confidence Intervals (CIs) for indirect effects using
methods that outperform the standard normal approximation:

- **Distribution of the Product (DOP):** Exact method for the product of
  two normal random variables using Meeker & Escobar (1994) algorithm.
- **Monte Carlo Method:** Robust simulation-based intervals for any
  number of variables.
- **Bootstrapping:** Parametric and semi-parametric bootstrap
  implementations via MBCO tests.
- **N-Variable Products (NEW):** Now supports confidence intervals for
  products of 3 or more variables—a capability not available in previous
  versions.

### 2. Advanced Hypothesis Testing

- **LRT-MBCO:** Implements the **Likelihood Ratio Test via Model-Based
  Constrained Optimization**, a powerful frequentist method for testing
  indirect effects that controls Type I error rates better than standard
  approaches.
- **Bootstrap Variants:** Parametric and semiparametric bootstrap
  methods for robust inference.
- **Sobel Test:** Asymptotic normal test included for baseline
  comparison.

### 3. Modern S7 Object-Oriented Architecture (v1.4.0)

- **S7 computational core:** Complete architectural redesign with S7 as
  the foundation—legacy functions are now thin wrappers.
- **Type-safe classes:** `ProductNormal` and `MBCOResult` S7 classes
  with validators.
- **Meaningful output:** All classes have
  [`print()`](https://rdrr.io/r/base/print.html),
  [`summary()`](https://rdrr.io/r/base/summary.html), and `show()`
  methods.
- **Zero breaking changes:** 100% backward compatible—all existing code
  works without modification.
- **Enhanced extensibility:** New architecture makes adding CI methods
  straightforward.

### 4. Clean Namespace

- **Zero masking warnings:** Package loads cleanly with no conflicts
  with base R functions.
- All S7 methods properly register with base generics (`print`,
  `summary`, `show`).
- New
  [`dist_quantile()`](https://data-wise.github.io/rmediation/reference/dist_quantile.md)
  generic avoids conflict with
  [`stats::quantile()`](https://rdrr.io/r/stats/quantile.html).

### 5. Seamless Integration

- Works directly with summary statistics (coefficients/SEs).
- Extracts parameters automatically from fitted `lavaan` or `OpenMx`
  model objects.
- Auto-detects indirect effects in `lavaan` models (e.g., `ab := a*b`).

------------------------------------------------------------------------

## Mediationverse Ecosystem

**RMediation** is part of the **mediationverse** ecosystem for mediation
analysis in R:

| Package                                                 | Purpose                              | Role        |
|---------------------------------------------------------|--------------------------------------|-------------|
| [**medfit**](https://github.com/data-wise/medfit)       | Model fitting, extraction, bootstrap | Foundation  |
| [**probmed**](https://github.com/data-wise/probmed)     | Probabilistic effect size (P_med)    | Application |
| **RMediation** (this)                                   | Confidence intervals (DOP, MBCO)     | Application |
| [**medrobust**](https://github.com/data-wise/medrobust) | Sensitivity analysis                 | Application |
| [**medsim**](https://github.com/data-wise/medsim)       | Simulation infrastructure            | Support     |

See [Ecosystem
Coordination](https://github.com/data-wise/medfit/blob/main/planning/ECOSYSTEM.md)
for version compatibility and development guidelines.

------------------------------------------------------------------------

## Installation

### Stable Release (CRAN)

Install the stable version from CRAN:

``` r
install.packages("RMediation")
```

### Development Version (GitHub)

Install the latest development version with new S7 features:

``` r
# Install remotes if needed
install.packages("remotes")

# Install from develop branch
remotes::install_github("Data-Wise/rmediation", ref = "develop")
```

**Development version includes (v1.4.0):**

- ✨ **S7 computational core** - Complete architectural redesign for
  extensibility
- 🚀 **N-variable product support** - Compute CIs for 3+ variable
  products (NEW capability)
- 🎯 Auto-detection of indirect effects in `lavaan` models
- 📊 Enhanced display methods (`print`, `summary`, `show`)
- ✅ Comprehensive input validation with better error messages
- 🧹 **Zero masking warnings** - Clean namespace with no conflicts
- 🔧 **100% backward compatible** - All existing code works without
  changes

------------------------------------------------------------------------

## Usage

### Using Summary Statistics to Calculate CIs

If you already have estimates from a published paper or other software,
you can calculate CIs using coefficients ($\widehat{a},\widehat{b}$) and
their standard errors.

``` r
library(RMediation)

# Example: Single mediator
# a = 0.5, b = 0.6, se.a = 0.08, se.b = 0.04, rho = 0 (independence)
medci(mu.x = 0.5, mu.y = 0.6, se.x = 0.08, se.y = 0.04, rho = 0, type = "prodclin")
```

### Using `ci` to Calculate CIs for Indirect Effects of Path with Two Sequential Mediators

``` r
library(RMediation)

# Example: Two sequential mediators
ci(mu = c(b1 = 1, b2 = .7, b3 = .6, b4 = .45),
  Sigma = c(.05, 0, 0, 0, .05, 0, 0, .03, 0, .03),
  quant = ~ b1 * b2 * b3 * b4, type = "MC", plot = TRUE, plotCI = TRUE)
```

### Using S7 `ProductNormal` Class

``` r
library(RMediation)

# Create a ProductNormal distribution (2 variables)
mu <- c(0.5, 0.3)
Sigma <- matrix(c(0.01, 0.002, 0.002, 0.01), 2, 2)
pn <- ProductNormal(mu = mu, Sigma = Sigma)

# Compute confidence interval
ci(pn, level = 0.95, type = "dop")

# Display detailed information
print(pn)
summary(pn)
```

### NEW: N-Variable Products (v1.4.0)

Compute confidence intervals for products of 3 or more variables—a
capability previously unavailable:

``` r
library(RMediation)

# Three-way product: a1 * a2 * b (e.g., multiple mediators)
pn3 <- ProductNormal(
  mu = c(0.3, 0.4, 0.5),
  Sigma = diag(3)
)

# Compute CI using Monte Carlo method
ci(pn3, level = 0.95, type = "mc", n.mc = 1e5)

# Output:
# $CI
# [1] -2.369153  2.768295
#
# $Estimate
# [1] 0.06
#
# $SE
# [1] 1.306089
```

### Using `lavaan` Integration

``` r
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

Contributions are welcome! If you encounter issues or have feature
requests:

- [Report a Bug](https://github.com/data-wise/rmediation/issues)
- [Submit a Pull Request](https://github.com/data-wise/rmediation/pulls)

## Citation

If you use **RMediation** in your research, please cite the following:

> **Package Reference:** \> Tofighi, D., & MacKinnon, D. P. (2011).
> RMediation: An R package for mediation analysis confidence intervals.
> *Behavior Research Methods*, 43, 692–700.
> <doi:10.3758/s13428-011-0076-x>

> **MBCO Method:** \> Tofighi, D., & Kelley, K. (2020). Improved
> inference in mediation analysis: Introducing the model-based
> constrained optimization procedure. *Psychological Methods*, 25(4),
> 496-515. <doi:10.1037/met0000259>

> **Bootstrap MBCO:** \> Tofighi, D. (2020). Bootstrap Model-Based
> Constrained Optimization Tests of Indirect Effects. *Frontiers in
> Psychology*, 10, 2989. <doi:10.3389/fpsyg.2019.02989>

## License

`RMediation` is licensed under the
[GPL-3.0](https://choosealicense.com/licenses/gpl-3.0/).

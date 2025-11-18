# RMediation <img src="man/figures/logo.png" align="right" height="139" alt="RMediation website" />

[![CRAN status](https://www.r-pkg.org/badges/version/RMediation)](https://CRAN.R-project.org/package=RMediation)
[![Website Status](https://github.com/data-wise/rmediation/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/data-wise/rmediation/actions/workflows/pkgdown.yaml)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)


**RMediation** provides rigorous statistical methods for mediation analysis in observational and experimental designs. It addresses the known limitations of normal-theory confidence intervals (e.g., Sobel test) by implementing advanced methods that account for the non-normal distribution of the indirect effect.

## Key Capabilities

### 1. Rigorous Confidence Intervals
Compute accurate Confidence Intervals (CIs) for indirect effects using methods that outperform the standard normal approximation:

* **Distribution of the Product:** Exact method for the product of two normal random variables.
* **Monte Carlo Method:** Robust simulation-based intervals.
* **Bootstrapping:** Parametric and semi-parametric bootstrap implementations.

### 2. Advanced Hypothesis Testing
* **LRT-MBCO:** Implements the **Likelihood Ratio Test via Model-Based Constrained Optimization**, a powerful frequentist method for testing indirect effects that controls Type I error rates better than standard approaches.
* **Sobel Test:** Asymptotic normal test included for baseline comparison.

### 3. Seamless Integration
* Works directly with summary statistics (coefficients/SEs).
* Extracts parameters automatically from fitted `lavaan` or `OpenMx` model objects.

---

## Installation

You can install the stable version from CRAN:

```r
install.packages("RMediation")
````

Or the development version from GitHub:

R

```
# install.packages("remotes")
remotes::install_github("data-wise/RMediation")
```

## Usage Scenarios

### Scenario A: Using Summary Statistics

If you already have estimates from a published paper or other software, you can calculate CIs using coefficients ($\hat{a}, \hat{b}$) and their standard errors.

```r
library(RMediation)

# Example: Single mediator
# a = 0.5, b = 0.6, se.a = 0.08, se.b = 0.04, rho = 0 (independence)
medci(mu.x = 0.5, mu.y = 0.6, se.x = 0.08, se.y = 0.04, rho = 0, type = "prodclin")
```

### Scenario B: Using a Fitted Model Object (Lavaan)

If you have fit a model using `lavaan`, `RMediation` can automatically extract the necessary information to compute CIs for indirect effects.

```r
library(lavaan)
library(RMediation)

# 1. Fit your model in lavaan
fit <- sem(my_model, data = my_data)

# 2. Pass the fitted object directly to ci()
# RMediation detects the coefficients and covariance matrix automatically
results <- ci(fit, type = "MC") 
print(results)
```

## Contributing

Contributions are welcome! If you encounter issues or have feature requests:

- [Report a Bug](https://github.com/data-wise/rmediation/issues)
    
- [Submit a Pull Request](https://www.google.com/search?q=https://github.com/data-wise/rmediation/pulls)
    
## Citation

If you use **RMediation** in your research, please cite the following:

> **Package Reference:** > Tofighi, D., & MacKinnon, D. P. (2011). RMediation: An R package for mediation analysis confidence intervals. _Behavior Research Methods_, 43, 692–700. doi:10.3758/s13428-011-0076-x

> **MBCO Method:** > Tofighi, D., & Kelley, K. (2020). Improved inference in mediation analysis: Introducing the model-based constrained optimization procedure. _Psychological Methods_, 25(4), 496-515. doi:10.1037/met0000259

> **Bootstrap MBCO:** > Tofighi, D. (2020). Bootstrap Model-Based Constrained Optimization Tests of Indirect Effects. _Frontiers in Psychology_, 10, 2989. doi:10.3389/fpsyg.2019.02989

## License

`RMediation` is licensed under the [GPL-3.0](https://choosealicense.com/licenses/gpl-3.0/).

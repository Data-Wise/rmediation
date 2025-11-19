## About This Package

RMediation is an R package for computing confidence intervals (CIs) for nonlinear functions of model parameters (e.g., indirect effects) in single-level and multilevel structural equation models. It provides parametric, semiparametric, and non-parametric methods for confidence interval estimation, with emphasis on exact distribution theory and robust bootstrap procedures.

### Core Mission
Provide researchers with flexible, statistically rigorous tools to quantify mediation mechanisms while maintaining accessibility for applied practitioners. Methods accommodate both observational studies and experimental designs.

### Key References
- Tofighi & MacKinnon (2011): RMediation foundational CI methods
- Tofighi (2020): MBCO bootstrap methods (*Frontiers in Psychology*)
- MacKinnon et al. (2007): PRODCLIN distribution of the product (*Behavior Research Methods*)
- Craig (1936): Frequency function of product of two normals

## Common Development Commands
## Building and Running

The project uses a `Makefile` and a custom R script (`dev/dev_agent.R`) to manage common development tasks.

*   **`make build`**: Builds the R package tarball using `devtools::build()`.
*   **`make test`**: Runs the test suite using `testthat::test_package()`.
*   **`make check`**: Performs a full package check using `devtools::check()`.
*   **`make lint`**: Lints the package code using `lintr::lint_package()`.
*   **`make doc`**: Generates Roxygen documentation using `roxygen2::roxygenise()`.
*   **`make site`**: Builds a `pkgdown` website for the package.
*   **`make status`**: Prints a summary of the `DESCRIPTION` file.

To install the package locally for development, you can use `devtools::install()`.

### Package Building and Checking
```r
# Install package dependencies
install.packages(c("remotes", "rcmdcheck"))
remotes::install_deps(dependencies = TRUE)

# Check package (standard R CMD check)
rcmdcheck::rcmdcheck(args = "--no-manual", error_on = "error")

# Build package
devtools::build()

# Install and reload package during development
devtools::load_all()
```

### Documentation
```r
# Generate documentation from roxygen2 comments
devtools::document()

# Build PDF manual
devtools::build_manual()
```

### Testing and Linting
The package uses GitHub Actions for CI/CD with workflows defined in `.github/workflows/`:
- `r.yml`: R package check on macOS for R versions 3.6.3 and 4.1.1
- `lintr.yml`: Code linting
- `codeql.yml`: Security analysis

## Coding Standards

### R Version and Style
- **Minimum R version**: 3.5.0 (specified in DESCRIPTION)
- **Roxygen2**: Use roxygen2 for documentation (current: 7.2.3)
- **Functional approach**: Vectorize operations; avoid loops where possible
- **Clarity priority**: Code must be readable for both methodologists and applied users

### Naming Conventions (Current Codebase)
The package currently uses **camelCase** and **snake_case** mixed conventions:

**Functions:**
- Main exports use camelCase: `medci()`, `qprodnormal()`, `pprodnormal()`
- Internal helpers use camelCase with lowercase prefix: `medciMeeker()`, `medciMC()`, `medciAsymp()`
- Formula interface uses lowercase: `quant` parameter

**Arguments:**
- `mu.x`, `mu.y` for path coefficient estimates (a path, b path)
- `se.x`, `se.y` for standard errors
- `rho` for correlation between coefficients (default: 0)
- `type` for CI algorithm: "dop", "mc", "asymp", "all"
- `alpha` for significance level (default: 0.05)
- `n.mc` for Monte Carlo sample size

**Note**: When adding new functions, maintain consistency with existing naming patterns in the codebase.

## Code Architecture

### Core Function Hierarchy

The package has three main user-facing functions with distinct internal implementations:

1. **`medci()`** - Specialized for two-variable product (a*b indirect effects)
   - Dispatches to: `medciMeeker()`, `medciMC()`, or `medciAsymp()`
   - Located in: `R/medci.R`
   - Implements distribution of product method via Meeker & Escobar (1994) algorithm

2. **`ci()`** - General purpose for any nonlinear function of coefficients
   - Dispatches to: `confintMC()` or `confintAsymp()`
   - Located in: `R/ci.R`
   - Accepts `lavaan` objects or raw mu/Sigma inputs
   - Uses formula interface (`quant` parameter) for specifying functions
   - Multivariate delta method for asymptotic SE

3. **`mbco()`** - Model-Based Constrained Optimization chi-squared tests
   - Dispatches to: `mbco_asymp()`, `mbco_parametric()`, or `mbco_semi()`
   - Located in: `R/mbco.R`
   - Works with OpenMx models (h0 and h1)
   - Implements bootstrap variants for hypothesis testing

### Distribution Functions

The package implements distribution functions for the product of two normal random variables:

- **`pprodnormal()`** / **`qprodnormal()`**: CDF and quantile functions
  - Internal implementations: `pprodnormalMeeker()`, `pprodnormalMC()`, `qprodnormalMeeker()`, `qprodnormalMC()`
  - Located in: `R/pprodnormal.R`, `R/qprodnormal.R`

- **`pMC()`** / **`qMC()`**: Monte Carlo-based distribution functions
  - General purpose for any function of coefficients
  - Located in: `R/pMC.R`, `R/qMC.R`

### Key Dependencies

- **lavaan**: For SEM parameter extraction (`coef()`, `vcov()`)
- **OpenMx**: For `mbco()` model-based optimization tests
- **MASS**: For `mvrnorm()` multivariate normal sampling
- **doParallel/foreach**: For parallel bootstrap computations in MBCO tests
- **e1071**: For skewness/kurtosis calculations

### Data

- `memory_exp.RData`: Example dataset for mediation analysis demonstrations
  - Located in: `data/`
  - Used in examples for `mbco()` function

## Important Implementation Details

### Standard Error Calculation
For product of two normals (a*b), the analytical SE formula (Craig, 1936) is:
```
SE = sqrt(se.y^2 * mu.x^2 + se.x^2 * mu.y^2 + 2*mu.x*mu.y*rho*se.x*se.y + se.x^2*se.y^2 + se.x^2*se.y^2*rho^2)
```
This is implemented consistently across methods except for MC where it's computed empirically.

### CI Method Types and When to Use Them

- **"dop"** (distribution of product):
  - Default for `medci()`
  - Uses Meeker & Escobar (1994) algorithm for exact distribution theory
  - Most accurate for small samples; computationally intensive
  - Assumes joint normality of coefficient estimates
  - **Use when**: Accuracy matters more than speed

- **"MC"** (Monte Carlo):
  - Default for `ci()`
  - Generates samples from multivariate normal, computes empirical quantiles
  - Flexible and works for complex functions (via `ci()` formula interface)
  - Accuracy increases with `n.mc` (default: 1e5 for `medci()`, 1e6 for `ci()`)
  - **Use when**: Need flexibility for complex mediation models or multiple paths

- **"asymp"** (Asymptotic/Sobel test):
  - Uses delta method approximation
  - Fast but often underestimates CI width
  - Assumes normality; questionable for small samples
  - **Use when**: Quick approximation needed; not recommended for inference

- **"all"**:
  - Returns results from all applicable methods
  - Useful for comparing method robustness
  - When `plot=TRUE`, superimposes distributions from different methods

### Plot Functionality
Both `medci()` and `ci()` support visualization:
- `plot=TRUE`: Displays density plot of the sampling distribution
- `plotCI=TRUE`: Overlays confidence interval with error bars (requires `plot=TRUE`)
- When `type="all"`, superimposes distributions from different methods

### MBCO (Model-Based Constrained Optimization)

The `mbco()` function tests H₀: indirect effect = 0 via constrained optimization with bootstrap refinement:

**Types:**
- **"asymp"** (default): Asymptotic MBCO chi-squared test
- **"parametric"**: Parametric bootstrap - resamples from asymptotic normal distribution of MLEs (more efficient, relies on model specification)
- **"semi"**: Semiparametric bootstrap - resamples data and re-estimates models (more robust to misspecification, computationally intensive)

**OpenMx Optimization:**
- Default optimizer: "SLSQP"
- Falls back to SLSQP if NPSOL unavailable
- Precision: 1e-9 by default for functional precision
- Arguments `checkHess` and `checkSE` default to "No" for speed

**Usage pattern:**
```r
# Define full and null models in OpenMx
full_model <- mxTryHard(full_model, checkHess=FALSE, silent=TRUE)
null_model <- mxTryHard(null_model, checkHess=FALSE, silent=TRUE)
mbco(h0=null_model, h1=full_model, type="asymp")
```

## Statistical Assumptions & Diagnostics

### Key Assumptions

1. **Normality of coefficient estimates**: (α̂, β̂) ~ N(α, β; Σ)
   - Generally holds for large n by Central Limit Theorem
   - Questionable for small samples (n < 50) or extreme parameters
   - Diagnostic: Q-Q plots of resampled coefficients in bootstrap

2. **Correlation parameter ρ**:
   - Default `rho=0` assumes independence of α̂ and β̂
   - Reality: Often correlated with shared confounders
   - Non-zero ρ widens confidence intervals
   - **Important**: Always check if `rho` should be specified from covariance matrix

3. **No unmeasured confounding** (causal inference):
   - Beyond package's scope but critical for causal interpretation
   - Package computes CIs conditional on specified model
   - Validity depends on research design and causal assumptions

4. **Correct model specification**:
   - Especially critical for parametric bootstrap in `mbco()`
   - Semiparametric bootstrap more robust to misspecification

### Common Pitfalls

1. **Ignoring ρ ≠ 0**: Can lead to overly narrow CIs
2. **Small samples with asymptotic method**: Normal approximation breaks down
3. **Effects near zero**: CIs may be highly asymmetric; interpret cautiously
4. **Assuming statistical significance implies causal mediation**: Always consider design and confounding

## Monte Carlo Implementation Details

The MC method in both `medci()` and `ci()` follows this pattern:

1. **Generate samples** from bivariate/multivariate normal distribution using `MASS::mvrnorm()`
2. **Compute products** (or arbitrary function via formula for `ci()`)
3. **Extract empirical quantiles** at α/2 and 1-α/2
4. **Report MC error**: SE of estimate = SD(products) / sqrt(n.mc)

**Memory considerations:**
- Default `n.mc=1e5` for `medci()` (two-variable case)
- Default `n.mc=1e6` for `ci()` (general case)
- For large covariance matrices: `length(mu) * n.mc` must be < `.Machine$integer.max`
- If exceeded, `n.mc` automatically reduced to 1e6 with warning

**Reproducibility:**
- Set seed before calling for reproducible results
- MC error reported to assess convergence

## Implementation Patterns

### Adding New CI Methods

When implementing a new CI method:

1. **Create internal function** with signature:
   ```r
   .ci_new_method <- function(mu.x, mu.y, se.x, se.y, rho, alpha) {
     # Returns list with: CI, Estimate, SE
     list(
       CI = c(lower, upper),
       Estimate = estimate,
       SE = se
     )
   }
   ```

2. **Add to dispatcher** in main function (`medci()` or `ci()`)
3. **Write unit tests** against known examples
4. **Document assumptions** in function documentation
5. **Benchmark** accuracy and speed against existing methods

### Working with lavaan Objects

The `ci()` function can accept lavaan fitted objects directly:

```r
# Extract from lavaan
if (isa(mu, "lavaan")) {
  pEst <- coef(fm1)                    # Parameter estimates
  name1 <- all.vars(quant)              # Extract variable names from formula
  mu <- pEst[name1]                     # Subset to relevant parameters
  covM1 <- vcov(fm1)                    # Covariance matrix
  Sigma <- covM1[name1, name1]          # Subset covariance
}
```

This pattern should be extended if adding support for other SEM packages.

## Testing Strategy

### Unit Tests Should Cover

1. **CI Method Accuracy**
   - Compare to published examples (MacKinnon et al. 2007, Tofighi & MacKinnon 2011)
   - Verify consistency: DOP ≈ MC for large n.mc
   - Check that asymptotic CIs are narrower than DOP/MC (known behavior)

2. **Bootstrap Methods (MBCO)**
   - Parametric vs semiparametric equivalence under correct model specification
   - Convergence with increasing bootstrap samples
   - Reproducibility with set.seed()

3. **Edge Cases**
   - Small sample size (n < 50)
   - Very small indirect effects (near zero)
   - High correlation ρ (near ±1)
   - Near-singular covariance matrices
   - Extreme SE values (numerical stability)

4. **Model Extraction**
   - Verify identical coefficients from lavaan object vs manual input
   - Handle different lavaan model types (sem, cfa, growth)
   - Proper extraction of constrained parameters

5. **Input Validation**
   - Invalid `type` argument
   - `alpha` outside (0, 1)
   - `rho` outside (-1, 1)
   - Mismatched dimensions in mu and Sigma
   - Non-positive-definite covariance matrices

### Coverage Expectations

For bootstrap methods, empirical coverage should be within Monte Carlo error:
- 95% CI should contain true value ~93-97% of time in simulations
- Lower coverage indicates method failure or assumption violation

## Key Mathematical Formulas

### Indirect Effect Estimate
For simple mediation (X → M → Y):
```
Indirect effect = α × β + ρ·SE(α)·SE(β)
```
Where:
- α = effect of X on M
- β = effect of M on Y (controlling for X)
- ρ = correlation between α̂ and β̂

### Standard Error (Craig, 1936)
```
SE(αβ) = sqrt(β²·SE(α)² + α²·SE(β)² + 2αβρ·SE(α)·SE(β) + SE(α)²·SE(β)² + SE(α)²·SE(β)²·ρ²)
```

Simplified when ρ = 0:
```
SE(αβ) = sqrt(β²·SE(α)² + α²·SE(β)² + SE(α)²·SE(β)²)
```

### Asymptotic CI (Sobel Test)
```
CI = (αβ) ± z₁₋α/₂ × SE(αβ)
```
Where z₁₋α/₂ is the normal quantile (e.g., 1.96 for 95% CI)

**Warning**: This often underestimates CI width because the product distribution is not normal.

## Additional Resources

### Key Publications
- **Craig, C. C. (1936)**. On the frequency function of xy. *The Annals of Mathematical Statistics*, 7(1), 1-15.
- **MacKinnon, D. P., Fritz, M. S., Williams, J., & Lockwood, C. M. (2007)**. Distribution of the product confidence limits for the indirect effect: Program PRODCLIN. *Behavior Research Methods*, 39(3), 384-389.
- **Meeker, W. Q., & Escobar, L. A. (1994)**. An algorithm to compute the CDF of the product of two normal random variables. *Communications in Statistics-Simulation and Computation*, 23(1), 271-280.
- **Tofighi, D., & MacKinnon, D. P. (2011)**. RMediation: An R package for mediation analysis confidence intervals. *Behavior Research Methods*, 43(3), 692-700.
- **Tofighi, D. (2020)**. Bootstrap Model-Based Constrained Optimization Tests of Indirect Effects. *Frontiers in Psychology*, 10, 2989.
- **Tofighi, D., & Kelley, K. (2020)**. Indirect effects in sequential mediation models: Evaluating methods for hypothesis testing and confidence interval formation. *Multivariate Behavioral Research*, 55(2), 188-210.

### Package Website
- Shiny web application for Monte Carlo CI: https://amplab.shinyapps.io/MEDMC/

# RMediation Package Improvement Plan

**Date**: 2024-11-16
**Version**: 2.0.0
**Analyst**: Claude Code

---

## Executive Summary

The RMediation package (1,531 lines across 26 R files) provides solid statistical methods for mediation analysis confidence intervals. However, the codebase has accumulated technical debt through:
- **47 identified issues** across code quality, organization, documentation, and testing
- **Critical bugs** requiring immediate attention (logic errors, copy-paste mistakes)
- **No test infrastructure** (highest risk)
- **Significant code duplication** (maintenance burden)

This plan provides a phased approach to modernization while maintaining backward compatibility.

---

## Phase 1: Critical Bug Fixes (Week 1)

### Priority: CRITICAL - Fix Before Any Release

#### 1.1 Logic Error in is_valid_lav_syntax.R
**File**: `R/lav_mice.R:53-55`
**Issue**: Negation error - stops on valid syntax instead of invalid

```r
# CURRENT (WRONG):
if (is_valid_lav_syntax(model, mids$data)) {
  stop("The model is not a valid lavaan model syntax.")
}

# FIX:
if (!is_valid_lav_syntax(model, mids$data)) {
  stop("The model is not a valid lavaan model syntax.")
}
```

**Impact**: Function fails on valid models
**Testing**: Add unit test with valid/invalid lavaan syntax

---

#### 1.2 Error Message Bugs
**Files**: `R/pMC.R:28-35`, `R/qMC.R:27-35`

**Issue**: Copy-paste errors in parameter names

```r
# pMC.R line 28 - WRONG:
if (missing(q)) stop(paste("argument", sQuote("p"), "must be specified"))
                                               ^^^
# Should reference "q"

# Both files lines 32-35 - WRONG:
if (is.null(q)) stop(paste("argument", sQuote("mu"), "cannot be a NULL value"))
                                               ^^^^
# Should reference "q" or "p" respectively
```

**Fix**: Correct all parameter references in error messages
**Testing**: Add parameter validation tests

---

#### 1.3 Typos
**Files**: `R/ci.R:94`, `R/mbco_semi.R:22`

```r
# ci.R:94 - Fix typo:
stop(paste("Please enter a ccorrect", ...))
                         ^^^^^^^^
# Should be: "correct"

# mbco_semi.R:22 - Fix comment:
# Seubset of teh manifest variables
  ^^^^^^^    ^^^
# Should be: "Subset of the"
```

**Impact**: Unprofessional error messages
**Testing**: Automated spell check in CI/CD

---

## Phase 2: Test Infrastructure (Week 2)

### Priority: HIGH - Foundation for All Improvements

#### 2.1 Create Test Framework

**Action**: Initialize testthat infrastructure

```r
# Run in R console:
usethis::use_testthat()
```

**Creates**:
- `tests/testthat/` directory
- `tests/testthat.R` file

---

#### 2.2 Core Function Tests

**Files to create**:

1. `tests/testthat/test-medci.R` - Test medci() with known results
   - Test against MacKinnon et al. (2007) published examples
   - Test all type options: "dop", "mc", "asymp", "all"
   - Test rho parameter variations
   - Test plot functionality

2. `tests/testthat/test-ci.R` - Test ci() function
   - Test with coefficient vectors
   - Test with lavaan objects
   - Test formula interface (~b1*b2*b3)
   - Test error handling for invalid inputs

3. `tests/testthat/test-product-dist.R` - Test pprodnormal/qprodnormal
   - Test consistency: qprodnormal(pprodnormal(x)) ≈ x
   - Test against known quantiles
   - Test MC vs Meeker convergence

4. `tests/testthat/test-mbco.R` - Test MBCO methods
   - Test asymp, parametric, semi methods
   - Test with simple OpenMx models
   - Verify chi-square statistics

5. `tests/testthat/test-validation.R` - Input validation
   - Test parameter bounds (alpha ∈ (0,1), rho ∈ (-1,1))
   - Test dimension matching (mu vs Sigma)
   - Test type parameter matching
   - Test NA/Inf/NaN handling

6. `tests/testthat/test-missing-data.R` - Test lav_mice/mx_mice
   - Test with mice::mids objects
   - Test lavaan model fitting
   - Test OpenMx model fitting

---

#### 2.3 Coverage Goals

**Minimum Acceptable**: 70% code coverage
**Target**: 85% code coverage

```r
# Check coverage:
covr::package_coverage()
covr::report()
```

---

## Phase 3: Code Refactoring (Weeks 3-4)

### Priority: HIGH - Reduce Technical Debt

#### 3.1 Extract Validation Utilities

**New file**: `R/utils_validation.R`

```r
#' Validate CI Method Type
#' @keywords internal
validate_ci_type <- function(type, allowed = c("dop", "mc", "asymp", "all")) {
  type <- tolower(type)  # Normalize case
  match.arg(type, allowed)
}

#' Validate Significance Level
#' @keywords internal
validate_alpha <- function(alpha) {
  if (!is.numeric(alpha) || length(alpha) != 1)
    stop("'alpha' must be a single numeric value", call. = FALSE)
  if (alpha <= 0 || alpha >= 1)
    stop("'alpha' must be between 0 and 1", call. = FALSE)
  alpha
}

#' Validate Correlation Parameter
#' @keywords internal
validate_rho <- function(rho) {
  if (!is.numeric(rho) || length(rho) != 1)
    stop("'rho' must be a single numeric value", call. = FALSE)
  if (rho <= -1 || rho >= 1)
    stop("'rho' must be between -1 and 1", call. = FALSE)
  rho
}

#' Ensure Covariance Matrix
#' @keywords internal
ensure_covariance_matrix <- function(Sigma, mu) {
  if (!is.matrix(Sigma)) {
    expected_len <- (length(mu) * (length(mu) + 1)) / 2
    if (length(Sigma) != expected_len) {
      stop(sprintf(
        "'Sigma' has length %d but should have length %d for %d parameters",
        length(Sigma), expected_len, length(mu)
      ), call. = FALSE)
    }
    Sigma <- lavaan::lav_matrix_vech_reverse(Sigma)
  }
  Sigma
}
```

**Updates required**:
- `R/medci.R`: Use validate_ci_type(), validate_alpha(), validate_rho()
- `R/ci.R`: Use validate_ci_type(), validate_alpha(), ensure_covariance_matrix()
- `R/pMC.R`, `R/qMC.R`: Use ensure_covariance_matrix()
- `R/confintMC.R`, `R/confintAsymp.R`: Use ensure_covariance_matrix()

---

#### 3.2 Extract Plotting Utilities

**New file**: `R/utils_plotting.R`

```r
#' Set Up Plot Margins for CI Plots
#' @keywords internal
setup_ci_plot_margins <- function() {
  op <- par(mar = c(7, 4, 7, 4) + 0.1, xpd = TRUE, ask = FALSE)
  op
}

#' Plot Density with CI Overlay
#' @keywords internal
plot_density_with_ci <- function(samples, ci_lower, ci_upper,
                                  estimate, se, method = "MC", ...) {
  # Implementation extracted from confintMC.R lines 63-136
  # Cleaner, modular plotting logic
}

#' Add CI Error Bars to Plot
#' @keywords internal
add_ci_errorbars <- function(ci_lower, ci_upper, estimate, y_position) {
  # Implementation for overlaying CI bars
}
```

**Updates required**:
- `R/confintMC.R`: Extract lines 63-136 to use plot utilities
- `R/confintAsymp.R`: Extract lines 19-88 to use plot utilities
- `R/medci.R`: Extract lines 120-152 to use plot utilities

---

#### 3.3 Consolidate Product Distribution Functions

**Action**: Merge related files

**Option A - Keep Separate (Current Structure)**:
- Maintain 6 separate files for modularity

**Option B - Consolidate (Recommended)**:

Merge into 2 files:
1. `R/product_distribution_cdf.R`:
   - pprodnormal()
   - pprodnormalMeeker()
   - pprodnormalMC()

2. `R/product_distribution_quantile.R`:
   - qprodnormal()
   - qprodnormalMeeker()
   - qprodnormalMC()

**Benefits**:
- Easier to maintain related functions together
- Reduces file count from 6 → 2
- All CDF logic in one place, all quantile logic in one place

---

#### 3.4 Standardize Monte Carlo Sample Sizes

**New file**: `R/constants.R`

```r
#' Default Monte Carlo Sample Sizes
#' @name mc_defaults
#' @keywords internal
NULL

#' @rdname mc_defaults
MC_SAMPLE_SIZE_SMALL <- 1e5   # For quick approximations

#' @rdname mc_defaults
MC_SAMPLE_SIZE_MEDIUM <- 1e6  # Default for ci()

#' @rdname mc_defaults
MC_SAMPLE_SIZE_LARGE <- 1e7   # For high-precision needs

#' @rdname mc_defaults
MC_DEFAULT_SIZE <- MC_SAMPLE_SIZE_MEDIUM
```

**Updates required**:
- `R/medci.R:92`: Change `n.mc=1e5` to `n.mc=MC_DEFAULT_SIZE`
- `R/ci.R:91`: Change `n.mc=1e6` to `n.mc=MC_DEFAULT_SIZE`
- `R/medciMC.R:2`: Document why 1e7 is used (high precision)
- All MC functions: Use named constants

**Rationale**: Document and centralize choices, easy to adjust globally

---

#### 3.5 Extract Standard Error Calculation

**New file**: `R/utils_statistics.R`

```r
#' Compute Standard Error of Product of Two Normals
#'
#' Uses Craig (1936) formula for SE(ab)
#'
#' @param mu.a Mean of a
#' @param mu.b Mean of b
#' @param se.a Standard error of a
#' @param se.b Standard error of b
#' @param rho Correlation between a and b
#' @return Standard error of the product
#' @keywords internal
se_product <- function(mu.a, mu.b, se.a, se.b, rho = 0) {
  sqrt(
    se.b^2 * mu.a^2 +
    se.a^2 * mu.b^2 +
    2 * mu.a * mu.b * rho * se.a * se.b +
    se.a^2 * se.b^2 +
    se.a^2 * se.b^2 * rho^2
  )
}

#' Compute Indirect Effect Estimate
#'
#' Computes ab + rho*SE(a)*SE(b)
#'
#' @inheritParams se_product
#' @return Point estimate of indirect effect
#' @keywords internal
estimate_indirect <- function(mu.a, mu.b, se.a, se.b, rho = 0) {
  mu.a * mu.b + rho * se.a * se.b
}
```

**Updates required**:
- `R/medciMeeker.R:8`: Use se_product()
- `R/medciAsymp.R:6`: Use se_product()
- `R/medci.R:128`: Use se_product()
- All functions computing SE(ab): Use centralized function

---

## Phase 4: Documentation Enhancement (Week 5)

### Priority: HIGH - Improve User Experience

#### 4.1 Add Roxygen Documentation to Internal Functions

**Files needing roxygen2 headers**:

1. `R/confintMC.R` - Add:
```r
#' Monte Carlo Confidence Intervals (Internal)
#'
#' Internal function for computing Monte Carlo confidence intervals.
#' Called by ci() and medci().
#'
#' @inheritParams ci
#' @return List with CI, Estimate, SE, MC.Error
#' @keywords internal
#' @noRd
```

2. Similarly for:
   - `R/confintAsymp.R`
   - `R/medciMeeker.R`
   - `R/medciMC.R`
   - `R/medciAsymp.R`
   - `R/pprodnormalMeeker.R`
   - `R/pprodnormalMC.R`
   - `R/qprodnormalMeeker.R`
   - `R/qprodnormalMC.R`
   - `R/mbco_asymp.R`
   - `R/mbco_parametric.R`
   - `R/mbco_semi.R`

---

#### 4.2 Create Vignettes

**Vignette 1**: `vignettes/quickstart.Rmd`
```yaml
---
title: "Getting Started with RMediation"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Getting Started with RMediation}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---
```

Content:
- What is mediation analysis?
- Simple example with medci()
- Interpreting results
- Choosing CI method

**Vignette 2**: `vignettes/ci-methods.Rmd`
```yaml
title: "Confidence Interval Methods Comparison"
```

Content:
- Distribution of Product (DOP/Meeker)
- Monte Carlo (MC)
- Asymptotic (Delta method)
- When to use each method
- Computational cost vs accuracy trade-offs
- Visual comparison

**Vignette 3**: `vignettes/complex-mediation.Rmd`
```yaml
title: "Complex Mediation Models with ci()"
```

Content:
- Multiple mediators
- Serial mediation
- Moderated mediation
- Formula interface (~b1*b2*b3)
- Integration with lavaan

**Vignette 4**: `vignettes/missing-data.Rmd`
```yaml
title: "Mediation Analysis with Missing Data"
```

Content:
- Using lav_mice() and mx_mice()
- Integration with mice package
- Note about missingmed package for more advanced features

**Vignette 5**: `vignettes/mbco-tests.Rmd`
```yaml
title: "Model-Based Constrained Optimization Tests"
```

Content:
- What is MBCO?
- Asymptotic vs parametric vs semiparametric
- OpenMx model specification
- Hypothesis testing for indirect effects

---

#### 4.3 Enhance Function Documentation

**Add @details sections** explaining:

1. **medci()** - Add guidance on method selection:
```r
#' @details
#' ## Method Selection
#'
#' **Distribution of Product (DOP, default)**: Uses exact distribution theory
#' via Meeker & Escobar (1994) algorithm. Most accurate for small samples but
#' computationally intensive. Recommended unless speed is critical.
#'
#' **Monte Carlo (MC)**: Generates samples from bivariate normal distribution
#' and computes empirical quantiles. Accuracy increases with n.mc. Good balance
#' of speed and accuracy.
#'
#' **Asymptotic (Sobel test)**: Uses delta method approximation. Fast but often
#' underestimates CI width. Not recommended for inference, use for quick checks only.
#'
#' ## Sample Size Recommendations
#'
#' For n.mc in Monte Carlo method:
#' - Quick check: 1e4 (10,000)
#' - Standard use: 1e5 (100,000, default)
#' - High precision: 1e6 - 1e7 (1-10 million)
```

2. **ci()** - Add formula interface examples:
```r
#' @examples
#' # Three-path indirect effect
#' ci(mu = c(a=0.3, b=0.4, c=0.5),
#'    Sigma = diag(0.01, 3),
#'    quant = ~a*b*c)
#'
#' # Complex function of parameters
#' ci(mu = c(a1=0.3, b1=0.4, a2=0.2, b2=0.5),
#'    Sigma = diag(0.01, 4),
#'    quant = ~(a1*b1) + (a2*b2))  # Total indirect effect
```

---

#### 4.4 Add Method Selection Decision Tree

**New documentation file**: `man/method-selection.Rd`

```
\name{method-selection}
\alias{method-selection}
\title{Choosing a CI Method in RMediation}
\description{
Decision guide for selecting confidence interval methods
}
\details{
Use this decision tree:

1. Do you need exact inference (e.g., for publication)?
   → YES: Use method="dop" (distribution of product)
   → NO: Continue to #2

2. Is speed critical (e.g., simulation study with 1000+ replications)?
   → YES: Use method="asymp" (asymptotic/Sobel)
   → NO: Continue to #3

3. Do you have complex functions (3+ paths)?
   → YES: Use method="mc" with ci()
   → NO: Use method="dop" for best accuracy

4. Sample size considerations:
   - n < 50: Prefer "dop" (asymptotic assumptions questionable)
   - 50 ≤ n < 200: "dop" or "mc" with high n.mc
   - n ≥ 200: Any method acceptable, "asymp" often sufficient

5. Effect size considerations:
   - Indirect effect near zero: Prefer "dop" or "mc"
   - CI highly asymmetric: Avoid "asymp"
}
\seealso{
\code{\link{medci}}, \code{\link{ci}}
}
```

---

## Phase 5: Dependency Optimization (Week 6)

### Priority: MEDIUM - Reduce Package Footprint

#### 5.1 Move Heavy Dependencies to Suggests

**Current DESCRIPTION Imports**:
```
Imports:
    OpenMx (>= 2.13),     # 50+ MB, only used in mbco_*
    lavaan (>= 0.6-0),    # Only used in ci() for lavaan objects
    mice (>= 3.8.0),      # Only used in lav_mice/mx_mice
```

**Proposed DESCRIPTION**:
```
Imports:
    graphics (>= 3.5.0),
    grDevices (>= 3.5),
    methods (>= 3.5.0),
    stats (>= 3.5.0),
    MASS (>= 7.3)

Suggests:
    OpenMx (>= 2.13),
    lavaan (>= 0.6-0),
    mice (>= 3.8.0),
    e1071 (>= 1.6-7),
    modelr (>= 0.1.8),
    testthat (>= 3.0.0),
    covr,
    knitr,
    rmarkdown
```

**Code changes required**:

1. Add conditional checks:
```r
# At top of mbco.R:
if (!requireNamespace("OpenMx", quietly = TRUE)) {
  stop("Package 'OpenMx' is required for mbco(). Install with:\n  install.packages('OpenMx')",
       call. = FALSE)
}

# At top of ci.R lavaan section:
if (inherits(mu, "lavaan")) {
  if (!requireNamespace("lavaan", quietly = TRUE)) {
    stop("Package 'lavaan' is required to use lavaan objects. Install with:\n  install.packages('lavaan')",
         call. = FALSE)
  }
  # Existing lavaan code...
}

# At top of lav_mice.R and mx_mice.R:
if (!requireNamespace("mice", quietly = TRUE)) {
  stop("Package 'mice' is required. Install with:\n  install.packages('mice')",
       call. = FALSE)
}
```

2. Update package documentation to note optional dependencies

---

#### 5.2 Remove Unused Dependencies

**Action**: Remove from DESCRIPTION:
- `boot` - Never actually used in code (only in commented example)
- `generics` - Can use base::tidy generic instead

---

## Phase 6: Modernization (Weeks 7-8)

### Priority: LOW - Nice to Have

#### 6.1 Add S3 Classes for Results

**New file**: `R/ci_result_class.R`

```r
#' Create CI Result Object
#' @keywords internal
new_ci_result <- function(ci, estimate, se, method, alpha, mc_error = NULL) {
  structure(
    list(
      ci = ci,
      estimate = estimate,
      se = se,
      method = method,
      alpha = alpha,
      mc_error = mc_error,
      contains_zero = ci[1] <= 0 && ci[2] >= 0
    ),
    class = "ci_result"
  )
}

#' @export
print.ci_result <- function(x, digits = 3, ...) {
  cat(sprintf("Mediation Analysis Confidence Interval\n"))
  cat(sprintf("Method: %s\n", x$method))
  cat(sprintf("Estimate: %.*f\n", digits, x$estimate))
  cat(sprintf("SE: %.*f\n", digits, x$se))
  cat(sprintf("%d%% CI: [%.*f, %.*f]\n",
              (1 - x$alpha) * 100,
              digits, x$ci[1],
              digits, x$ci[2]))
  if (!is.null(x$mc_error)) {
    cat(sprintf("MC Error: %.*f\n", digits, x$mc_error))
  }
  if (x$contains_zero) {
    cat("Note: CI contains zero (non-significant at alpha = ", x$alpha, ")\n", sep = "")
  }
  invisible(x)
}

#' @export
summary.ci_result <- function(object, ...) {
  # More detailed output
}

#' @export
plot.ci_result <- function(x, ...) {
  # Visualization of CI
}
```

**Updates**: Modify medci(), ci() to return ci_result objects

---

#### 6.2 Improve Error Messages with rlang

**Example modernization**:

```r
# OLD (base R):
if (alpha <= 0 || alpha >= 1)
  stop("alpha must be between 0 and 1!")

# NEW (rlang):
if (alpha <= 0 || alpha >= 1) {
  rlang::abort(
    "Invalid significance level",
    class = "rmediation_invalid_alpha",
    alpha = alpha,
    message = sprintf("alpha must be in (0, 1), got %g", alpha)
  )
}
```

**Benefits**:
- Structured error conditions
- Better error context
- Can be caught with specific classes

---

#### 6.3 Vectorize Functions

**Example**: Allow multiple alpha levels

```r
#' @param alpha Significance level(s). Can be vector (e.g., c(0.05, 0.10))
medci_vectorized <- function(mu.x, mu.y, se.x, se.y,
                               rho = 0,
                               alpha = 0.05,  # Now accepts vector
                               ...) {
  # Compute once, return multiple CIs
  lapply(alpha, function(a) {
    medci_single(mu.x, mu.y, se.x, se.y, rho, a, ...)
  })
}
```

---

## Phase 7: Integration and Release (Week 9)

### Priority: CRITICAL - Ensure Quality

#### 7.1 Pre-Release Checklist

- [ ] All critical bugs fixed (Phase 1)
- [ ] Test coverage ≥ 70% (Phase 2)
- [ ] All refactoring complete (Phase 3)
- [ ] Vignettes created (Phase 4)
- [ ] Documentation complete (Phase 4)
- [ ] Dependencies optimized (Phase 5)
- [ ] `R CMD check` passes with 0 errors, 0 warnings
- [ ] `devtools::check()` passes
- [ ] All examples run successfully
- [ ] Version number bumped appropriately
- [ ] NEWS.md updated
- [ ] CRAN comments prepared

---

#### 7.2 GitHub Actions CI/CD

**Create**: `.github/workflows/R-CMD-check.yml`

```yaml
name: R-CMD-check

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  R-CMD-check:
    runs-on: ${{ matrix.os }}

    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        r-version: ['4.1', '4.2', '4.3', 'release']

    steps:
      - uses: actions/checkout@v3

      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: ${{ matrix.r-version }}

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: any::rcmdcheck

      - uses: r-lib/actions/check-r-package@v2
```

**Create**: `.github/workflows/test-coverage.yml`

```yaml
name: test-coverage

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  coverage:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: r-lib/actions/setup-r@v2
        with:
          use-public-rspm: true

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: any::covr

      - name: Test coverage
        run: covr::codecov()
        shell: Rscript {0}
```

---

#### 7.3 Version Strategy

**Current**: 2.0.0
**Recommended versioning**:

After Phase 1-2 (bug fixes + tests):
- **2.0.1** - Patch release with critical bug fixes

After Phase 3-4 (refactoring + documentation):
- **2.1.0** - Minor release with improved documentation

After Phase 5-6 (dependencies + modernization):
- **2.2.0** - Minor release with dependency optimization

After Phase 7 (if breaking changes):
- **3.0.0** - Major release (only if API changes)

---

## Implementation Timeline

| Phase | Duration | Deliverables | Priority |
|-------|----------|--------------|----------|
| 1: Critical Bugs | 1 week | Bug fixes, typos | CRITICAL |
| 2: Testing | 1 week | Test infrastructure, 70%+ coverage | HIGH |
| 3: Refactoring | 2 weeks | Utilities extracted, code consolidated | HIGH |
| 4: Documentation | 1 week | Vignettes, enhanced docs | HIGH |
| 5: Dependencies | 1 week | Optimized DESCRIPTION | MEDIUM |
| 6: Modernization | 2 weeks | S3 classes, rlang, vectorization | LOW |
| 7: Release | 1 week | CI/CD, final checks | CRITICAL |
| **Total** | **9 weeks** | Production-ready v2.1.0+ | |

---

## Success Metrics

### Code Quality
- ✅ 0 critical bugs
- ✅ Test coverage ≥ 70%
- ✅ R CMD check: 0 errors, 0 warnings, ≤ 5 notes
- ✅ Reduced code duplication by 50%

### Documentation
- ✅ 5 comprehensive vignettes
- ✅ All exported functions fully documented
- ✅ Method selection guide

### Maintainability
- ✅ Modular code structure
- ✅ Clear internal/external separation
- ✅ Standardized constants
- ✅ Reduced file count by 15%

### User Experience
- ✅ Clearer error messages
- ✅ Consistent API
- ✅ Better examples
- ✅ Integration with missingmed package

---

## Risk Mitigation

### Risk 1: Breaking Changes
**Mitigation**:
- Maintain backward compatibility
- Use deprecation warnings before removing features
- Version appropriately (major bump for breaking changes)

### Risk 2: Test Development Time
**Mitigation**:
- Start with high-impact functions (medci, ci)
- Use published examples as test cases
- Incremental coverage increase

### Risk 3: Dependency Conflicts
**Mitigation**:
- Test on multiple R versions (4.1, 4.2, 4.3, release)
- Use GitHub Actions for continuous testing
- Document minimum versions clearly

---

## Post-Release Maintenance

### Ongoing Tasks
1. Monitor CRAN check results
2. Respond to user issues on GitHub
3. Update for new R versions
4. Keep dependencies updated
5. Add new features based on user feedback

### Integration with missingmed
- Document interoperability
- Create examples showing joint usage
- Consider missingmed as Suggests dependency
- Cross-reference in documentation

---

## Conclusion

This 9-week plan transforms RMediation from a functional but technically-debt-laden package into a modern, well-tested, well-documented R package suitable for CRAN submission and long-term maintenance. The phased approach ensures critical issues are addressed first while allowing flexibility in lower-priority enhancements.

**Immediate Action Items**:
1. Fix critical bugs (Phase 1) - Can be done in 1 day
2. Set up test infrastructure (Phase 2.1) - Can be done in 1 day
3. Begin writing core tests (Phase 2.2) - Ongoing

**Question for Package Maintainer**:
- What is your priority: Quick bug fix release vs comprehensive overhaul?
- Are breaking changes acceptable for v3.0.0, or must maintain backward compatibility?
- Timeline constraints for next CRAN submission?

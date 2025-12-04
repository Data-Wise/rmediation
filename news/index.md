# Changelog

## RMediation (development version)

### Ecosystem Notes

- Part of the mediationverse ecosystem for mediation analysis
- Integration with medfit planned for future release
- See [Ecosystem
  Coordination](https://github.com/data-wise/medfit/blob/main/planning/ECOSYSTEM.md)
  for guidelines

------------------------------------------------------------------------

## RMediation 1.4.0

### Major Changes

#### S7 Core Architecture (Complete Refactoring)

- **Complete architectural redesign:** S7 is now the computational core,
  with legacy functions as thin wrappers.
- **Zero breaking changes:** All existing code continues to work exactly
  as before (100% backward compatible).
- **Enhanced extensibility:** New computational architecture makes
  adding CI methods and features straightforward.

#### S7 OOP Classes

- Introduced S7 object-oriented programming for modern, type-safe class
  definitions.
- **New S7 Classes:**
  - `ProductNormal`: Represents the distribution of the product of
    normal random variables.
  - `MBCOResult`: Encapsulates results from MBCO tests.
- **New S7 Generics:**
  [`cdf()`](https://data-wise.github.io/rmediation/reference/cdf.md),
  [`dist_quantile()`](https://data-wise.github.io/rmediation/reference/dist_quantile.md),
  [`ci()`](https://data-wise.github.io/rmediation/reference/ci.md),
  [`print()`](https://rdrr.io/r/base/print.html),
  [`summary()`](https://rdrr.io/r/base/summary.html), `show()`.
- All S7 classes include comprehensive display methods (`print`,
  `summary`, `show`) for meaningful output.

#### N-Variable Product Support (NEW)

- **Breaking limitation removed:** Can now compute confidence intervals
  for products of 3 or more variables.
- Works with Monte Carlo method (`type = "mc"`).
- Example: `ProductNormal(mu = c(0.3, 0.4, 0.5), Sigma = diag(3))` for
  three-way products.
- Previous versions limited to 2-variable products only.

#### Internal Computational Core

- **New internal S7 functions:**
  [`.compute_ci_dop()`](https://data-wise.github.io/rmediation/reference/dot-compute_ci_dop.md),
  [`.compute_ci_mc()`](https://data-wise.github.io/rmediation/reference/dot-compute_ci_mc.md),
  [`.compute_ci_asymp()`](https://data-wise.github.io/rmediation/reference/dot-compute_ci_asymp.md),
  [`.compute_cdf_dop()`](https://data-wise.github.io/rmediation/reference/dot-compute_cdf_dop.md),
  [`.compute_cdf_mc()`](https://data-wise.github.io/rmediation/reference/dot-compute_cdf_mc.md),
  [`.compute_quantile_dop()`](https://data-wise.github.io/rmediation/reference/dot-compute_quantile_dop.md),
  [`.compute_quantile_mc()`](https://data-wise.github.io/rmediation/reference/dot-compute_quantile_mc.md).
- All core algorithms now work with `ProductNormal` objects natively.
- Legacy functions
  ([`medci()`](https://data-wise.github.io/rmediation/reference/medci.md),
  [`pprodnormal()`](https://data-wise.github.io/rmediation/reference/pprodnormal.md),
  [`qprodnormal()`](https://data-wise.github.io/rmediation/reference/qprodnormal.md))
  convert parameters and dispatch to S7 core.
- Identical numerical results to previous versions (validated with 201
  tests).

#### Enhanced `ci()` Function

- Migrated
  [`ci()`](https://data-wise.github.io/rmediation/reference/ci.md) to S7
  generic with methods for:
  - `numeric`: Legacy support for direct coefficient/covariance input.
  - `lavaan`: Automatic extraction and CI computation for indirect
    effects.
  - `ProductNormal`: Native S7 class support.
- **Auto-detection**: Automatically identifies product parameters (e.g.,
  `ab := a*b`) in `lavaan` models.
- Renamed first argument to `mu` for better legacy compatibility.

#### MBCO Function Updates

- Migrated
  [`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md)
  to S7 generic with method for `MxModel` objects.
- Returns `MBCOResult` S7 objects with properties: `statistic`, `df`,
  `p_value`, `type`.
- **Legacy Compatibility**: Implemented S3 methods (`$`, `[[`, `names`)
  for backward-compatible list-style access (e.g., `result$chisq`,
  `result$p`).
- Display methods show significance indicators (*, **,*** , ns) and
  interpretation.

#### Input Validation

- Comprehensive input validation using `checkmate` package across all
  functions.
- Type checking with
  [`match.arg()`](https://rdrr.io/r/base/match.arg.html) for categorical
  arguments.
- Improved error messages for invalid inputs.

#### Display Methods

- All S7 classes have meaningful
  [`print()`](https://rdrr.io/r/base/print.html),
  [`summary()`](https://rdrr.io/r/base/summary.html), and `show()`
  methods.
- `ProductNormal` displays: distribution type, means, covariance matrix,
  SDs, and correlations.
- `MBCOResult` displays: test type, statistics, p-values with
  significance levels, and interpretation.

#### Namespace Improvements

- **Zero masking warnings:** Package now loads cleanly with no namespace
  conflicts.
- Renamed [`quantile()`](https://rdrr.io/r/stats/quantile.html) generic
  to
  [`dist_quantile()`](https://data-wise.github.io/rmediation/reference/dist_quantile.md)
  to avoid masking
  [`stats::quantile()`](https://rdrr.io/r/stats/quantile.html).
- S7 methods for [`print()`](https://rdrr.io/r/base/print.html),
  [`summary()`](https://rdrr.io/r/base/summary.html), `show()` now
  properly register with base generics.
- Added S4 compatibility via
  [`S7::S4_register()`](https://rconsortium.github.io/S7/reference/S4_register.html)
  for formal generic support.

#### Package Cleanup

- Removed unused dependencies (`doParallel`, `foreach`, `methods`).
- Fixed all documentation warnings and notes.
- **R CMD check**: Now passes with 0 errors, 0 warnings, 0 notes.
- Added 40 new S7 prototype tests + 19 display method tests (total: 201
  tests, 100% pass rate).

### Bug Fixes

- Fixed argument dispatch issues between `alpha` and `level` parameters.
- Resolved S7 generic conflicts with base R functions (print, summary,
  quantile).
- Fixed recursive dispatch issues in display methods.
- Added case-insensitive handling for `type` parameter (accepts “MC”,
  “mc”, “DOP”, “dop”, etc.).
- Fixed return value structure for
  [`ci()`](https://data-wise.github.io/rmediation/reference/ci.md)
  method (now returns list with `CI`, `Estimate`, `SE` components).

## RMediation 1.3.0

CRAN release: 2025-11-20

## RMediation 1.3.0 (2025-11-18)

CRAN release: 2025-11-20

- Updated functions and package documentation.
- Updated package dependencies.
- Updated `mbco` function documentation.
- Implemented `checkmate` for robust input validation.
- Created GitHub pages for package documentation.
- Refactored package structure for better organization.
- Refactored package validation for better input validation.
- Added tests for package functions.

## RMediation 1.2.3 (5/12/2023)

- Fixed an issue where the type=“all” in the medci function would
  generate incorrect labels for CIs.

## RMediation 1.2.2 (5/11/2023)

CRAN release: 2023-05-12

- Fixed an issue where the type=“all” in the medci function would
  generate an error “object ‘MeekerCI’ not found”.

- changed the dependency version for grDevices to \>= 3.5 in the
  description file.

## RMediation 1.2.1 (4/28/2023)

CRAN release: 2023-05-03

- Fixed issues to meet CRAN submission requirements.

## RMediation 1.2.0 (6/28/2022)

CRAN release: 2022-07-08

*New parametric and non-parametric MBCO test, using `mbco` function.*
Fixed an error with printing medci, ‘(1-alpha)% CI’

## RMediation 1.1.5 (6/7/2020)

- Fixed the issue with ‘medic’ function that printed ‘(1-alpha/2)% CI’
  instead of ‘(1-alpha)% CI’

## RMediation 1.1.4 (3/12/2016)

CRAN release: 2016-03-14

- ‘medci’ function output structure is changed. For each ‘type’, it
  produces a ‘list’ of ‘(1-alpha/2)% CI’, ‘Estimate’, and ‘SE’. See
  help(ci) for more information.

- Two functions ‘pMC’ and ‘qMC’ are added.

- for medci(), type=‘prodclin’ is replaced with ‘dop’.

## RMediation 1.1.3

CRAN release: 2014-03-07

- New ‘ci’ function produces CIs for any well-defined function of
  parameter estimates in an SEM and MSEM using the Monte Carlo or
  asymptotic normal theory with the multivariate delta standard error
  method.

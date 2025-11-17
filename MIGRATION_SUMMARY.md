# Migration Summary: Separating missingmed from RMediation

**Date**: 2024-11-16 **Action**: Extracted multiple imputation
functionality into separate package

## Files Moved to missingmed

### From RMediation → missingmed

1.  **R/lav_mice.R** - Fit lavaan models to multiply imputed data
2.  **R/mx_mice.R** - Fit OpenMx models to multiply imputed data  
3.  **R/is_valid_lav_syntax.R** - Validate lavaan model syntax

## Changes to RMediation

### NAMESPACE Updates

**Removed exports**: - `lav_mice()` - `mx_mice()` -
`is_valid_lav_syntax()`

**Removed imports**: - `mice::complete` - `mice::mice` - `mice::pool` -
[`lavaan::sem`](https://rdrr.io/pkg/lavaan/man/sem.html) -
[`lavaan::lavaan`](https://rdrr.io/pkg/lavaan/man/lavaan.html)

**Retained** (still needed): -
[`lavaan::lav_matrix_vech_reverse`](https://rdrr.io/pkg/lavaan/man/lav_matrix.html)
(used in ci(), pMC(), qMC())

### DESCRIPTION Updates

**Removed from Imports**: - `mice (>= 3.8.0)` - No longer used

**Added to Suggests**: - `missingmed (>= 0.1.0)` - For users who need
missing data functionality

## Impact on Users

### Breaking Changes

Users who were using `lav_mice()` or `mx_mice()` from RMediation will
need to:

``` r
# OLD (no longer works):
library(RMediation)
lav_mice(imputed_data, model)

# NEW (install missingmed):
install.packages("missingmed")  # or devtools::install_github("Data-Wise/missingmed")
library(missingmed)
lav_mice(imputed_data, model)
```

### No Impact

Users of the core RMediation functions are unaffected: -
[`medci()`](https://data-wise.github.io/rmediation/reference/medci.md) -
Still works -
[`ci()`](https://data-wise.github.io/rmediation/reference/ci.md) - Still
works -
[`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md) -
Still works -
[`pprodnormal()`](https://data-wise.github.io/rmediation/reference/pprodnormal.md),
[`qprodnormal()`](https://data-wise.github.io/rmediation/reference/qprodnormal.md) -
Still work -
[`pMC()`](https://data-wise.github.io/rmediation/reference/pMC.md),
[`qMC()`](https://data-wise.github.io/rmediation/reference/qMC.md) -
Still work

### Integration

Users who need both packages can use them together:

``` r
library(RMediation)
library(missingmed)

# Use missingmed for multiple imputation
pooled_results <- imputed_data |>
  set_sem(model) |>
  run_sem() |>
  pool_sem()

# Use RMediation for CI of indirect effects
ci(mu = pooled_results@tidy_table$estimate,
   Sigma = pooled_results@cov_total,
   quant = ~b1*b2,
   type = "MC")
```

## Package Size Reduction

**Before**: - 26 R files - mice, lavaan (heavy dependencies)

**After**: - 23 R files (-3) - Removed mice dependency - Cleaner
separation of concerns

## Next Steps

1.  **RMediation**:
    - Update documentation to reference missingmed
    - Add examples showing integration
    - Release as v2.0.1 (patch) or v2.1.0 (minor)
2.  **missingmed**:
    - Complete package documentation
    - Add comprehensive tests
    - Publish to GitHub
    - Submit to CRAN (when ready)

## Commit References

**RMediation**: - Commit: 92cdf28 - “Move missing data functions to
missingmed package”

**missingmed**: - Commit: 10baed7 - “Initial commit: missingmed
package” - Commit: d04048c - “Add lav_mice and mx_mice functions” -
Commit: ef6cfc8 - “Update is_valid_lav_syntax with full implementation”

## Submission summary

This is a resubmission of **RMediation** (version 1.6.1), an existing CRAN package.

Key changes in this release:
- Renamed `p_prod3()` to `pprodnormal3()` to match the existing
  `pprodnormal()`/`qprodnormal()` naming family; `p_prod3()` remains available
  as a non-warning forwarding alias.
- Renamed the `ci()` S7 generic's dispatch argument from `mu` to `object` for
  consistency with the package's other S7 generics (`cdf()`, `dist_quantile()`).
  Only affects callers using `ci(mu = ...)` as a named argument.
- Hid undocumented internal helpers (`validate_ProductNormal()`,
  `is_valid_for_computation()`, `ProductNormal_from_lavaan()`) from the
  documentation index (`@noRd`); no change to public API.
- Added `@examples` to all exported functions/generics that previously lacked
  them (goodpractice advisory cleanup).

(v1.6.0, the prior submission, introduced the S7 class `ProductNormal3` for
exact CDF of sequential indirect effects `a1 * a2 * b`, its CDF/quantile/CI
methods, and the `cubature` dependency.)

## Test environments

* Local: macOS 15 (aarch64-apple-darwin25.5.0), R 4.6.1 — `R CMD check --as-cran`
  — `0 errors | 0 warnings | 0 notes`
* win-builder / r-hub / GitHub Actions: **pending re-run for 1.6.1** (the
  results below are from the 1.6.0 submission and need refreshing before
  this version is submitted)
  - win-builder R-oldrelease (4.5.3): https://win-builder.r-project.org/Y0YVu51197F9 — OK (1.6.0)
  - win-builder R-release (4.6.x): https://win-builder.r-project.org/Ely6l4rqSSzw — OK (1.6.0)
  - win-builder R-devel (r90199): https://win-builder.r-project.org/MbTqhngibodc — OK (1.6.0)
  - GitHub Actions: macOS-latest, ubuntu-latest, windows-latest — R release + oldrel-1 (1.6.0)

## R CMD check results

`0 errors | 0 warnings | 0 notes`

## Notes for the CRAN team

* `medfit (>= 0.2.0)` in `Suggests` is available on CRAN (v0.2.1). It is used
  only in optional integration helpers guarded by `requireNamespace()`.

* **r-hub `nosuggests` failure** (if present): The `nosuggests` container
  intentionally does not install `Suggests` packages. Vignettes require `rmarkdown`
  (listed in `Suggests`), so they cannot be rebuilt in this environment. CRAN's
  servers install `Suggests` when building vignettes — not a real-world issue.

## Downstream dependencies

There are no CRAN reverse dependencies for this package.

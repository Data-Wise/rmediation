## Submission summary

This is a resubmission of **RMediation** (version 1.6.0), an existing CRAN package.

Key changes in this release:
- New S7 class `ProductNormal3` for exact CDF of sequential indirect effects
  (`a1 * a2 * b`) via the distribution-of-the-product framework
- New `p_prod3()` computes `P(a1 * a2 * b <= q)` by a 2D conditional-expectation
  dimension-reduction integral via `cubature::hcubature`
- New `dist_quantile` S7 generic and `ProductNormal3` method for quantile inversion
- `cdf()`, `confint()`, and `ci()` S7 methods for `ProductNormal3`
- Added `cubature (>= 2.1.0)` to `Imports`

## Test environments

* Local: macOS 15 (aarch64-apple-darwin25.5.0), R 4.6.1 — `R CMD check --as-cran`
* win-builder R-oldrelease (4.5.3): https://win-builder.r-project.org/Y0YVu51197F9 — OK
* win-builder R-release (4.6.x): https://win-builder.r-project.org/Ely6l4rqSSzw — OK
* win-builder R-devel (r90199): https://win-builder.r-project.org/MbTqhngibodc — OK
* GitHub Actions: macOS-latest, ubuntu-latest, windows-latest — R release + oldrel-1

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

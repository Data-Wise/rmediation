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
- Fixed a NAMESPACE regression introduced by a `roxygen2` 8.0.0 upgrade:
  `@export` on three base-type S7 method dispatches (`ci(class_numeric)`,
  `ci(class_any)`, `cdf(class_numeric)`) generated invalid
  `export("cdf,double-method")`-style entries that broke package installation.
  Switched to `@noRd` (methods are dispatched via the exported generic; only
  the generic needs `@export`), matching this package's existing convention.

(v1.6.0, the prior submission, introduced the S7 class `ProductNormal3` for
exact CDF of sequential indirect effects `a1 * a2 * b`, its CDF/quantile/CI
methods, and the `cubature` dependency.)

## R CMD check results

`0 errors | 0 warnings | 0 notes`

Checked locally with `R CMD check --as-cran` (0/0/0), plus strict
`--run-donttest` passes with `_R_CHECK_DEPENDS_ONLY_=true` and
`_R_CHECK_SUGGESTS_ONLY_=true` (both clean).

## Test environments

* Local: macOS, R 4.6.1 — `R CMD check --as-cran` — 0 errors | 0 warnings | 0 notes
* win-builder (all 3 flavors, dispatched 2026-07-21 against this exact source,
  post-NAMESPACE-fix): R-devel (r90283), R-release (4.6.1), R-oldrelease
  (4.5.3) — all `Status: OK`, no NOTEs
* r-hub v2 (GitHub Actions, dispatched 2026-07-21): linux, macos, windows
  (R-devel) — all passed

## Notes for the CRAN team

* `medfit (>= 0.2.0)` in `Suggests` is available on CRAN (v0.2.1). It is used
  only in optional integration helpers guarded by `requireNamespace()`.

## Reverse dependencies

There are no CRAN reverse dependencies for this package.

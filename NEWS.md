# RMediation 1.8.1 (2026-10-31)

No change to returned values or to the API.

## Documentation

- The README examples for `medci()` and `ci()` on a `ProductNormal3` now show the real output of those calls (they
  showed intervals that the functions do not return), and the Monte Carlo calculator of the online apps is linked.
- The SEMFit `mbco()` route is no longer described as experimental: medfit dropped that label in 0.11.0.
- The pkgdown site gains a Quick Reference, a Cookbook (including serial mediation through medfit, the SEMFit route
  and omitted-confounder sensitivity) and Technical Notes (the exact CDF at `|rho| = 1`, point masses, the densities).

## Internal

- Added `.lintr` (120 columns) and wrapped 61 over-long or mis-indented lines in R sources and tests; the parsed code
  is unchanged. Rewrapped roxygen lines regenerate seven help pages with the same content.

# RMediation 1.8.0 (2026-10-30)

* S7 property access now works under the declared R 4.1 minimum.

## Testing

- Expanded public OpenMx MBCO argument, bootstrap-routing and optimizer-fallback
  tests, including result-field mutation checks and fitted RAM smoke tests.
  Coverage CI now retains line/expression summaries and uncovered-line artifacts.
- The `SEMFit` MBCO tests and the `mbco()` example pass `fixed_x` and
  `meanstructure` to `medfit::fit_sem()` explicitly, at today's values, so
  medfit 0.14.0's default-change warning does not appear (medfit flips these
  defaults in 0.15.0). Results are unchanged; the example now needs medfit
  >= 0.9.0 (#85).

## Removed

- `medci_prototype()` is removed. It was an exported S7-core prototype of
  `medci()` (shipped in 1.6.1) that nothing in the package called. Use
  `medci()`, or `ci()` on a `ProductNormal`, which return the same intervals.

## Bug fixes

- `mbco(type = "parametric")` now checks every bootstrap replicate like `type = "semi"` does.
  It used to hand the bootstrap to `OpenMx::mxCompare(boot = TRUE)`, so a replicate null fit
  that violated its constraint (for example OpenMx/OpenMx#433 dropping a zero-Jacobian
  equality at a replicate's start) entered the null distribution unchecked and understated its
  statistic. The package now simulates each replicate from the fitted `h0` with
  `OpenMx::mxGenerateData()`, fits `h0` and `h1`, refits a violated `h0` constraint, and stops
  with an error of class `RMediation_bootstrap_infeasible` when it cannot be repaired. Behavior
  changes: a replicate with a non-finite statistic or an h1 fit worse than its h0 fit now stops the
  call (`mxCompare` dropped such replicates; the last check also applies to `type = "semi"`; a
  replicate that does not converge is dropped within a 5% bound, see the next entry), and a model without a
  single raw data set (a covariance-data or multigroup model) is refused before sampling. The
  observed statistic, df and the result shape are
  unchanged; seeded p-values differ because the replicates are drawn by a different loop.

- The DOP CDF (`pprodnormal()`, `qprodnormal()`, `medci()`) is exact at `|rho| = 1`: it now uses
  Meeker & Escobar's (1994) quadratic-root solution instead of integrating a step function, which
  was wrong by up to 4e-5 and could stop with "the integral is probably divergent". For
  `|rho| < 1` the integrand is evaluated from the factored quadratic (no cancellation at large
  means) with the roots as breakpoints, and a roundoff report from `integrate()` relaxes the
  tolerance to 1e-8, then 1e-6, instead of failing. All 495 evaluations in the article's own test
  domain (means of +/-3e5, `|rho|` up to 0.99999) now succeed; 10 used to stop with an integrator
  error.

- `mbco_product_null()` stops, with class `RMediation_h1_nonconverged`, when the full model `h1` did
  not converge or was never run. `mbco()` warns, with class `RMediation_fit_nonconverged`, when a
  supplied `h0` or `h1` carries an unaccepted OpenMx status; the result is unchanged.

- Point masses now have the right-continuous CDF. `pprodnormal3()` returned `0.5` at `q == 0` for a
  product identically equal to `0` (and for a single zero-variance, zero-mean first component);
  it now returns `1`, matching `P(XYZ <= q)`. `pprodnormal()` with a zero standard error follows
  the same rule (`q >= c` lower, `q < c` upper). Continuous zero-mean distributions still give
  `0.5` at `0`.
- `pprodnormal3()` rejects a covariance that is not finite and positive semidefinite, including
  negative variances at very different scales, instead of clamping negative variances to zero.

- `pprodnormal(lower.tail = FALSE)` and `qprodnormal(lower.tail = FALSE)` with
  `type = "dop"` now integrate the upper tail directly instead of computing
  `1 - P(XY <= q)`, which cancelled below about 1e-10 (an upper quantile at
  `p = 1e-12` round-tripped to a relative error of 7e-5, and smaller tails
  could not be resolved). The quantile root finder's tolerance is tightened
  from the `uniroot()` default (1.2e-4) to 1e-12, and the integrand handles
  `|rho| = 1` (a point-mass conditional) without a `0/0`. Probabilities below
  about 1e-22 remain unresolved (the integration window leaves out 1.5e-23).

- `medci(type = "mc")` reported `MC.Error` as `SE / n.mc`; it is now
  `SE / sqrt(n.mc)`, the standard error of the simulated mean, as documented
  elsewhere. Intervals and estimates are unchanged.
- `medci()` Monte Carlo and plotting no longer stop with a Cholesky error when
  the covariance is singular (`rho = +/-1` or a zero standard error); `type =
  "dop"`/`"all"` with a zero standard error now fails with an actionable
  message instead of "non-finite function value".
- `plot`/`plotCI` must be a single `TRUE`/`FALSE` in `medci()` and `ci()`
  (a vector or `NA` previously failed with an obscure condition error).

- `ci(<ProductNormal>, type = "dop")` shared the large-mean defect of #60 through
  a second copy of the integral (it stopped with "please use type='MC'" at
  `mu/se` of about 20 where `medci()` already worked). The S7 core now calls
  `qprodnormalMeeker()`, so both paths use one integral.

- `pprodnormal3()` (and `cdf()`/`dist_quantile()` on `ProductNormal3`) returned 0
  for every `q`, or an error, when two or three components had zero variance.
  It now returns the exact answer: a point mass at `prod(mean)` when all three
  are fixed, and a scaled normal when exactly one is random (#64).
- `medci()` was defined twice, in `R/medci.R` and `R/medci_legacy_backup.R`
  (identical code). The backup sorted later and was the live definition, and
  `?medci` merged both sets of documentation into duplicated Usage, Value and
  Details sections. The backup file is removed; behavior is unchanged. A test
  now fails if any top-level function is defined in more than one `R/` file.
- `pprodnormal()` and `qprodnormal()` with `type = "dop"` no longer collapse at
  large standardized means (`pprodnormal(400, 20, 20, 1, 1)` returned 8e-7
  instead of about 0.507) and are accurate in far tails (previously wrong by up
  to 4e-6 absolute). Both now share one integral over the support of the
  conditioning variable at a tight tolerance. The CDF is also clamped to
  [0, 1], so `lower.tail = FALSE` can no longer be slightly negative (#60).

## New features

- `dprodnormal3()`: exact density of the product of three normal variables with any mean vector and
  positive-definite covariance (the counterpart of `pprodnormal3()`), computed as a
  two-dimensional integral that conditions on the first factor and reuses the `dprodnormal()`
  integral for the other two. Matches the derivative of `pprodnormal3()` to about 7 digits.
- `dprodnormal()` now resolves very small `z` at nonzero means (it previously could stop with
  "the integral is probably divergent").

- `dprodnormal()` is the exact density of the product of two normal random
  variables (any means, any `-1 < rho < 1`), completing the d/p/q family. It
  uses the one-dimensional integral of Rohatgi (Glen et al., 2004) in general
  and the Bessel-K closed form of Nadarajah and Pogany (2016) when both means
  are zero; the two agree to near machine precision and each is the other's
  test oracle. The density is `Inf` at exactly 0 (a log singularity).

- `pprodnormal()` and `qprodnormal()` accept a vector `q` / `p` and return one
  probability / quantile per element (a list of two vectors for `type = "all"`).
  For `type = "MC"` all elements share one simulated sample, so the estimates
  are mutually consistent. Scalar calls are unchanged.

- `ml_omitted_confounder()` adds a sensitivity analysis for an omitted
  confounder of the mediator-outcome relation in two-level (1-1-1) mediation,
  after Tofighi and Kelley (2016). It returns an `MLOmittedConfounder` object
  with `print`, `summary`, `plot` and `as.data.frame` methods. The default
  screen keeps only positive-definite grid points, so it does not reproduce the
  published tables; use `screen = "none"` for those.
- `mbco(h0, h1, type = "asymp")` accepts two fitted medfit `SEMFit` objects
  with medfit >= 0.8.0. It returns `MBCOResult` using `stats::anova()` without
  refitting or requiring OpenMx. The restricted fit must come first; df is the
  actual difference. Active tested bounds refuse an invalid chi-square p-value.
  Bootstrap types, mixed classes and unused fitting controls error. Existing
  OpenMx paths and CI integration with medfit >= 0.2.0 are preserved.
- medfit remains optional in Suggests >= 0.2.0. The SEMFit route needs the
  GitHub/r-universe medfit release; CRAN medfit 0.3.2 cannot exercise it. This
  development change does not lift the CRAN submission or development-to-main hold.
- OpenMx `mbco()` now checks the constraints of `h0` and `h1` at the fitted
  solution (issue #34). The OpenMx default feasibility tolerance (0.05) can leave
  a constrained fit off the null set and understate the statistic. **A returned
  number now changes in that case:** a violated `h0` (scaled violation above
  1e-6) is refit once at tolerance 1e-8 for all three types, the refit model
  supplies the observed statistic and the bootstrap, a warning of class
  `RMediation_h0_refit` reports the change, and the new `refit` slot of
  `MBCOResult` records it (`NULL` when no refit was needed). Clean fits and
  constraint-free models are unchanged. If the refit fails, does not converge or leaves
  the constraint violated, `mbco()` stops with an error of class
  `RMediation_h0_refit_failed` naming the constraint, instead of returning a
  statistic from a known-invalid fit. A
  constraint that cannot be evaluated now errors. See the wrong-branch warning below.
- OpenMx `mbco()` now also warns, with class `RMediation_constraint_not_enforced` and right
  after `RMediation_h0_refit`, when the refit ran and `h0`'s fit was identical to
  `h1`'s (statistic 0 before the refit) although a constraint of `h0` was violated
  (issue #84). The constraint may not have been enforced. OpenMx (2.19.1 and later)
  silently drops an equality constraint whose Jacobian is zero at the starting values
  (OpenMx/OpenMx#433), for example `b1 * b2 == 0` started at zero, and a violation
  within the feasibility tolerance looks the same; a fitted `h0` keeps no starting
  values, so the warning cannot say which. The statistic and the `refit` slot are
  unchanged (the seeded example goes from 0 to 0.0878); for a product null use
  `mbco_product_null()`. Bootstrap replicates are refit and checked the same way
  for both bootstrap types (see the `type = "parametric"` entry under Bug fixes).
- `mbco(type = "semi")` and `mbco(type = "parametric")` now drop a bootstrap replicate whose
  fits did not converge instead of stopping at the first one (issue #92). Up to 5% of the `R`
  replicates may be dropped; above that the call stops with an error of class
  `RMediation_bootstrap_too_many_dropped` (with fewer than 20 replicates none may be dropped).
  The new `dropped` slot of `MBCOResult` reports the count (`NULL` for results without a
  bootstrap), and the p-value is the proportion of the kept replicates strictly above the
  observed statistic, with no `(1 + k)/(R + 1)` correction: the rule of
  `OpenMx::mxCompare(boot = TRUE)`, whose denominator was also the kept replicates. Only
  non-convergence is dropped; an unrepairable constraint violation
  (`RMediation_bootstrap_infeasible`), a non-finite statistic and an h1 fit worse than its h0
  fit still stop the call. `?mbco` states the rule.
- OpenMx `mbco()` now warns (class `RMediation_constraint_branch`) when a
  feasible, converged `h0` is not the constrained optimum of an equality
  constraint: fixing one of the parameters the constraint depends on at 0 gives a
  converged, feasible fit with -2LL lower by more than 1e-4 (issue #35). It
  catches the single-constraint product null that lands on the larger-statistic
  branch (`memory_exp`: 221.05 against 0.0831) without parsing the constraint.
  It runs once per call for every `type`, costs one extra fit per involved
  parameter (a constraint with more than 5 is skipped with a message), changes no
  result, and cannot fail the call. In a simulation (60 seeds at each of three
  effect sizes) it flagged all 28 wrong-branch fits with no false positives.
  `mbco_product_null()` avoids the problem.
- `mbco_product_null(h1, paths, ...)` tests a product null (`a*b = 0`, or a
  serial product) with OpenMx as an intersection-union test: it fixes each path
  at 0 in a copy of the fitted full model, runs `mbco()` on each, and returns the
  result of the branch with the largest p-value, with the new optional
  `MBCOResult@branch` slot naming it. Unlike a single nonlinear constraint such
  as `ind == 0`, it cannot land on the larger-statistic branch (issue #35; on
  `memory_exp` it returns 0.0831 where one constraint gives 221.05). The
  p-value is conservative when more than one path is 0. A branch whose fit
  does not converge is an error naming the branch.


- For numeric/lavaan formula CIs, `MCError` now uses `SE / sqrt(n.mc)`,
  the sampling standard error of the simulated mean. The previous `SE / n.mc`
  understated simulation uncertainty. This is not an endpoint error estimate.
- `ci(type = "all", H0 = TRUE)` now forwards `H0`, `mu0` and `Sigma0` to
  its Monte Carlo component, preserving the alternative/null result pair
  rather than silently ignoring the requested null distribution.

- OpenMx MBCO now rejects equal-df and reversed model pairs, and nonfinite
  or negative observed statistics, before bootstrap sampling. Previously the
  semiparametric route could report a significant result with df 0 or -1.
  The restricted model must be supplied first; substantive nesting is still
  the analyst's responsibility.

- OpenMx bootstrap workers now restore global options on success and error.
  Semiparametric bootstrap rejects failed refits and nonfinite statistics, with
  explicit errors for singular sample or null covariances. Parametric bootstrap
  rejects invalid reported statistics, degrees of freedom and p-values.

- `mbco()` no longer rejects fitted OpenMx RAM models with "h0 must be an
  MxModel". The check compared `class(h0)` to `"MxModel"`, which fails for
  subclasses such as `MxRAMModel`; it now uses `methods::is()`. Verified for
  `type = "asymp"` only; the bootstrap types (`"parametric"`, `"semi"`) have
  not been exercised on fitted RAM models (rmediation#35).
- The `?mbco` example had shifted path labels (`endVar` started with `"x"`, so
  the labels `a1`, `a2`, `cp` landed on the wrong paths) and passed a tibble to
  `mxData()`. Both are fixed. The example now tests `a1 * b1 = 0` with one
  linear null per path (`a1 == 0`, `b1 == 0`) and reports the smaller statistic
  (0.0831), because a single nonlinear `ind1 == 0` null can converge to the
  wrong branch (221.05) (rmediation#35).

## Documentation

- `?mbco` now has a Details section on testing a product null (`a*b = 0`): fit
  one linear null per path and report the smaller statistic, because a single
  nonlinear null can converge to the wrong branch. It also says to build `h0`
  from the unfitted model, since a constraint refit from the fitted model's
  estimates can stop at an infeasible point (diffLL 0) (rmediation#35).

## Tests

- Added a known-answer OpenMx fixture on `memory_exp` (linear nulls
  `a1 == 0`: 221.045546 and `b1 == 0`: 0.083100) and an end-to-end `mbco()`
  test against it.

# RMediation 1.7.0 (2026-08-16)

## Correctness fix: `pprodnormal3()` on ill-conditioned covariance (#27)

`pprodnormal3()` (and its alias `p_prod3()`) returned materially wrong
probabilities when the `(X, Y)` covariance block was ill-conditioned, silently
and with no diagnostic. At `rho = 0.999` the error reached 24% at `q = 0.5`,
and 92% in relative terms in the lower tail. Tightening `tol` did not help --
the old integrator converged to a stable but incorrect value. Because
`cdf()`, `dist_quantile()`, `confint()` and `ci()` invert this CDF by
root-finding, all of them inherited the error.

* **The default integration method is now `"gauss"`** -- tensor-product
  Gauss-Legendre quadrature on a domain partitioned at the coordinate axes,
  with the node count escalated automatically until successive rules agree to
  `tol`. Partitioning is what makes a fixed-grid rule valid here: the integrand
  has a kink along both axes, and an unpartitioned grid can return values
  outside `[0, 1]`.

* **This changes results.** On well-conditioned input the new default agrees
  with the old one to about `1e-6`. On ill-conditioned input it differs
  substantially -- that difference is the correction. The new method is also
  faster (roughly 8-20x at the covariances tested).

* `method = "hcubature"` selects the previous integrator, retained for
  cross-checking and backward comparison. It is not recommended when the
  `(X, Y)` block is ill-conditioned.

* The error figures above were measured at `q = 0.5` with
  `mean = c(0.2, 0.1, 0)` on one family of covariance matrices: unit
  variances, correlation `0.5` between `Z` and each of `X` and `Y`, and `rho`
  between `X` and `Y` in `{0.5, 0.99, 0.999, 0.9999}`. The reference value
  was a 1024-node Gauss-Legendre rule that agreed with the 512-node rule to
  `3e-7` or better and lay within 3 standard errors of a `1e7`-draw Monte
  Carlo check. The magnitudes describe that family: the error is not a
  monotone function of the condition number across arbitrary covariance
  matrices, and a well-conditioned matrix can show a smaller error than an
  ill-conditioned one.

* New `nodes` argument forces a fixed number of Gauss-Legendre nodes per
  dimension instead of escalating adaptively.

* New `diagnostics` argument. When `TRUE`, the returned value carries `"error"`
  (the gap between the last two quadrature rules -- a real convergence
  estimate) and `"nodes"` attributes. It defaults to `FALSE` so the return
  value stays a bare numeric for existing callers. The meaning of `"error"`
  differs by `method` and is `NA` when `nodes` is supplied; see
  `?pprodnormal3` for the per-method contract.

* `pprodnormal3()` now warns when quadrature reaches the node cap without
  meeting `tol`, instead of returning a wrong answer silently. The warning
  reports the gap between the last two rules, which bounds the remaining
  discretization error, and does not assert a cause: a well-conditioned
  covariance reaches the cap too when `tol` is tighter than 2048 nodes can
  deliver (issue #31).

* **Fixed: the documented `ProductNormal3()` constructor call raised an error.**
  The `method` property had no default, and the validator rejected the resulting
  empty value, so the form shown in the README and the getting-started
  vignette --

  ```r
  ProductNormal3(mu = mu, Sigma = Sigma)
  #> Error: method must be 'hcubature'
  ```

  -- failed for anyone who copied it. `method` now defaults to `"gauss"`, and
  the call works as documented. Passing `method` explicitly was, and remains, a
  valid alternative.

* The new default also fixes a second, previously unreported failure of the old
  integrator: at large standardized means (`mean / sd` beyond roughly 8) it
  returned exactly `0` where the true probability is around `0.46`. That failure
  was independent of conditioning and equally silent.

# RMediation 1.6.1 (2026-06-30)

## Naming convention cleanup

* `p_prod3()` is renamed to `pprodnormal3()` to match the existing
  `pprodnormal()`/`qprodnormal()` family. `p_prod3()` remains available as a
  silent (non-warning) alias and will gain a formal deprecation warning in a
  future release.
* `ProductNormal2()` remains available but is superseded by `ProductNormal()`
  for direct construction; internal callers now use `ProductNormal()`
  directly.
* The `ci()` generic's dispatch argument is renamed from `mu` to `object` for
  consistency with the package's other S7 generics (`cdf()`, `dist_quantile()`).
  This only affects callers using `ci(mu = ...)` as a named argument;
  positional calls (`ci(mu, ...)`) are unaffected.
* Undocumented internal helpers (`validate_ProductNormal()`,
  `is_valid_for_computation()`, `ProductNormal_from_lavaan()`) are now hidden
  from the package documentation index (`@noRd`); they remain available
  internally but are not part of the public API.

  | Old | New |
  |-----|-----|
  | `p_prod3(q, mean, cov, ...)` | `pprodnormal3(q, mean, cov, ...)` |
  | `ci(mu = ..., Sigma = ..., quant = ...)` | `ci(..., Sigma = ..., quant = ...)` (positional) |

## Documentation and lint

* Added `@examples` to all exported functions/generics that previously
  lacked them, addressing `goodpractice::gp()` advisories ahead of CRAN
  resubmission.

# RMediation 1.6.0 (2026-06-29)

## ProductNormal3: exact CDF for the product of three normals

* New S7 class `ProductNormal3` for sequential indirect effects of the form
  `a1 * a2 * b`, with `print()`, `cdf()`, `confint()`, and `ci()` methods.
* New core engine `p_prod3()` computes `P(a1 * a2 * b <= q)` via the
  conditional-expectation dimension-reduction double integral (Tofighi, 2026).
* Integration is performed by `cubature::hcubature`; degenerate covariances are
  reduced to the existing two-variable product-normal CDF.

## Dependencies

* Added `cubature (>= 2.1.0)` to `Imports`.

# RMediation 1.5.0 (2026-06-18)

## Dependencies

* **medfit is now available on CRAN** (v0.2.0/0.2.1). Removed `Remotes:
  data-wise/medfit`; medfit now resolves from CRAN. Pinned `Suggests: medfit
  (>= 0.2.0)`.

## medfit Covariance Extraction

* `ci()` for medfit `MediationData`/`SerialMediationData` now extracts the path
  covariance by parameter name and uses the full covariance matrix (including
  off-diagonals) for both simple and serial mediation. Removed the previous
  positional/value-matching heuristics and the independence/diagonal fallbacks,
  which could silently produce incorrect intervals; unresolved path labels now
  raise an informative error.
* The serial-mediation pipeline is now verified end-to-end against medfit's
  released serial extractor (medfit >= 0.2.0): `medfit::extract_mediation()`
  produces a `SerialMediationData` for both lavaan (ordered `mediator` vector)
  and lm/glm (`mediator_models`) chains, and `ci()` consumes it via the
  documented `d1, d2, ...` path-name contract. Added integration tests that fit a
  real model, extract, and run `ci()` end-to-end (skipped when medfit < 0.2.0).

## Workflow Optimization & Standardization (2025-12-05)

### Performance Improvements
* **Optimized R-CMD-check workflow**: Reduced from 5 to 3 platforms (macOS, Windows, Ubuntu release)
* **Removed failing platforms**: Dropped `ubuntu-latest (devel)` and `ubuntu-latest (oldrel-1)` configurations
* **Runtime improvement**: Check workflows now complete in ~2 minutes (down from 6+ minutes, **67% faster**)
* **Build optimization**: Added `--ignore-vignettes` flag to skip vignette validation during CI checks

### Bug Fixes
* **Fixed pkgdown build errors**:
  - Removed non-existent `reexports` topic from `_pkgdown.yml` reference index
  - Added missing `tidy` topic to `_pkgdown.yml` reference index
  - pkgdown workflow now passes successfully

### Standardization
* **Badge order**: Added R-hub badge to README, standardized order to match mediationverse ecosystem:
  CRAN, Lifecycle, R-CMD-check, Website, R-hub, Codecov
* **.Rbuildignore**: Added `^STATUS\.md$` to match ecosystem standards
* **Website configuration**: Already compliant with mediationverse standards:
  - Academic blue color scheme (#0054AD)
  - Consistent fonts (Inter, Montserrat, Fira Code)
  - Ecosystem and Status dropdown menus

### Documentation
* Updated README badge order for consistency across ecosystem
* All workflows now passing on main branch

## Workflow Optimization & Standardization (2025-12-05)

### Performance Improvements
* **Optimized R-CMD-check workflow**: Reduced from 5 to 3 platforms (macOS, Windows, Ubuntu release)
* **Removed failing platforms**: Dropped `ubuntu-latest (devel)` and `ubuntu-latest (oldrel-1)` configurations
* **Runtime improvement**: Check workflows now complete in ~2 minutes (down from 6+ minutes, **67% faster**)
* **Build optimization**: Added `--ignore-vignettes` flag to skip vignette validation during CI checks

### Bug Fixes
* **Fixed pkgdown build errors**:
  - Removed non-existent `reexports` topic from `_pkgdown.yml` reference index
  - Added missing `tidy` topic to `_pkgdown.yml` reference index
  - pkgdown workflow now passes successfully

### Standardization
* **Badge order**: Added R-hub badge to README, standardized order to match mediationverse ecosystem:
  CRAN, Lifecycle, R-CMD-check, Website, R-hub, Codecov
* **.Rbuildignore**: Added `^STATUS\.md$` to match ecosystem standards
* **Website configuration**: Already compliant with mediationverse standards:
  - Academic blue color scheme (#0054AD)
  - Consistent fonts (Inter, Montserrat, Fira Code)
  - Ecosystem and Status dropdown menus

### Documentation
* Updated README badge order for consistency across ecosystem
* All workflows now passing on main branch

## Dependency Reduction

* **Removed dependencies**: `e1071`, `modelr`, and `generics` packages are no longer required.
* **Internal implementations**: Added internal `.skewness()`, `.kurtosis()`, and `.resample_bootstrap()` functions to replace external dependencies.
* **Own tidy generic**: Package now defines its own `tidy()` generic instead of re-exporting from `generics`.
* Total Imports reduced from 10 to 7 packages.

## CI/CD Improvements

* Added `R-CMD-check.yaml` workflow for multi-platform testing (macOS, Windows, Ubuntu with R devel/release/oldrel).
* Added `test-coverage.yaml` workflow for Codecov integration.
* Added `VignetteBuilder: knitr` to DESCRIPTION for proper vignette building.
* Standardized README.md to mediationverse format.

## Ecosystem Notes

* Part of the **mediationverse** ecosystem for mediation analysis in R.
* Integration with medfit planned for v1.5.0 (Q1 2026).
* See [Ecosystem Coordination](https://github.com/data-wise/medfit/blob/main/planning/ECOSYSTEM.md) for version compatibility and development guidelines.
* See [Development Roadmap](https://data-wise.github.io/mediationverse/articles/roadmap.html) for timeline.

---

# RMediation 1.4.0

## Major Changes

### S7 Core Architecture (Complete Refactoring)
* **Complete architectural redesign:** S7 is now the computational core, with legacy functions as thin wrappers.
* **Zero breaking changes:** All existing code continues to work exactly as before (100% backward compatible).
* **Enhanced extensibility:** New computational architecture makes adding CI methods and features straightforward.

### S7 OOP Classes
* Introduced S7 object-oriented programming for modern, type-safe class definitions.
* **New S7 Classes:**
  - `ProductNormal`: Represents the distribution of the product of normal random variables.
  - `MBCOResult`: Encapsulates results from MBCO tests.
* **New S7 Generics:** `cdf()`, `dist_quantile()`, `ci()`, `print()`, `summary()`, `show()`.
* All S7 classes include comprehensive display methods (`print`, `summary`, `show`) for meaningful output.

### N-Variable Product Support (NEW)
* **Breaking limitation removed:** Can now compute confidence intervals for products of 3 or more variables.
* Works with Monte Carlo method (`type = "mc"`).
* Example: `ProductNormal(mu = c(0.3, 0.4, 0.5), Sigma = diag(3))` for three-way products.
* Previous versions limited to 2-variable products only.

### Internal Computational Core
* **New internal S7 functions:** `.compute_ci_dop()`, `.compute_ci_mc()`, `.compute_ci_asymp()`, `.compute_cdf_dop()`, `.compute_cdf_mc()`, `.compute_quantile_dop()`, `.compute_quantile_mc()`.
* All core algorithms now work with `ProductNormal` objects natively.
* Legacy functions (`medci()`, `pprodnormal()`, `qprodnormal()`) convert parameters and dispatch to S7 core.
* Identical numerical results to previous versions (validated with 201 tests).

### Enhanced `ci()` Function
* Migrated `ci()` to S7 generic with methods for:
  - `numeric`: Legacy support for direct coefficient/covariance input.
  - `lavaan`: Automatic extraction and CI computation for indirect effects.
  - `ProductNormal`: Native S7 class support.
* **Auto-detection**: Automatically identifies product parameters (e.g., `ab := a*b`) in `lavaan` models.
* Renamed first argument to `mu` for better legacy compatibility.

### MBCO Function Updates
* Migrated `mbco()` to S7 generic with method for `MxModel` objects.
* Returns `MBCOResult` S7 objects with properties: `statistic`, `df`, `p_value`, `type`.
* **Legacy Compatibility**: Implemented S3 methods (`$`, `[[`, `names`) for backward-compatible list-style access (e.g., `result$chisq`, `result$p`).
* Display methods show significance indicators (*, **, ***, ns) and interpretation.

### Input Validation
* Comprehensive input validation using `checkmate` package across all functions.
* Type checking with `match.arg()` for categorical arguments.
* Improved error messages for invalid inputs.

### Display Methods
* All S7 classes have meaningful `print()`, `summary()`, and `show()` methods.
* `ProductNormal` displays: distribution type, means, covariance matrix, SDs, and correlations.
* `MBCOResult` displays: test type, statistics, p-values with significance levels, and interpretation.

### Namespace Improvements
* **Zero masking warnings:** Package now loads cleanly with no namespace conflicts.
* Renamed `quantile()` generic to `dist_quantile()` to avoid masking `stats::quantile()`.
* S7 methods for `print()`, `summary()`, `show()` now properly register with base generics.
* Added S4 compatibility via `S7::S4_register()` for formal generic support.

### Package Cleanup
* Removed unused dependencies (`doParallel`, `foreach`, `methods`).
* Fixed all documentation warnings and notes.
* **R CMD check**: Now passes with 0 errors, 0 warnings, 0 notes.
* Added 40 new S7 prototype tests + 19 display method tests (total: 201 tests, 100% pass rate).

## Bug Fixes
* Fixed argument dispatch issues between `alpha` and `level` parameters.
* Resolved S7 generic conflicts with base R functions (print, summary, quantile).
* Fixed recursive dispatch issues in display methods.
* Added case-insensitive handling for `type` parameter (accepts "MC", "mc", "DOP", "dop", etc.).
* Fixed return value structure for `ci()` method (now returns list with `CI`, `Estimate`, `SE` components).

# RMediation 1.3.0

RMediation 1.3.0 (2025-11-18)
==============
* Updated functions and package documentation.
* Updated package dependencies.
* Updated `mbco` function documentation.
* Implemented `checkmate` for robust input validation.
* Created GitHub pages for package documentation.
* Refactored package structure for better organization.
* Refactored package validation for better input validation.
* Added tests for package functions.

RMediation 1.2.3 (5/12/2023)
==============
* Fixed an issue where the type="all" in the medci function would generate incorrect labels for CIs.

RMediation 1.2.2 (5/11/2023)
==============
* Fixed an issue where the type="all" in the medci function would generate an error "object 'MeekerCI' not found".

* changed the dependency version for grDevices to >= 3.5 in the description file.

RMediation 1.2.1 (4/28/2023)
==============
* Fixed issues to meet CRAN submission requirements.

RMediation 1.2.0 (6/28/2022)
==============
*New parametric and non-parametric MBCO test, using `mbco` function.
* Fixed an error with printing medci, '(1-alpha)% CI'

RMediation 1.1.5 (6/7/2020)
==============
* Fixed the issue with 'medic' function that printed '(1-alpha/2)% CI' instead of '(1-alpha)% CI'

RMediation 1.1.4 (3/12/2016)
=============
* 'medci' function output structure is changed. For each 'type', it produces a 'list' of '(1-alpha/2)% CI', 'Estimate', and 'SE'. See help(ci) for more information.

* Two functions 'pMC' and 'qMC' are added.

* for medci(), type=`’prodclin’` is replaced with `’dop’`.

RMediation 1.1.3
=============
* New 'ci' function produces CIs for any well-defined function of parameter estimates in an SEM and MSEM using the Monte Carlo or asymptotic normal theory with the multivariate delta standard error method.

## Submission summary

This is an update of **RMediation** (version 1.7.0), an existing CRAN package.
It is primarily a **correctness fix**.

`pprodnormal3()` — the CDF of the product of three normal random variables,
used for sequential indirect effects `a1 * a2 * b` — returned materially wrong
probabilities whenever the covariance of the first two components was
ill-conditioned. The failure was silent: no warning, no error, and no
diagnostic the caller could inspect. Requesting a tighter tolerance did not
help, because the adaptive integrator converged to a stable but incorrect
value. `cdf()`, `dist_quantile()`, `confint()` and `ci()` invert this CDF by
root-finding, so all of them inherited the error.

At a correlation of 0.999 between the first two components the returned
probability was wrong by 0.196 in absolute terms (24%), and by up to 92% in
relative terms in the lower tail. Strongly correlated coefficient estimates are
ordinary in mediation models, so this affected realistic input.

Key changes in this release:

- **The default integration method for `pprodnormal3()` is now `"gauss"`** —
  tensor-product Gauss-Legendre quadrature on a domain partitioned at the
  coordinate axes, with the node count escalated until successive rules agree
  to `tol`. Partitioning is required rather than optional: the integrand has a
  kink along both axes, and an unpartitioned fixed grid can return values
  outside `[0, 1]`.
- The previous adaptive method remains available as `method = "hcubature"` for
  cross-checking. It is documented as not recommended.
- **This changes returned values.** On well-conditioned input the new default
  agrees with the previous one to about 1e-7. On ill-conditioned input it
  differs substantially; that difference is the correction. The new method is
  also roughly 8-20x faster at the covariances tested.
- New `nodes` argument (force a fixed quadrature rule) and `diagnostics`
  argument (expose the convergence estimate). `diagnostics` defaults to `FALSE`
  so the return value remains a bare numeric for existing callers.
- `pprodnormal3()` now warns when quadrature reaches its node cap without
  meeting `tol`, rather than returning a wrong answer silently.
- Fixed a second, unrelated silent failure of the previous integrator: at large
  standardized means (`mean / sd` beyond roughly 8) it returned exactly `0`
  where the true probability is around 0.46.
- Fixed the `ProductNormal3` constructor: its `method` property had no default,
  so the documented form `ProductNormal3(mu = , Sigma = )` — as shown in the
  README and the getting-started vignette — raised an error. It now defaults to
  `"gauss"`.

No user-visible function signatures were removed and no arguments were renamed.
The new arguments are optional and appear after existing ones, so positional
calls are unaffected.

## R CMD check results

`0 errors | 0 warnings | 0 notes`

Checked locally with `R CMD check --as-cran` (0/0/0).

## Test environments

* Local: macOS, R 4.6.1 — `R CMD check --as-cran` — 0 errors | 0 warnings | 0 notes
* GitHub Actions: ubuntu-latest (R-release and R-devel), macos-latest,
  windows-latest — all passing
* r-hub v2 (GitHub Actions, dispatched 2026-08-17 against `dev` at 661b5b4):
  linux, windows, macos-arm64 (all R-devel) — all three passed
* win-builder R-devel (dispatched 2026-08-17 against the same source):
  `Status: OK` under R Under development (unstable) (2026-08-15 r90413 ucrt) —
  no NOTEs, no WARNINGs
* win-builder R-release and R-oldrelease (dispatched 2026-08-17) — RESULTS
  PENDING; fill in before submitting

## Notes for the CRAN team

* `medfit (>= 0.2.0)` in `Suggests` is available on CRAN (v0.2.1). It is used
  only in optional integration helpers guarded by `requireNamespace()`.
* Version 1.6.1 was published on 2026-07-21. This submission is deliberately
  held until on or after 2026-08-21 to respect the requested update cadence for
  established packages. It is submitted sooner than a routine update would be
  only because the change is a correctness fix; the fix has been available to
  affected users from a tagged GitHub release in the interim.

## Reverse dependencies

There are no CRAN reverse dependencies for this package.

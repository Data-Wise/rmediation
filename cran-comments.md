## Submission summary

This is an update of **RMediation** (version 1.7.1), an existing CRAN package
(CRAN currently serves 1.6.1). It is primarily a **correctness fix**. Version
1.7.0 was published only as a GitHub pre-release and was never submitted to
CRAN; this submission carries its changes plus the later fixes listed below.

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

- Later fixes in `mbco()` and `ci()` (see NEWS): `mbco()` no longer rejects
  fitted OpenMx RAM models; invalid or reversed model pairs and invalid
  bootstrap statistics are now rejected with explicit errors instead of
  producing a result with df <= 0; formula-CI `MCError` now uses
  `SE / sqrt(n.mc)`; `ci(type = "all", H0 = TRUE)` forwards the null
  distribution; and the `?mbco` example was corrected.

No user-visible function signatures were removed and no arguments were renamed.
The new arguments are optional and appear after existing ones, so positional
calls are unaffected.

## R CMD check results

Local, 1.7.1 release tree (`release/1.7.1`, 2026-10-12):
`R CMD check --as-cran --run-donttest` -- 0 errors | 0 warnings | 0 notes
(`Status: OK`). Full test suite: 593 expectations, 0 failures.

## Test environments

* Local: macOS, R 4.6.1 -- see above.
* GitHub Actions on the 1.7.1 release branch (PR into `main`, head `bc97590`):
  R-CMD-check (ubuntu-latest release and devel, macos-latest, windows-latest),
  pkgdown and test-coverage all passing.
* r-hub v2 (GitHub Actions, dispatched 2026-10-13 against `release/1.7.1` at
  `051fcbc`; the later tip `bc97590` differs only by one added test file):
  linux (R-devel) `Status: OK`, windows (R-devel) `Status: OK`, macos-arm64
  (R-devel) job succeeded.
* win-builder (dispatched 2026-10-13 against the 1.7.1 release tree, head
  `bc97590`) -- all three returned `Status: OK`:
  * R-devel -- R Under development (unstable) (2026-10-10 r90659 ucrt)
  * R-release -- R version 4.6.1 (2026-06-24 ucrt)
  * R-oldrelease -- R version 4.5.3 (2026-03-11 ucrt)

## Notes for the CRAN team

* Earlier win-builder runs the same day reported one NOTE from the URL check:
  `https://github.com/data-wise/rmediation/issues` returned HTTP 503 (Service
  Unavailable). This was a transient GitHub outage — the URL is valid and later
  runs on both R-release and R-oldrelease returned `Status: OK`. Flagged here in
  case the same transient re-appears in CRAN's incoming check.
* `medfit (>= 0.2.0)` in `Suggests` is available on CRAN (currently 0.3.2). It is used
  only in optional integration helpers guarded by `requireNamespace()`.
* `mvtnorm` is in `Suggests` (available on CRAN); it is used only inside
  `testthat` tests guarded by `skip_if_not_installed()` because `OpenMx`'s
  internal parametric bootstrap depends on it. No `R/` source file references it.
* Version 1.6.1 was published on 2026-07-21; this submission is made after the
  requested update cadence window, and is a correctness fix.

## Reverse dependencies

There are no CRAN reverse dependencies for this package.

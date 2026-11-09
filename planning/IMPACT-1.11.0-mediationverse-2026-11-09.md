# Impact of RMediation 1.11.0 on the mediationverse

Date: 2026-11-09. Release: `v1.11.0` (main `f90f25a`), GitHub only; CRAN still serves 1.6.1 and the hold is unchanged. Method: `rforge:impact`, then a manual read of every package's DESCRIPTION and call sites, then the consumers' own test suites run against the tagged install. Nothing outside the RMediation repo was modified.

## Verdict

**Low risk. No downstream package needs an update.** None of the six packages calls a function whose behavior changed. The two consumers with real call sites pass their full suites against 1.11.0, and the one that pins RMediation internals by line reference (`medfit`) is unaffected because those two files did not change. Four follow-up issues were filed in this repo (#176 to #179); none of them has a current consumer.

## What 1.11.0 changed

| Change | Functions | Who could notice |
|---|---|---|
| `a*a`-style perfect correlation no longer fails (#174; `rho` within 1e-12 of +/-1 is taken as exactly +/-1) | `ci()`, `medci()` and every distribution-of-the-product route that derives `rho` from a covariance | Anyone with the same coefficient twice and `type = "dop"`; also fixes 1.10.0 |
| `pprodnormal3()` takes a vector of `q` and `lower.tail` (#157, #169) | `pprodnormal3()` | Nobody, unless they call it; default values unchanged |
| New `qprodnormal3()` (#170) | `qprodnormal3()` | New export, so no one depends on it yet |
| `dist_quantile()` on a `ProductNormal3` shares `qprodnormal3()`'s routine; `p = 0, 1` return `-Inf, Inf`; a point mass returns `prod(mu)` (#170) | `dist_quantile()` | Anyone who used `ProductNormal3` and the quantile at 0 or 1 |
| A repeated coefficient in a product of three or more takes Monte Carlo instead of erroring (#156) | `ci(<lavaan>)` | Users who hit the old error |
| `p` and `MCError` documented (#167) | `?ci` | Documentation only |

`R/ci_medfit.R` and `R/mbco_semfit.R` are byte-identical to 1.10.0 (`git diff v1.10.0 v1.11.0`), and `mbco()` did not change. Six files in `R/` changed in total (plus one line in `NAMESPACE`).

## Per-package impact

| Package | Relationship (DESCRIPTION) | Uses | Touches changed code | Evidence |
|---|---|---|---|---|
| missingmed | Imports RMediation (>= 1.5.0) | `ci_mediation_data` (10 call sites), `mbco` (3), `medci` (2), `ci` (2, positional) | No | 488 tests, 0 failed, 0 skipped (with `NOT_CRAN=true`, so the end-to-end `mbco` tests ran) |
| medsim | Suggests | `medci()` once | No | 571 tests, 0 failed, 1 skipped; 20 warnings, none mentioning RMediation, `medci`, `dop`, `rho` or `non-finite` |
| medfit | Mentions RMediation in tests and a contract test | `mbco()` example as an oracle; `test-dependents-contract.R` cites `R/ci_medfit.R` and `R/mbco_semfit.R` by line | No | `test-sem-mbco.R` 16 and `test-sem-parity.R` 10 tests, 0 failed; the two cited files are unchanged |
| mediationverse | Suggests | Tells users to `library(RMediation)`; vignettes attach it | No | Nothing to run; it only attaches the package |
| probmed | None found | None | No | Nothing to check |
| medrobust | None found | None | No | Nothing to check |

A search for `pprodnormal3`, `qprodnormal3`, `dist_quantile`, `dprodnormal3`, `ProductNormal3` and `p_prod3` across all six repositories finds no use outside RMediation, so neither the new exports nor the `dist_quantile()` edge change can reach any of them.

All runs used `R_LIBS` pointing at a clean install of the `v1.11.0` GitHub tarball (loads as 1.11.0) and medfit 0.16.0, from scratch copies of the consumer repositories.

## What rforge reported, and what it missed

`rforge:impact --package RMediation --change-type feature` listed one direct dependent (`missingmed`), medium risk, about 30 affected tests and 1.0 h of work. It counts hard dependencies only, so it did not list `medsim`, `medfit` or `mediationverse`, which reference RMediation as a suggestion or by name. The manual check above found those. The "medium" rating overstates the risk because nothing downstream calls the changed code; the real rating is low.

## Issues filed

| # | Title | Class | Affects today | Downstream consumers affected |
|---|---|---|---|---|
| [176](https://github.com/Data-Wise/rmediation/issues/176) | `dist_quantile()` on a `ProductNormal` fails for a vector of probabilities | bug | Anyone passing a vector `p` to a `ProductNormal` object; the cookbook already says to pass one `p` per call | None: no consumer calls `dist_quantile()` |
| [177](https://github.com/Data-Wise/rmediation/issues/177) | `cdf()` for `ProductNormal3` computes `1 - p` for `lower.tail = FALSE` | bug (omission in #169) | Far upper tails of a `ProductNormal3` object: 4.0e-09 returned at `q = 100`, default tol, against 7.84e-11 from the direct call (about 50 times too large; 4% off at tol 1e-14) | None: no consumer uses `ProductNormal3` or `cdf()` |
| [178](https://github.com/Data-Wise/rmediation/issues/178) | Run the Linux and Windows matrix on `dev` before the release PR | process | The maintainer: the 1.11.0 rho bug surfaced only on the release PR, costing an extra matrix run | None |
| [179](https://github.com/Data-Wise/rmediation/issues/179) | `ci(mu = , Sigma = , quant = )` fails with `argument "object" is missing` | usability | Anyone following `?ci`, whose usage section documents the internal `.ci_core(mu, Sigma, quant, ...)` | None: `missingmed` calls `ci()` positionally; no consumer uses `ci(mu =` |

Suggested order, by value and size: #177 first (a one-line change plus a test; it completes #169), then #176 (a `vapply`, as the `ProductNormal3` method already does), then #179 (fix the `?ci` usage section even if the code is left alone), and #178 before the next release. None blocks anything, and none needs a release of its own.

## Not covered

- `probmed` and `medrobust` test suites were not run (no use of RMediation found); `mediationverse` has no tests to run against the package.
- The consumers were tested on macOS only. The rho bug (#174) differed by platform, so a Linux or Windows consumer run is not covered here; see #178.
- `mediationverse/STATUS.md` links RMediation without a version number (last edited 2026-08-03); it is not wrong, and it lives in another repository, so it was not touched.
- No CRAN reverse dependencies exist (decided 2026-10-12), so CRAN-side impact is nil until a CRAN release.

## Reproduce

```bash
gh api repos/Data-Wise/rmediation/tarball/v1.11.0 > src.tar.gz && mkdir -p src lib && tar xzf src.tar.gz -C src
R CMD INSTALL --library=lib src/Data-Wise-rmediation-*
# in a copy of missingmed / medsim, with NOT_CRAN=true and R_LIBS=<lib>:<medfit 0.16.0 library>:
#   devtools::load_all(); testthat::test_dir("tests/testthat")
python3 -m lib.deps --path ~/projects/r-packages/active --format text impact --package RMediation --change-type feature
```

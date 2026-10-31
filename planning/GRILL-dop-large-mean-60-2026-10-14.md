# GRILL — DOP CDF large-mean collapse (issue #60), 2026-10-14

Target: fix `pprodnormalMeeker()` / `qprodnormalMeeker()` (R/pprodnormalMeeker.R, R/qprodnormalMeeker.R).

## Pre-answer sweep (evidence, scratch scripts not saved)

| Variant | NA (of 1152 grid points) | Points differing from old by > 1e-6 | Max difference |
|---|---|---|---|
| mu.b +/- 10 window, split at 0, default `integrate()` tolerance | 1 | many | 2.7e-3 |
| same, `rel.tol` 1e-6 or 1e-10, 2000 subdivisions | 0 | 9 | 1.8e-4 |

- The earlier "2.7e-3 shift" was `integrate()`'s default tolerance on a step-like integrand near x = 0, not the window idea.
- The 9 changed points are far-tail probabilities (~1e-5). For rho = 0, an independent oracle (direct integration over x, split at 0) agrees with the windowed values (8.866e-6, 4.352e-6) and not with the old ones (5.8e-6, 6.0e-6). For rho = -0.8, q = -3, mu = (0, 3), se = (0.2, 0.4): new 1.79e-4, Monte Carlo 1.83e-4, old 6e-9. The old code was also wrong in far tails, not only at large means.
- Cost: 0.07-0.08 ms per call at every tolerance tried, the same as the old code (0.083 ms). The cost worry behind Q1 did not materialize.
- `qprodnormalMeeker()` carries its own copy of the same infinite-range integral, so a fix in `pprodnormalMeeker()` alone leaves the quantile broken.

## Decisions

| Q | Decision | Recommended? |
|---|---|---|
| 1 Scope | Window mu.b +/- 10 sd, split at 0, tight tolerance (user choice) | yes |
| 2 Placement | One internal helper used by both the p and q functions | yes (follows from the sweep) |
| 3 Tolerance | `rel.tol = 1e-10`, `abs.tol = 1e-13`, 2000 subdivisions; benchmarked, no cost | yes |
| 4 Upper tail | Keep `1 - lower`; integrating the complement for tail precision is a separate follow-up | yes |
| 5 Evidence gate | Unskip the large-mean test; far-tail grid vs independent oracle; q round trip at large means; mutants: no window, no split at 0, loose tolerance | yes |

# Status and Roadmap

What is settled for RMediation, what is on hold, and what could come
next. This page states only decisions already made; the last section
lists candidates, not commitments. For the ecosystem view, see the
[mediationverse
roadmap](https://data-wise.github.io/mediationverse/articles/roadmap.html)
and the [package status
dashboard](https://github.com/data-wise/mediationverse/blob/main/STATUS.md).

## Where each release lives

- **CRAN** serves 1.6.1.
- **GitHub** carries the later releases (published as pre-releases); the
  development version is 1.9.0. Install with
  `pak::pak("Data-Wise/rmediation")`; the
  [README](https://github.com/Data-Wise/rmediation#installation) lists
  the tagged install commands.
- The [News](https://data-wise.github.io/rmediation/news/index.md) page
  lists every change by version.

## CRAN submission is on hold

No CRAN submission is planned until a medfit release that provides
`fixed_x` and observed mean structure is on CRAN. medfit is GitHub-only
for now. When that happens, the `Suggests` entry for medfit rises to
`medfit >= 0.8.0`. A later CRAN candidate must also remove or finish the
SEMFit route described below, so its version will be later than the
current development version.

## The SEMFit route for `mbco()`

`mbco(h0, h1, type = "asymp")` accepts two fitted medfit `SEMFit`
objects. It calls `stats::anova(h1, h0)`, never refits, requires medfit
0.8.0 or later (older versions get a clear error), and does not need
OpenMx. The OpenMx paths are unchanged. The route is no longer labeled
experimental, because medfit dropped that label in 0.11.0.

## Settled behavior worth knowing

- [`pprodnormal3()`](https://data-wise.github.io/rmediation/reference/pprodnormal3.md)
  integrates with Gauss-Legendre by default; the earlier adaptive
  default returned wrong values on ill-conditioned covariance (see the
  [Technical
  Notes](https://data-wise.github.io/rmediation/articles/technical-notes.md)).
- [`mbco_product_null()`](https://data-wise.github.io/rmediation/reference/mbco_product_null.md)
  tests `a*b = 0` exactly, one single-path null per branch.
- `ci(type = "asymp")` labels its interval by the confidence level, and
  the densities are correct for very small standard errors (both in
  1.9.0; see
  [News](https://data-wise.github.io/rmediation/news/index.md)).

## Candidates for what comes next

These are open items, not promises and not dated.

- A CRAN submission, once the criteria above are met.
- Issue [\#88](https://github.com/Data-Wise/rmediation/issues/88):
  releasing the defenses for OpenMx#433, tracked in the repository.
- Keeping the documentation in step with the code; see the
  [Cookbook](https://data-wise.github.io/rmediation/articles/cookbook.md)
  and the [Quick
  Reference](https://data-wise.github.io/rmediation/articles/refcard.md).

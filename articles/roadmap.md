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
- **GitHub** carries the later releases (1.10.0 and 1.11.0 are full
  releases; 1.9.0 and earlier are pre-releases); the latest release is
  1.11.0, and changes made after it are listed under “development
  version” on the News page. Install with
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
SEMFit route described below, so its version will be later than 1.11.0.

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
- [`pprodnormal3()`](https://data-wise.github.io/rmediation/reference/pprodnormal3.md)
  accepts a vector of `q`, like the other distribution functions; a
  single `q` behaves as before (since 1.11.0).
- An
  [`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md)
  result carries `@provenance` (package and R versions, test type,
  bootstrap size, [`RNGkind()`](https://rdrr.io/r/base/Random.html) and
  run time). The seed is not recorded; call
  [`set.seed()`](https://rdrr.io/r/base/Random.html) and report it. In
  1.10.0; see
  [News](https://data-wise.github.io/rmediation/news/index.md).
- [`ci()`](https://data-wise.github.io/rmediation/reference/ci.md) on a
  `lavaan` fit resolves a `:=` that uses another `:=`. A product of
  three different coefficients gets the exact three-factor interval;
  four or more get a Monte Carlo interval, with a warning when you set
  `type`. In 1.10.0; see
  [News](https://data-wise.github.io/rmediation/news/index.md). A
  coefficient repeated inside a product of three or more also gets a
  Monte Carlo interval (since 1.11.0).
- `ci(type = "asymp")` labels its interval by the confidence level, and
  the densities are correct for very small standard errors (both in
  1.9.0; see
  [News](https://data-wise.github.io/rmediation/news/index.md)).
- The element names and order of what
  [`medci()`](https://data-wise.github.io/rmediation/reference/medci.md)
  and [`ci()`](https://data-wise.github.io/rmediation/reference/ci.md)
  return, the leading argument names of
  [`medci()`](https://data-wise.github.io/rmediation/reference/medci.md)
  and
  [`pprodnormal3()`](https://data-wise.github.io/rmediation/reference/pprodnormal3.md),
  and the shape of `memory_exp` are pinned by tests, because downstream
  code indexes results by position and by name. Changing one of these
  needs a deprecation period first.

## Candidates for what comes next

These are open items, not promises and not dated.

- A CRAN submission, once the criteria above are met. Issue
  [\#88](https://github.com/Data-Wise/rmediation/issues/88), on
  releasing the defenses for OpenMx#433, was closed on 2026-11-04; the
  CRAN decision itself is unchanged.
- Recording the RMediation version in the packages and manuscripts that
  call it, once a breaking change or a submission makes that necessary.
- Keeping the documentation in step with the code; see the
  [Cookbook](https://data-wise.github.io/rmediation/articles/cookbook.md)
  and the [Quick
  Reference](https://data-wise.github.io/rmediation/articles/refcard.md).

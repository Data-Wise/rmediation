# Reporting RMediation in a Paper

A result from RMediation is reproducible only if a reader knows which
version produced it, which method and settings, and, for a stochastic
method, the seed. This page lists what to record and report. It is a
checklist, not a set of rules about what is statistically right.

## 1. Pin the version

CRAN serves RMediation 1.6.1. Later releases are on GitHub only, as
pre-releases, and are not on CRAN. Report which you used, and install
the exact tag so a reader can too:

``` r

pak::pak("Data-Wise/rmediation@v1.9.0")
# or
remotes::install_github("Data-Wise/rmediation", ref = "v1.9.0")
```

Replace `v1.9.0` with the tag you ran. The [Releases
page](https://github.com/Data-Wise/rmediation/releases) lists the tags.
Do not cite `dev` or an untagged install: it moves.

Record what R reports for your session:

``` r

as.character(packageVersion("RMediation"))
#> [1] "1.10.0"
```

[`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) goes in a
supplement or the project’s `README`. A result that depends on OpenMx or
medfit should also record those versions.

## 2. Report the method and its settings

| You used | Report |
|----|----|
| [`medci()`](https://data-wise.github.io/rmediation/reference/medci.md) | `type` (`"dop"`, `"MC"`, `"asymp"`), the confidence level, and `rho` if you set it |
| a Monte Carlo interval (`type = "MC"`, [`ci()`](https://data-wise.github.io/rmediation/reference/ci.md) with a formula) | `n.mc` and the seed |
| [`ci()`](https://data-wise.github.io/rmediation/reference/ci.md) on a `lavaan` fit | how each `:=` was handled: two coefficients honor `type`, exactly three get the exact interval, four or more and other formulas get Monte Carlo (see [Technical Notes](https://data-wise.github.io/rmediation/articles/technical-notes.md), section 7) |
| [`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md) or [`mbco_product_null()`](https://data-wise.github.io/rmediation/reference/mbco_product_null.md) | `type`, `R` for a bootstrap, the seed, the OpenMx version, and any warning raised |

Name the interval as the package does: a distribution-of-the-product
interval is not a “Sobel” interval.

## 3. Report the seed

A stochastic method (Monte Carlo, a bootstrap) is reproducible only with
its seed. Set it immediately before the call and say so:

``` r

set.seed(2026)
medci(mu.x = 0.5, mu.y = 0.6, se.x = 0.08, se.y = 0.04, type = "MC", n.mc = 1e5)
#> $`95% CI`
#> [1] 0.2003788 0.4053485
#> 
#> $Estimate
#> [1] 0.300136
#> 
#> $SE
#> [1] 0.05219825
#> 
#> $MC.Error
#> [1] 0.0001650654
```

RMediation does **not** record the seed. It cannot be recovered from the
random-number state afterward, so your analysis script has to say it.
Run each stochastic call after its own
[`set.seed()`](https://rdrr.io/r/base/Random.html) so a reader can
reproduce it alone.

## 4. Use `@provenance` for `mbco()` results

From 1.10.0, an
[`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md)
result records what produced it. Report these fields, or paste the
printed block:

| Field | Holds |
|----|----|
| `rmediation`, `openmx`, `medfit`, `r` | package and R versions (`NULL` for a package not loaded) |
| `type` and `R` | the test type and the bootstrap size (`NULL` without a bootstrap) |
| `rng_kind` | [`RNGkind()`](https://rdrr.io/r/base/Random.html) at the time |
| `time` | when it ran |

Also report `@dropped` (bootstrap replicates that did not converge),
`@refit` (when `h0` had to be refit) and `@branch` (for a product null).
See [Testing an Indirect Effect with
MBCO](https://data-wise.github.io/rmediation/articles/mbco.md).

## 5. A methods sentence to adapt

> Confidence intervals for indirect effects were computed with the R
> package RMediation (version *x.y.z*, installed from the GitHub tag
> *vX.Y.Z*) using the *distribution of the product / Monte Carlo (n =*
> N*, seed =* S*)* method at the *95%* level. Likelihood-ratio tests
> used
> [`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md)
> with *type* and, for the bootstrap, *R* = *R* replicates (seed = *S*),
> with OpenMx *version*.

Cite the method papers listed under
[Citation](https://github.com/Data-Wise/rmediation#citation) in the
README, and `citation("RMediation")` for the package itself.

## 6. Reporting a problem

When a result looks wrong, include the version, the call, the seed,
[`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) and, for
[`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md),
the printed provenance block in the
[issue](https://github.com/Data-Wise/rmediation/issues). That is usually
enough to reproduce it.

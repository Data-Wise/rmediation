# SPEC-26 — Link the mediation-apps Shiny front end from README and pkgdown

**Issue:** [\#26](https://github.com/Data-Wise/rmediation/issues/26)
**Branch:** `dev` (docs-only) **Status:** implemented, uncommitted
**Created:** 2026-08-16

------------------------------------------------------------------------

## Context

[`medci()`](https://data-wise.github.io/rmediation/reference/medci.md)
and the Monte Carlo / Asymptotic-Delta CI calculators have a live,
no-install Shiny front end at
<https://data-wise.github.io/mediation-apps/>. Nothing in the package
points at it.

Grounding check:
`grep -rn "mediation-apps" . --exclude-dir=.git --exclude-dir=docs`
returned zero hits before this change — not in README, `_pkgdown.yml`,
vignettes, or NEWS. The issue is accurate and nothing had partially
landed.

The audience is people who want to evaluate the method without
installing R: reviewers, students, and collaborators. That group
currently has no path in.

------------------------------------------------------------------------

## Scope

Docs-only. Two files, no R code, no tests. Permitted directly on `dev`
under the branch-guard rules (`.md` allowed; `_pkgdown.yml` is an
existing file).

`README.md` is hand-maintained — there is no `README.Rmd`, so the edit
is direct and will not be clobbered by a knit step. Verified with
`ls README*`.

`docs/` is gitignored (pkgdown build output), so no generated artifact
is committed and no site rebuild is required in this change.

------------------------------------------------------------------------

## Changes

### 1. `README.md` — new section between *Overview* and *Why RMediation?*

Placed above *Why RMediation?* deliberately: a reader deciding whether
the package is worth their time should reach the zero-cost demo before
the methodological argument, not after the installation instructions.

``` markdown
## Try It Online (No Install)

The core confidence-interval methods run in the browser through the
[mediation-apps](https://data-wise.github.io/mediation-apps/) Shiny front end—no R
installation required:

- **[Distribution-of-Product CI calculator](https://data-wise.github.io/mediation-apps/medci/)** — a live front end for `medci()`
- **Monte Carlo / Asymptotic-Delta CI calculator** — built on `ci(type = "mc")` and `ci(type = "asymp")`

Useful for quick checks, teaching, and for collaborators who do not use R.
```

### 2. `_pkgdown.yml` — first entry in `home: links:`

``` yaml
  links:
  - text: "Try It Online (Shiny apps)"
    href: https://data-wise.github.io/mediation-apps/
  - text: "Source Code"
    ...
```

First position, above *Source Code*: the sidebar is ordered by what a
new visitor is most likely to want.

------------------------------------------------------------------------

## Deliberately not done

- **No badge.** The badge row is already 7 wide; an eighth adds noise
  for a link that is better served by a titled section.
- **No vignette changes.** The apps are an entry point, not part of the
  package’s computational narrative.
- **No `reference/` index entry.** The apps are not package functions.

------------------------------------------------------------------------

## Verification

| Check | Command | Result |
|----|----|----|
| YAML still parses, links in order | `Rscript -e 'yaml::read_yaml("_pkgdown.yml")'` | PASS — 4 links, Shiny first |
| Both URLs live | `curl -o /dev/null -w "%{http_code}" -L <url>` | **200** and **200** |
| Links present in README | `grep -n "mediation-apps" README.md` | 2 hits (lines 27, 30) |

A full
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
is not required — `home: links:` is rendered directly from the YAML, and
the site deploys from `main` on push.

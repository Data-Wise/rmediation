# SPEC-29 — Site/CRAN version-gap remediation

**Status:** GRILLED — scope settled, ready to execute
**Created:** 2026-08-17
**Related:** SPEC-27 (prod3 integrator), issue #26, `.github/workflows/pkgdown.yaml`

---

## Context

Publishing the v1.7.0 GitHub release fired the pkgdown workflow — it triggers on
`release: types: [published]`, not only on push to `main` — so run `31999598351`
deployed the public site **from the tag `v1.7.0`, which lives on `dev`**.

| | version |
|---|---|
| Live site | **1.7.0** |
| `main` | 1.6.1 |
| CRAN | 1.6.1 |

`pkgdown::check_pkgdown()` reports no problems and the reference index is
complete. Nothing is malformed; the gap is purely version currency.

---

## What the grill removed

The audit proposed five changes. Four were cut, and the reasoning is worth
keeping because it applies to the next audit too.

**The deciding constraint: the CRAN submission is 2026-08-21, four days out.**
On acceptance `main` becomes 1.7.0 and the version gap closes by itself. Any
work whose only justification is the gap is remediation for a window that shuts
before the work matters.

| # | Proposed | Verdict |
|---|---|---|
| 1 | pkgdown `development: mode: devel` banner | **Cut** — moot in 4 days, and its `/dev/` URL move is a large change for a temporary condition |
| 2 | README pointer to the fix | **Kept, reduced** — see below |
| 3 | Surface the integrator in README + vignettes | **Cut** — the reference page and NEWS already carry it |
| 4 | Version-qualify the DOP accuracy claims | **Cut** — the claims are true as of 1.7.0; qualifying them dates the prose |
| 5 | Deploy-trigger fix | **Kept** — a standing bug, independent of CRAN |

### Decided: the live site stays at 1.7.0

Considered and rejected: redeploying from `main` to restore 1.6.1 docs.

The 1.7.0 site carries the Note that the pre-1.7.0 integrator "returns
materially wrong values on ill-conditioned covariance matrices — at rho = 0.999
the error reaches 24%". Reverting would delete the only public warning that
CRAN's current default is broken, during the exact window in which that broken
version is what everyone has installed.

The cost is accepted knowingly: for four days, CRAN users see `nodes` and
`diagnostics` arguments they do not have, and a `ProductNormal3()` example that
errors on their version. A failing example is a smaller harm than a silently
wrong confidence interval with no public notice.

---

## Changes to make

### 1. `README.md` — permanent version requirement

In the Three-Variable Indirect Effects section, state the requirement as a
standing API fact. No `install_github()` line, no dates, no reference to the
current gap — nothing that needs removing after 2026-08-21.

> The corrected integrator requires RMediation >= 1.7.0. Earlier versions
> return wrong values when the `a1`/`a2` covariance is ill-conditioned.

Deliberately *not* a version-gap banner: a temporary notice would need a cleanup
commit, and cleanup commits that nobody remembers to make are how docs go stale
in the first place.

### 2. `.github/workflows/pkgdown.yaml` — drop the release trigger

```diff
 on:
   push:
     branches: [main, master]
   pull_request:
     branches: [main, master]
-  release:
-    types: [published]
```

For a normal release — merge `dev` → `main`, then tag `main` — the push-to-main
trigger already deploys. The release trigger is therefore **redundant in every
correct case and active only in the incorrect one**: a tag on any other ref
republishing the public site. Removing it makes the site track `main` (and so
CRAN) by construction rather than by discipline.

Considered and rejected: gating on `github.event.release.prerelease`. It would
have blocked tonight's misfire but still leaves the deploy ref-dependent — a
non-prerelease tag on `dev` would publish just the same.

**Note:** removing the trigger does not revert the site. It stays at 1.7.0 until
the next push to `main`, which is what the decision above intends.

---

## Verification

1. Parse the workflow and assert the trigger set — do **not** grep for
   `types: [published]`, which now matches the explanatory comment and returns a
   false positive. `on:` is also parsed as boolean `true` under YAML 1.1, so a
   naive `y[["on"]]` lookup silently yields `NULL` and a false *negative*:

   ```bash
   python3 -c "
   import yaml; d = yaml.safe_load(open('.github/workflows/pkgdown.yaml'))
   t = d[True if True in d else 'on']
   print(list(t.keys()))  # expect: ['push', 'pull_request', 'workflow_dispatch']
   "
   ```
2. Push to `dev` must **not** deploy the site — confirm no new pkgdown run
   appears in `gh run list --workflow=pkgdown.yaml`
3. The next `dev` → `main` merge **must** deploy, taking the site to 1.7.0 from
   `main` and closing the gap
4. `R CMD check --as-cran` stays 0/0/0 (README is checked)

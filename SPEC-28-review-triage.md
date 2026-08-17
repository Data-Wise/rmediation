# SPEC-28 — Code review triage for PR \#28 (prod3 integrator)

**PR:** [\#28](https://github.com/Data-Wise/rmediation/pull/28)
**Reviews:** `/code-review 28` (low effort — 1 diff pass, no
verification) **Design spec:** `SPEC-27-prod3-integrator.md` **Status:**
all findings triaged; 2 acted on, 1 refuted, 1 declined **Created:**
2026-08-16

------------------------------------------------------------------------

## Context

An automated review of PR \#28 returned four findings against the
non-test hunks. The review ran at **low effort with no verification
pass**, so every finding is a hypothesis from reading the diff, not a
demonstrated defect. This document records what each turned out to be
and the evidence that settled it.

The headline outcome: the most serious-sounding finding was **wrong**,
and checking it turned up a **different, real defect** in the legacy
code path that neither the review nor issue \#27 had identified.

------------------------------------------------------------------------

## Triage summary

| \# | Finding | Verdict | Action |
|----|----|----|----|
| 1 | Partition invariant breaks when `|m| > bound` | **REFUTED** | Comment + regression test |
| 2 | `error = NA` on the fixed-`nodes` path | **VALID** | Doc clarified |
| 3 | Node cache grows unbounded | **DECLINED** | Rationale recorded |
| 4 | Planning docs not updated | **VALID** | `.STATUS` + `CLAUDE.md` updated |

------------------------------------------------------------------------

## Finding 1 — partition invariant — REFUTED

### The claim

> Cells are built as `[m-bound, 0]` and `[0, m+bound]`; when a
> standardized mean exceeds `bound` (e.g. `mean=10, sd=1` → `m=10 > 6`),
> the first cell has reversed limits and the two cells overlap on
> `[0, m-bound]`, canceling only approximately across two different node
> sets. The axis-kink partition that the method’s validity rests on no
> longer holds for that input, with no guard or warning.

Suggested remedy: clamp the split point into the box.

### Why it is wrong

The reversed limits are load-bearing, not a slip. `cell(a, b)` computes
`pts = (b-a)/2 * x + (a+b)/2` and `wts = (b-a)/2 * w`. When `a > b` the
weights are **negative**, so the cell evaluates `-integral(b, a)`. With
`m > bound`:

    cell 1: [m-bound, 0]  ->  -integral(0, m-bound)
    cell 2: [0, m+bound]  ->  +integral(0, m+bound)
    sum                   ->   integral(m-bound, m+bound)

The overlap does not cancel *approximately* — it telescopes to exactly
the truncation box that `.prod3_bound()` guarantees. And because every
node in both cells lies on the same side of the axis, `sign(x)` is
constant throughout: the single-signed property the method depends on is
**preserved**, not broken. The kink at 0 is never crossed, because 0 is
outside the integration region.

Adopting the suggested clamp would have changed which region is
integrated, turning a correct implementation into an incorrect one.

### Evidence

Gauss-Legendre vs Monte Carlo (4e6 draws, 3 SE ≈ 7.5e-04), `q = 0.5`,
`bound(1e-6) = 6` — so every row from `m₁ = 6.5` down is in the disputed
regime:

**Benign covariance** `[[1,.5,.3],[.5,1,.2],[.3,.2,1]]`:

| m₁   | gauss     | Monte Carlo | \|gauss − MC\| | within 3 SE |
|------|-----------|-------------|----------------|-------------|
| 0.2  | 0.8056638 | 0.8056455   | 1.83e-05       | yes         |
| 5.0  | 0.5314906 | 0.5313052   | 1.85e-04       | yes         |
| 6.5  | 0.5111826 | 0.5110577   | 1.25e-04       | yes         |
| 10.0 | 0.4855340 | 0.4855733   | 3.93e-05       | yes         |
| 20.0 | 0.4582572 | 0.4583408   | 8.36e-05       | yes         |

**Both stressors at once** (ρ = 0.999 *and* mean outside the bound):

| m₁   | gauss     | Monte Carlo | \|gauss − MC\| | within 3 SE |
|------|-----------|-------------|----------------|-------------|
| 0.2  | 0.8067150 | 0.8066768   | 3.83e-05       | yes         |
| 8.0  | 0.4189495 | 0.4189883   | 3.88e-05       | yes         |
| 15.0 | 0.3865714 | 0.3867492   | 1.78e-04       | yes         |

**Large negative mean:** m₁ = −8 → 1.10e-04, m₁ = −15 → 1.47e-04. Both
within 3 SE.

### Action taken

Not a code change — the code was right. Instead:

- An explanatory comment on `.prod3_gauss_cells()` deriving the
  telescoping sum and stating explicitly *do not clamp the split point*.
- A regression test,
  `"accuracy holds when the standardised mean exceeds the bound"`,
  pinning m₁ ∈ {10, 20, −15} plus the combined-stressor case.

The test exists because the construct reads like a defect. Without it, a
future reader — human or automated — reaches the same conclusion this
review did and “fixes” it into a genuine bug.

------------------------------------------------------------------------

## Discovered while verifying Finding 1 — legacy path collapses on large means

The verification table above also compared against
`method = "hcubature"`, which produced this:

| m₁             | true (MC) | hcubature     |
|----------------|-----------|---------------|
| 6.5            | 0.5110577 | 0.5111825     |
| 10.0           | 0.4855733 | **0.2201079** |
| 20.0           | 0.4583408 | **0.0000000** |
| 15.0 (ρ=0.999) | 0.3867492 | **0.0000000** |
| −15.0          | 0.6248695 | **0.0000000** |

The pre-1.7.0 integrator returns **exactly zero** where the true
probability is around 0.46. This is a **separate defect from issue
\#27**: it is driven by mean location, not by conditioning, and it
appears on well-conditioned covariance (κ = 4). Nobody had reported it.

It needs no separate fix — the new default already handles these inputs
to within Monte Carlo noise — but it is recorded in a test and in
`NEWS.md` so the default change is not mistaken for a mere accuracy
refinement. It also strengthens the case in SPEC-27 for making `"gauss"`
the default rather than an opt-in: a κ-threshold escalation design would
never have triggered here, because conditioning is benign.

------------------------------------------------------------------------

## Finding 2 — `error = NA` on the fixed-`nodes` path — VALID

The review noted that supplying `nodes` returns `error = NA_real_` with
no convergence check, so `diagnostics = TRUE` reports `NA` and the
node-cap warning cannot fire — while the documentation described
`"error"` as a convergence estimate without qualification.

The behavior is intended: a single fixed rule produces no
successive-rule gap to measure. The documentation was the defect.
`@param diagnostics` now states that `"error"` is `NA` when `nodes` is
supplied or when `method = "hcubature"`, and tells the caller how to
check convergence at a fixed rule (evaluate at `nodes` and `2 * nodes`,
compare).

------------------------------------------------------------------------

## Finding 3 — unbounded node cache — DECLINED

`.prod3_gl_cache` never evicts. In practice it holds at most five
entries — the node counts 128, 256, 512, 1024, 2048 reachable through
the escalation ladder — for the lifetime of the session. Eviction
machinery would add moving parts to bound something already bounded by
construction.

Declined deliberately, with the rationale recorded in the commit message
rather than left as a silent non-response.

------------------------------------------------------------------------

## Finding 4 — planning docs — VALID, done

Addressed in `91b2117`:

- **`.STATUS`** — version 1.7.0, status back to `in_progress` (PR in
  review), the new worktree entry, and a session log.
- **`CLAUDE.md`** —
  [`pprodnormal3()`](https://data-wise.github.io/rmediation/reference/pprodnormal3.md)
  was missing from the Distribution Functions list entirely, despite
  being the subject of this work. Now documents the function, records
  that `method = "gauss"` is the default and must not be reverted, and
  flags both look-like-bugs invariants in `R/prod3_core.R`.

Each fact is written on one surface only: `.STATUS` carries project
state, `CLAUDE.md` carries the standing convention, SPEC-27 carries the
design evidence, and this document carries the review triage.

------------------------------------------------------------------------

## Gates after triage

| Gate | Result |
|----|----|
| Test suite (worktree) | **339 passed**, 0 failed, 0 warnings, 0 skipped (was 333) |
| `R CMD check --as-cran` | **0 errors, 0 warnings, 0 notes** |
| NAMESPACE | byte-identical after `document()` — the roxygen2 8.0.0 S7 bug did not recur |
| CI on PR \#28 | **6/6 green** — ubuntu release + devel, macOS, Windows, test-coverage, codecov |
| Leak scan | clean — no keys, tokens, credentials, or plain-text destructive git commands |

Commits: `3335914` (review follow-ups, feature branch), `91b2117`
(planning docs, `dev`).

------------------------------------------------------------------------

## Process note

A low-effort review with no verification pass produced one finding that
was correct-as-stated (2), one housekeeping item (4), one judgment call
(3), and one confident-but-wrong claim about the most intricate part of
the diff (1) — whose suggested remedy would have introduced a real bug.

The reviewer’s instinct on (1) was reasonable: the construct genuinely
looks wrong. The cost of checking it was one script; the cost of
accepting it would have been a regression. Verify before acting on a
finding, and when the finding is refuted, leave behind the comment and
the test that stop the next reader from re-deriving it.

# Implementation Plan: next RMediation features (2026-11-08)

Status: DONE (2026-11-08). T1-T4 shipped in #137 (`b70f7f9`), T5-T7 in #138 (`3d6ebe9`). The release (1.10.0) is not cut. Kept as the decision record. Source: the 2026-11-08 brainstorm.
Existing `tasks/plan.md` (coverage and edge-case plan) is untouched. Tasks are in `tasks/todo-features-2026-11-08.md`.

## Overview

Two small features for the next GitHub pre-release, in this order, plus a parked list. The pre-release exists so papers
(mbco-lrt, probmed, ...) can cite a tag; `mbco()` is what mbco-lrt calls (33 `RMediation::mbco` calls).

1. **Provenance on `mbco()` results**: the result records which versions produced it.
2. **Resolve `:=` that references other `:=`** in `ci(lavaan)`: turn #136's warning into a result.

## Architecture decisions

- **Provenance is an optional `MBCOResult` property, default `NULL`**, exactly the pattern `branch` and `dropped` already
  use (default `quote(NULL)`, tested "built the old way"). **Additive, but not invisible:** `names.MBCOResult` returns
  `c("chisq", "p", S7::prop_names(x))`, so `names()` GAINS `"provenance"` (verified: today it returns
  chisq, p, statistic, df, p_value, type, refit, branch, dropped; `branch` and `dropped` changed it the same way, and
  tests assert `"branch" %in% names(res)`). Contract: every existing name keeps its position and `"provenance"` is
  appended last. Existing constructors and positional use keep working. A consumer scan (missingmed, medsim, probmed,
  the papers) for `names()`/`length()` on an `mbco()` result is part of T1. (Codex review, finding 1.)
- **What provenance can honestly hold:** RMediation, OpenMx, medfit (if loaded) and R versions, `type`, `R`, `RNGkind()`,
  and the call time. The **seed value is not recoverable** after the fact (only `.Random.seed` state, not what was
  passed to `set.seed()`), so it is NOT claimed. A caller who wants the seed recorded passes it in (open question 1).
- **Nested `:=` is resolved by substitution on parsed expressions** (`substitute()` over an environment of defined
  expressions, in dependency order), never by regex on the string. A regex would also rewrite names inside other
  identifiers (`ab` inside `tab`, labels like `c`).
- **After expansion the expression is re-classified, not sent straight to Monte Carlo.** Substitution leaves parentheses
  (`(a*b)*c`), which `.parse_product_string()` rejects, so the product tree is flattened (walk `*` and `(`) and the
  factors are routed exactly as a flat product would be. (Codex review, finding 2.)
- **Found while checking that finding: a flat `abc := a*b*c` already errors for every `type` except `"MC"`**, including the
  default `"dop"` ("Distribution of Product method currently only supports 2 variables"), verified on `dev`. A serial
  indirect effect therefore fails `ci(fit)` today. Nested expansion would inherit it (`ab*c` is three factors), so the
  3-or-more-factor behavior must be decided inside this feature (T6). Decision (recommended, see open question): factors
  >= 3 take the existing Monte Carlo fallback and warn when `type` was explicit, the same contract as #136. The exact
  three-factor interval (`pprodnormal3`/`qprodnormal3`) stays parked.
- **One feature per `feature/*` branch off `dev`, one PR each, squash.** A release is a separate step needing your
  go-ahead (CRAN hold unchanged).

## Dependency graph

```
T1 provenance property (+ default-NULL back-compat test)
   └── T2 mbco() fills it ── T3 print/summary shows it ── T4 docs + NEWS
T5 expand-defined helper ── T5b product-factor helper (both pure, unit-tested)
   └── T6 re-classify expanded expressions in ci(lavaan) ── T7 docs + NEWS
```

The two chains are independent; run them as separate branches. Within a chain, order is fixed.

## Phases

### Phase 1: provenance (branch `feature/mbco-provenance`)
T1-T4 in `tasks/todo-features-2026-11-08.md`.

### Checkpoint: provenance
- [ ] Full suite green, `scripts/check-local.sh` Status: OK, output-shape contract tests unchanged and green
- [ ] An MBCOResult built the old way still has `provenance` NULL
- [ ] You review the printed form before the PR opens

### Phase 2: nested defined parameters (branch `feature/ci-nested-defined`)
T5-T7 (with T5b) in `tasks/todo-features-2026-11-08.md`.

### Checkpoint: nested `:=`
- [ ] `abc := ab*c` returns an interval, not a warning; a cyclic or unresolvable definition still warns and keeps the rest
- [ ] Full suite and `check-local.sh` green

### Parked (not planned; each needs its own decision)
- `qprodnormal3()`, upper-tail precision for `pprodnormal3()`: numerical core, risk-listed, needs known-answer tests.
- `type`-aware intervals for non-product `:=` (delta method): changes returned values.
- Export `ml_admissible()`: grows the public surface; CRAN export is locked once on CRAN.
- One result class for `ci()`/`medci()`: breaking for missingmed; skip.

## Risks and mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| A new slot changes printed output or `names()` that a paper's logs or a consumer parses | Med | `names()`: append last, keep existing order, test the prefix; print: separate trailing block, existing lines byte-identical, tested; consumer scan in T1. |
| 3-or-more-factor products change from an error to a Monte Carlo result | Med | It is a behavior change (error to result plus warning): NEWS "Bug fixes", test pins flat and nested equal for each `type`. |
| Provenance claims reproducibility it cannot give (seed) | High (misleading) | Record only recoverable facts; say "seed not recorded" in `?mbco`; optional explicit seed argument is an open question. |
| Substitution loops on a cyclic `:=` | Low | Detect cycles; warn and return NULL for those labels only (same contract as #136). |
| `R/mbco.R` and `R/ci*.R` are in `.github/risk-files.txt` | Med | The PR body needs the risk-tier evidence block (known answer, planted defect, transcript). Plan the tests for it in T2/T6. |
| Scope creep into the parked list | Med | Parked items stay parked unless you promote one. |

## Decisions on the open questions (2026-11-08, maintainer)

1. **No `seed =` argument.** Provenance omits the seed; `?mbco` says "seed not recorded"; the paper calls `set.seed()`
   and states it. The public `mbco()` signature does not change.
2. **No extra paper needs.** Plan as is. (Checked: mbco-lrt calls `RMediation::mbco` 33 times; probmed and medsim call
   `medci` once and `memory_exp` once.) A later specific need would outrank this plan.
3. **Pre-release version 1.10.0** (a new public result slot is a minor bump). The release itself is still a separate step
   needing a go-ahead; CRAN hold unchanged.

The plan was approved and built; any release still needs its own go-ahead.

## Revision 2026-11-08 (after Codex adversarial review)

Codex returned `needs-attention` with two medium findings; both were verified against `dev` before revising.
1. `names(MBCOResult)` gains `"provenance"`: the compatibility claim is corrected above, T1 now specifies and tests it.
2. Nested expansion must re-enter product detection: T5/T6 rewritten. Checking it exposed that flat three-factor products
   error today for any `type` but `"MC"`; T6 now decides that case.

## Decision (2026-11-08, maintainer): three-or-more-factor `:=` in `ci(lavaan)`

Monte Carlo, with the #136 warning when `type` was given explicitly. This also stops the flat `abc := a*b*c` case from
erroring under `"dop"`, `"asymp"`, `"prodclin"` and `"all"`, so it is a behavior change beyond the nested feature: NEWS
"Bug fixes" (T7). The exact three-factor interval (`pprodnormal3`/`qprodnormal3`) stays parked.

No open questions remain.

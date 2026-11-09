# Task list: next RMediation features (2026-11-08)

Plan: `tasks/plan-features-2026-11-08.md`. All tasks done: T1-T4 in #137, T5-T7 in #138. Each task must leave the suite
green. Focused test command: `Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/<file>")'`. Full: `scripts/check-local.sh`.

## Phase 1: provenance (`feature/mbco-provenance`)

- [x] **T1: optional `provenance` property on `MBCOResult`** (XS, `R/00_classes.R`, new `tests/testthat/test-mbco-provenance-slot.R`)
  - Accept: property is `NULL | list`, default `quote(NULL)`; validator accepts NULL or a named list with the expected keys; an
    `MBCOResult` built the old way has `provenance` NULL; a malformed list errors naming `provenance`.
    **`names()` contract:** `names(res)` equals the previous nine names in the same order followed by `"provenance"`
    (so it DOES change; it is appended last). Consumer scan done first: grep missingmed, medsim, probmed and the papers
    (mbco-lrt, Missing Effect) for `names(`, `length(` or `[[` by position on an `mbco()` result; none may depend on the old length.
  - Verify: new test file passes, including `expect_identical(names(res)[1:9], <old nine>)` and `names(res)[10] == "provenance"`;
    `test-mbco-branch-slot.R` and the shape-contract tests unchanged and green; the scan result is quoted in the PR.
  - Deps: none.
- [x] **T2: `mbco()` records provenance** (S, `R/mbco.R`, `tests/testthat/test-mbco-provenance-slot.R`, a risk-file)
  - Accept: result carries RMediation/OpenMx/(medfit if loaded)/R versions, `type`, `R`, `RNGkind()`, timestamp; for each of
    `asymp`, `parametric`, `semi` and the SEMFit route; no version is invented when a package is not loaded (NULL, not "").
  - Verify: known-answer test on the recorded versions (compare to `packageVersion()`); planted defect: a result with the
    wrong `type` recorded must fail the test; statistic, df and p are byte-identical to before.
  - Deps: T1.
- [x] **T3: `print`/`summary` show provenance** (S, `R/MBCOResult_methods.R`, test)
  - Accept: a trailing "Provenance" block appears only when set; all existing printed lines are unchanged.
  - Verify: snapshot or `expect_output` on old lines unchanged; new block present for a fresh `mbco()` result.
  - Deps: T2.
- [x] **T4: docs and NEWS** (XS, `man/` via `devtools::document()`, `NEWS.md`, `vignettes/` if `mbco()` is shown there)
  - Accept: `?mbco` and `?MBCOResult` describe the slot and state that the seed is not recorded; NEWS entry under the
    development version; refcard/cookbook mention if they print `mbco()` output.
  - Verify: `devtools::document()` clean; `grep -rn "MBCOResult" vignettes man` reviewed.
  - Deps: T3.

### Checkpoint: after T1-T4
- [x] full suite + `scripts/check-local.sh` Status: OK; counts quoted
- [x] you review the printed form
- [x] PR body carries the risk-tier evidence (R/mbco.R is a risk file)

## Phase 2: nested defined parameters (`feature/ci-nested-defined`)

- [x] **T5: `.expand_defined()` helper** (S, `R/external_methods.R`, new `tests/testthat/test-expand-defined.R`)
  - Accept: given the `:=` table, replaces references to other defined labels by their expressions, in dependency order,
    using `substitute()` on parsed expressions; detects cycles; leaves unresolvable labels flagged, not dropped; returns the
    expanded expression (as a call), not a string.
  - Verify: unit tests, including a label that is a substring of another (`ab`/`tab`), the label `c`, a chain of three, and a
    cycle (`x := y`, `y := x`) that must be reported; a planted wrong substitution must fail a test.
  - Deps: none.
- [x] **T5b: `.product_factors()` helper** (XS, `R/external_methods.R`, `tests/testthat/test-expand-defined.R`)
  - Accept: walks an expression tree through `*` and `(` and returns the factor names when it is a pure product of
    estimated coefficients, else NULL; `(a*b)*c` and `a*b*c` give the same factors; `a*b+c` gives NULL.
  - Verify: unit tests for parenthesized, reordered and mixed expressions; old `.parse_product_string()` results unchanged.
  - Deps: T5.
- [x] **T6: route expanded expressions through the same logic as flat ones** (M, `R/external_methods.R`, `tests/testthat/test-external-methods-lavaan.R`)
  - Accept: after expansion the expression is classified by `.product_factors()`. Two factors: ProductNormal path, honors
    `type`. Three or more factors (flat OR nested): Monte Carlo fallback with the #136 warning when `type` was explicit, so a
    flat `abc := a*b*c` no longer errors under `"dop"`/`"asymp"`/`"prodclin"`/`"all"` (decided 2026-11-08: Monte Carlo with warning). A cycle or unresolvable label still warns and keeps the other results.
  - Verify: for each `type` in dop/asymp/MC/prodclin/all, nested (`ab := a*b`, `abc := ab*c`) and flat (`abc := a*b*c`)
    give the same result class, names and (same seed) the same interval; a nested alias (`e := ab`, which expands to the two-factor `a*b`) honors `type` like the flat product;
    planted defect: forcing the nested path to ignore `type` must fail a test.
  - Deps: T5, T5b.
- [x] **T7: docs and NEWS** (XS, `NEWS.md`, `man/`)
  - Accept: NEWS "Bug fixes" entry covering nested `:=` and the three-factor change from error to result; the `ci()` lavaan
    documentation states nested `:=` is supported, how cycles behave, and that three or more factors use Monte Carlo.
  - Verify: `devtools::document()` clean.
  - Deps: T6.

### Checkpoint: after T5-T7
- [x] full suite + `scripts/check-local.sh` Status: OK; counts quoted
- [x] PR opened only after you say so

## Not planned (parked)

`qprodnormal3()`, upper-tail precision for `pprodnormal3()`, `type`-aware intervals for non-product `:=`, export `ml_admissible()`,
a unified `ci()`/`medci()` result class. Promote one only on your say-so.

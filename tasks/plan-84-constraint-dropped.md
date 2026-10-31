# Plan: `RMediation_constraint_dropped` (issue #84, R1-R3)

Spec: `tasks/spec-84-constraint-dropped.md`. Review: `tasks/codex-review-84.md`.
Separate file: `tasks/plan.md` / `tasks/todo.md` belong to other work and are untouched.

Dependency order: T1 (tests, red) -> T2 (helper + wiring, green) -> T3 (docs) -> T3b (website) -> T4 (harness) -> T5 (suite, lint, review, PR).

- [ ] T1 Failing tests (S, 1 file) `tests/testthat/test-mbco-constraint-dropped.R`
  - Accept: known answer (class, statistic positive = `mbco_product_null()`, 0.0878 pin), message
    wording, tolerance fixture raises the class, clean h0 and `statistic_before > 0` do not,
    planted defect. Fails on dev before T2 (class absent).
  - Verify: `testthat::test_file(...)` shows failures only for the missing class.
- [ ] T2 Implement (S, 2 files) `R/mbco-compare.R`, `R/mbco.R`
  - Accept: T1 green; existing `test-mbco-*` files unchanged and green.
  - Verify: `devtools::test(filter = "mbco")`.
- [ ] Checkpoint: mbco tests green, planted defect still fails when helper is no-op'd.
- [ ] T3 Docs (S, 3 files) `R/00_classes.R`, `man/mbco.Rd`, `NEWS.md`, `.STATUS`
  - Accept: `?mbco` cites OpenMx#433, describes an ambiguous symptom, recommends
    `mbco_product_null()`, states the parametric-replicate gap; NEWS under 1.7.1; no
    "detects/fixes #433" claim.
  - Verify: `devtools::document()` clean diff; grep for the claim words.
- [ ] T3b Website and user docs (S, 1-2 files) `README.md` (MBCO section), pkgdown build
  - Added at the user's request. The site is pkgdown (`_pkgdown.yml`; reference page `mbco`,
    News page from `NEWS.md`); there is no Quarto site in this repo (only a vestigial
    `vignettes/_quarto.yml`, untouched). The cross-package site (mediationverse) is a separate repo
    and out of scope.
  - Accept: README MBCO section states the symptom, the new warning class and
    `mbco_product_null()`; `pkgdown::check_pkgdown()` clean; `pkgdown::build_reference(topics = "mbco")`
    and `build_news()` render the new text (checked in a scratch dir, not committed: `docs` is ignored).
  - Verify: `Rscript -e 'pkgdown::check_pkgdown()'`; grep rendered HTML for `RMediation_constraint_dropped`.
- [ ] T4 Harness (S, 1 file) `scripts/verify-constraint-dropped.R`
  - Accept: per available optimizer prints versions, optimizer, statistic, warning classes,
    planted-defect result; non-zero exit when the known answer fails.
  - Verify: run it; output quoted in the PR body.
- [ ] T5 Gate (M): full `devtools::test()`, `lintr::lint_package()`, code-review pass, PR to `dev`.
  - Accept: counts reported; PR body has transcript, Codex dispositions, follow-up (parametric).

Risks: SLSQP/CSOLNP may land on different values (mitigation: pin only on the machine's
optimizer, compare to `mbco_product_null()` for the general check); `devtools::test()` runtime.

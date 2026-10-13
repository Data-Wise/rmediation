# RMediation coverage and edge-case plan

Date: 2026-10-12. Baseline: dev `4bda219`; medfit 0.8.0 in a scratch library, OpenMx available. Implementation started on feature/coverage-mbco; runtime code remains unchanged.

## Recommendation and scope

First close result-bearing MBCO and CI gaps; then exercise graphics and legacy compatibility. Target at least 95% overall line coverage, at least 95% in changed numerical/dispatch modules, and every reachable critical refusal and result-selection branch. Treat these as implementation acceptance targets, not current achievements. Do not exclude legacy files or delete code to improve the denominator. CRAN, dev-to-main and integrator holds remain.

## Measured baseline

Fresh covr run: 73.00613% line coverage, 1,793 instrumented lines, 484 uncovered. With the denominator unchanged, 395 additional covered lines reach 95% (at most 89 lines remain uncovered); implementation changes require recomputation. `coverage-baseline.csv` records the complete per-file tally.

| Module | Line coverage | Priority |
|---|---:|---|
| R/mbco.R | 48.00% | Public dispatch and bootstrap routing |
| R/mbco_semfit.R | 85.71% | Version/registration and boundary refusal |
| R/confintAsymp.R | 29.51% | Delta-method edge cases and graphics |
| R/confintMC.R | 42.11% | MC inference and graphics |
| R/ci_medfit.R | 76.62% | Covariance mapping and optional registration |
| R/prod3_core.R | 92.18% | Numerical failure/tail paths |
| R/medci_legacy_backup.R | 29.06% | Reachability and compatibility audit |
| R/medci_prototype.R | 29.46% | Reachability and compatibility audit |

Line coverage differs from expression coverage. Bootstrap workers already show 100% line coverage; this does not establish convergence handling, RNG isolation or valid bootstrap inference. Startup registration may run before instrumentation; supplement the metric with installed-process evidence.

## Ordered implementation slices

### 1. Reproducible coverage inventory (small)

Files: a focused coverage reporting script, CI coverage workflow, tasks baseline.
Acceptance: report uncovered lines/functions with R/package versions and optional dependencies; distinguish line and expression metrics; preserve the medfit v0.8.0 coverage pin and absent/CRAN/0.7/0.8 compatibility jobs. Save before/after artifacts with commit SHA. Do not lower the Codecov gate.
Verification: reproduce this baseline within explained environment differences; verify absent dependencies are genuinely absent in subprocess gates. Dependencies: none.

### 2. MBCO public dispatch and failure cases (medium)

Files: test-s7-mbco.R, test-mbco-parametric-semi.R, test-mbco-semfit.R and existing helpers; runtime files only if a test exposes a defect.
Acceptance: invalid R (zero, negative, fractional, NA), alpha endpoints/nonfinite values, precision and optimizer controls; fitted RAM subclass acceptance; missing OpenMx; mixed classes and unsupported SEMFit controls. Exercise public bootstrap routes, optimizer fallback without NPSOL, and result-field mapping using narrow mocks plus a real smoke fit. Add null-equals-full/reversed pairs, nonconverged or failed bootstrap fits, singular resampling covariance and RNG/global-option behavior. Establish intended failure/cleanup policy before fixing newly discovered behavior; do not freeze silently wrong results into tests.
Oracles: existing clean-start a1/b1/product-null fixtures and independent chi-square tail computation. Retain both branch values and minimum selection. Plant mapping/fallback/refusal defects that relevant assertions reject. Dependencies: 1.
Verification: focused MBCO tests and both installed load orders; no unguarded OpenMx dependency.

### Checkpoint A

Review MBCO findings and behavior changes; run full suite and coverage delta. Any numerical fix gets a NEWS note and a narrow reviewed feature PR. No release work.

### 3. CI numerical/validation cases (medium)

Files: test-ci.R, test-ci-medfit-covariance.R, test-serial-medfit-integration.R, test-utils-validation.R.
Acceptance: correlated analytic delta-method oracle for two/three paths; exact zero gradient distinguished from near-zero gradients; reordered named covariance entries and missing aliases; incompatible dimensions, asymmetric/non-PSD covariance, NA/Inf, invalid confidence/MC sizes. Probe rank-deficient PSD covariance separately from indefinite covariance and define its supported behavior. Cover formula H0/type combinations and optional extraction errors without duplicating existing basic cases.
Oracles: hand gradient times covariance times gradient, existing lm/lavaan extraction fixtures, fixed-seed MC with tolerance justified by MC uncertainty. Mutants: dropped covariance term, positional alias mapping, zero-gradient cutoff. Dependencies: 1.
Verification: focused CI tests, full suite, per-file coverage delta.

### 4. Product distribution numerical boundaries (medium)

Files: test-product-distributions.R, test-product-normal3.R; selected numerical modules if defects arise.
Acceptance: probability endpoints, both tails and log probabilities only where supported, monotonicity, sign/permutation/scaling identities, extreme means, near-perfect positive/negative correlation, singular versus near-singular covariance and integration-limit failures. Inventory existing cases first: do not repeat the current inverse/monotonicity and ill-conditioned regression tests. Quantile/CDF round trips are consistency checks, not independent numerical proof.
Oracles: analytic limiting cases and independent high-accuracy integration; MC cross-checks use uncertainty bounds. Mutants: removed axis partition, fixed truncation, wrong tail or covariance term. Dependencies: 1.
Verification: focused deterministic tests; expensive stress grids remain separate from default CI.

### Checkpoint B

Full suite and coverage report; verify all critical mapped cases have assertions that fail planted defects. If the 90% intermediate milestone remains unmet, report the remaining uncovered lines before choosing the next slice.

### 5. Graphics and legacy compatibility (two small slices)

Files: focused CI graphics tests; separate legacy/prototype test files.
Acceptance: exercise plot/plotCI and all-method overlays on temporary devices; assert numeric outputs are unchanged, device cleanup occurs, and zero-SE paths behave as documented. Inspect one rendered representative plot; plot existence alone is insufficient. Audit exports/call sites of backup/prototype functions before testing their reachable contracts. Do not delete or exclude them without a separate decision.
Dependencies: 3; legacy slice also uses 1. Verification: focused tests, one inspected render and coverage gain attributable to reachable behavior.

### 5c. Remaining uncovered-line closure (bounded slices)

Files: remaining S7 validators, display/extraction methods, CI internals, registration hooks and numerical fallback branches identified by the refreshed report.
Acceptance: classify every remaining uncovered line as reachable contract, dependency/version branch, instrumentation limitation or genuinely unreachable code. Add meaningful tests for reachable behavior in small feature PRs. Merge coverage from compatible instrumented dependency scenarios where useful; fresh-process smoke gates alone do not increase measured coverage. Resolve registration instrumentation gaps with measured evidence rather than assuming startup tests count. Preserve the denominator and do not add exclusions to reach the target. Dead-code removal or unsupported API decisions require separate review.
Dependencies: 2-5b. Verification: coverage milestones 80%, 90%, then >=95%, with remaining-line inventories at each checkpoint. The final uncovered budget is at most 89 lines only while the baseline denominator stays 1,793; recompute after code changes. Every reachable critical refusal/result-selection branch must be tested even if the overall percentage already passes. If 95% cannot be reached honestly, report the specific blockers and measured ceiling rather than silently reducing the target.

### 6. Final gates and integration (small)

Acceptance: >=95% overall, >=95% changed numerical/dispatch modules, no unexplained critical uncovered branch, no denominator exclusions; report unavailable/unreachable cases explicitly. If targets are missed, revise scope transparently rather than declaring success. All tests pass with known existing warnings separated; lint changed R, spelling and URLs for changed docs; strict full CRAN check and dependency-flavor limitation reported. Update NEWS/status/plan with evidence.
Verification: full suite with medfit0.8; absent/old/new installed gates; platform CI and Codecov green; review and merge feature PRs to dev. No package version bump, CRAN submission or dev-to-main integration. Dependencies: 2-5c.

## Execution policy

Implement one bounded slice per feature branch/PR; reuse existing numerical fixtures. Keep MC work deterministic and use uncertainty-based tolerances. Treat revealed correctness defects as fixes requiring their own regression evidence. Test small sample bootstrap failure policy without large stochastic CI simulations. Next authorized implementation slice: task 1 followed by task 2; this plan itself does not perform implementation.


## First slice evidence (2026-10-12)

`scripts/report-coverage.R` writes line/expression summaries, uncovered functions/lines, saved covr object, commit/dirty-tree state and dependency versions. CI uploads this inventory without lowering Codecov or changing the optional-version matrix. Saved-object reports explicitly distinguish report-process metadata from original measurement provenance.

Public MBCO routing tests cover invalid controls, alpha endpoints, absent OpenMx guidance, both bootstrap dispatches, NPSOL availability/fallback, exact result fields, worker-error propagation and real fitted RAM bootstrap smoke checks. Local copies with wrong df or fallback optimizer fail their corresponding assertions; production code is untouched.

Measured line coverage: 73.00613% -> 74.45622%; `R/mbco.R`: 24/50 -> 50/50 lines. This is a bounded first slice, not completion of task 2 or the 95% goal. Actual nonconvergence/singular-resampling behavior and RNG/global-option policy remain next; 100% dispatcher line coverage does not prove these worker contracts.

Validation: full suite 562 passed / 0 failed / 2 existing OpenMx warnings / 1 intentional version skip; changed-file lint and spelling passed.

## First slice integration

PR #42 merged into dev as `610676de40ad435088908ca18c127432edaa0103` after all ten checks passed on `ef7e31f`. Review hardened invalid-input tests with a successful fitting mock and zero-call assertion to prevent unfitted-model errors masking removed validators. Final local suite: 563 passed, zero failures, two existing warnings and one version skip. CI inventory generation/upload passed. Task 2 worker contracts remain pending.

## Bootstrap worker checkpoint (2026-10-12)

The next slice fixes demonstrated OpenMx option leaks on success/error and
rejects failed semiparametric refits or nonfinite replicate statistics. An
actual degenerate resample triggers the refit refusal; controlled status/error
cases cover cleanup. Fixed seeds reproduce both bootstrap routes, consuming
the caller RNG stream without changing RNGkind. Singular sample/null covariance
errors are explicit; parametric reported results are validated. No replicate
retry/drop policy or covariance regularization is introduced.

Full suite: 599 passed, 0 failed, 2 existing OpenMx warnings, 1 intentional
version skip. Fresh overall line coverage: 74.82133% (expression: 76.53936%);
95% is still pending. New tests lint clean; remaining runtime lint findings
are legacy names, explicit returns and existing long/commented lines.
Task 2 remains open for null-equals-full/reversed OpenMx pairs and installed
load orders. Release holds and integration defaults remain unchanged.

## Observed comparison and load-order checkpoint (2026-10-12)

Real fitted equal/reversed OpenMx pairs exposed invalid inference: the semi
route returned df 0/-1 with p=0, and the asymptotic route returned invalid
results. All three workers now share an observed-comparison gate requiring
positive df and a finite nonnegative statistic before bootstrap sampling.
This is a necessary condition, not proof of substantive nesting. Real refusal
tests verify unchanged RNG/options and zero bootstrap comparison calls.
Parametric post-bootstrap validation remains independently tested.

Full suite: 634 passed, 0 failed, 2 existing warnings, 1 intentional version
skip. Fresh line coverage: 75.02726%; expression: 76.70279%. Weakening the
zero-df guard produced 1 failed assertion and 1 test error; restored pair tests
passed 35 assertions. Both installed OpenMx orders passed, plus eight controlled
medfit load-order gates (absent/CRAN/0.7/0.8, without OpenMx). The OpenMx gate
is now in the release-R CI jobs. New files lint clean and spelling passed.
Strict dependency/incoming check: 0 errors, 0 warnings, 1 NOTE (old Date and
missing prebuilt vignette index), with vignettes/manual excluded.

Task 2 implemented; Checkpoint A still requires PR review and green CI. Next:
CI numerical/covariance edge cases. The 95% target and release holds remain.

Checkpoint A closed: PR #44 reviewed and squash-merged into dev as
`26e86032bb688eaade66e30084c62e2e8363d79e`; all ten checks passed, including
installed OpenMx gates on macOS, Windows and Linux. No blocking review findings.
The reviewed head passed 35 pair assertions again. Next is task 3; no release.

# Codex adversarial review of the #84 plan (2026-10-30)

Run: `codex-companion.mjs task --effort high --prompt-file ...` (read-only, ChatGPT login, codex-cli
0.166.0). Codex could not execute R in its sandbox (`cannot create 'R_TempDir'`), so this was a
static review of code and OpenMx sources; the numeric facts are from this session's runs.

| # | Codex finding | Disposition |
|---|---|---|
| 1 | Blocker: a fitted h0 keeps no provenance; the predicate cannot show OpenMx dropped the constraint. Abandon `RMediation_constraint_dropped`, use a cause-neutral class (e.g. `RMediation_constraint_not_enforced`) | Predicate: accepted (already established before the review; user chose option A: symptom-based trigger, "may have been dropped" wording, #433 cited as one cause). Rename: **rejected for now**, user decided the class name; class and message are honest about ambiguity; left as an open item for the PR reviewer |
| 2 | Blocker: `.mbco_involved()` is a finite-difference heuristic (false negatives for `x^2` at 0, vector `max(abs())`) | Accepted: helper is not used by the new check; not generalized |
| 3 | Ordering: check after the swap loses the user's state; before it duplicates the warning. Prefer one warning with several classes | Trigger reads the refit record (holds the user's pre-refit statistic), emitted after `RMediation_h0_refit`. Single merged warning **rejected**: the brief says not to change `RMediation_h0_refit`; two warnings accepted as the cost |
| 4 | Blocker: parametric bootstrap replicates have no per-replicate refit (`mxCompare(boot = TRUE)`) | Accepted as a real gap; **out of scope** per the session brief; listed as follow-up in PR/NEWS/docs, docs do not claim bootstrap-wide protection |
| 5 | R2: `.guard_fits(1)` is not a #433 fixture; `expect_failure` alone is not mutation-resistant; 0.0878 is optimizer-brittle; use fresh zero-start h0; assert positive statistic and equality with `mbco_product_null()` | Accepted: fresh zero-start fixture, tolerance fixture as competing-history control (raises the same class, per option A), planted defect paired with ordinary assertion, 0.0878 as a pinned regression plus product-null agreement, harness per optimizer |
| 6 | R3 must not claim detection/fix of #433 or bootstrap-wide protection | Accepted |

## Summary

<!-- What changes and why. -->

## Test evidence

<!-- Exact command, pass/fail/skip counts, and a transcript of a check that can fail. -->

## Risk-tier evidence

<!-- Required when the PR changes a file in .github/risk-files.txt (scripts/risk_tier.py checks it). Tick each item;
     the known-answer and planted-defect items must name a tests/testthat/ file that is in this PR's diff;
     `n/a: <reason>` needs a reason of at least 8 characters. Delete this block when no risk file changed.
     For a change with no logic effect (for example a rename), replace it with one line:
     Risk-tier: exempt: <reason>
     A release PR (dev into main, or release/*) skips the checklist but needs one body line: Ships: #101, #102 -->

- [ ] Independent oracle:
- [ ] Known answer: tests/testthat/<file>.R
- [ ] Planted defect: tests/testthat/<file>.R
- [ ] Invariance or boundary:
- [ ] Dependency or optimizer coverage:
- [ ] Evidence transcript:

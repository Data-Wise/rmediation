# RMediation #34 tasks (MBCO constraint-violation guard)

Plan and acceptance criteria: `tasks/plan-34.md`. Worktree: `~/.git-worktrees/rmediation/feature-mbco-tolerance` (branch `feature/mbco-tolerance`).

- [x] 0. T0 prototypes: constraint evaluation and bootstrap-tolerance behavior (results in `planning/PLAN-34-...md`).
- [x] 1. Guard end to end for equality constraints, type "asymp" (tests first, then `.mbco_constraint_violation()` wired into `.mbco_compare()`). Done 2026-10-14: 20 new expectations; full suite 716 passed/0 failed/10 skipped/2 pre-existing warnings.
- [x] 2. Scaled threshold, inequality operators, `h1` check. Done 2026-10-14.
- [ ] Checkpoint 1: reprex warns/silent, existing mbco tests unchanged, full-suite counts vs the `dev` baseline.
- [ ] 3. Unevaluable constraint: error naming the constraint; unsupported operators skipped.
- [ ] 4. All three types through the single call site; planted defects each fail a named test.
- [ ] Checkpoint 2: mutant evidence quoted.
- [ ] 5. `?mbco` docs and NEWS (tolerance, two-fit route, exact-statistic/conservative-p wording, wrong-branch limit, new error).
- [ ] Checkpoint 3: strict check 0/0, E2E transcript, spelling, PR to `dev` (merge on instruction only).
- [ ] Deferred, separate plan: B (bootstrap tolerance) and E (refit `h0` for the observed statistic).

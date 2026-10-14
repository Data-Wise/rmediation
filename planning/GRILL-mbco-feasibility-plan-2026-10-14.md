# GRILL — PLAN-34 (issue #34, MBCO feasibility tolerance)

**Target:** `planning/PLAN-34-mbco-feasibility-tolerance-2026-10-14.md`
**Date:** 2026-10-14. Interactive grill, one question at a time, `--no-refine`.

## Decisions

| # | Branch | Decision | Consequence |
|---|---|---|---|
| 1 | Weakest recommendation: option E (refit `h0` in bootstrap paths) | No. Build the guard (A) and docs (C) only; defer B (bootstrap tolerance) and E | No returned number changes; users are told, not silently corrected; bootstrap warnings/errors at the default tolerance remain |

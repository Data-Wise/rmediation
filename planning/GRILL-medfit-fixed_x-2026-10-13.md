# GRILL: medfit `fixed_x` with per-variable selection

Date: 2026-10-13. Target: `PROPOSAL-medfit-fixed_x-2026-10-13.md` (evidence: `RESEARCH-medfit-fixed_x-selection-2026-10-13.md`).
Scope: decisions for the request to the medfit author. Nothing implemented; nothing written in medfit.

## Decisions

| # | Branch | Decision | Overrode recommendation? |
|---|---|---|---|
| 1 | Benefit honesty: what does selection buy? | **Many covariates: fix them, keep the exposure random.** Benefit measured, see below | No |
| 2 | Conflicts with explicit user statements (`x ~~ 2*x`, shared label, `x ~ 1`) | **Error naming the conflicting term** | No |
| 3 | Which logLik | **Conditional on the fixed block (lavaan parity); refuse `anova()`/AIC comparisons across different fixed sets** | No |
| 4 | Meaning of "fixed.x completed" for the CRAN hold | **Option C (fixed_x with variable selection) shipped in medfit** | No |
| 5 | Default | **`FALSE` (current behavior); revisit at 1.0** | No |

## Evidence added in this grill (benefit of fixing many covariates)

medfit 0.7.0 native engine, n = 500, expected information, exogenous moments free vs fixed at sample values
(emulated with medfit's own fixed-value syntax; the real argument was not tested). `ab` and its SE agree to
2e-9 and 3e-10 in every row; all fits converged.

| Covariates | Free parameters (free -> fixed) | Time free | Time fixed | Speedup |
|---|---|---|---|---|
| 5 | 36 -> 16 | 0.02 s | 0.01 s | 1.4x |
| 10 | 91 -> 26 | 0.05 s | 0.03 s | 2.0x |
| 20 | 276 -> 46 | 1.15 s | 0.11 s | 10.5x |
| 30 | 561 -> 66 | 8.98 s | 0.18 s | 49x |

Caveat: one simulated design; installed medfit is 0.7.0, not 0.8.0; timing depends on hardware and settings.

## Consequences

- The hold's `fixed.x` clause now waits for Option C to ship in medfit. That adds delay only if medfit sequences it
  after 0.11.0; the request should ask for early placement (after the 0.9.0 G8 `anova()` fix).
- Branch 3 means `mbco()` product-null fits must share `fixed_x` with the full fit (they do by construction when the user passes one value).
- Branch 2 forces a validation step that detects explicit statements, labels and constraints touching selected variables.

## Open questions

- Which medfit release carries it (author's call); whether it counts toward "non-experimental".
- Benchmark on the real implementation, and with weights and mean structure (0.9.0).
- Whether to flip the default to `TRUE` later (revisit at 1.0).

## 2026-10-13 medfit session reply (information only)

medfit session reply 2026-10-13 (information only; the medfit author has not decided): (1) placement undecided; early placement is not free because fixed_x touches `.sem_complete`, `.sem_df`, the logLik method and `anova()`, the same code 0.9.0 T2/T3/T5 rewrite (df rule p(p+1)/2 + p, anova across mean-structure status), so building it first would force those tasks to be redone; after 0.9.0 T3/T5 or as a 0.9.x on top of 0.9.0 avoids that. The G8 `anova()` nesting fix is Data-Wise/medfit PR #171 (unmerged, CI running); 'refuse anova() across different fixed sets' would sit on top of its nesting check. (2) semantics not reviewed; two traps match known medfit facts (fixed exogenous moments must be excluded from the df rule; `.sem_complete` pairing drops free exogenous covariances when any `~~` statement touches a variable); explicit-statement error and conditional logLik are open for the author. (3) nothing decided on dropping the 'experimental' label; fixed_x alone would not settle it. Revised expectation: place after 0.9.0 T3/T5 or as 0.9.x, not before; the hold's exit remains driven by medfit's release plan.

**Effect on this ledger:** the Consequences bullet asking for early placement (after the G8 fix) is superseded:
place it after 0.9.0 T3/T5 or as a 0.9.x on top of 0.9.0, to avoid redoing the mean-structure tasks. The five decisions above stand; the author has not yet accepted or changed them.

**Update 2026-10-13 19:26Z (observed):** medfit PR #171 (G8 `anova()` fix) merged to medfit `dev` as `5ebdecf`. `fixed_x` is still not started or placed; no release named for dropping "experimental".

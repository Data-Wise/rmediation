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

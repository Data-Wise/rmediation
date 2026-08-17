# SPEC-27 — `pprodnormal3()` integrator rewrite (partition + Gauss–Legendre)

**Issue:** [#27](https://github.com/Data-Wise/rmediation/issues/27)
**Branch:** `feature/prod3-illconditioned`
**Status:** design settled, implementation in progress
**Created:** 2026-08-16

---

## Context

`pprodnormal3()` silently returns materially wrong probabilities when the
`(X, Y)` covariance block is ill-conditioned. Reproduced against the installed
CRAN build 1.6.1; `git log fb370dd..HEAD -- R/` is empty, so the source on `dev`
is identical to what was tested.

The failure is already documented in the roxygen `@note` at `R/prod3_core.R:85-87`
("accuracy can degrade as the standardized `(X, Y)` correlation approaches ±1")
but nothing detects it at runtime — no warning, no error estimate, no diagnostic.
Documented-but-silent is the core defect.

### Why it shipped

`tests/testthat/test-product-normal3.R:91-99` is named
*"p_prod3 handles near-singular covariance"*, runs ρ = 0.99, and asserts only
`expect_no_error()` plus `0 ≤ p ≤ 1`. The one test that checks accuracy
(line 39, `expect_lt(abs(diff), 5e-3)`) runs at ρ ≤ 0.3. The failure mode had a
test that never looked at the value.

---

## Evidence

All figures from spikes in the session scratchpad, reproducible from
`spike-prod3.R`, `spike-prod3b.R`, `spike-prod3c.R` + `gl-helpers.R`.

A **parity gate** confirms the spike's vectorized integrand matches the package's
own `.prod3_integrand_2d()` to 1.3e-14, so these results test the package's
math, not a reimplementation.

### The reporter's fix #1 (partitioning alone) is insufficient

ρ = 0.999, q = 0.5, κ(Σ) = 2411:

| approach | value | abs. error vs GL-1024 |
|---|---|---|
| hcubature, whole plane (**current**) | 0.6109671 | 1.96e-01 |
| hcubature, 4 quadrants (issue's fix #1) | 0.7480058 | **5.87e-02 — still 7.3% wrong** |
| Gauss–Legendre n=256 on partitioned cells | 0.80671500 | **2.6e-08** |

### Partitioning is mandatory *for* Gauss, not an alternative to it

Unpartitioned Gauss–Legendre is catastrophic — it does not resolve the
`sign(x*y)` kink at the coordinate axes:

| n | partitioned | unpartitioned |
|---|---|---|
| 128 | 0.8083843 | **2.1056221** (not a probability) |
| 256 | 0.80671500 | 1.0646312 |
| 512 | 0.80671502 | 0.8077682 |

### The bug is wider than the issue reported

The issue tested only q = 0.5. At ρ = 0.999 the current integrator is wrong at
**every** q tested. `confint()` / `ci()` invert this CDF repeatedly, so they
inherit the error:

| q | GL-1024 (reference) | current hcubature | abs. error |
|---|---|---|---|
| −2.0 | 0.05711903 | 0.0044691 | 5.26e-02 (**92% relative**) |
| −0.5 | 0.16636496 | 0.0343979 | 1.32e-01 |
| 0.0 | 0.49727060 | 0.3445185 | 1.53e-01 |
| 0.5 | 0.80671502 | 0.6109671 | 1.96e-01 |
| 2.0 | 0.92056384 | 0.6506248 | 2.70e-01 |

### Gauss dominates hcubature everywhere, and is faster

n=256, q=0.5, error vs GL-1024:

| ρ | κ(Σ) | gauss | hcubature |
|---|---|---|---|
| 0.5 | 4 | ~1e-14 | 4.0e-06 |
| 0.99 | 239 | ~1e-14 | 5.4e-03 |
| 0.999 | 2411 | 2.6e-08 | 1.96e-01 |
| 0.9999 | 24139 | 2.1e-03 (needs n=512) | **5.56e-01** |

Cost: gauss n=256 = 0.033 s, n=512 = 0.181 s, hcubature = 0.733 s.

### Reference values are pinned to GL self-consistency, not Monte Carlo

Monte Carlo at n=1e7 has 3 SE ≈ 3.7e-04 — too noisy to pin a regression test.
Two different seeds disagree by 5.4e-05, which is larger than the errors being
measured. GL is self-consistent to machine precision instead:

| ρ | \|GL256 − GL512\| | \|GL512 − GL1024\| |
|---|---|---|
| 0.5 | 2.8e-14 | 1.3e-13 |
| 0.99 | 7.2e-15 | 4.9e-14 |
| 0.999 | 2.6e-08 | 1.7e-14 |
| 0.9999 | **2.1e-03** | 3.0e-07 |

MC is used only as an independent sanity bound: all four (ρ, seed) checks land
within 3 SE of GL-1024.

**Consequence for design:** the ρ=0.9999 row shows n=256 is *not* converged
there — and that the 256↔512 gap *detects* it. That gap is a genuine error
estimate, which is exactly what `hcubature()`'s `$error` failed to provide in
this failure mode.

---

## Design decisions

| Decision | Choice | Why |
|---|---|---|
| Default integrator | **`method = "gauss"`** | Needs no κ threshold to get right; matches hcubature to ~1e-6 on benign input; 22× faster. Error is already real at κ=239, so any threshold would be a guess. |
| Node count | **auto-escalate on self-consistency** | Start n=256, double until \|I(n) − I(2n)\| < tol, cap 2048. Delivers correctness *and* a real error estimate. |
| Domain | **partition at x=0 and y=0 always** | Mandatory for Gauss (see table above); each cell is single-signed and kink-free. |
| hcubature | **retained** as `method = "hcubature"` | Backward compatibility and cross-checking. |
| Truncation bound | **capped, adaptive around the mean** | L=6..12 all give ~5e-07; L=20 degrades to 4.6e-05. Generous is *worse*. |

This is a **behavior change**: benign inputs move by ~1e-6, ill-conditioned
inputs change materially (that is the fix). NEWS.md must say so.

---

## Implementation

**File:** `R/prod3_core.R`

1. Add `.prod3_gauss_legendre(n)` — Golub–Welsch via `eigen()` of the Jacobi
   matrix. No new dependency.
2. Add a vectorized `.prod3_integrand_vec(x, y, ...)` mirroring
   `.prod3_integrand_2d()`. Keep the scalar version for the hcubature path.
   **A test must gate parity between the two** (the spike's parity check,
   promoted into the suite).
3. Add `.prod3_integrate_gauss(p, tol, nodes, max_nodes)` — tensor-product GL
   over the four single-signed cells, with the doubling loop.
4. `pprodnormal3()` signature becomes
   `(q, mean, cov, method = c("gauss", "hcubature"), tol = 1e-6, nodes = NULL)`.
   Replace `match.arg(method, "hcubature")` at line 103 with a real two-value
   `match.arg()`.
5. Keep the returned value a bare numeric in `[0, 1]`; attach the convergence
   diagnostic as `attr(p, "error")` so no caller breaks on the class.
6. Warn when the escalation loop hits `max_nodes` without converging.

**Untouched:** the degenerate-covariance branches (lines 114-135), the PD check
(142-150), and the zero-mean shortcut (152-155). All are orthogonal to this bug.

---

## Test plan

**File:** `tests/testthat/test-product-normal3.R`

1. **Fix the smoke test** at lines 91-99 — assert accuracy, not just bounds.
2. **Regression anchors at ρ = 0.999**, all five q values from the table above,
   asserted against the GL-1024 references to 1e-08. These fail on `main` today.
3. **ρ = 0.9999 escalation test** — assert the result is correct *and* that
   `attr(p, "error")` reflects a converged run.
4. **Parity test** — vectorized vs scalar integrand agree to < 1e-12.
5. **Benign-input non-regression** — ρ ≤ 0.9 results unchanged to 1e-6 under
   the new default, so existing users' numbers do not move.
6. **`method = "hcubature"` still reachable** and still returns its old value.

---

## Release plan

Correctness ships before CRAN etiquette allows a resubmission:

1. Merge to `dev`, tag a GitHub release — affected users get it immediately via
   `remotes::install_github("Data-Wise/RMediation")`.
2. CRAN submission on/after **2026-08-21** (v1.6.1 published 2026-07-21; the
   one-month cadence window opens 5 days from this spec).
3. NEWS.md entry states the default-method change explicitly.

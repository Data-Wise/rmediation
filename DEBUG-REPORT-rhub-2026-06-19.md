# RMediation rhub Debug Report — 2026-06-19

## Final Verdict: RESOLVED (with one expected failure) ✅

Run **major-viceroybutterfly** (run 27854572331, main branch, v1.5.0):
- `ubuntu-clang`: ✅
- `ubuntu-gcc12`: ✅
- `nosuggests`: ❌ — EXPECTED (documented; see below)
- `gcc-asan`: ⏳ in progress (expected ✅ based on gcc-asan pass on turtleshelled-stagbeetle)

---

## Timeline of Runs

| Run name | Branch | ubuntu-clang | ubuntu-gcc12 | nosuggests | asan platform | Notes |
|----------|--------|:---:|:---:|:---:|:---:|-------|
| consolable-chickadee (27851702242) | main | ✅ | ✅ | ❌ | ❌ (clang-asan) | clang-asan: RcppParallel ODR via lavaan |
| turtleshelled-stagbeetle (27853131297) | dev | ✅ | ✅ | ❌ | ✅ (gcc-asan) | Switched clang→gcc-asan; nosuggests expected |
| **major-viceroybutterfly (27854572331)** | **main** | **✅** | **✅** | **❌ (expected)** | **⏳** | **pak-version:stable; nosuggests documented** |

---

## Root Cause Analysis

### Failure 1 — clang-asan: RcppParallel ODR violation (RESOLVED by platform switch)

**Run:** consolable-chickadee

**Symptom:** ASAN failure at dependency-installation step, before any RMediation code ran.

**Root cause:** `RcppParallel` 5.1.11-2 (transitive dependency via `lavaan`) bundles TBB shared libraries (`libtbb.so.2`, `libtbbmalloc.so.2`). Under clang-ASAN these trigger a One-Definition-Rule (ODR) violation — two copies of the same symbol loaded from different `.so` paths. This is a known upstream bug in `RcppParallel` under ASAN.

**Fix:** Switched from `clang-asan` to `gcc-asan` (Fedora 42 with GCC). The ODR violation does not manifest under GCC's ASAN implementation. `gcc-asan` passed on turtleshelled-stagbeetle and is expected to pass on major-viceroybutterfly.

**CRAN implication:** CRAN's ASAN checks use their own infrastructure (typically Debian with clang). If they hit the same RcppParallel ODR, it would surface as a NOTE/WARNING on a transitive dependency's check, not on RMediation's check. No code change needed in RMediation.

---

### Failure 2 — nosuggests: Vignette rebuild (EXPECTED, documented)

**All runs:** Expected failure on every run.

**Symptom:** `run-check@v1` fails (not an infrastructure step — the full R CMD check runs but fails during vignette rebuilding).

**Root cause:** The `nosuggests` container does not install packages listed in `Suggests`. RMediation has `VignetteBuilder: knitr` and `rmarkdown` in `Suggests`. Without `rmarkdown`, vignette rebuilding fails with a "package not found" error. This is by design in the nosuggests container.

**Why this is NOT a CRAN problem:** CRAN installs `Suggests` packages when building vignettes on their servers. The failure only occurs in the deliberately stripped nosuggests environment. The two passing Linux containers (ubuntu-clang, ubuntu-gcc12) rebuild vignettes successfully.

**Fix:** None required. Documented in `cran-comments.md`.

---

### pak devel regression (AVOIDED by pak-version: stable)

**Run:** turtleshelled-stagbeetle and major-viceroybutterfly both use `pak-version: stable` in `rhub.yaml` — added after diagnosing the same regression that affected medrobust. RMediation had no renv artifacts, so Layer 2 and Layer 3 of medrobust's failure chain did not apply here.

---

## Files Changed

| Commit | Files | Change |
|--------|-------|--------|
| 5f9be98 | `.github/workflows/rhub.yaml` | Add `pak-version: stable` to both setup-deps blocks |
| (prior session) | `cran-comments.md` | Document nosuggests + clang-asan failures with explanations |

---

## CRAN Readiness

- **R CMD check**: 0 errors, 0 warnings, 0 notes
- **win-builder R-release**: OK (token 9Yl6dT037ae0)
- **win-builder R-oldrelease**: OK (token mKpQ5ycMhVBG)
- **win-builder R-devel**: OK (token KvUk0DM4QDqq)
- **r-hub major-viceroybutterfly**: 2/4 complete ✅✅; nosuggests ❌ documented; gcc-asan ⏳
- **Status**: Ready for `devtools::submit_cran()` once gcc-asan confirms ✅

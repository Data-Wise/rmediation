# ORCHESTRATE: ProductNormal3 S7 class for product-of-three normals

> Feature branch: `feature/product-normal3`
> Worktree: `~/.git-worktrees/rmediation/feature-product-normal3`
> Source issue: Data-Wise/rmediation#18
> Status: plan complete; implementation requires a new session in the worktree

## Goal

Add exact CDF computation for sequential indirect effects of the form `a1 * a2 * b`,
where `(a1, a2, b)` follows an asymptotic trivariate normal distribution. Expose it
as a new S7 class `ProductNormal3` with `confint()` and `print()` methods.

## Why now

Issue #18 originally listed the prod3 manuscript submission as a blocker. That
blocker has been waived by project decision; implementation can proceed with the
algorithm described in the issue body.

## Non-goals

- Do NOT change existing `ProductNormal` two-variable code.
- Do NOT promote `cubature` beyond `Imports`.
- Do NOT break the existing API or test suite.

## Architecture

### New files

| File | Purpose |
|------|---------|
| `R/00_classes.R` | Add `ProductNormal3` S7 class |
| `R/ProductNormal3_methods.R` | `confint()` and `print()` S7 methods |
| `R/prod3_core.R` | CDF engine `p_prod3()` and helpers |
| `tests/testthat/test-product-normal3.R` | Unit + integration tests |
| `NEWS.md` | v1.6.0 entry |

### Modified files

| File | Change |
|------|--------|
| `DESCRIPTION` | Add `cubature (>= 2.1.0)` to `Imports`; bump `Version:` to `1.6.0` |
| `NAMESPACE` | Regenerate via `devtools::document()` — exports S7 class/methods |

### S7 class design

```r
ProductNormal3 <- new_class(
  "ProductNormal3",
  properties = list(
    mean   = class_numeric,   # length 3: c(a1_hat, a2_hat, b_hat)
    cov    = class_matrix,    # 3x3 asymptotic covariance
    method = class_character  # "hcubature" (default) | "cuhre"
  )
)
```

### Core engine

```r
p_prod3(q, mean, cov, method = "hcubature", tol = 1e-6)
```

- Validate inputs: `length(mean) == 3`, symmetric positive-definite `cov`.
- Standardise internally to correlation parameterisation.
- Compute `P(a1 * a2 * b <= q)` via the conditional-expectation dimension-reduction
  double integral from the prod3 algorithm.
- Dispatch to `cubature::hcubature()` or `cubature::cuhre()` based on `method`.

## Implementation phases

### Phase 1 — Scaffold

1. Add `cubature` to `DESCRIPTION` `Imports`.
2. Bump `Version:` to `1.6.0`.
3. Define `ProductNormal3` class in `R/00_classes.R`.
4. Add `print()` method in `R/ProductNormal3_methods.R`.

### Phase 2 — Core engine

1. Implement `p_prod3()` in `R/prod3_core.R`.
2. Internal helpers for conditional mean/variance and integration limits.
3. Handle edge cases:
   - zero-mean symmetric distribution → `P(V <= 0) == 0.5`
   - near-zero covariance determinants
   - out-of-support `q` values

### Phase 3 — `confint()` method

1. Implement `confint(ProductNormal3, level = 0.95, ...)`.
2. Use `stats::uniroot()` to invert `p_prod3()` for quantiles.
3. Provide sensible search intervals based on mean and covariance.

### Phase 4 — Tests

1. Unit tests for `p_prod3()`:
   - symmetry test (zero mean)
   - agreement between `hcubature` and `cuhre`
   - Monte Carlo ground-truth comparison (n = 1e6, tolerance 1e-4)
2. Integration tests:
   - construct from a lavaan serial-mediation fixture
   - `confint()` returns valid interval
3. Test coverage target: ≥90% on new files.

### Phase 5 — Documentation

1. Add roxygen docs for class, methods, and `p_prod3()`.
2. Run `devtools::document()` to regenerate `NAMESPACE` + `man/`.
3. Add `NEWS.md` entry for v1.6.0.

### Phase 6 — CRAN gate

Run the `r-dev-workflow` dev cycle until clean:

```r
devtools::document()
lintr::lint_package()
testthat::test_local()
rcmdcheck::rcmdcheck(args = "--as-cran")
```

Then run the strict pass:

```r
rcmdcheck::rcmdcheck(
  args = "--as-cran",
  env = c("_R_CHECK_DEPENDS_ONLY_" = "true")
)
rcmdcheck::rcmdcheck(
  args = "--as-cran",
  env = c("_R_CHECK_SUGGESTS_ONLY_" = "true")
)
```

Target: 0 errors / 0 warnings / 0 notes.

## Acceptance criteria

- [ ] `confint(ProductNormal3(...))` matches MC ground truth (n = 1e6) within 1e-4
- [ ] `P(V <= 0) == 0.5` exactly for zero-mean symmetric distributions
- [ ] Both `"hcubature"` and `"cuhre"` methods produce consistent results
- [ ] End-to-end test passes with a lavaan serial-mediation fixture
- [ ] `R CMD check --as-cran`: 0 errors / 0 warnings / 0 notes
- [ ] Test coverage ≥90% on new files
- [ ] `NEWS.md` updated with v1.6.0 entry

## Risks and mitigations

| Risk | Mitigation |
|------|------------|
| `cubature` integration slow or unstable | Expose `tol` and `method`; default to robust `hcubature` |
| Confusing S7 dispatch under `R CMD check` | Follow `.onLoad()` registration order (`S4_register` → `methods_register`) |
| Existing tests regress | Run full suite after every phase; diff-aware baseline if needed |
| CRAN NOTE from new dependency | `cubature` is on CRAN; keep it in `Imports` with version pin |

## Verification gates

1. **Phase gate after Phase 2:** `p_prod3()` passes symmetry + method-agreement tests.
2. **Phase gate after Phase 4:** Full test suite passes; coverage ≥90% on new files.
3. **Final gate:** `R CMD check --as-cran` clean and strict passes clean.

## Stop rule

Do NOT begin implementation in this session. The next session must start in the
worktree directory `~/.git-worktrees/rmediation/feature-product-normal3`.

## Session handoff

Next session command (for the user):

```bash
cd ~/.git-worktrees/rmediation/feature-product-normal3
```

Then continue with Phase 1.

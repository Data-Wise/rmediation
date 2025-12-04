# CLAUDE.md for RMediation Package

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## About This Package

**RMediation** provides confidence intervals for nonlinear functions of model parameters (e.g., indirect effects) in mediation analysis. It implements parametric, semiparametric, and non-parametric methods with emphasis on exact distribution theory and robust bootstrap procedures.

### Core Mission

Provide statistically rigorous tools for quantifying mediation mechanisms through Distribution of Product (DOP), Model-Based Constrained Optimization (MBCO), and Monte Carlo methods.

### Key Methods

| Method | Description | Use When |
|--------|-------------|----------|
| **DOP** | Exact distribution of product | Accuracy matters, two-variable product |
| **MC** | Monte Carlo sampling | Flexibility needed, complex functions |
| **MBCO** | Bootstrap chi-squared tests | Hypothesis testing for indirect effects |
| **Asymptotic** | Delta method (Sobel) | Quick approximation (not recommended for inference) |

---

## Common Development Commands

```r
# Install dependencies and check package
remotes::install_deps(dependencies = TRUE)
rcmdcheck::rcmdcheck(args = "--no-manual", error_on = "error")

# Development workflow
devtools::load_all()
devtools::document()
devtools::test()
```

---

## Coding Standards

### R Version and Style

- **Minimum R version**: 3.5.0
- **Style**: Mixed camelCase and snake_case (legacy codebase)
- **Functional approach**: Vectorize operations, avoid loops
- **Namespacing**: Use explicit `package::function()` for non-base functions

### Naming Conventions (Current Codebase)

| Type | Convention | Examples |
|------|------------|----------|
| Main functions | camelCase | `medci()`, `qprodnormal()`, `pprodnormal()` |
| Internal helpers | camelCase lowercase | `medciMeeker()`, `medciMC()` |
| Arguments | dot.case | `mu.x`, `mu.y`, `se.x`, `se.y`, `rho` |

**Note**: When adding new functions, maintain consistency with existing patterns.

---

## Code Architecture

### Core Functions

| Function | Purpose | Use For |
|----------|---------|---------|
| `medci()` | Product a*b CIs | Two-variable indirect effects |
| `ci()` | General nonlinear function CIs | Complex mediation models, formulas |
| `mbco()` | Bootstrap chi-squared tests | Hypothesis testing H₀: indirect = 0 |

### Distribution Functions

- `pprodnormal()` / `qprodnormal()`: CDF and quantile for product of two normals
- `pMC()` / `qMC()`: Monte Carlo-based for arbitrary functions

### Key Dependencies

- **lavaan**: SEM parameter extraction
- **OpenMx**: For MBCO model-based tests
- **MASS**: Multivariate normal sampling
- **doParallel/foreach**: Parallel bootstrap

---

## Testing Strategy

### Coverage Targets

- **Target**: >80% overall
- Compare to published examples (MacKinnon et al. 2007, Tofighi & MacKinnon 2011)
- Test CI method consistency (DOP ≈ MC for large n.mc)
- Test edge cases: small n, high correlation rho, near-zero effects

---

## Ecosystem Coordination

RMediation is an **application package** in the mediationverse ecosystem.

### Central Planning

Ecosystem coordination managed in `/Users/dt/mediation-planning/`:
- `ECOSYSTEM-COORDINATION.md` - Version matrix, release timeline
- `MONTHLY-CHECKLIST.md` - Health checks

### Related Packages

| Package | Repository | Purpose | Website |
|---------|-----------|---------|---------|
| mediationverse | https://github.com/data-wise/mediationverse | Meta-package (loads all) | https://data-wise.github.io/mediationverse/ |
| medfit | https://github.com/data-wise/medfit | Foundation (model fitting, extraction) | https://data-wise.github.io/medfit/ |
| probmed | https://github.com/data-wise/probmed | P_med effect size | https://data-wise.github.io/probmed/ |
| medrobust | https://github.com/data-wise/medrobust | Sensitivity analysis | https://data-wise.github.io/medrobust/ |
| medsim | https://github.com/data-wise/medsim | Simulation infrastructure | https://data-wise.github.io/medsim/ |

### Integration with medfit (planned)

- Model extraction will use medfit infrastructure
- Bootstrap utilities may be shared
- S7 classes may inherit from medfit base classes

---

## Key References

- Craig (1936): Frequency function of product of two normals
- MacKinnon et al. (2007): PRODCLIN distribution of product
- Meeker & Escobar (1994): CDF computation algorithm
- Tofighi & MacKinnon (2011): RMediation R package
- Tofighi (2020): MBCO bootstrap methods

---

**Last Updated**: 2025-12-04

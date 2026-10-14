# GRILL — pprodnormal3() with two or more zero-variance components (issue #64), 2026-10-14

Evidence (probe, mean (.5,.4,.3)): all-zero Sigma returns 0 for every q (truth: step at 0.06); diag(0,0,.01) errors "non-finite function value"; diag(0,.01,0) and diag(.01,0,0) return 0 for every q. Variance 1e-14 per component is NOT silent: Gauss-Legendre warns it hit the node cap with a gap up to 0.858.

| Q | Decision | Recommended? |
|---|---|---|
| 1 Scope | Exact closed form for >= 2 zero-sd components, before the single-zero branches | yes |
| 2 Atom convention | Right-continuous: CDF = 1 at and above a point mass, matching the existing `as.numeric(q >= 0)` branches except an atom at exactly 0, which keeps the existing 0.5-at-q=0 convention pinned by test-product-normal3.R:89 (found when the first implementation broke that test) | yes |
| 3 Formulas | Two fixed components: product = c * X, c = product of fixed means, X ~ N(m, s^2); c = 0 gives a point mass at 0; else pnorm((q/c - m)/s) (flipped when c < 0). All three fixed: step at prod(mean) | yes |
| 4 Near-degenerate | Out of scope: already warns, not silent | yes |

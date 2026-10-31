# RMediation Technical Notes

Why three behaviors work the way they do. Each section states the rule,
the reason, and where it is tested.

## 1. `pprodnormal3()` uses Gauss-Legendre by default

**Rule.** `pprodnormal3(method = "gauss")` is the default:
tensor-product Gauss-Legendre quadrature on a domain split at the
coordinate axes, with the node count increased until successive rules
agree to `tol`.

**Reason.** The adaptive `"hcubature"` method returned silently wrong
values on an ill-conditioned covariance matrix: 24% error at a
correlation of 0.999 (up to 92% relative in the lower tail), and exactly
`0` at large standardized means. It is kept only for cross-checking.

``` r

cv <- diag(c(0.05, 0.04, 0.03)^2)
p <- pprodnormal3(0.1, mean = c(0.4, 0.5, 0.6), cov = cv, diagnostics = TRUE)
c(probability = as.numeric(p), error = attr(p, "error"), nodes = attr(p, "nodes"))
#>  probability        error        nodes 
#> 1.422054e-01 1.387779e-16 2.560000e+02
```

Two details look like bugs and are not. The truncation bound is derived
from a tail-mass argument, not tuned, because truncation error is a bias
and a self-consistency check cannot see a bias. The domain splits at 0
even when the mean lies beyond the bound; one cell then has reversed
limits and negative weights, and the two cells telescope to the intended
box.

## 2. `mbco()` and OpenMx’s dropped constraint (OpenMx#433)

**The problem.** OpenMx silently drops an equality constraint whose
Jacobian is exactly zero at the starting values (OpenMx/OpenMx#433). A
product constraint `a*b == 0` started at `a = b = 0` is such a
constraint: the null model is fitted without it, so the statistic is `0`
with a status of 0.

**What
[`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md)
does.** After fitting,
[`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md)
checks h0 for a violated constraint. It warns
(`RMediation_constraint_violation`), refits h0 at a tighter feasibility
tolerance, and uses the refit statistic. If the refit cannot repair the
violation, the call stops (`RMediation_h0_refit_failed`) rather than
return an understated number.

**Why the warning is named “not enforced”.** When h0’s fit equals h1’s
fit although a constraint was violated,
[`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md)
signals `RMediation_constraint_not_enforced`. A fitted h0 keeps no
starting values, so the function cannot tell a dropped constraint from a
violation that OpenMx accepted within its feasibility tolerance (default
0.05). The name and the message say only what is observable: the
constraint may not have been enforced.

**What to use for a product null.**
[`mbco_product_null()`](https://data-wise.github.io/rmediation/reference/mbco_product_null.md)
fixes one path at 0 per branch, runs
[`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md) on
each, and returns the branch with the largest p-value. A test of a union
of nulls rejects only if every single-path null is rejected (an
intersection-union test), and fixing a parameter is exact, so neither
the dropped-constraint problem nor the wrong-branch problem arises.

## 3. The bootstrap p-value and failed replicates

**Rule.** For `type = "semi"` and `type = "parametric"`, the p-value is
the proportion of kept replicate statistics strictly above the observed
statistic:

``` math
p = \frac{\#\{\text{kept replicates with } T^* > T_{\text{obs}}\}}{\#\{\text{kept replicates}\}}
```

There is no `+1` correction. This is the rule OpenMx’s
`mxCompare(boot = TRUE)` used.

**Dropped replicates.** A replicate whose OpenMx fit did not converge is
dropped, up to 5% of `R`; exactly 5% is allowed. Above that the call
stops with `RMediation_bootstrap_too_many_dropped`. The count is
reported in `result@dropped`. With fewer than 20 replicates a single
drop already exceeds 5%.

**What is never dropped.** A replicate whose constraint violation cannot
be repaired stops the call (`RMediation_bootstrap_infeasible`), as do a
non-finite or a negative statistic. An infeasible fit understates the
statistic, so it is not a draw from the null distribution, and dropping
it would bias the p-value downward.

**Example of the arithmetic.** With 100 replicates, 4 dropped, 24 of the
96 kept above the observed value, and 10 of the kept tied with it:
`p = 24 / 96 = 0.25`. A denominator of 100 would give `0.24`, and `>=`
would count the ties and give `34 / 96`. The package tests pin this
case.

## 4. The exact CDF of a product of two normals, and its perfectly correlated case

**Rule.**
[`pprodnormal()`](https://data-wise.github.io/rmediation/reference/pprodnormal.md)
and
[`qprodnormal()`](https://data-wise.github.io/rmediation/reference/qprodnormal.md)
with `type = "dop"` compute the CDF of `a*b` by one-dimensional
integration of the bivariate normal (Meeker and Escobar, 1994). When
`|rho| = 1` the two factors are linear in one standard normal variable,
so `a*b` is a quadratic in it and the CDF has a closed form from the
roots of that quadratic. The package uses the closed form, not a step
integral.

**Reason.** A step integral at `|rho| = 1` was off by up to 4.3e-5 and
once stopped with “probably divergent”. The closed form is exact, and
every one of the 495 evaluations in the article’s test domain now
succeeds.

``` r

set.seed(1)
z <- rnorm(2e6)
a <- 0.3 + 0.2 * z   # mu.x = 0.3, se.x = 0.2
b <- 0.5 + 0.1 * z   # mu.y = 0.5, se.y = 0.1, perfectly correlated with a
q <- c(0.05, 0.15, 0.30)
rbind(
  exact      = pprodnormal(q, 0.3, 0.5, 0.2, 0.1, rho = 1),
  simulation = vapply(q, function(v) mean(a * b <= v), 0)
)
#>                 [,1]     [,2]      [,3]
#> exact      0.1863292 0.500000 0.8413447
#> simulation 0.1863300 0.499953 0.8412675
```

The exact row and the simulated row agree to Monte Carlo error (about 3
decimals at this sample size).

## 5. Point masses: a zero standard error

**Rule.** A factor with zero standard error is a constant, so the
product is either a constant or a scaled normal.
[`pprodnormal()`](https://data-wise.github.io/rmediation/reference/pprodnormal.md)
returns the exact answer there, and the CDF of a point mass is
right-continuous: at an atom at `q`, `P(X <= q) = 1`.

**Reason.** A CDF is right-continuous by definition. Earlier versions
returned `0.5` at an atom at 0, which is the midpoint convention, not a
CDF. The change is in NEWS as a behavior change.

``` r

c(at_atom = pprodnormal(0, 0, 0, 0, 0),
  just_below = pprodnormal(-1e-9, 0, 0, 0, 0))
#>    at_atom just_below 
#>          1          0

# One fixed factor: the product is normal(mu.x * mu.y, (mu.x * se.y)^2)
c(pprodnormal = pprodnormal(0.1, 0.3, 0.5, 0, 0.1),
  normal      = pnorm(0.1, mean = 0.3 * 0.5, sd = 0.3 * 0.1))
#> pprodnormal      normal 
#>  0.04779035  0.04779035
```

[`pprodnormal3()`](https://data-wise.github.io/rmediation/reference/pprodnormal3.md)
follows the same rule with two or three zero-variance components (issue
\#64).

## 6. The densities

**Rule.**
[`dprodnormal()`](https://data-wise.github.io/rmediation/reference/dprodnormal.md)
is the exact density of the product of two normals, and
[`dprodnormal3()`](https://data-wise.github.io/rmediation/reference/dprodnormal3.md)
of three. For two normals with zero means the density is a Bessel `K0`
expression; otherwise it is a one-dimensional integral (Rohatgi; Glen).
The three-factor density is a one-dimensional integral of the two-factor
density conditioned on the first factor. At exactly 0 the density is
infinite for zero means, and
[`dprodnormal()`](https://data-wise.github.io/rmediation/reference/dprodnormal.md)
returns `Inf` there.

**Reason.** A closed form exists only for the zero-mean case. The
integral form is exact up to the integration tolerance, and it is
checked against a finite difference of the CDF.

``` r

h <- 1e-5
c(density = dprodnormal(0.1, 0.3, 0.5, 0.2, 0.1),
  numerical_derivative =
    (pprodnormal(0.1 + h, 0.3, 0.5, 0.2, 0.1) -
     pprodnormal(0.1 - h, 0.3, 0.5, 0.2, 0.1)) / (2 * h))
#>              density numerical_derivative 
#>             3.719755             3.719755
```

## Where each rule is tested

| Rule | Test file |
|----|----|
| bootstrap p-value and bounded drops | `tests/testthat/test-mbco-bounded-replicates.R` |
| not-enforced warning | `tests/testthat/test-mbco-constraint-not-enforced.R` |
| `scripts/verify-constraint-not-enforced.R` | known answer plus planted defect, per optimizer |
| exact CDF, `\|rho\| = 1` | `tests/testthat/test-dop-meeker-article.R` |
| zero standard error, point masses | `tests/testthat/test-zero-se-cdf.R`, `tests/testthat/test-prod3-pointmass.R` |
| densities | `tests/testthat/test-dprodnormal.R`, `tests/testthat/test-dprodnormal3.R` |

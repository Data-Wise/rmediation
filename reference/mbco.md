# Model-based Constrained Optimization (MBCO) Chi-squared Test

This function computes asymptotic MBCO chi-squared test for a smooth
function of model parameters including a function of indirect effects.

## Usage

``` r
mbco(h0, h1, ...)
```

## Arguments

- h0:

  A fitted restricted `OpenMx` model or medfit `SEMFit` under the null
  hypothesis.

- h1:

  A fitted full model of the same class as `h0`, under the alternative
  hypothesis.

- ...:

  Additional arguments.

## Value

An object of class `MBCOResult` containing

- statistic:

  asymptotic chi-squared test statistic value

- df:

  chi-squared df

- p_value:

  chi-squared p-value computed based on the method specified by the
  argument `type`

- type:

  The type of test performed

## Details

**Two medfit SEMFits (medfit \>= 0.8.0).** Supply the already-fitted
restricted model as `h0` and the full model as `h1`. Only
`type = "asymp"` is supported; `alpha` is validated as for OpenMx. The
adapter compares the fits through `stats::anova(h1, h0)` and uses the
degrees-of-freedom difference. It never refits. Bootstrap types, mixed
model classes, OpenMx-only fitting controls (`R`, `checkHess`,
`checkSE`, `optim`, `precision`) and unused dots are rejected. This
route does not require OpenMx.

medfit checks convergence, identical data and observed variables,
unweighted fits, and parameter-table nesting. The analyst must establish
substantive nesting and a valid chi-square reference distribution;
arbitrary nonlinear restrictions do not necessarily have one. An active
tested bound or inequality at the null causes an error here because the
ordinary chi-square p-value is invalid. Other medfit warnings propagate.

For a product-zero null, `medfit::fit_sem()` with `a*b == 0` fits one
branch per factor from clean starts and selects the smallest
discrepancy. Pass that fitted null and the full fit to `mbco()`. medfit
is optional: this route needs 0.8.0 or later (GitHub/r-universe);
existing
[`ci()`](https://data-wise.github.io/rmediation/reference/ci.md)
integration needs only 0.2.0. No change to the CRAN dependency minimum
is implied.

OpenMx comparisons require a finite nonnegative observed statistic and a
positive degrees-of-freedom difference: supply the restricted model as
h0 and the full model as h1. Equal-df and reversed pairs error before
bootstrap sampling. These checks do not establish substantive model
nesting.

OpenMx bootstrap methods restore global options on success and error.
Set a seed before calling for reproducibility; bootstrap sampling
consumes the current RNG stream. The semiparametric method requires
positive-definite sample and null covariances. The parametric method
simulates each replicate from the fitted `h0` with
[`OpenMx::mxGenerateData()`](https://rdrr.io/pkg/OpenMx/man/mxGenerateData.html)
(the `mvtnorm` package is required) and fits `h0` and `h1` to it in a
loop the package runs itself, under the same rules as the semiparametric
method; it needs a model with a single raw data set. For both bootstrap
types a replicate whose fits did not converge is left out of the null
distribution, and the `dropped` slot of the result counts them. If more
than 5% of the `R` replicates are dropped, the call stops with an error
of class `RMediation_bootstrap_too_many_dropped` (with fewer than 20
replicates no replicate may be dropped). Nothing else is dropped: a
replicate with an unrepairable constraint violation (class
`RMediation_bootstrap_infeasible`), a non-finite statistic, or an h1 fit
worse than its h0 fit stops the call. The p-value is the proportion of
the kept replicates, `R - dropped` of them, whose statistic is strictly
above the observed one, `mean(null > observed)` over the kept
replicates. There is no `(1 + k)/(R + 1)` correction, so it can be
exactly 0 when no kept replicate exceeds the observed statistic.

**Testing an OpenMx product null (\\a b = 0\\).** The null \\ab = 0\\
holds when \\a = 0\\ or \\b = 0\\. A single nonlinear constraint such as
`ind == 0` can converge to either branch, and the optimizer may return
the branch with the larger statistic, which gives a wrong test.
[`mbco_product_null()`](https://data-wise.github.io/rmediation/reference/mbco_product_null.md)
avoids this: give it the fitted full model and the path labels. By hand,
fit one linear null per path (`a == 0` and `b == 0`), run `mbco()` on
each, and report the smaller statistic with 1 degree of freedom (see the
example). The smaller statistic is the exact constrained
likelihood-ratio statistic for \\ab = 0\\. Its chi-square(1) p-value is
conservative when both paths are 0 (an intersection-union test; standard
theory, not verified here).

Build each `h0` from the unfitted model. A constraint refit from the
fitted model's estimates can stop at an infeasible point and return a
statistic of 0.

**Constraint violations and the automatic refit (OpenMx).** OpenMx
accepts a constrained fit whose constraints are violated by up to its
`"Feasibility tolerance"` (default 0.05), which can understate the
statistic (for example 0 where the exact value is 0.4745). Before
comparing, `mbco()` evaluates every equality and inequality constraint
of `h0` and `h1` at the fitted solution. A constraint counts as violated
when its scaled violation, `|lhs - rhs| / max(1, |lhs|, |rhs|)` for
equalities and the wrong-side gap for inequalities, exceeds 1e-6.
Constraints with other operators are skipped; a constraint that cannot
be evaluated is an error naming it.

When `h0` is violated, all three `type`s refit it once from its own
estimates with `"Feasibility tolerance"` set to 1e-8, then use the refit
model for the observed statistic and the bootstrap, and warn with class
`RMediation_h0_refit` (statistic before and after). The `refit` slot of
the result records `tolerance`, `statistic_before` and
`statistic_after`, and is `NULL` when no refit was needed. Your own
model object is not modified. This is the one case where the returned
statistic differs from
[`OpenMx::mxCompare()`](https://rdrr.io/pkg/OpenMx/man/mxCompare.html)
on your fits. If the refit errors, does not converge or leaves the
constraint violated, `mbco()` stops with an error of class
`RMediation_h0_refit_failed` that names the constraint and the reason,
before any bootstrap work and for every `type`: no statistic is returned
from a fit known to be invalid. Refit yourself with
`mxOption(model, "Feasibility tolerance", 1e-8)` or use
[`mbco_product_null()`](https://data-wise.github.io/rmediation/reference/mbco_product_null.md)
for a product null. `h1` is checked and warned about
(`RMediation_constraint_violation`) but never refit. Both bootstrap
types (`"semi"` and `"parametric"`) apply the same checks to every
replicate: a replicate whose `h0` or `h1` fit does not converge stops
the call at the first one (6 of 100 runs in a simulation with
`R = 200`); a replicate null fit that violates its constraint is refit
as above, and one that cannot be repaired stops the call with an error
of class `RMediation_bootstrap_infeasible` instead of entering the null
distribution. (Before 1.8.0 `type = "parametric"` delegated its
bootstrap to `OpenMx::mxCompare(boot = TRUE)`, which does neither.)

**When h0 came back identical to h1.** A refit whose `statistic_before`
is about 0 (\|statistic\| \< 1e-6, h0 and h1 have the same -2LL although
a constraint of `h0` was violated) also raises a warning of class
`RMediation_constraint_not_enforced`, right after `RMediation_h0_refit`.
It means the constraint may not have been enforced. Two causes give this
symptom. OpenMx (2.19.1 and later) silently drops an equality constraint
whose Jacobian row is zero at the starting values, so `b1 * b2 == 0`
started at `b1 = b2 = 0` returns the unconstrained fit
([OpenMx/OpenMx#433](https://github.com/OpenMx/OpenMx/issues/433)); a
violation within the feasibility tolerance looks the same. A fitted `h0`
keeps no starting values, so `mbco()` cannot tell the causes apart and
the warning does not name either one as the cause. The reported
statistic is the refit one. For a product null, skip the problem:
[`mbco_product_null()`](https://data-wise.github.io/rmediation/reference/mbco_product_null.md)
fits exact single-path nulls and never relies on a nonlinear constraint.
The refit and this warning apply to the observed statistic for every
`type`. Both bootstrap types (`"semi"` and `"parametric"`) repeat the
refit on every bootstrap replicate, and a replicate null fit that cannot
be repaired stops the call (see above).

**Wrong-branch check (OpenMx).** A feasible, converged fit of a product
null such as `a*b == 0` can still sit on the larger-statistic branch
(for example `a = 0` when `b = 0` fits far better), which neither the
violation guard nor the refit can see. After the refit, `mbco()`
therefore checks every equality constraint of the `h0` it will use. It
finds the free parameters the constraint depends on (by perturbing each
at the full model's estimates, without parsing the formula), drops the
constraint, fixes each of them at 0 in turn, and refits. If a converged
fit that still satisfies the constraint has a -2LL lower than `h0`'s by
more than 1e-4, `mbco()` warns with class
`RMediation_constraint_branch`, naming the constraint, the parameter and
the gap. It runs once per call for every `type`, costs one extra fit per
involved parameter, and skips (with a message of class
`RMediation_constraint_branch_skipped`) a constraint that depends on
more than 5 parameters. The check is advisory: it never changes the
result and a failure inside it never fails the call. It only searches
fits that fix one involved parameter at 0, so it can show that `h0` is
not the constrained optimum but not that it is. Use
[`mbco_product_null()`](https://data-wise.github.io/rmediation/reference/mbco_product_null.md)
to avoid the problem.

## Author

Davood Tofighi <dtofighi@gmail.com>

## Examples

``` r
if (requireNamespace("medfit", quietly = TRUE) &&
    utils::packageVersion("medfit") >= "0.9.0") {
  d <- as.data.frame(memory_exp)
  d$x <- as.numeric(d$x) - 1
  syntax <- paste("repetition ~ a1*x", "imagery ~ a2*x",
                  "recall ~ cp*x + b1*repetition + b2*imagery", sep = "\n")
  full <- medfit::fit_sem(syntax, d, fixed_x = FALSE, meanstructure = NULL)
  null <- medfit::fit_sem(paste(syntax, "a1*b1 == 0", sep = "\n"), d,
                          fixed_x = FALSE, meanstructure = NULL)
  mbco(null, full) # statistic 0.0831, df 1
}
if (FALSE) { # \dontrun{
data(memory_exp)
memory_exp <- as.data.frame(memory_exp) # mxData() does not accept tibbles
memory_exp$x <- as.numeric(memory_exp$x) - 1 # manually creating dummy codes
endVar <- c("repetition", "imagery", "recall") # endogenous variables (not "x")
manifests <- c("x", "repetition", "imagery", "recall")
full_model <- OpenMx::mxModel(
  "memory_example",
  type = "RAM",
  manifestVars = manifests,
  OpenMx::mxPath(
    from = "x",
    to = endVar,
    arrows = 1,
    free = TRUE,
    values = .2,
    labels = c("a1", "a2", "cp")
  ),
  OpenMx::mxPath(
    from = "repetition",
    to = "recall",
    arrows = 1,
    free = TRUE,
    values = .2,
    labels = "b1"
  ),
  OpenMx::mxPath(
    from = "imagery",
    to = "recall",
    arrows = 1,
    free = TRUE,
    values = .2,
    labels = "b2"
  ),
  OpenMx::mxPath(
    from = manifests,
    arrows = 2,
    free = TRUE,
    values = .8
  ),
  OpenMx::mxPath(
    from = "one",
    to = manifests,
    arrows = 1,
    free = TRUE,
    values = .1
  ),
  OpenMx::mxAlgebra(a1 * b1, name = "ind1"),
  OpenMx::mxAlgebra(a2 * b2, name = "ind2"),
  OpenMx::mxCI("ind1", type = "both"),
  OpenMx::mxCI("ind2", type = "both"),
  OpenMx::mxData(observed = memory_exp, type = "raw")
)
## H0: a1*b1 = 0 holds if a1 = 0 or b1 = 0. Fit one linear null per path and
## report the smaller statistic (what medfit::mbco_sem() automates). A single
## nonlinear null ind1 == 0 can converge to the wrong branch (rmediation#35).
## Build each h0 from the unfitted model: a constraint refit from the fitted
## model's estimates can stop at an infeasible point.
null_a1 <- OpenMx::mxModel(
  model = full_model,
  name = "Null a1 = 0",
  OpenMx::mxConstraint(a1 == 0, name = "a1_eq0_constr")
)
null_b1 <- OpenMx::mxModel(
  model = full_model,
  name = "Null b1 = 0",
  OpenMx::mxConstraint(b1 == 0, name = "b1_eq0_constr")
)
full_model <- OpenMx::mxTryHard(full_model, checkHess = FALSE, silent = TRUE)
null_a1 <- OpenMx::mxTryHard(null_a1, checkHess = FALSE, silent = TRUE)
null_b1 <- OpenMx::mxTryHard(null_b1, checkHess = FALSE, silent = TRUE)
res_a1 <- mbco(null_a1, full_model)
res_b1 <- mbco(null_b1, full_model)
res_a1
res_b1
## Test of H0: a1*b1 = 0 (df = 1): the smaller of the two statistics
min(res_a1@statistic, res_b1@statistic)
## The same test in one call: fixes each path at 0 in a copy of the fitted
## full model and returns the binding branch (here b1, statistic 0.0831)
mbco_product_null(full_model, c("a1", "b1"))
} # }
```

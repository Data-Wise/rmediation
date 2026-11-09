# MBCO on medfit SEM Models

[`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md) can
test a constraint on two models fitted with medfit’s own SEM engine
(`SEMFit` objects) instead of OpenMx. It compares the two fits with a
chi-squared difference test, refits nothing, and needs no OpenMx. This
page shows the route end to end and lists exactly what it refuses. For
the OpenMx route, the bootstrap types and the product null, see [Testing
an Indirect Effect with
MBCO](https://data-wise.github.io/rmediation/articles/mbco.md).

## 1. Fit the pair

Fit the full model (`h1`) and the same model with the constraint added
(`h0`). The restricted model goes first in the
[`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md)
call. Here the null is that the product of two paths is zero,
`a1*b1 == 0`, in the `memory_exp` data that ships with the package:

``` r

d <- as.data.frame(memory_exp)
d$x <- as.numeric(d$x) - 1
syntax <- paste(
  "repetition ~ a1*x",
  "imagery ~ a2*x",
  "recall ~ cp*x + b1*repetition + b2*imagery",
  sep = "\n"
)
full <- medfit::fit_sem(syntax, d, fixed_x = FALSE, meanstructure = NULL)
null <- medfit::fit_sem(
  paste(syntax, "a1*b1 == 0", sep = "\n"), d,
  fixed_x = FALSE, meanstructure = NULL
)
```

Pass `fixed_x` and `meanstructure` yourself. medfit changed their
defaults in 0.15.0 and warns before that, so a call that leaves them out
can change meaning when medfit updates; the values above are the ones
the package’s own tests use.

## 2. Test and read the result

``` r

res <- mbco(null, full)
res
```

With these data the statistic is 0.0831 on 1 degree of freedom,
`p = 0.7731`. The test type is always `"asymp"` here, so the test uses
no random numbers and there is no seed to report. The result is an
ordinary `MBCOResult`: `res@statistic`, `res@df` and `res@p_value` hold
the numbers. Its `@provenance` records the RMediation, medfit and R
versions, which is what to cite; see [Reporting RMediation in a
Paper](https://data-wise.github.io/rmediation/articles/reporting.md).

## 3. What it refuses

Each of these stops with a message, so a mistake is loud:

| You do | You get |
|----|----|
| put the full model first | `h0 must have more degrees of freedom than h1: supply the restricted SEMFit first.` |
| ask for a bootstrap (`type = "semi"` or `"parametric"`) | `Assertion on 'type' failed: Must be element of set {'asymp'}` |
| pass OpenMx controls or any extra argument (`R = 10`) | `unused arguments for SEMFit: OpenMx fitting controls and other dots are not supported.` |
| mix a `SEMFit` with an OpenMx model | `mbco() requires two SEMFit objects or two OpenMx models; mixed pairs are not supported.` |
| use medfit older than 0.8.0 | `mbco() for SEMFit requires medfit >= 0.8.0` |
| test a null that sits on the boundary of the parameter space | `mbco() cannot report a chi-square p-value for a SEMFit null on the boundary`, with medfit’s own explanation appended |

The last row matters most for variance constraints: when the tested
value is a bound, an ordinary chi-squared p-value is not valid, medfit
says so in a warning, and
[`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md)
turns that warning into an error instead of returning a number.

## 4. What stays your responsibility

[`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md)
compares the two fits and checks only what the table above lists. It
does not check that `h0` is nested in `h1` in substance, and it does not
choose a reference distribution: the p-value is the asymptotic
chi-squared one. A null such as `a1*b1 == 0` is a nonlinear constraint,
so decide whether that reference is justified before you report the
p-value. The OpenMx route has a dedicated test for this null,
[`mbco_product_null()`](https://data-wise.github.io/rmediation/reference/mbco_product_null.md),
described in [Testing an Indirect Effect with
MBCO](https://data-wise.github.io/rmediation/articles/mbco.md). The
SEMFit route is described in [Status and
Roadmap](https://data-wise.github.io/rmediation/articles/roadmap.md);
the CRAN question is on hold until a medfit release with the features it
needs is on CRAN.

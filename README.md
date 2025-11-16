# RMediation

Below is the revised README.md file for the RMediation package, incorporating additional features such as MBCO, parametric and semi-parametric bootstrap methods, distribution of the product, and Monte Carlo method for confidence intervals:

# RMediation

RMediation is an R package for conducting mediation analysis in observational studies and experimental designs.
Mediation analysis allows researchers to assess the mechanisms through which an independent variable affects a dependent variable by examining the role of intermediate variables, known as mediators.

## Features

-   Implements various mediation analysis methods, including:
    -   Distribution of the product method CI
    -   Sobel test (asymptotic normal)
    -   Monte Carlo method for confidence intervals
    -   Likelihood ratio test of mediation using Model-based Constraint Optimization, LRT-MBCO
    -   Parametric and semi-parametric bootstrap methods for LRT MBCO
-   Provides functions for estimating direct and indirect effects and confidence intervals.
-   Includes visualization functions for displaying distribution of indirect estimates.

## Installation

You can install the latest version of RMediation from CRAN using the following command:

``` r
install.packages("RMediation")
```

Alternatively, you can install the development version directly from GitHub using the `remotes` package:

``` r
remotes::install_github("quantpsych/RMediation")
```

## Usage

To conduct a basic mediation analysis using RMediation, follow these steps:

1.  Load the RMediation package:

``` r
library(RMediation)
```

There are several scenarios for mediation analysis using the RMediation:

1.  You have already performed a mediation analysis using a structural equation model (SEM) software and you have coeffiecient and indirect effect estimates along with their standard errors and covariance matrix of the coefficients.
    For a single mediator model, you can use the `medci` function to calculate confidence intervals for the indirect effects.
    For multiple mediator models, you can use the `ci` function to calculate confidence intervals for the indirect effects.
    For a general mediation model, you can use the `ci` function to calculate confidence intervals for the indirect effects.
    These two functions offer a variety of methods for calculating confidence intervals, such as distribution of the product and Monte Carlo methods.

2.  You have not yet performed a mediation analysis in `lavaan` or `OpenMx` and you have a fitted model object.
    In this case, you can use the `ci` function to estimate indirect effect confidence interval with multiple mediators and the `medci` function to calculate confidence intervals for the indirect effects with a single mediator.
    The first argument for these functions are the fitted model object-- you do not need to specify the coefficnet estimates and their standard errors (covariance matrix of the coefficients) as the functions will extract these from the fitted model object.

## Contributing

Contributions to RMediation are welcome!
If you encounter any issues, have suggestions for improvements, or would like to contribute new features, please open an issue or submit a pull request on GitHub.

## Citation

If you use RMediation in your research, please cite it using the following citation:

```         
Tofighi, D. and MacKinnon, D. P. (2011). 'RMediation' An R package for mediation analysis confidence intervals. Behavior Research Methods, 43, 692--700. <doi:10.3758/s13428-011-0076-x>.

Tofighi, D. (2020). Bootstrap Model-Based Constrained Optimization Tests of Indirect Effects. Frontiers in Psychology, 10, 2989. <doi:10.3389/fpsyg.2019.02989>.
```

## License

`RMediation` is licensed under the [GPL-3.0](https://choosealicense.com/licenses/gpl-3.0/).
See the LICENSE file for details.

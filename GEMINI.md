# RMediation Project `GEMINI.md`

This file provides a comprehensive overview of the `RMediation` R package, designed to serve as a quick-start guide and instructional context for developers and users.

## Project Overview

`RMediation` is a statistical R package for mediation analysis. It provides functions to compute confidence intervals for indirect effects using various methods, including the distribution of the product, Monte Carlo simulation, and bootstrapping. The package also implements the Model-Based Constrained Optimization (MBCO) procedure for hypothesis testing of indirect effects.

**Main Technologies:**

*   **Language:** R
*   **Dependencies:** `lavaan`, `OpenMx`, `boot`, and others (see `DESCRIPTION` file).
*   **Testing:** `testthat`

**Architecture:**

The project is structured as a standard R package. The main functions are located in the `R/` directory, and the tests are in the `tests/` directory. The package uses `roxygen2` for documentation.

## Building and Running

### Installation

To install the package from CRAN, use:

```r
install.packages("RMediation")
```

To install the development version from GitHub, use:

```r
# install.packages("remotes")
remotes::install_github("data-wise/RMediation")
```

### Running Tests

To run the test suite, use the following command in the R console:

```r
devtools::test()
```

## Development Conventions

### Coding Style

*   The code follows the standard R coding conventions.
*   Functions are well-documented using `roxygen2` comments.
*   Variable names are descriptive and use `.` as a separator (e.g., `mu.x`).

### Testing

*   The project uses the `testthat` framework for unit testing.
*   Tests are located in the `tests/testthat/` directory.
*   Test files are named `test-<function_name>.R`.
*   Tests cover a wide range of scenarios, including basic functionality, parameter validation, edge cases, and method comparisons.

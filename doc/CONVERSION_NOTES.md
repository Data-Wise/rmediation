# Vignette Conversion Summary: RMarkdown to Quarto

## Overview

The RMediation package vignettes have been converted from RMarkdown (`.Rmd`) to Quarto (`.qmd`) format with improved code chunk formatting and modern features.

## Files Converted

1. **getting-started.Rmd** → **getting-started.qmd**
2. **methods-comparison.Rmd** → **methods-comparison.qmd**

## Key Changes

### 1. YAML Header Updates

**Old (RMarkdown):**
```yaml
---
title: "Getting Started with RMediation"
author: "RMediation Development Team"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Getting Started with RMediation}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---
```

**New (Quarto):**
```yaml
---
title: "Getting Started with RMediation"
author: "RMediation Development Team"
format: html
vignette: >
  %\VignetteIndexEntry{Getting Started with RMediation}
  %\VignetteEngine{quarto::html}
  %\VignetteEncoding{UTF-8}
---
```

### 2. Code Chunk Formatting

**Old (RMarkdown):**
```r
```{r setup, include = FALSE}
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
library(RMediation)
```
```

**New (Quarto):**
```r
```{r}
#| label: setup
#| include: false

knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
library(RMediation)
```
```

### 3. Code Chunk Options

Quarto uses the **hashpipe** (`#|`) syntax for chunk options instead of inline options:

**Old:**
- `{r example1}` - simple label
- `{r setup, include = FALSE}` - inline options
- `{r lavaan_integration, eval=FALSE}` - multiple inline options

**New:**
- `{r}` with `#| label: example1`
- `{r}` with `#| label: setup` and `#| include: false`
- `{r}` with `#| label: lavaan-integration` and `#| eval: false`

### 4. Configuration Files

#### Created `_quarto.yml`

A new configuration file for consistent rendering across all vignettes:

```yaml
project:
  type: default
  output-dir: ../inst/doc

format:
  html:
    toc: true
    toc-depth: 3
    code-fold: false
    code-tools: true
    code-copy: true
    theme: cosmo
    highlight-style: github
    df-print: paged
    embed-resources: false

execute:
  echo: true
  warning: true
  message: true
  cache: false
  freeze: auto

knitr:
  opts_chunk:
    collapse: true
    comment: "#>"
    fig.width: 7
    fig.height: 5
    fig.align: "center"
```

#### Updated `DESCRIPTION`

Changed `VignetteBuilder` from:
```
VignetteBuilder: knitr
```

To:
```
VignetteBuilder: knitr, quarto
```

#### Updated `.Rbuildignore`

Added exclusions for old RMarkdown files and Quarto intermediate files:
```
## Vignette files
^vignettes/.*\.Rmd$
^vignettes/.*\.knit\.md$
^vignettes/.*_cache$
^vignettes/.*_files$
```

## Benefits of Quarto Format

1. **Modern Syntax**: Cleaner, more readable code chunk options using `#|` syntax
2. **Better Tooling**: Enhanced IDE support in RStudio and VS Code
3. **Consistency**: Unified syntax across R, Python, Julia, and Observable
4. **Features**: Built-in code folding, code copying, and better theming
5. **Output Control**: More granular control over HTML output and styling
6. **Cross-format**: Easier to render to multiple formats (HTML, PDF, Word, etc.)

## Rendering Vignettes

### Individual Vignette
```bash
cd vignettes
quarto render getting-started.qmd
quarto render methods-comparison.qmd
```

### All Vignettes
```bash
cd vignettes
quarto render
```

### From R Package Build
The vignettes will automatically be built when running:
```r
devtools::build_vignettes()
# or
devtools::build()
```

## Output Location

Rendered HTML files are placed in:
```
inst/doc/
├── getting-started.html
├── getting-started_files/
├── methods-comparison.html
└── methods-comparison_files/
```

## Backward Compatibility

- Old `.Rmd` files are kept in the repository but excluded from package builds
- The package still supports `knitr` for backward compatibility
- Both `knitr` and `quarto` are listed as VignetteBuilders

## Testing

Both vignettes have been successfully rendered and tested:
- ✅ `getting-started.qmd` → HTML output generated
- ✅ `methods-comparison.qmd` → HTML output generated
- ✅ All code chunks execute without errors
- ✅ Proper formatting and styling applied

## Next Steps

1. **Review**: Check the rendered HTML files in `inst/doc/` for formatting
2. **Test**: Run `devtools::build_vignettes()` to ensure package integration
3. **Document**: Update NEWS.md to mention the Quarto migration
4. **Cleanup**: Consider removing old `.Rmd` files after confirming everything works
5. **Commit**: Commit the changes with appropriate message

## References

- [Quarto Documentation](https://quarto.org/)
- [Quarto for R Packages](https://quarto.org/docs/extensions/nbdev.html)
- [Quarto Code Cells](https://quarto.org/docs/reference/cells/cells-knitr.html)

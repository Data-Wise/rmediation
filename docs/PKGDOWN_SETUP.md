# pkgdown Website Setup - Complete! ✅

## What Was Done

### 1. **Installed and Configured pkgdown**

- Installed the pkgdown package (v2.2.0)
- Created comprehensive `_pkgdown.yml` configuration file
- Updated DESCRIPTION file with package URL

### 2. **Built Local Website**

- Successfully built the pkgdown site in the `docs/` directory
- Site includes:
  - Homepage (from README.md)
  - Function reference (organized by category)
  - News page (from NEWS.md)
  - Additional documentation pages
  - Search functionality
  - Responsive Bootstrap 5 design with Cosmo theme

### 3. **GitHub Actions Workflow**

- Created `.github/workflows/pkgdown.yaml`
- Configured for automatic deployment to GitHub Pages
- Triggers on:
  - Push to main/master branch
  - Pull requests
  - Releases
  - Manual dispatch

### 4. **Updated GitHub URLs**

- Changed username from `quantPsych` to `data-wise` in:
  - `_pkgdown.yml`
  - `DESCRIPTION`
  - `README.md`

## Website Structure

The website is organized with the following sections:

### **Core Functions**

- [`medci()`](https://data-wise.github.io/rmediation/reference/medci.md) -
  Specialized for two-variable product (a\*b indirect effects)
- [`ci()`](https://data-wise.github.io/rmediation/reference/ci.md) -
  General purpose for any nonlinear function
- [`mbco()`](https://data-wise.github.io/rmediation/reference/mbco.md) -
  Model-Based Constrained Optimization tests

### **Distribution Functions**

- [`pprodnormal()`](https://data-wise.github.io/rmediation/reference/pprodnormal.md)
  /
  [`qprodnormal()`](https://data-wise.github.io/rmediation/reference/qprodnormal.md) -
  CDF and quantile for product of normals
- [`pMC()`](https://data-wise.github.io/rmediation/reference/pMC.md) /
  [`qMC()`](https://data-wise.github.io/rmediation/reference/qMC.md) -
  Monte Carlo-based distribution functions

### **Datasets**

- `memory_exp` - Example dataset for demonstrations

### **Utility Functions**

- [`tidy.logLik()`](https://data-wise.github.io/rmediation/reference/tidy_logLik.md) -
  S3 method for tidying logLik objects

## Next Steps to Deploy

### Step 1: Push to GitHub

``` bash
cd "/Users/dt/Library/CloudStorage/GoogleDrive-dtofighi@gmail.com/My Drive/packages/rmediation"
git add .
git commit -m "Add pkgdown website configuration and GitHub Actions workflow"
git push origin main
```

### Step 2: Enable GitHub Pages

1.  Go to your GitHub repository:
    <https://github.com/data-wise/rmediation>
2.  Click **Settings** → **Pages** (in left sidebar)
3.  Under **Source**, select:
    - Branch: `gh-pages`
    - Folder: `/ (root)`
4.  Click **Save**

### Step 3: Wait for Workflow to Complete

- The GitHub Actions workflow will automatically build and deploy the
  site
- Check the **Actions** tab to monitor progress
- First deployment takes ~5-10 minutes

### Step 4: Access Your Website

Once deployed, your site will be available at:
**<https://data-wise.github.io/rmediation/>**

## Local Development

### Preview Locally

To view the site locally before pushing:

``` r

# Build and preview
pkgdown::build_site()
pkgdown::preview_site()
```

### Update Documentation

After making changes to function documentation:

``` r

# Regenerate documentation
devtools::document()

# Rebuild site
pkgdown::build_site()
```

## Future Enhancements

### 1. Add Vignettes (Recommended)

Create detailed tutorials to help users:

``` r

# Create vignette directory and files
usethis::use_vignette("getting-started")
usethis::use_vignette("ci-methods-comparison")
usethis::use_vignette("mbco-methods")
usethis::use_vignette("multiple-mediators")
```

These will automatically appear in the “Articles” section of your
website.

### 2. Add Badges to README

``` r

usethis::use_cran_badge()
usethis::use_lifecycle_badge("stable")
```

Add these manually to README.md:

``` markdown
<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/RMediation)](https://CRAN.R-project.org/package=RMediation)
[![R-CMD-check](https://github.com/data-wise/rmediation/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/data-wise/rmediation/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/data-wise/rmediation/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/data-wise/rmediation/actions/workflows/pkgdown.yaml)
<!-- badges: end -->
```

### 3. Add R-CMD-check Workflow

``` r

# Use standard R package check
usethis::use_github_action("check-standard")
```

This will test your package on multiple platforms (Windows, macOS,
Ubuntu) and R versions.

### 4. Add Code of Conduct and Contributing Guidelines

``` r

usethis::use_code_of_conduct()
usethis::use_tidy_contributing()
```

### 5. Add Unit Tests

``` r

usethis::use_testthat()
usethis::use_test("medci")
usethis::use_test("ci")
usethis::use_test("mbco")
```

## Customization

### Change Theme

Edit `_pkgdown.yml`:

``` yaml
template:
  bootstrap: 5
  bootswatch: flatly  # Try: cosmo, flatly, sandstone, yeti, etc.
```

### Add Custom CSS/JS

Create `pkgdown/extra.css` or `pkgdown/extra.js` and reference in
`_pkgdown.yml`.

### Customize Home Page

The homepage uses `README.md`. To add a custom homepage: 1. Create
`index.md` in the root directory 2. pkgdown will use `index.md` instead
of `README.md`

## Files Added/Modified

### New Files

- `_pkgdown.yml` - Main configuration
- `.github/workflows/pkgdown.yaml` - GitHub Actions workflow
- `docs/` - Built website (git-ignored, regenerated automatically)
- `PKGDOWN_SETUP.md` - This file

### Modified Files

- `DESCRIPTION` - Added package URL
- `README.md` - Updated GitHub username
- `.Rbuildignore` - Added pkgdown files

## Troubleshooting

### Workflow Fails

- Check GitHub Actions logs under the “Actions” tab
- Ensure all dependencies are listed in DESCRIPTION
- Verify R version compatibility

### Site Not Updating

- Clear browser cache
- Wait 5-10 minutes for GitHub Pages to update
- Check that the workflow completed successfully

### Missing Functions

- Ensure functions are exported in NAMESPACE
- Run
  [`devtools::document()`](https://devtools.r-lib.org/reference/document.html)
  to regenerate documentation
- Rebuild site with
  [`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)

## Resources

- [pkgdown documentation](https://pkgdown.r-lib.org/)
- [GitHub Pages documentation](https://docs.github.com/en/pages)
- [r-lib GitHub Actions](https://github.com/r-lib/actions)

------------------------------------------------------------------------

**Website URL (after deployment):**
<https://data-wise.github.io/rmediation/>

Good luck with your package website! 🎉

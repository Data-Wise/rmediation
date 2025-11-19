# GitHub Pages Setup - Complete! ✅

## What Was Done

### 1. Created `gh-pages` Branch

- Created an orphan branch (no shared history with `main`)
- Initialized with a README.md placeholder
- Added `.nojekyll` file to prevent Jekyll processing
- Pushed to remote repository

### 2. Updated `.gitignore`

- Added `docs/` to .gitignore on main branch
- This ensures locally built site files aren’t committed to main
- The GitHub Action will build and deploy to `gh-pages` automatically

### 3. GitHub Actions Workflow

- Already configured in `.github/workflows/pkgdown.yaml`
- Will automatically:
  - Build the pkgdown site when you push to main
  - Deploy to the `gh-pages` branch
  - Update the live website

## Next Steps to Enable GitHub Pages

### Step 1: Enable GitHub Pages in Repository Settings

1.  Go to your GitHub repository:
    **<https://github.com/data-wise/rmediation>**

2.  Click **Settings** (top navigation bar)

3.  In the left sidebar, click **Pages**

4.  Under **Source**, configure:

    - **Branch**: Select `gh-pages`
    - **Folder**: Select `/ (root)`

5.  Click **Save**

6.  GitHub will display a message: “Your site is ready to be published
    at <https://data-wise.github.io/rmediation/>”

### Step 2: Push Your Changes to Trigger Deployment

``` bash
cd "/Users/dt/Library/CloudStorage/GoogleDrive-dtofighi@gmail.com/My Drive/packages/rmediation"

# Make sure you're on main branch
git checkout main

# Add and commit any remaining changes
git add .
git commit -m "Complete pkgdown and GitHub Pages setup"

# Push to trigger the workflow
git push origin main
```

### Step 3: Monitor the Deployment

1.  Go to the **Actions** tab in your GitHub repository

2.  You should see a workflow run called “pkgdown” starting

3.  Click on the workflow run to see progress

4.  The workflow will:

    - Set up R environment
    - Install dependencies
    - Build the pkgdown site
    - Deploy to `gh-pages` branch

5.  First deployment takes ~5-10 minutes

### Step 4: Access Your Live Website

Once the workflow completes successfully, your website will be live at:

**<https://data-wise.github.io/rmediation/>**

## Deployment Workflow

### How It Works

1.  **You push to `main`** → Triggers GitHub Actions workflow

2.  **Workflow builds site** → Runs
    [`pkgdown::build_site_github_pages()`](https://pkgdown.r-lib.org/reference/build_site_github_pages.html)

3.  **Deploys to `gh-pages`** → Uses
    JamesIves/github-pages-deploy-action

4.  **GitHub Pages serves** → Website updates automatically

### Automatic Updates

Every time you push to `main`, the website will automatically rebuild
and update. This includes:

- Changes to function documentation (roxygen2)
- Updates to README.md
- New vignettes
- Updates to NEWS.md
- Changes to `_pkgdown.yml` configuration

## Branch Structure

### `main` Branch

- Contains source code
- R functions, documentation, tests
- `_pkgdown.yml` configuration
- GitHub Actions workflow

### `gh-pages` Branch

- Contains built website only
- Automatically updated by GitHub Actions
- Do NOT manually edit this branch
- GitHub Pages serves content from here

## Troubleshooting

### Workflow Fails

**Check the Actions tab for error logs:**

1.  Click on the failed workflow run
2.  Click on the job name (e.g., “pkgdown”)
3.  Expand the failed step to see error messages

**Common issues:** - Missing dependencies in DESCRIPTION - Errors in
roxygen2 documentation - Invalid `_pkgdown.yml` syntax

**Solution:** - Fix the error in main branch - Commit and push -
Workflow will run again automatically

### Site Not Updating

**Wait time:** - After workflow completes, allow 2-5 minutes for GitHub
Pages to update - Clear your browser cache

**Check deployment:** - Go to Settings → Pages - Look for “Your site is
live at…” message - If you see an error, check that: - Branch is set to
`gh-pages` - Folder is set to `/ (root)`

### 404 Error on Website

**Most common cause:** GitHub Pages not enabled

**Solution:** 1. Go to Settings → Pages 2. Ensure Source is set to
`gh-pages` branch 3. Wait 2-5 minutes after saving

## Files Created/Modified

### New Files

- `README.md` on `gh-pages` branch (placeholder)
- `.nojekyll` on `gh-pages` branch (prevents Jekyll processing)
- `GITHUB_PAGES_SETUP.md` (this file)

### Modified Files

- `.gitignore` - Added `docs/` to ignore locally built site

### Existing Files (from earlier)

- `.github/workflows/pkgdown.yaml` - Workflow configuration
- `_pkgdown.yml` - Site configuration
- `DESCRIPTION` - Package URLs

## Customization

### Update Website Appearance

Edit `_pkgdown.yml` on main branch:

``` yaml
template:
  bootstrap: 5
  bootswatch: cosmo  # Change theme here
  bslib:
    primary: "#0054AD"  # Change color scheme
```

Available themes: cosmo, flatly, sandstone, yeti, minty, etc.

### Add Custom Pages

Create markdown files in your repository:

    my-package/
      ├── README.md        # Homepage
      ├── NEWS.md          # News page
      ├── vignettes/       # Articles
      └── _pkgdown.yml     # Configuration

### Update Navigation

Edit `_pkgdown.yml`:

``` yaml
navbar:
  structure:
    left: [home, reference, articles, news, tutorials]
    right: [search, github]
  components:
    tutorials:
      text: Tutorials
      href: articles/index.html
```

## Maintenance

### Regular Updates

The website will automatically update when you:

1.  **Update function documentation:**

    ``` r
    devtools::document()
    git commit -am "Update documentation"
    git push
    ```

2.  **Add vignettes:**

    ``` r
    usethis::use_vignette("my-new-tutorial")
    # Write vignette...
    git add vignettes/
    git commit -m "Add new tutorial vignette"
    git push
    ```

3.  **Update NEWS:**

    - Edit NEWS.md
    - Commit and push
    - Automatically appears on website

### Manual Site Rebuild

To rebuild the site locally without pushing:

``` r

pkgdown::build_site()
```

Preview at: `docs/index.html` (open in browser)

## Resources

- [pkgdown documentation](https://pkgdown.r-lib.org/)
- [GitHub Pages documentation](https://docs.github.com/en/pages)
- [GitHub Actions for R](https://github.com/r-lib/actions)

------------------------------------------------------------------------

## Summary

✅ **gh-pages branch created and pushed** ✅ **.gitignore updated to
exclude docs/** ✅ **.nojekyll added to prevent Jekyll processing** ✅
**GitHub Actions workflow configured**

**Next Step:** Enable GitHub Pages in repository settings (see Step 1
above)

**Website URL:** <https://data-wise.github.io/rmediation/>

The setup is complete! Once you enable GitHub Pages in settings and push
to main, your website will be live automatically. 🎉

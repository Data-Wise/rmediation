## Submission summary

This is a resubmission of **RMediation** (version 1.5.0), an existing CRAN package.

Key changes in this release:
- New `medci()` argument `type = "dop"` (replaces deprecated `"prodclin"`)
- MBCO procedure via `mbco()` using S7 class system
- `Language: en-US` added to DESCRIPTION; `inst/WORDLIST` updated

## Test environments

* Local: macOS 15 (aarch64-apple-darwin25.4.0), R 4.6.0 — `R CMD check --as-cran`
* win-builder R-oldrelease (R 4.5.3): token mKpQ5ycMhVBG — **Status: OK**
* win-builder R-release (R 4.6.0): token 9Yl6dT037ae0 — **Status: OK**
* win-builder R-devel: token KvUk0DM4QDqq — **Status: OK**
* GitHub Actions: macOS-latest, ubuntu-latest, windows-latest — R release + oldrel-1
* r-hub (major-viceroybutterfly, run 27854572331, on main/v1.5.0):
  - `ubuntu-clang`: OK
  - `ubuntu-gcc12`: OK
  - `nosuggests`: FAILED — expected (see Notes below)
  - `gcc-asan`: OK

## R CMD check results

`0 errors | 0 warnings | 0 notes`

## Notes for the CRAN team

* `medfit (>= 0.2.0)` in `Suggests` is a GitHub-only package and will appear as an
  INFO note on CRAN's check machines. It is used only in examples/vignettes guarded by
  `requireNamespace()`. This is expected and intentional.

* **r-hub `nosuggests` failure**: The `nosuggests` container intentionally does not
  install packages listed in `Suggests`. Vignettes require `rmarkdown` (listed in
  `Suggests`), so they cannot be re-built in this environment. CRAN's servers install
  `Suggests` packages when building vignettes, so this is not a real-world issue.

## Downstream dependencies

There are no CRAN reverse dependencies for this package.

#!/usr/bin/env Rscript
# Development agent for R package tasks

help_text <- paste(
    c(
        "dev/dev_agent.R - development helper for this package",
        "",
        "Usage:",
        "  Rscript dev/dev_agent.R <command>",
        "",
        "Commands:",
        "  doc      - generate roxygen documentation (roxygen2::roxygenise)",
        "  lint     - run lintr on the package (lintr::lint_package)",
        "  test     - run tests (devtools::test)",
        "  check    - run devtools::check()",
        "  build    - build package tarball (devtools::build)",
        "  site     - build pkgdown site (pkgdown::build_site)",
        "  status   - print package DESCRIPTION summary (desc::desc)",
        "  load     - load all package contents (devtools::load_all)",
        "  help     - show this message"
    ),
    collapse = "\n"
)

pkg_dir <- function() normalizePath(".", winslash = "/", mustWork = TRUE)

install_if_missing <- function(pkgs) {
    missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
    if (length(missing)) {
        message(
            "Installing missing packages: ",
            paste(missing, collapse = ", ")
        )
        install.packages(missing, repos = "https://cran.rstudio.com")
    }
}

run_safe <- function(fun) {
    tryCatch(
        {
            fun()
            invisible(0)
        },
        error = function(e) {
            message("ERROR: ", conditionMessage(e))
            invisible(1)
        }
    )
}

args <- commandArgs(trailingOnly = TRUE)
cmd <- if (length(args) >= 1) args[[1]] else "help"

res <- switch(
    cmd,
    help = {
        cat(help_text, sep = "\n")
        0
    },
    doc = {
        install_if_missing(c("roxygen2"))
        run_safe(function() roxygen2::roxygenise(pkg_dir(), clean = TRUE))
    },
    lint = {
        install_if_missing(c("lintr"))
        run_safe(function() lintr::lint_package(pkg_dir()))
    },
    test = {
        install_if_missing(c("devtools"))
        run_safe(function() devtools::test(pkg = pkg_dir()))
    },
    check = {
        install_if_missing(c("devtools", "quarto"))
        run_safe(function() devtools::check(pkg = pkg_dir()))
    },
    build = {
        install_if_missing(c("devtools"))
        run_safe(function() devtools::build(pkg = pkg_dir()))
    },
    site = {
        install_if_missing(c("pkgdown"))
        run_safe(function() pkgdown::build_site(pkg = pkg_dir()))
    },
    status = {
        install_if_missing(c("desc"))
        run_safe(function() {
            d <- desc::desc(file = file.path(pkg_dir(), "DESCRIPTION"))
            cat("Package:", d$get("Package"), "\n")
            cat("Version:", d$get("Version"), "\n")
            cat("Title:", d$get("Title"), "\n")
            cat("Description:\n", d$get("Description"), "\n")
        })
    },
    load = {
        install_if_missing(c("devtools"))
        run_safe(function() devtools::load_all(pkg_dir()))
    },
    {
        message("Unknown command: ", cmd)
        message("Run `Rscript dev/dev_agent.R help` for available commands.")
        2
    }
)

if (!is.null(res) && is.numeric(res) && res != 0) {
    quit(status = as.integer(res))
}

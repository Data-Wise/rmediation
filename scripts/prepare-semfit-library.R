# Link installed dependencies into a controlled library without OpenMx.
# Usage: Rscript scripts/prepare-semfit-library.R LIB MODE
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L, args[2] %in% c("none", "old", "new"))
dir.create(args[1], recursive = TRUE, showWarnings = FALSE)
pkgs <- utils::installed.packages()
pkgs <- pkgs[!duplicated(pkgs[, "Package"]), , drop = FALSE]
exclude <- c("RMediation", "OpenMx", if (args[2] == "none") "medfit")
for (i in which(!pkgs[, "Package"] %in% exclude)) {
  name <- pkgs[i, "Package"]
  target <- file.path(args[1], name)
  if (!file.exists(target)) {
    stopifnot(file.symlink(file.path(pkgs[i, "LibPath"], name), target))
  }
}

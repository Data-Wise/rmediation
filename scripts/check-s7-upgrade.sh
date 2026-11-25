#!/bin/sh
# Run with two R library directories containing S7 0.2.2 and 1.0.0, respectively.
# Usage: sh scripts/check-s7-upgrade.sh OLD_LIBRARY NEW_LIBRARY
set -eu

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 OLD_LIBRARY NEW_LIBRARY" >&2
  exit 2
fi
old_library=$(cd "$1" && pwd)
new_library=$(cd "$2" && pwd)
root=$(cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/RMediation-s7-upgrade.XXXXXX")
trap 'rm -rf "$work"' EXIT

R_LIBS_USER="$old_library" Rscript --vanilla -e 'stopifnot(packageVersion("S7") == "0.2.2")'
R_LIBS_USER="$old_library" R CMD INSTALL --library="$work" "$root"
R_LIBS_USER="$new_library" Rscript --vanilla - "$work" <<'RS'
library_path <- normalizePath(commandArgs(trailingOnly = TRUE)[[1L]], winslash = "/")
.libPaths(c(library_path, .libPaths()))
stopifnot(packageVersion("S7") == "1.0.0", dirname(find.package("RMediation")) == library_path)
res <- RMediation::MBCOResult(statistic = 4.2, df = 1, p_value = 0.04, type = "asymp")
stopifnot(is.null(res@refit), is.null(res@provenance), is.null(res@branch), is.null(res@dropped))
invisible(methods::setGeneric("s4UpgradeProbe", function(x) methods::standardGeneric("s4UpgradeProbe")))
methods::setMethod("s4UpgradeProbe", "RMediation::MBCOResult", function(x) x@statistic)
stopifnot(identical(s4UpgradeProbe(res), 4.2))
cat("PASS installed MBCOResult S4 dispatch after upgrading S7 from 0.2.2 to 1.0.0\n")
RS

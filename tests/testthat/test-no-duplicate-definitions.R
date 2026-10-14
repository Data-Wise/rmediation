# A top-level name defined in two R/ files is resolved by collation order, not by intent: the
# file that sorts last silently wins. R/medci_legacy_backup.R duplicated medci() from R/medci.R
# and, sorting later, was the live definition while the documented one was dead.

test_that("no top-level function is defined in more than one R/ file", {
  rdir <- testthat::test_path("..", "..", "R")
  skip_if_not(dir.exists(rdir), "R/ sources are not available (installed-package test run)")
  defs <- do.call(rbind, lapply(list.files(rdir, pattern = "[.][Rr]$", full.names = TRUE), function(f) {
    exprs <- parse(f, keep.source = FALSE)
    nm <- unlist(lapply(exprs, function(e) {
      if (is.call(e) && as.character(e[[1L]])[1L] %in% c("<-", "=") && is.name(e[[2L]]) &&
            is.call(e[[3L]]) && identical(e[[3L]][[1L]], as.name("function"))) {
        as.character(e[[2L]])
      }
    }))
    if (length(nm)) data.frame(name = nm, file = basename(f)) else NULL
  }))
  dup <- defs[duplicated(defs$name) | duplicated(defs$name, fromLast = TRUE), ]
  expect_equal(nrow(dup), 0L, info = paste(capture.output(print(dup)), collapse = "\n"))
})

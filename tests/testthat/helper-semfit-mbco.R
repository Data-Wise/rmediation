# medfit 0.14.0 warns when fit_sem() leaves fixed_x or meanstructure unset (the
# defaults change in 0.15.0). Pass today's values where this medfit has the
# argument, so older medfit versions still run these tests.
.fit_sem <- function(...) {
  args <- list(...)
  f <- names(formals(medfit::fit_sem))
  if ("fixed_x" %in% f && !"fixed_x" %in% names(args)) args$fixed_x <- FALSE
  if ("meanstructure" %in% f && !"meanstructure" %in% names(args)) {
    args["meanstructure"] <- list(NULL)
  }
  do.call(medfit::fit_sem, args)
}

# Shared known-answer data and syntax; no OpenMx requirement for native fits.
.semfit_mbco_syntax <- paste(
  "repetition ~ a1*x", "imagery ~ a2*x",
  "recall ~ cp*x + b1*repetition + b2*imagery",
  sep = "\n"
)
.semfit_mbco_fits <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) {
      d <- .memory_exp_data()
      fit <- function(extra = "") {
        .fit_sem(paste(.semfit_mbco_syntax, extra, sep = "\n"), d)
      }
      cache <<- list(
        data = d, full = fit(), a1 = fit("a1 == 0"),
        b1 = fit("b1 == 0"), product = fit("a1*b1 == 0"),
        both = fit("a1 == 0\nb1 == 0")
      )
    }
    cache
  }
})

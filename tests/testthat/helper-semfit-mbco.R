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
        medfit::fit_sem(paste(.semfit_mbco_syntax, extra, sep = "\n"), d)
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

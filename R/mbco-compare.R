# Validate the observed comparison before any bootstrap sampling.
.mbco_compare <- function(h0, h1) {
  result <- OpenMx::mxCompare(h1, h0)
  df <- result$df[2] - result$df[1]
  if (length(df) != 1L || !is.finite(df) || df <= 0) {
    stop("h0 must be more restricted than h1 (positive df difference).",
      call. = FALSE
    )
  }
  statistic <- result$diffLL[2]
  if (length(statistic) != 1L || !is.finite(statistic) || statistic < 0) {
    stop("The observed MBCO statistic must be finite and nonnegative.",
      call. = FALSE
    )
  }
  result
}

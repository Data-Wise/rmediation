#' MBCO test of a product null (a zero-product indirect effect)
#'
#' Tests the null that a product of paths is zero (`a * b = 0`, or a serial
#' `a1 * a2 * b = 0`) with OpenMx. The null holds when any single path is 0, so
#' it is a union of single-path nulls. `mbco_product_null()` fits one null per
#' path by fixing that path at 0 in a copy of the fitted full model, runs
#' [mbco()] on each, and returns the result of the branch with the largest
#' p-value, because a test of a union rejects only if every single-path null is
#' rejected (an intersection-union test). For `type = "asymp"` this is the
#' smaller statistic with 1 degree of freedom.
#'
#' A single nonlinear constraint such as `ind == 0` can converge to the branch
#' with the larger statistic and give a wrong test; see [mbco()]. Fixing a
#' parameter is exact, so this function avoids that and the feasibility
#' tolerance problem. The p-value is conservative when more than one path is 0
#' (standard intersection-union theory, not verified here).
#'
#' @param h1 A fitted full `OpenMx` model.
#' @param paths Character vector of two or more labels of free parameters of
#'   `h1`, the paths whose product is tested.
#' @param ... Passed to [mbco()] (`type`, `R`, `alpha`, `optim`, ...).
#' @return An [MBCOResult] for the binding branch, with the label of its
#'   single-path null in the `branch` slot.
#' @export
mbco_product_null <- function(h1, paths, ...) {
  if (!requireNamespace("OpenMx", quietly = TRUE)) {
    stop(
      "Package 'OpenMx' is required for MBCO functions but is not installed.",
      call. = FALSE
    )
  }
  if (!methods::is(h1, "MxModel")) stop("h1 must be an MxModel", call. = FALSE)
  checkmate::assert_character(paths, any.missing = FALSE, min.len = 2L, unique = TRUE, min.chars = 1L)
  free <- names(OpenMx::omxGetParameters(h1, free = TRUE))
  missing <- setdiff(paths, free)
  if (length(missing)) {
    stop(
      "paths must be labels of free parameters of h1; not found: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  nulls <- .mbco_product_models(h1, paths)
  results <- lapply(nulls, function(h0) mbco(.mbco_run_null(h0), h1, ...))
  i <- .mbco_pick_branch(results)
  res <- results[[i]]
  res@branch <- paths[i]
  res
}

# One copy of h1 per path with that path fixed at 0.
.mbco_product_models <- function(h1, paths) {
  lapply(paths, function(lab) {
    OpenMx::omxSetParameters(
      h1,
      labels = lab, free = FALSE, values = 0,
      name = paste0(h1$name, "_", lab, "_zero")
    )
  })
}

.mbco_run_null <- function(model) {
  suppressWarnings(OpenMx::mxRun(model, silent = TRUE))
}

# Intersection-union test: the binding branch has the largest p-value (first on ties).
.mbco_pick_branch <- function(results) {
  which.max(vapply(results, function(r) r@p_value, numeric(1)))
}

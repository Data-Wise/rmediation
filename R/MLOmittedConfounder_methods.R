.mloc_lines <- function(x) {
  r <- x@ranges
  vapply(seq_len(nrow(r)), function(i) {
    sprintf(
      "  %-7s r_za = %-4s ab_adj %s to %s (admitted %d of %d)",
      r$level[i], format(r$r_za[i]),
      if (is.na(r$min[i])) "NA" else formatC(r$min[i], digits = 4, format = "f"),
      if (is.na(r$max[i])) "NA" else formatC(r$max[i], digits = 4, format = "f"),
      r$n_admitted[i], r$n_total[i]
    )
  }, "")
}

#' @return The object `x` invisibly.
#' @noRd
#' @export
S7::method(print, MLOmittedConfounder) <- function(x, ...) {
  cat("Omitted-confounder sensitivity (Tofighi & Kelley, 2016)\n")
  cat("=======================================================\n")
  cat("Unadjusted indirect effect:\n")
  for (lv in names(x@unadjusted)) {
    cat(sprintf("  %-7s %s\n", lv, formatC(x@unadjusted[[lv]], digits = 4, format = "f")))
  }
  cat("Screen:", x@screen, "\n")
  if (identical(x@screen, "pd")) {
    cat("  Points with a non-positive-definite augmented matrix are NA; use\n")
    cat("  screen = \"none\" to reproduce the published tables.\n")
  }
  cat("Adjusted indirect effect by level and r_za:\n")
  cat(.mloc_lines(x), sep = "\n")
  cat("Assumption: the covariance of the level-2 random slopes of a and b is zero.\n")
  invisible(x)
}

#' @return A list invisibly: the ranges and the sign-change table.
#' @noRd
#' @export
S7::method(summary, MLOmittedConfounder) <- function(object, ...) {
  g <- object@grid
  keys <- unique(g[, c("level", "r_za")])
  sc <- do.call(rbind, lapply(seq_len(nrow(keys)), function(i) {
    p <- g[g$level == keys$level[i] & g$r_za == keys$r_za[i] & is.finite(g$ab_adj), ]
    base <- object@unadjusted[[keys$level[i]]]
    flip <- p[sign(p$ab_adj) != sign(base) & p$ab_adj != 0, , drop = FALSE]
    out <- data.frame(
      level = keys$level[i], r_za = keys$r_za[i], n_flip = nrow(flip),
      share_flip = if (nrow(p)) nrow(flip) / nrow(p) else NA_real_,
      weakest_r_zm = NA_real_, weakest_r_zy = NA_real_
    )
    if (nrow(flip)) {
      k <- which.min(flip$r_zm^2 + flip$r_zy^2)
      out$weakest_r_zm <- flip$r_zm[k]
      out$weakest_r_zy <- flip$r_zy[k]
    }
    out
  }))
  cat("Omitted-confounder sensitivity: summary\n")
  cat("Ranges of the adjusted indirect effect:\n")
  print(object@ranges, row.names = FALSE, digits = 4)
  cat("\nPoints where the adjusted effect changes sign relative to the unadjusted effect\n")
  cat("(weakest = flipping point with the smallest r_zm^2 + r_zy^2):\n")
  print(sc, row.names = FALSE, digits = 4)
  invisible(list(ranges = object@ranges, sign_change = sc))
}

#' @return The grid data frame.
#' @noRd
#' @export
S7::method(as.data.frame, MLOmittedConfounder) <-
  function(x, row.names = NULL, optional = FALSE, ...) {
    g <- x@grid
    if (!is.null(row.names)) rownames(g) <- row.names
    g
  }

#' @return The object `x` invisibly.
#' @noRd
#' @export
S7::method(plot, MLOmittedConfounder) <-
  function(x, level = NULL, r_za = NULL, type = c("heat", "region"), ...) {
    type <- match.arg(type)
    g <- x@grid
    levels <- unique(g$level)
    if (is.null(level)) level <- levels[1L]
    if (length(level) != 1L || !level %in% levels) {
      stop("`level` must be one of: ", paste(levels, collapse = ", "), ".",
        call. = FALSE
      )
    }
    zs <- unique(g$r_za[g$level == level])
    if (is.null(r_za)) r_za <- zs[1L]
    if (length(r_za) != 1L || !any(abs(zs - r_za) < 1e-12)) {
      stop("`r_za` must be one of: ", paste(zs, collapse = ", "), ".",
        call. = FALSE
      )
    }
    p <- g[g$level == level & abs(g$r_za - r_za) < 1e-12, ]
    xs <- sort(unique(p$r_zm))
    ys <- sort(unique(p$r_zy))
    z <- matrix(NA_real_, length(xs), length(ys))
    w <- z
    z[cbind(match(p$r_zm, xs), match(p$r_zy, ys))] <- p$ab_adj
    w[cbind(match(p$r_zm, xs), match(p$r_zy, ys))] <- p$r2
    main <- sprintf("Adjusted indirect effect (%s, r_za = %s)", level, format(r_za))
    old <- graphics::par(mar = c(4.2, 4.2, 3, 1))
    on.exit(graphics::par(old), add = TRUE)
    if (all(is.na(z))) {
      graphics::plot.new()
      graphics::title(main = main)
      graphics::text(0.5, 0.5, "No admissible grid points")
      return(invisible(x))
    }
    graphics::image(xs, ys, z,
      col = grDevices::hcl.colors(64, "Blue-Red 3"),
      xlab = "r_zm (confounder-mediator)", ylab = "r_zy (confounder-outcome)",
      main = main, ...
    )
    if (min(z, na.rm = TRUE) < 0 && max(z, na.rm = TRUE) > 0) {
      graphics::contour(xs, ys, z, levels = 0, add = TRUE, drawlabels = FALSE, lwd = 2)
    }
    if (type == "region") {
      graphics::contour(xs, ys, w,
        levels = 1, add = TRUE, drawlabels = FALSE,
        lwd = 2, lty = 2, col = "darkgreen"
      )
    }
    invisible(x)
  }

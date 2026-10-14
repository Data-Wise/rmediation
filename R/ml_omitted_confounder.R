#' Sensitivity of a Multilevel Indirect Effect to an Omitted Confounder
#'
#' Sensitivity analysis for an omitted confounder `Z` of the mediator-outcome
#' relation in a two-level 1-1-1 mediation model (treatment `A`, mediator `M`
#' and outcome `Y`, all measured at level 1), after Tofighi and Kelley (2016).
#' For each level the unmeasured, standardized confounder is described by its
#' correlations with the treatment, mediator and outcome (`r_za`, `r_zm`,
#' `r_zy`), the sensitivity parameters. The adjusted paths are
#' `a = a* - d_MZ * d_ZA` and `b = b* - d_YZ * s_ZM`, where `a*` and `b*` are
#' the supplied (unadjusted) estimates, `d_ZA` is the slope of `Z` on `A`,
#' `d_MZ` is the coefficient of `Z` in the regression of `M` on `A` and `Z`,
#' `s_ZM` is the coefficient of `M` in the regression of `Z` on `A` and `M`, and
#' `d_YZ` is the coefficient of `Z` in the regression of `Y` on `A`, `M` and
#' `Z`. These coefficients are obtained from the observed covariance matrix of
#' `A`, `M` and `Y` together with the sensitivity correlations. The adjusted
#' indirect effect is `a * b`.
#'
#' @details
#' **Inputs.** Each level is a list with the unadjusted estimates `a` (the
#' `A` to `M` path) and `b` (the `M` to `Y` path, adjusting for `A`) and the
#' observed covariance matrix of `A`, `M` and `Y` at that level, given either as
#' `cov` or as `cor` together with `sd`. Rows and columns follow `var_order`.
#' If the matrix has dimnames they must equal `var_order`; otherwise they are
#' absent. The supplied `a` and `b` need not equal the values implied by the
#' covariance matrix (the published example does not). The function subtracts a
#' covariance-derived bias term from the supplied estimates, so the result is
#' the supplied estimate adjusted by that term, not a refit.
#'
#' **Assumption.** As in the published illustration, the covariance between the
#' level-2 random slopes of the `a` and `b` paths is taken to be zero; it is not
#' estimated.
#'
#' **Screen.** A grid point is admissible when the augmented 4 by 4 correlation
#' matrix of `A`, `M`, `Y` and `Z` is positive definite, equivalently
#' `r' R^-1 r < 1` with `r = (r_za, r_zm, r_zy)` and `R` the observed
#' correlation matrix; this quantity is returned as `r2` in the grid. With
#' `screen = "pd"` (the default) points that are not admissible get `NA` for
#' the adjusted paths. **The default does not reproduce the published
#' tables:** the endpoints printed by Tofighi and Kelley (2016) are computed over
#' the whole grid, which corresponds to `screen = "none"`. With the published
#' example, the default shrinks the between-level ranges.
#'
#' **Sensitivity grids.** `r_za` may be a single numeric vector (used for every
#' supplied level) or a list with elements `between` and/or `within`. A level
#' named in the list must have data, and a level with data must be named.
#' `r_zm` and `r_zy` are the grid of confounder correlations with the mediator
#' and outcome. All correlations must be finite with absolute value below 1.
#' Points where a regression block is numerically singular return `NA`.
#'
#' @param between,within Lists describing the between-cluster and
#'   within-cluster levels (see Details). At least one is required.
#' @param r_za Correlation(s) of the confounder with the treatment: a numeric
#'   vector, or a list with elements `between` and/or `within`.
#' @param r_zm,r_zy Numeric vectors of correlations of the confounder with the
#'   mediator and the outcome.
#' @param screen `"pd"` (default) keeps only admissible points; `"none"` keeps
#'   every grid point.
#' @param var_order Character vector, a permutation of `c("A", "M", "Y")`,
#'   giving the row and column order of the supplied matrices.
#'
#' @return An `MLOmittedConfounder` object with properties `grid` (one row per
#'   level and grid point: `level`, `r_za`, `r_zm`, `r_zy`, `a_adj`, `b_adj`,
#'   `ab_adj`, `r2`, `admissible`), `ranges` (minimum and maximum adjusted
#'   indirect effect and where they occur, per level and `r_za`, with the
#'   number of admitted points), `unadjusted`, `screen`, `inputs` and `call`.
#'   It has `print`, `summary`, `plot` and `as.data.frame` methods.
#'
#' @references
#' Tofighi, D., & Kelley, K. (2016). Assessing omitted confounder bias in
#' multilevel mediation models. *Multivariate Behavioral Research, 51*(1),
#' 86-105. \doi{10.1080/00273171.2015.1105736}
#'
#' @examples
#' # Synthetic between-cluster level: correlation matrix of A, M, Y and SDs
#' R <- matrix(c(1, .3, .2, .3, 1, .4, .2, .4, 1), 3)
#' res <- ml_omitted_confounder(
#'   between = list(a = 0.3, b = 0.4, cor = R, sd = c(1, 1, 1)),
#'   r_za = c(0, 0.1)
#' )
#' res
#' summary(res)
#' head(as.data.frame(res))
#' plot(res, r_za = 0.1)
#' @export
ml_omitted_confounder <- function(between = NULL, within = NULL,
                                  r_za = c(0, 0.1, 0.3),
                                  r_zm = seq(-0.5, 0.5, 0.01),
                                  r_zy = seq(-0.5, 0.5, 0.01),
                                  screen = c("pd", "none"),
                                  var_order = c("A", "M", "Y")) {
  cl <- match.call()
  screen <- match.arg(screen)
  checkmate::assert_character(var_order, len = 3L, any.missing = FALSE)
  if (!setequal(var_order, c("A", "M", "Y"))) {
    stop("`var_order` must be a permutation of c(\"A\", \"M\", \"Y\").",
      call. = FALSE
    )
  }
  if (is.null(between) && is.null(within)) {
    stop("At least one of `between` and `within` is required.", call. = FALSE)
  }
  levels <- list(between = between, within = within)
  levels <- levels[!vapply(levels, is.null, NA)]
  prepared <- Map(.mloc_prepare_level, levels, names(levels),
    MoreArgs = list(var_order = var_order)
  )
  r_za_by_level <- .mloc_r_za(r_za, names(prepared))
  r_zm <- .mloc_check_r(r_zm, "r_zm")
  r_zy <- .mloc_check_r(r_zy, "r_zy")

  grids <- lapply(names(prepared), function(nm) {
    g <- .mloc_grid(prepared[[nm]], r_za_by_level[[nm]], r_zm, r_zy, screen)
    cbind(level = nm, g, stringsAsFactors = FALSE)
  })
  grid <- do.call(rbind, grids)
  rownames(grid) <- NULL
  ranges <- .mloc_ranges(grid)
  unadjusted <- vapply(prepared, function(p) p$a * p$b, 0)
  inputs <- list(
    levels = prepared, r_za = r_za_by_level, r_zm = r_zm, r_zy = r_zy,
    var_order = var_order
  )
  MLOmittedConfounder(
    grid = grid, ranges = ranges, unadjusted = unadjusted, screen = screen,
    inputs = inputs, call = cl
  )
}

# Row-wise r' R^-1 r for an n x 3 matrix of sensitivity correlations. Used for
# the admissibility screen (admissible when < 1) and for the region plot.
ml_admissible <- function(r, R) {
  r <- matrix(r, ncol = 3L)
  rowSums((r %*% solve(R)) * r)
}

.MLOC_SINGULAR <- 1e-12 # smallest Var(Z | A, M) treated as non-singular

.mloc_check_r <- function(x, name) {
  checkmate::assert_numeric(x,
    any.missing = FALSE, min.len = 1L, finite = TRUE,
    .var.name = name
  )
  if (any(abs(x) >= 1)) {
    stop("`", name, "` values must have absolute value below 1.", call. = FALSE)
  }
  if (anyDuplicated(x)) {
    stop("`", name, "` must not contain duplicate values.", call. = FALSE)
  }
  as.numeric(x)
}

.mloc_r_za <- function(r_za, present) {
  if (is.list(r_za)) {
    nms <- names(r_za)
    if (is.null(nms) || anyNA(nms) || !all(nms %in% c("between", "within")) ||
      anyDuplicated(nms)) {
      stop("A list `r_za` must have unique names from \"between\" and \"within\".",
        call. = FALSE
      )
    }
    extra <- setdiff(nms, present)
    if (length(extra)) {
      stop("`r_za` names a level with no data: ", paste(extra, collapse = ", "),
        ".",
        call. = FALSE
      )
    }
    missing_lv <- setdiff(present, nms)
    if (length(missing_lv)) {
      stop("`r_za` is missing for level: ", paste(missing_lv, collapse = ", "),
        ".",
        call. = FALSE
      )
    }
    out <- lapply(r_za[present], .mloc_check_r, name = "r_za")
  } else {
    one <- .mloc_check_r(r_za, "r_za")
    out <- stats::setNames(rep(list(one), length(present)), present)
  }
  out
}

# Validate one level and return its covariance/correlation in A, M, Y order.
.mloc_prepare_level <- function(x, name, var_order) {
  if (!is.list(x) || is.null(names(x))) {
    stop("`", name, "` must be a named list.", call. = FALSE)
  }
  checkmate::assert_number(x$a, finite = TRUE, .var.name = paste0(name, "$a"))
  checkmate::assert_number(x$b, finite = TRUE, .var.name = paste0(name, "$b"))
  has_cov <- !is.null(x$cov)
  has_cor <- !is.null(x$cor)
  if (has_cov == has_cor) {
    stop("`", name, "` needs exactly one of `cov` or `cor` (with `sd`).",
      call. = FALSE
    )
  }
  check_mat <- function(m, label) {
    checkmate::assert_matrix(m,
      mode = "numeric", nrows = 3L, ncols = 3L, any.missing = FALSE,
      .var.name = paste0(name, "$", label)
    )
    if (!isSymmetric(unname(m), tol = 1e-8)) {
      stop("`", name, "$", label, "` must be symmetric.", call. = FALSE)
    }
    if (!is.null(rownames(m)) || !is.null(colnames(m))) {
      if (!identical(rownames(m), var_order) ||
        !identical(colnames(m), var_order)) {
        stop("Dimnames of `", name, "$", label,
          "` must equal `var_order` or be absent.",
          call. = FALSE
        )
      }
    }
  }
  perm <- match(c("A", "M", "Y"), var_order)
  if (has_cov) {
    check_mat(x$cov, "cov")
    S <- unname(x$cov)[perm, perm]
    sdv <- sqrt(diag(S))
    if (anyNA(sdv) || any(diag(S) <= 0)) {
      stop("`", name, "$cov` must have a positive diagonal.", call. = FALSE)
    }
    R <- stats::cov2cor(S)
  } else {
    check_mat(x$cor, "cor")
    checkmate::assert_numeric(x$sd,
      len = 3L, any.missing = FALSE, finite = TRUE,
      .var.name = paste0(name, "$sd")
    )
    if (any(x$sd <= 0)) {
      stop("`", name, "$sd` must be positive.", call. = FALSE)
    }
    if (!isTRUE(all.equal(unname(diag(x$cor)), rep(1, 3)))) {
      stop("`", name, "$cor` must have a unit diagonal.", call. = FALSE)
    }
    R <- unname(x$cor)[perm, perm]
    sdv <- x$sd[perm]
    S <- R * tcrossprod(sdv)
  }
  if (min(eigen(R, symmetric = TRUE, only.values = TRUE)$values) < 1e-10) {
    stop("The covariance matrix of `", name,
      "` must be positive definite.",
      call. = FALSE
    )
  }
  dimnames(S) <- dimnames(R) <- list(c("A", "M", "Y"), c("A", "M", "Y"))
  list(a = x$a, b = x$b, cov = S, cor = R, sd = sdv)
}

# The four coefficients that define the bias terms, for every row of `r` (n x 3
# sensitivity correlations). With Z standardized, the covariance of Z with
# A, M, Y is `r * sd`. Each coefficient is a partial regression slope, computed
# from residualized covariances so that the whole grid is handled at once:
#   d_za = slope of Z on A
#   d_mz = coefficient of Z in M ~ A + Z
#   s_zm = coefficient of M in Z ~ A + M
#   d_yz = coefficient of Z in Y ~ A + M + Z
# Rows where the residual variance of Z given (A, M) is numerically zero (the
# A, M, Z block is singular) return NA.
.mloc_bias <- function(S, sd, r) {
  cz <- sweep(r, 2L, sd, "*")
  W <- solve(S[1:2, 1:2]) # constant 2 x 2 inverse of the (A, M) block
  u <- cz[, 1:2, drop = FALSE] %*% W # Cov(A, M)^-1 Cov((A, M), Z)
  var_z_am <- 1 - rowSums(u * cz[, 1:2, drop = FALSE]) # Var(Z | A, M)
  cov_y_z <- cz[, 3L] - drop(u %*% S[1:2, 3L]) # Cov(Y, Z | A, M)
  var_z_a <- 1 - cz[, 1L]^2 / S[1L, 1L] # Var(Z | A)
  cov_m_z <- cz[, 2L] - S[1L, 2L] * cz[, 1L] / S[1L, 1L] # Cov(M, Z | A)
  singular <- !(var_z_am > .MLOC_SINGULAR)
  cbind(
    d_za = cz[, 1L] / S[1L, 1L],
    d_mz = cov_m_z / var_z_a,
    s_zm = u[, 2L],
    d_yz = ifelse(singular, NA_real_, cov_y_z / var_z_am)
  )
}

.mloc_adjust <- function(a0, b0, k) {
  cbind(a = a0 - k[, "d_mz"] * k[, "d_za"], b = b0 - k[, "d_yz"] * k[, "s_zm"])
}

.mloc_grid <- function(lv, r_za, r_zm, r_zy, screen) {
  g <- expand.grid(r_zm = r_zm, r_zy = r_zy, r_za = r_za)
  g <- g[, c("r_za", "r_zm", "r_zy")]
  r <- as.matrix(g)
  r2 <- ml_admissible(r, lv$cor)
  admissible <- r2 < 1
  compute <- if (screen == "pd") admissible else rep(TRUE, nrow(g))
  a_adj <- b_adj <- rep(NA_real_, nrow(g))
  if (any(compute)) {
    ab <- .mloc_adjust(
      lv$a, lv$b,
      .mloc_bias(unname(lv$cov), lv$sd, r[compute, , drop = FALSE])
    )
    a_adj[compute] <- ab[, "a"]
    b_adj[compute] <- ab[, "b"]
  }
  data.frame(
    g,
    a_adj = a_adj, b_adj = b_adj, ab_adj = a_adj * b_adj, r2 = r2,
    admissible = admissible, row.names = NULL
  )
}

.mloc_ranges <- function(grid) {
  keys <- unique(grid[, c("level", "r_za")])
  rows <- lapply(seq_len(nrow(keys)), function(i) {
    p <- grid[grid$level == keys$level[i] & grid$r_za == keys$r_za[i], ]
    ok <- is.finite(p$ab_adj)
    out <- data.frame(
      level = keys$level[i], r_za = keys$r_za[i],
      min = NA_real_, max = NA_real_,
      argmin_r_zm = NA_real_, argmin_r_zy = NA_real_,
      argmax_r_zm = NA_real_, argmax_r_zy = NA_real_,
      n_admitted = sum(p$admissible), n_total = nrow(p)
    )
    if (any(ok)) {
      q <- p[ok, ]
      lo <- which.min(q$ab_adj)
      hi <- which.max(q$ab_adj)
      out$min <- q$ab_adj[lo]
      out$max <- q$ab_adj[hi]
      out$argmin_r_zm <- q$r_zm[lo]
      out$argmin_r_zy <- q$r_zy[lo]
      out$argmax_r_zm <- q$r_zm[hi]
      out$argmax_r_zy <- q$r_zy[hi]
    }
    out
  })
  do.call(rbind, rows)
}

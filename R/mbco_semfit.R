# Optional SEMFit dispatch. Register the version-error route even for medfit
# 0.7.x (which exports SEMFit but does not provide the required comparison API).
.register_semfit_mbco <- function() {
  if (!"SEMFit" %in% getNamespaceExports("medfit")) {
    return(invisible(NULL))
  }
  cls <- getExportedValue("medfit", "SEMFit")
  S7::method(mbco, list(cls, cls)) <- .mbco_semfit
  S7::method(mbco, list(cls, S7::class_any)) <- .mbco_semfit_mixed
  S7::method(mbco, list(S7::class_any, cls)) <- .mbco_semfit_mixed
  invisible(NULL)
}

.mbco_semfit_mixed <- function(h0, h1, ...) {
  stop("mbco() requires two SEMFit objects or two OpenMx models; ",
    "mixed pairs are not supported.",
    call. = FALSE
  )
}

.mbco_semfit <- function(h0, h1, type = "asymp", alpha = .05, ...) {
  if (utils::packageVersion("medfit") < "0.8.0") {
    stop("mbco() for SEMFit requires medfit >= 0.8.0; ",
      "older medfit CI methods remain available.",
      call. = FALSE
    )
  }
  checkmate::assert_choice(type, "asymp")
  checkmate::assert_number(alpha, lower = 0, upper = 1, finite = TRUE)
  if (length(list(...))) {
    stop("unused arguments for SEMFit: ",
      "OpenMx fitting controls and other dots are not supported.",
      call. = FALSE
    )
  }
  if (!(h0@df > h1@df)) {
    stop("h0 must have more degrees of freedom than h1: ",
      "supply the restricted SEMFit first.",
      call. = FALSE
    )
  }
  comparison <- .mbco_semfit_compare(h0, h1)
  MBCOResult(
    statistic = as.numeric(comparison[2L, "Chisq diff"]),
    df = as.numeric(comparison[2L, "Df diff"]),
    p_value = as.numeric(comparison[2L, "Pr(>Chisq)"]), type = type
  )
}

# medfit 0.8.0 warns but returns a numeric p-value for an active tested bound.
# Match its specific public diagnostic; do not silence unrelated warnings or
# rely on medfit internals. Tests pin the diagnostic and refusal behavior.
.mbco_semfit_compare <- function(h0, h1) {
  withCallingHandlers(stats::anova(h1, h0), warning = function(w) {
    msg <- conditionMessage(w)
    boundary <- grepl("the null lies on the boundary of the parameter space",
      msg,
      fixed = TRUE
    )
    invalid <- grepl("its p-value is not valid", msg, fixed = TRUE)
    if (boundary && invalid) {
      stop("mbco() cannot report a chi-square p-value for a SEMFit null ",
        "on the boundary: ",
        conditionMessage(w),
        call. = FALSE
      )
    }
  })
}

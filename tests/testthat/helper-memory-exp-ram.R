# Fixture: OpenMx RAM mediation models on `memory_exp` (x -> {repetition, imagery} -> recall).
# Used by test-mbco-memory-exp-oracle.R. Requires OpenMx; callers skip first.

.memory_exp_data <- function() {
  d <- as.data.frame(RMediation::memory_exp) # mxData() rejects tibbles
  d$x <- as.numeric(d$x) - 1 # dummy code, as in the ?mbco example
  d
}

# Correctly labeled model: a1 = x -> repetition, a2 = x -> imagery, cp = x -> recall,
# b1 = repetition -> recall, b2 = imagery -> recall.
.memory_exp_ram <- function(name = "memory_example") {
  manifests <- c("x", "repetition", "imagery", "recall")
  OpenMx::mxModel(
    name,
    type = "RAM",
    manifestVars = manifests,
    OpenMx::mxPath(
      from = "x", to = c("repetition", "imagery", "recall"),
      arrows = 1, free = TRUE, values = .2, labels = c("a1", "a2", "cp")
    ),
    OpenMx::mxPath(
      from = "repetition", to = "recall",
      arrows = 1, free = TRUE, values = .2, labels = "b1"
    ),
    OpenMx::mxPath(
      from = "imagery", to = "recall",
      arrows = 1, free = TRUE, values = .2, labels = "b2"
    ),
    OpenMx::mxPath(from = manifests, arrows = 2, free = TRUE, values = .8),
    OpenMx::mxPath(from = "one", to = manifests, arrows = 1, free = TRUE, values = .1),
    OpenMx::mxData(observed = .memory_exp_data(), type = "raw")
  )
}

# The ?mbco example's model as written: endVar starts with "x", so the three labels
# are assigned to x -> {x, repetition, imagery, recall} and shift to a2, cp, a1.
# Only differences from the Rd: data coerced to data.frame, mxCI() omitted (no effect on the fit).
.memory_exp_ram_rd_shifted <- function(name = "memory_example_rd") {
  endVar <- c("x", "repetition", "imagery", "recall")
  manifests <- c("x", "repetition", "imagery", "recall")
  suppressWarnings(OpenMx::mxModel(
    name,
    type = "RAM",
    manifestVars = manifests,
    OpenMx::mxPath(
      from = "x", to = endVar,
      arrows = 1, free = TRUE, values = .2, labels = c("a1", "a2", "cp")
    ),
    OpenMx::mxPath(
      from = "repetition", to = "recall",
      arrows = 1, free = TRUE, values = .2, labels = "b1"
    ),
    OpenMx::mxPath(
      from = "imagery", to = "recall",
      arrows = 1, free = TRUE, values = .2, labels = "b2"
    ),
    OpenMx::mxPath(from = manifests, arrows = 2, free = TRUE, values = .8),
    OpenMx::mxPath(from = "one", to = endVar, arrows = 1, free = TRUE, values = .1),
    OpenMx::mxAlgebra(a1 * b1, name = "ind1"),
    OpenMx::mxAlgebra(a2 * b2, name = "ind2"),
    OpenMx::mxData(observed = .memory_exp_data(), type = "raw")
  ))
}

# Fit quietly; fail loudly on a non-OK optimizer status.
.mx_fit <- function(model) {
  fitted <- suppressMessages(
    OpenMx::mxTryHard(model, checkHess = FALSE, silent = TRUE, extraTries = 10)
  )
  code <- fitted$output$status$code
  if (is.null(code) || code > 1) {
    stop("OpenMx fit '", model$name, "' did not converge (status code ", code, ")")
  }
  fitted
}

# diffLL and df of `h0` against `h1` as mxCompare reports them (h1 = alternative).
.mx_lrt <- function(h1, h0) {
  cmp <- OpenMx::mxCompare(h1, h0)
  c(diffLL = cmp$diffLL[2], df = cmp$diffdf[2])
}

# Memoized fits for the oracle tests: the full model plus the linear nulls a1 == 0, b1 == 0,
# each fitted from the UNFITTED model. (Refitting a constraint from the full model's estimates
# can return an infeasible point: b1 == 0 then gives diffLL 0.)
.memory_exp_oracle <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) {
      base <- .memory_exp_ram("full")
      null_a1 <- OpenMx::mxModel(base, name = "a1_eq0", OpenMx::mxConstraint(a1 == 0, name = "c"))
      null_b1 <- OpenMx::mxModel(base, name = "b1_eq0", OpenMx::mxConstraint(b1 == 0, name = "c"))
      full <- .mx_fit(base)
      cache <<- list(full = full, null_a1 = .mx_fit(null_a1), null_b1 = .mx_fit(null_b1))
    }
    cache
  }
})

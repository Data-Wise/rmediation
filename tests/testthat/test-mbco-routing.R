test_that("public OpenMx dispatch validates controls before fitting", {
  skip_if_not_installed("OpenMx")
  h <- .memory_exp_ram()
  fits <- 0L
  local_mocked_bindings(mbco_asymp = function(...) {
    fits <<- fits + 1L
    list(chisq = 0, df = 1, p = 1)
  })
  bad <- list(
    R = list(0, -1, 1.5, NA_real_, Inf),
    alpha = list(-.1, 1.1, NA_real_, Inf),
    precision = list(-1, NA_real_, Inf),
    checkHess = list("maybe"), checkSE = list("maybe"),
    optim = list("unknown"), type = list("unknown")
  )
  for (arg in names(bad)) {
    for (value in bad[[arg]]) {
      call <- list(h0 = h, h1 = h)
      call[[arg]] <- value
      expect_error(do.call(mbco, call))
    }
  }
  expect_error(mbco(list(), h), "h0 must be an MxModel")
  expect_error(mbco(h, list()), "h1 must be an MxModel")
  expect_identical(fits, 0L)
})

test_that("public bootstrap routes preserve controls and result fields", {
  skip_if_not_installed("OpenMx")
  h <- .memory_exp_ram()
  seen <- NULL
  worker <- function(...) {
    seen <<- list(...)[c(
      "R", "alpha", "checkHess", "checkSE",
      "optim", "precision"
    )]
    list(chisq = 7.25, df = 2, p = .123)
  }
  local_mocked_bindings(mbco_parametric = worker, .mbco_semi = worker)
  local_mocked_bindings(imxHasNPSOL = function() FALSE, .package = "OpenMx")
  for (type in c("parametric", "semi")) {
    for (alpha in c(0, 1)) {
      r <- mbco(h, h,
        R = 3L, type = type, alpha = alpha,
        checkHess = "Yes", checkSE = "Yes", optim = "NPSOL", precision = 0
      )
      expect_identical(seen, list(
        R = 3L, alpha = alpha,
        checkHess = "Yes", checkSE = "Yes", optim = "SLSQP", precision = 0
      ))
      expect_identical(r@statistic, 7.25)
      expect_identical(r@df, 2)
      expect_identical(r@p_value, .123)
      expect_identical(r@type, type)
    }
  }
})

test_that("available NPSOL and worker failures propagate", {
  skip_if_not_installed("OpenMx")
  h <- .memory_exp_ram()
  local_mocked_bindings(imxHasNPSOL = function() TRUE, .package = "OpenMx")
  local_mocked_bindings(mbco_parametric = function(..., optim) {
    expect_identical(optim, "NPSOL")
    stop("bootstrap fit failed", call. = FALSE)
  }, .mbco_semi = function(...) stop("singular resampling covariance"))
  expect_error(mbco(h, h, type = "parametric", optim = "NPSOL"),
    "bootstrap fit failed",
    fixed = TRUE
  )
  expect_error(mbco(h, h, type = "semi"), "singular resampling covariance")
})

test_that("missing OpenMx gives installation guidance", {
  original <- base::requireNamespace
  local_mocked_bindings(requireNamespace = function(package, ...) {
    if (package == "OpenMx") {
      return(FALSE)
    }
    original(package, ...)
  }, .package = "base")
  expect_error(
    mbco(list(), list()), "Package 'OpenMx' is required",
    fixed = TRUE
  )
})

test_that("public bootstrap methods accept fitted RAM subclasses", {
  skip_if_not_installed("OpenMx")
  skip_if_not_installed("mvtnorm")
  f <- .memory_exp_oracle()
  expect_true(methods::is(f$full, "MxModel"))
  set.seed(471)
  for (type in c("parametric", "semi")) {
    r <- mbco(f$null_b1, f$full, type = type, R = 3L, optim = "SLSQP")
    expect_lt(abs(r@statistic - 0.083100), 1e-6)
    expect_identical(r@df, 1)
    expect_true(is.finite(r@p_value) && r@p_value >= 0 && r@p_value <= 1)
  }
})


test_that("df and optimizer mutants fail routing assertions", {
  skip_if_not_installed("OpenMx")
  h <- .memory_exp_ram()
  seen <- NULL
  local_mocked_bindings(imxHasNPSOL = function() FALSE, .package = "OpenMx")
  local_mocked_bindings(mbco_parametric = function(..., optim) {
    seen <<- optim
    list(chisq = 7.25, df = 2, p = .123)
  })
  original <- S7::method(mbco, list(S7::class_any, S7::class_any))
  mutate <- function(old, new) {
    source <- paste(deparse(body(original)), collapse = "\n")
    stopifnot(grepl(old, source, fixed = TRUE))
    copy <- original
    body(copy) <- parse(text = sub(old, new, source, fixed = TRUE))[[1L]]
    copy
  }
  wrong_df <- mutate("as.numeric(res_list$df)", "1")
  expect_failure(expect_identical(
    wrong_df(h, h, type = "parametric")@df, 2
  ))
  wrong_optim <- mutate('optim <- "SLSQP"', 'optim <- "NPSOL"')
  wrong_optim(h, h, type = "parametric", optim = "NPSOL")
  expect_failure(expect_identical(seen, "SLSQP"))
})

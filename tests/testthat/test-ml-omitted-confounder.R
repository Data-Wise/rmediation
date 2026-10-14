# Fixture: covariance estimates printed in the supplementary materials of
# Tofighi & Kelley (2016), Multivariate Behavioral Research 51(1), 86-105,
# https://doi.org/10.1080/00273171.2015.1105736 (figshare 2252944, CC BY 4.0).
# The supplement prints Mplus estimates to 3 decimals, in the order (m, y, x),
# so the tests pass var_order = c("M", "Y", "A"). a, b are the unadjusted paths.
.mloc_SW <- matrix(c(
  .351, .167, .062,
  .167, .474, .096,
  .062, .096, .793
), 3)
.mloc_SB <- matrix(c(
  .649, .475, -.001,
  .475, .526, -.024,
  -.001, -.024, .207
), 3)

.mloc_fit <- function(screen = "pd", r_za = c(0, .1, .3), ...) {
  ml_omitted_confounder(
    between = list(a = .024, b = .784, cov = .mloc_SB),
    within = list(a = .086, b = .433, cov = .mloc_SW),
    r_za = r_za, screen = screen, var_order = c("M", "Y", "A"), ...
  )
}

# Exact-precision expected values: computed from the same 3-decimal matrices by
# a separately coded script (sub-block solve() at every grid point), tolerance 1e-8.
.mloc_expected <- data.frame(
  level = rep(c("between", "within"), each = 3),
  r_za = rep(c(0, .1, .3), 2),
  none_min = c(
    0.0169582356626615, -0.0871860987700007, -0.372865686670506,
    0.0167564715380494, 0.011140331037193, -0.0161319774766511
  ),
  none_max = c(
    0.0318720283734971, 0.151829543795459, 0.446212794024116,
    0.0846321729502454, 0.121000516075252, 0.225834325902815
  ),
  pd_min = c(
    0.0169582356626615, -0.0708413055284973, -0.295776148989767,
    0.0167564715380494, 0.011140331037193, -0.0161319774766511
  ),
  pd_max = c(
    0.0259662292181144, 0.122889610643477, 0.347548892085637,
    0.0846321729502454, 0.121000516075252, 0.225834325902815
  ),
  n_adm = c(8539L, 8518L, 8289L, 10201L, 10201L, 10201L)
)
# Endpoints printed in the paper (pp. 99-100), 3 decimals, as listed in issue #33.
.mloc_paper <- data.frame(
  min = c(.017, -.087, -.372, .017, .011, -.016),
  max = c(.032, .152, .447, .085, .121, .226)
)
.MLOC_TOL_PAPER <- 0.001 # rounded fixture: 10 of 12 endpoints fall within 5e-4, worst 9e-4
.MLOC_TOL_EXACT <- 1e-8

test_that("published example: unscreened ranges match exact oracle and the paper", {
  res <- .mloc_fit("none")
  expect_s3_class(res, "RMediation::MLOmittedConfounder")
  expect_equal(res@ranges$min, .mloc_expected$none_min, tolerance = .MLOC_TOL_EXACT)
  expect_equal(res@ranges$max, .mloc_expected$none_max, tolerance = .MLOC_TOL_EXACT)
  expect_lte(max(abs(res@ranges$min - .mloc_paper$min)), .MLOC_TOL_PAPER)
  expect_lte(max(abs(res@ranges$max - .mloc_paper$max)), .MLOC_TOL_PAPER)
})

test_that("default screen: positive-definite points only, with known admitted counts", {
  res <- .mloc_fit("pd")
  expect_equal(res@ranges$min, .mloc_expected$pd_min, tolerance = .MLOC_TOL_EXACT)
  expect_equal(res@ranges$max, .mloc_expected$pd_max, tolerance = .MLOC_TOL_EXACT)
  expect_identical(res@ranges$n_admitted, .mloc_expected$n_adm)
  expect_true(all(res@ranges$n_total == 101L^2))
  # the default shrinks the between-level ranges; the paper's tables need "none"
  expect_lt(res@ranges$max[3], .mloc_expected$none_max[3] - 0.05)
})

test_that("r2 is r' R^-1 r and the screen is r2 < 1", {
  g <- as.data.frame(.mloc_fit("none"))
  expect_identical(g$admissible, g$r2 < 1)
  R <- stats::cov2cor(.mloc_SB[c(3, 1, 2), c(3, 1, 2)]) # A, M, Y order
  i <- which(g$level == "between")[c(1, 500, 7000)]
  r <- as.matrix(g[i, c("r_za", "r_zm", "r_zy")])
  expect_equal(g$r2[i], unname(drop(rowSums((r %*% solve(R)) * r))), tolerance = 1e-12)
  expect_equal(g$r2[i], unname(ml_admissible(r, R)), tolerance = 1e-12)
})

test_that("positive control holds at r_za = 0 only", {
  one <- ml_omitted_confounder(
    between = list(a = .3, b = .4, cov = diag(3) + .2 - diag(.2, 3)),
    r_za = 0, r_zm = 0, r_zy = 0
  )
  expect_equal(one@grid$ab_adj, one@unadjusted[["between"]], tolerance = 1e-12)
  moved <- ml_omitted_confounder(
    between = list(a = .3, b = .4, cov = diag(3) + .2 - diag(.2, 3)),
    r_za = .3, r_zm = 0, r_zy = 0
  )
  expect_gt(abs(moved@grid$ab_adj - one@unadjusted[["between"]]), 1e-3)
})

test_that("regression oracle: adjusted paths equal the full-model coefficients", {
  set.seed(20261014)
  n <- 5000
  z <- rnorm(n)
  a <- .4 * z + rnorm(n, sd = 1.2)
  m <- .3 * a + .5 * z + rnorm(n)
  y <- .25 * m + .1 * a + .35 * z + rnorm(n)
  zs <- as.numeric(scale(z))
  S <- unname(cov(cbind(a, m, y)))
  r <- c(cor(zs, a), cor(zs, m), cor(zs, y))
  a_star <- unname(coef(lm(m ~ a))["a"])
  b_star <- unname(coef(lm(y ~ a + m))["m"])
  res <- ml_omitted_confounder(
    between = list(a = a_star, b = b_star, cov = S),
    r_za = r[1], r_zm = r[2], r_zy = r[3], screen = "none"
  )
  expect_equal(res@grid$a_adj, unname(coef(lm(m ~ a + zs))["a"]), tolerance = 1e-8)
  expect_equal(res@grid$b_adj, unname(coef(lm(y ~ a + m + zs))["m"]), tolerance = 1e-8)

  # supplied a*, b* need not equal the covariance-implied values (as in the paper's example):
  # the bias term is what is subtracted, so a shifted a* shifts a_adj one for one
  shifted <- ml_omitted_confounder(
    between = list(a = a_star + .1, b = b_star, cov = S),
    r_za = r[1], r_zm = r[2], r_zy = r[3], screen = "none"
  )
  expect_equal(shifted@grid$a_adj, res@grid$a_adj + .1, tolerance = 1e-10)
})

test_that("sign symmetry holds pointwise on any grid", {
  a <- ml_omitted_confounder(
    between = list(a = .3, b = .4, cov = .mloc_SB),
    r_za = .2, r_zm = c(-.3, .1, .45), r_zy = c(-.2, .05, .4), var_order = c("M", "Y", "A"),
    screen = "none"
  )
  b <- ml_omitted_confounder(
    between = list(a = .3, b = .4, cov = .mloc_SB),
    r_za = -.2, r_zm = -c(-.3, .1, .45), r_zy = -c(-.2, .05, .4), var_order = c("M", "Y", "A"),
    screen = "none"
  )
  ga <- a@grid[order(a@grid$r_zm, a@grid$r_zy), ]
  gb <- b@grid[order(-b@grid$r_zm, -b@grid$r_zy), ]
  expect_equal(ga$ab_adj, gb$ab_adj, tolerance = 1e-12)
})

test_that("the screen admits what a per-coordinate check would not", {
  R <- stats::cov2cor(.mloc_SW[c(3, 1, 2), c(3, 1, 2)])
  bad <- matrix(c(.9, .9, -.9), 1)
  expect_gt(ml_admissible(bad, R), 1)
  naive <- function(r, R) as.numeric(max(abs(r)) < 1) # planted weak screen
  expect_identical(naive(bad, R), 1) # the naive screen would admit it
  expect_lt(ml_admissible(matrix(c(.1, .1, .1), 1), R), 1)
})

test_that("var_order is applied: pre-permuted input matches, and a wrong order differs", {
  P <- c(3, 1, 2)
  pre <- ml_omitted_confounder(
    between = list(a = .024, b = .784, cov = .mloc_SB[P, P]),
    r_za = c(0, .3), r_zm = seq(-.5, .5, .1), r_zy = seq(-.5, .5, .1), screen = "none"
  )
  ord <- ml_omitted_confounder(
    between = list(a = .024, b = .784, cov = .mloc_SB),
    r_za = c(0, .3), r_zm = seq(-.5, .5, .1), r_zy = seq(-.5, .5, .1), screen = "none",
    var_order = c("M", "Y", "A")
  )
  expect_identical(pre@grid, ord@grid)
  expect_identical(pre@ranges, ord@ranges)
  wrong <- ml_omitted_confounder(
    between = list(a = .024, b = .784, cov = .mloc_SB),
    r_za = c(0, .3), r_zm = seq(-.5, .5, .1), r_zy = seq(-.5, .5, .1), screen = "none"
  )
  expect_false(isTRUE(all.equal(wrong@grid$ab_adj, ord@grid$ab_adj)))
})

test_that("cor + sd input equals cov input", {
  S <- .mloc_SB[c(3, 1, 2), c(3, 1, 2)]
  a <- ml_omitted_confounder(between = list(a = .3, b = .4, cov = S), r_za = .1, r_zm = c(-.2, .2), r_zy = .1)
  b <- ml_omitted_confounder(
    between = list(a = .3, b = .4, cor = stats::cov2cor(S), sd = sqrt(diag(S))),
    r_za = .1, r_zm = c(-.2, .2), r_zy = .1
  )
  expect_equal(a@grid, b@grid, tolerance = 1e-12)
})

test_that("input validation refuses bad arguments with clear messages", {
  S <- .mloc_SB[c(3, 1, 2), c(3, 1, 2)]
  ok <- list(a = .3, b = .4, cov = S)
  call <- function(...) ml_omitted_confounder(r_zm = .1, r_zy = .1, ...)
  expect_error(call(), "At least one")
  expect_error(call(between = ok, screen = "bogus"), "should be one of")
  expect_error(call(between = ok, r_za = 1), "absolute value below 1")
  expect_error(call(between = ok, r_za = c(.1, .1)), "duplicate")
  expect_error(call(between = ok, r_za = numeric(0)))
  expect_error(call(between = ok, r_za = NA_real_))
  expect_error(ml_omitted_confounder(between = ok, r_zm = 1.2, r_zy = .1), "absolute value below 1")
  expect_error(ml_omitted_confounder(between = ok, r_zm = numeric(0), r_zy = .1))
  expect_error(call(between = list(a = NA, b = .4, cov = S)))
  expect_error(call(between = list(a = .3, b = Inf, cov = S)))
  expect_error(call(between = list(a = .3, b = .4)), "exactly one")
  expect_error(call(between = list(a = .3, b = .4, cov = S, cor = diag(3), sd = 1:3)), "exactly one")
  expect_error(call(between = list(a = .3, b = .4, cov = S + c(0, .1, 0, 0, 0, 0, 0, 0, 0))), "symmetric")
  expect_error(call(between = list(a = .3, b = .4, cov = matrix(1, 3, 3))), "positive definite")
  expect_error(call(between = list(a = .3, b = .4, cor = diag(3), sd = c(1, -1, 1))), "positive")
  expect_error(call(between = list(a = .3, b = .4, cor = diag(3) * 2, sd = c(1, 1, 1))), "unit diagonal")
  expect_error(call(between = ok, var_order = c("A", "M", "M")), "permutation")
  expect_error(call(between = ok, var_order = c("A", "M")))
  named <- S
  dimnames(named) <- list(c("m", "y", "x"), c("m", "y", "x"))
  expect_error(call(between = list(a = .3, b = .4, cov = named)), "var_order")
  dimnames(named) <- list(c("A", "M", "Y"), c("A", "M", "Y"))
  expect_s3_class(call(between = list(a = .3, b = .4, cov = named)), "RMediation::MLOmittedConfounder")
})

test_that("r_za list rules", {
  S <- .mloc_SB[c(3, 1, 2), c(3, 1, 2)]
  two <- function(r_za) {
    ml_omitted_confounder(
      between = list(a = .3, b = .4, cov = S), within = list(a = .2, b = .3, cov = S),
      r_za = r_za, r_zm = .1, r_zy = .1
    )
  }
  res <- two(list(between = .1, within = c(0, .3)))
  expect_identical(res@ranges$r_za, c(.1, 0, .3))
  expect_error(two(list(between = .1)), "missing for level")
  expect_error(two(list(between = .1, within = .1, extra = .2)), "names")
  expect_error(two(list(between = .1, between = .2)), "unique names")
  expect_error(
    ml_omitted_confounder(
      between = list(a = .3, b = .4, cov = S), r_za = list(between = .1, within = .1),
      r_zm = .1, r_zy = .1
    ),
    "no data"
  )
  # a single vector applies to every supplied level
  expect_identical(two(.1)@ranges$r_za, c(.1, .1))
})

test_that("degenerate points return NA instead of aborting or warning", {
  # R_AM = 0 and r_za^2 + r_zm^2 = 1 makes the (A, M, Z) block exactly singular
  expect_no_warning(
    res <- ml_omitted_confounder(
      between = list(a = .3, b = .4, cov = diag(3)),
      r_za = .6, r_zm = .8, r_zy = 0, screen = "none"
    )
  )
  expect_true(is.na(res@grid$ab_adj))
  expect_true(is.na(res@ranges$min))
  # no admissible points: NA ranges, zero admitted, no warning
  expect_no_warning(
    none <- ml_omitted_confounder(
      between = list(a = .3, b = .4, cov = diag(3)),
      r_za = .95, r_zm = c(.5, .6), r_zy = c(.5, .6)
    )
  )
  expect_identical(none@ranges$n_admitted, 0L)
  expect_true(is.na(none@ranges$min) && is.na(none@ranges$max))
  expect_output(print(none), "admitted 0 of 4")
  pdf(NULL)
  on.exit(dev.off(), add = TRUE)
  expect_no_error(plot(none))
})

test_that("methods: print, summary, as.data.frame and plot", {
  res <- .mloc_fit("pd", r_za = c(0, .3), r_zm = seq(-.5, .5, .05), r_zy = seq(-.5, .5, .05))
  out <- capture.output(print(res))
  expect_true(any(grepl("Unadjusted indirect effect", out)))
  expect_true(any(grepl("screen = \"none\" to reproduce", out)))
  expect_true(any(grepl("between", out)) && any(grepl("within", out)))
  expect_output(s <- summary(res), "Ranges of the adjusted indirect effect")
  expect_named(s, c("ranges", "sign_change"))
  expect_true(all(c("n_flip", "share_flip", "weakest_r_zm", "weakest_r_zy") %in% names(s$sign_change)))
  expect_gt(s$sign_change$n_flip[s$sign_change$level == "between" & s$sign_change$r_za == .3], 0)
  g <- as.data.frame(res)
  expect_s3_class(g, "data.frame")
  expect_named(g, c("level", "r_za", "r_zm", "r_zy", "a_adj", "b_adj", "ab_adj", "r2", "admissible"))
  expect_identical(rownames(as.data.frame(res, row.names = seq_len(nrow(g)))), as.character(seq_len(nrow(g))))
  pdf(NULL)
  on.exit(dev.off(), add = TRUE)
  expect_no_error(plot(res))
  expect_no_error(plot(res, level = "within", r_za = .3, type = "region"))
  expect_error(plot(res, level = "other"), "must be one of")
  expect_error(plot(res, r_za = .77), "must be one of")
  par_before <- par("mar")
  plot(res)
  expect_identical(par("mar"), par_before)
})

# Planted defects: each mutant must break an oracle above, so the oracles can fail.
test_that("planted defects are caught by the exact oracle", {
  skip_if_not_installed("testthat", "3.2.0")
  fit_pd <- function() .mloc_fit("pd", r_za = .3, r_zm = seq(-.5, .5, .25), r_zy = seq(-.5, .5, .25))
  ref <- fit_pd()
  differs <- function(x) !isTRUE(all.equal(x@grid$ab_adj, ref@grid$ab_adj, tolerance = 1e-8))
  # (1) sign error in the adjusted a path
  testthat::local_mocked_bindings(
    .mloc_adjust = function(a0, b0, k) {
      cbind(a = a0 + k[, "d_mz"] * k[, "d_za"], b = b0 - k[, "d_yz"] * k[, "s_zm"])
    },
    .package = "RMediation"
  )
  expect_true(differs(fit_pd()))
})

test_that("planted defect: a path built from the wrong regression", {
  skip_if_not_installed("testthat", "3.2.0")
  fit_pd <- function() .mloc_fit("pd", r_za = .3, r_zm = seq(-.5, .5, .25), r_zy = seq(-.5, .5, .25))
  ref <- fit_pd()
  orig <- RMediation:::.mloc_bias
  testthat::local_mocked_bindings(
    .mloc_bias = function(S, sd, r) {
      k <- orig(S, sd, r)
      k[, c("d_mz", "s_zm")] <- k[, c("s_zm", "d_mz")] # a from the wrong regression
      k
    },
    .package = "RMediation"
  )
  expect_false(isTRUE(all.equal(fit_pd()@grid$ab_adj, ref@grid$ab_adj, tolerance = 1e-8)))
})

test_that("vectorized coefficients equal a per-point solve() on sub-blocks", {
  # reference: solve() on sub-blocks of the 4 x 4 covariance of (A, M, Y, Z), Z standardized
  ref_bias <- function(S, sd, r) {
    t(vapply(seq_len(nrow(r)), function(i) {
      V <- rbind(cbind(S, r[i, ] * sd), c(r[i, ] * sd, 1))
      co <- function(y, x) solve(V[x, x, drop = FALSE], V[x, y])
      c(
        d_za = V[4, 1] / V[1, 1], d_mz = co(2, c(1, 4))[2],
        s_zm = co(4, c(1, 2))[2], d_yz = co(3, c(1, 2, 4))[3]
      )
    }, numeric(4)))
  }
  set.seed(14)
  S <- crossprod(matrix(rnorm(9), 3)) + diag(3)
  sd <- sqrt(diag(S))
  R <- stats::cov2cor(S)
  r <- matrix(runif(300, -.4, .4), ncol = 3)
  r <- r[ml_admissible(r, R) < 1, , drop = FALSE]
  expect_gt(nrow(r), 20)
  got <- RMediation:::.mloc_bias(S, sd, r)
  expect_equal(unname(got), unname(ref_bias(S, sd, r)), tolerance = 1e-10)
  expect_identical(colnames(got), c("d_za", "d_mz", "s_zm", "d_yz"))
})

test_that("planted defect: weakened screen is caught by the screened oracle", {
  skip_if_not_installed("testthat", "3.2.0")
  testthat::local_mocked_bindings(
    ml_admissible = function(r, R) {
      r <- matrix(r, ncol = 3L)
      apply(abs(r), 1, max)^2 # per-coordinate check only
    },
    .package = "RMediation"
  )
  res <- .mloc_fit("pd")
  expect_failure(expect_identical(res@ranges$n_admitted, .mloc_expected$n_adm))
})

test_that("planted defect: ignoring var_order is caught", {
  skip_if_not_installed("testthat", "3.2.0")
  orig <- RMediation:::.mloc_prepare_level
  testthat::local_mocked_bindings(
    .mloc_prepare_level = function(x, name, var_order) orig(x, name, c("A", "M", "Y")),
    .package = "RMediation"
  )
  res <- .mloc_fit("none")
  expect_failure(expect_equal(res@ranges$min, .mloc_expected$none_min, tolerance = .MLOC_TOL_EXACT))
})

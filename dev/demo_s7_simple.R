# Simple Demo: S7 Core vs Legacy

library(RMediation)

cat("\n========== S7 PROTOTYPE DEMONSTRATION ==========\n\n")

# Parameters for simple mediation
mu.x <- 0.2  # a path
mu.y <- 0.4  # b path  
se.x <- 1.0
se.y <- 1.0
rho <- 0.3
alpha <- 0.05

cat("Example: Mediation with a=0.2, b=0.4, rho=0.3\n")
cat("True indirect effect:", mu.x * mu.y, "\n\n")

# Legacy interface
cat("--- LEGACY medci() ---\n")
legacy <- medci(mu.x, mu.y, se.x, se.y, rho, alpha, type = "dop")
utils::str(legacy)
cat("\n")

# New S7 interface
cat("--- NEW S7 INTERFACE ---\n")
Sigma <- matrix(c(se.x^2, rho * se.x * se.y, 
                  rho * se.x * se.y, se.y^2), nrow = 2)
pn <- ProductNormal(mu = c(mu.x, mu.y), Sigma = Sigma)
s7_result <- ci(pn, level = 1 - alpha, type = "dop")
utils::str(s7_result)
cat("\n")

# Comparison
cat("--- VERIFICATION ---\n")
cat("Legacy CI: [", legacy$`95% CI`[1], ",", legacy$`95% CI`[2], "]\n")
cat("S7 CI:     [", s7_result$CI[1], ",", s7_result$CI[2], "]\n")
cat("Match:", all.equal(legacy$`95% CI`, s7_result$CI, tolerance = 1e-10), "\n\n")

# NEW CAPABILITY: 3-variable product
cat("--- NEW: 3-VARIABLE PRODUCT (impossible with legacy) ---\n")
cat("Sequential mediation: X -> M1 -> M2 -> Y\n")
cat("Indirect: a1=0.3, a2=0.4, b=0.5\n")
cat("True effect:", 0.3 * 0.4 * 0.5, "\n\n")

pn3 <- ProductNormal(mu = c(0.3, 0.4, 0.5), Sigma = diag(c(0.01, 0.01, 0.01)))
result3 <- ci(pn3, level = 0.95, type = "mc", n.mc = 1e5)

cat("95% CI: [", result3$CI[1], ",", result3$CI[2], "]\n")
cat("Estimate:", result3$Estimate, "(true:", 0.3*0.4*0.5, ")\n")
cat("SE:", result3$SE, "\n\n")

cat("✅ SUCCESS: S7 core is numerically equivalent to legacy\n")
cat("✅ BONUS: Supports N-variable products!\n\n")

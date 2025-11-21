# ==============================================================================
# Data Preparation Script: memory_exp
# ==============================================================================
#
# Purpose: Prepare the memory_exp dataset for the RMediation package
#
# Data Source:
#   MacKinnon, D. P., Valente, M. J., & Wurpts, I. C. (2018).
#   Benchmark validation of statistical models: Application to mediation
#   analysis of imagery and memory. Psychological Methods, 23, 654–671.
#   https://doi.org/10.1037/met0000174
#
# Supplemental Materials:
#   http://dx.doi.org/10.1037/met0000174.supp
#
# Description:
#   Data from eight replicated experiments collected on the first day of class
#   as part of Dr. MacKinnon's classroom teaching. Students participated in a
#   memory experiment to gain first-hand knowledge of experimental methods.
#
# Variables:
#   - study: Replication ID (1-8)
#   - repetition: Use of repetition rehearsal technique (1-12)
#   - recall: Total words recalled (3-20 out of 20 words)
#   - imagery: Use of imagery rehearsal technique (1-9 scale)
#   - x: Factor with two levels ("repetition" = primary, "imagery" = secondary)
#
# ==============================================================================

# Load the dataset (if reading from external source)
# NOTE: The current memory_exp.RData was already prepared and is in data/
# This script documents how it was originally prepared or can be updated

# If you need to recreate from raw data:
# memory_exp <- read.csv("path/to/raw/data.csv")

# Load existing data for validation
data(memory_exp, package = "RMediation")

# ------------------------------------------------------------------------------
# Data Validation
# ------------------------------------------------------------------------------

# Check structure
stopifnot(
  "memory_exp must be a data.frame" = is.data.frame(memory_exp),
  "memory_exp must have 369 rows" = nrow(memory_exp) == 369,
  "memory_exp must have 5 columns" = ncol(memory_exp) == 5,
  "Required columns missing" = all(c("study", "repetition", "recall", "imagery", "x") %in% names(memory_exp))
)

# Validate data ranges
stopifnot(
  "study should range from 1 to 8" = all(memory_exp$study %in% 1:8),
  "repetition should be positive" = all(memory_exp$repetition >= 1),
  "recall should be between 0-20" = all(memory_exp$recall >= 0 & memory_exp$recall <= 20),
  "imagery should be 1-9" = all(memory_exp$imagery >= 1 & memory_exp$imagery <= 9),
  "x should be a factor" = is.factor(memory_exp$x),
  "x should have correct levels" = all(levels(memory_exp$x) %in% c("repetition", "imagery"))
)

# Ensure x is a factor
if (!is.factor(memory_exp$x)) {
  memory_exp$x <- factor(memory_exp$x, levels = c(0, 1),
                         labels = c("repetition", "imagery"))
}

# ------------------------------------------------------------------------------
# Data Summary
# ------------------------------------------------------------------------------

cat("\n=== Memory Experiment Dataset Summary ===\n")
cat("Total observations:", nrow(memory_exp), "\n")
cat("Number of studies:", length(unique(memory_exp$study)), "\n")
cat("\nVariable summaries:\n")
print(summary(memory_exp))

cat("\nObservations per study:\n")
print(table(memory_exp$study))

cat("\nTreatment group distribution:\n")
print(table(memory_exp$x))

# ------------------------------------------------------------------------------
# Save to package data/
# ------------------------------------------------------------------------------

# Save as .RData for package use
usethis::use_data(memory_exp, overwrite = TRUE)

cat("\n✓ memory_exp dataset saved to data/memory_exp.rda\n")
cat("✓ Documentation is in R/memory_exp.R\n")
cat("\nTo use: data(memory_exp)\n")

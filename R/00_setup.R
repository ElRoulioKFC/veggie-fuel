# ============================================================================
# 00_setup.R — Install & load required packages
# ============================================================================
# Run this once when you first clone the project.
# After that, each script sources what it needs.
# ============================================================================

cat("── VeggieFuel Setup ──────────────────────────────────────────────\n")

required_packages <- c("dplyr", "readr", "tidyr", "ggplot2", "knitr", "scales")

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

invisible(lapply(required_packages, install_if_missing))
invisible(lapply(required_packages, library, character.only = TRUE))

cat("All packages loaded.\n")
cat("Project root:", getwd(), "\n")
cat("──────────────────────────────────────────────────────────────────\n\n")

# ============================================================================
# 00_setup.R — Install & load required packages
# ============================================================================
# Run this once when you first clone the project.
# After that, each script sources what it needs.
# ============================================================================

cat("── VeggieFuel Setup ──────────────────────────────────────────────\n")

required_packages <- c("dplyr", "readr", "tidyr", "ggplot2", "scales", "here", "lpSolve", "jsonlite")

user_lib <- Sys.getenv("R_LIBS_USER")
if (!dir.exists(user_lib)) dir.create(user_lib, recursive = TRUE)

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg, repos = "https://cloud.r-project.org", lib = user_lib)
  }
}

invisible(lapply(required_packages, install_if_missing))
invisible(lapply(required_packages, library, character.only = TRUE))

cat("All packages loaded.\n")
cat("Project root:", getwd(), "\n")
cat("──────────────────────────────────────────────────────────────────\n\n")

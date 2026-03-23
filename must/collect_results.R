# ============================================================================
# collect_results.R — Combine Monte Carlo simulation results
# ============================================================================
# Reads all output/sim_*.csv files from the batch simulation, combines
# them into a single summary table, and prints the top 10 plans by
# amino acid coverage.
#
# Usage:
#   Rscript must/collect_results.R
#
# Output:
#   output/all_simulations.csv — combined results sorted by coverage
# ============================================================================

if (!requireNamespace("here", quietly = TRUE)) {
  user_lib <- Sys.getenv("R_LIBS_USER")
  if (!dir.exists(user_lib)) dir.create(user_lib, recursive = TRUE)
  install.packages("here", repos = "https://cloud.r-project.org", lib = user_lib)
}

suppressPackageStartupMessages({
  library(here)
  library(readr)
  library(dplyr)
})

# ── Find simulation files ──────────────────────────────────────────────────

sim_files <- list.files(
  here::here("output"),
  pattern = "^sim_\\d+\\.csv$",
  full.names = TRUE
)

if (length(sim_files) == 0) {
  stop("No simulation files found in output/.\n",
       "Run the batch jobs first:\n",
       "  condor_submit must/run_batch.sub")
}

# ── Read and combine ──────────────────────────────────────────────────────

all_results <- lapply(sim_files, read_csv, show_col_types = FALSE) %>%
  bind_rows() %>%
  arrange(desc(min_amino_pct))

# ── Print summary ─────────────────────────────────────────────────────────

cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║        VeggieFuel — Monte Carlo Simulation Results              ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n\n")

cat(sprintf("Collected %d simulation results\n\n", nrow(all_results)))

cat("Top 10 by minimum amino acid coverage:\n\n")
print(head(all_results, 10), n = 10)

n_met <- sum(all_results$all_aminos_met)
cat(sprintf("\nSimulations meeting ALL amino targets: %d / %d (%.1f%%)\n",
            n_met, nrow(all_results), 100 * n_met / nrow(all_results)))

cat(sprintf("\nCalorie range: %d – %d kcal\n",
            min(all_results$total_kcal), max(all_results$total_kcal)))
cat(sprintf("Protein range: %.1f – %.1fg\n",
            min(all_results$total_protein), max(all_results$total_protein)))
cat(sprintf("Min amino coverage range: %.1f – %.1f%%\n",
            min(all_results$min_amino_pct), max(all_results$min_amino_pct)))

# ── Save combined results ─────────────────────────────────────────────────

output_path <- here::here("output", "all_simulations.csv")
write_csv(all_results, output_path)
cat(sprintf("\nFull results saved to %s\n", output_path))

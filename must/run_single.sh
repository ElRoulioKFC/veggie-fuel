#!/bin/bash
# ============================================================================
# run_single.sh — Run VeggieFuel meal planner as a single HTCondor job
# ============================================================================
# Generates optimized daily meal plans (trail, kayak, rest) and checks
# amino acid coverage. Optionally override the athlete weight via the
# VEGGIEFUEL_WEIGHT environment variable.
#
# Usage:
#   ./must/run_single.sh                     # default 60 kg
#   VEGGIEFUEL_WEIGHT=55 ./must/run_single.sh  # override to 55 kg
#
# Output:
#   output/trail_day_plan.csv
#   output/kayak_day_plan.csv
#   output/rest_day_plan.csv
# ============================================================================
set -euo pipefail

# Navigate to the project root (one level up from must/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║          VeggieFuel — Single Job (MUST Cluster)                 ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Working directory: $(pwd)"
echo "R_LIBS_USER: ${R_LIBS_USER:-not set}"
echo "VEGGIEFUEL_WEIGHT: ${VEGGIEFUEL_WEIGHT:-default (60 kg)}"
echo ""

# Run the meal planner via an inline R script.
# We source the dependency chain manually (NOT 03_meal_planner.R directly)
# because 03_meal_planner.R auto-runs the optimizer with the hardcoded
# 60 kg profile on lines 22-26. Instead, we source up to the optimizer,
# override the athlete profile, then call optimize_day_plan() ourselves.

Rscript --vanilla - <<'RSCRIPT'
library(here)

# Source the dependency chain: setup → food db → targets → optimizer
# Note: 03a_optimizer.R already sources 00_setup, 01_food_database, 02_targets
source(here::here("R", "03a_optimizer.R"))

# Source 03_meal_planner.R for its utility functions
# (calculate_plan_nutrition, summarize_plan, compare_macros, etc.)
# The top-level optimizer calls on lines 22-26 will run with defaults,
# but we'll re-run with our custom profile below.
source(here::here("R", "03_meal_planner.R"))

# Source amino check functions
source(here::here("R", "04_amino_check.R"))

# ── Override athlete weight if env var is set ──────────────────────────────

profile <- athlete  # copy default profile

weight_str <- Sys.getenv("VEGGIEFUEL_WEIGHT", unset = "")
if (nzchar(weight_str)) {
  w <- as.numeric(weight_str)
  if (is.na(w) || w <= 0 || w > 300) {
    stop("VEGGIEFUEL_WEIGHT must be a number between 1 and 300, got: ", weight_str)
  }
  profile$weight_kg <- w
  cat(sprintf("Using custom athlete weight: %g kg\n\n", w))
} else {
  cat(sprintf("Using default athlete weight: %g kg\n\n", profile$weight_kg))
}

# ── Generate optimized plans ───────────────────────────────────────────────

dir.create(here::here("output"), showWarnings = FALSE)

for (day_type in c("trail", "kayak", "rest")) {
  cat(sprintf("━━━ Optimizing %s day plan ━━━\n", toupper(day_type)))

  plan <- optimize_day_plan(day_type, profile = profile)

  if (is.null(plan)) {
    cat(sprintf("  WARNING: Optimizer returned no solution for %s day\n\n", day_type))
    next
  }

  # Calculate and save nutrition
  nutrition <- calculate_plan_nutrition(plan)
  output_path <- here::here("output", paste0(day_type, "_day_plan.csv"))
  write_csv(
    nutrition %>% select(meal, food, grams, all_of(c(macro_cols, amino_cols))),
    output_path
  )
  cat(sprintf("  Saved to %s\n", output_path))

  # Show summary
  totals <- summarize_plan(nutrition)
  cat(sprintf("  Total: %g kcal, %.1fg protein, %.1fg carbs, %.1fg fat\n",
              totals$kcal, totals$protein_g, totals$carbs_g, totals$fat_g))

  # Check amino coverage
  coverage <- check_amino_coverage(plan, profile = profile)
  deficient <- coverage %>% filter(status != "SUFFICIENT")
  if (nrow(deficient) == 0) {
    cat("  Amino acids: ALL SUFFICIENT\n")
  } else {
    cat(sprintf("  Amino acids: %d deficient or marginal\n", nrow(deficient)))
    for (j in seq_len(nrow(deficient))) {
      r <- deficient[j, ]
      cat(sprintf("    %s: %.0f%% (%s)\n", r$amino_acid, r$pct, r$status))
    }
  }
  cat("\n")
}

cat("Single job complete.\n")
RSCRIPT

echo ""
echo "Done! Check output/ for generated plans."

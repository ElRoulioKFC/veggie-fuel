# ============================================================================
# run_simulation.R — Monte Carlo food sampling simulation
# ============================================================================
# Randomly samples foods into 6 meals with random portion sizes,
# then checks whether the combination meets all essential amino acid
# requirements. Used by the batch HTCondor jobs (run_batch.sub) to
# explore which random food combos can cover amino acid needs.
#
# Usage:
#   Rscript must/run_simulation.R <seed>
#
# Output:
#   output/sim_<seed>.csv — one-row summary with:
#     seed, total_kcal, total_protein, min_amino_pct, all_aminos_met
# ============================================================================

# ── Parse command-line argument ─────────────────────────────────────────────

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Usage: Rscript must/run_simulation.R <seed>\n",
       "  Example: Rscript must/run_simulation.R 42")
}

seed <- as.integer(args[1])
if (is.na(seed)) stop("Seed must be an integer, got: ", args[1])
set.seed(seed)

# ── Load project dependencies ──────────────────────────────────────────────

if (!requireNamespace("here", quietly = TRUE)) {
  user_lib <- Sys.getenv("R_LIBS_USER")
  if (!dir.exists(user_lib)) dir.create(user_lib, recursive = TRUE)
  install.packages("here", repos = "https://cloud.r-project.org", lib = user_lib)
}

source(here::here("R", "00_setup.R"))
source(here::here("R", "01_food_database.R"))
source(here::here("R", "02_targets.R"))
source(here::here("R", "04_amino_check.R"))

# ── Simulation parameters ──────────────────────────────────────────────────

# 6 meals, with varying number of foods per meal
# Main meals get 3 foods, snacks/recovery get 1 = 12 foods total
meal_structure <- list(
  "Breakfast"  = 3,
  "Snack AM"   = 1,
  "Lunch"      = 3,
  "Snack PM"   = 1,
  "Dinner"     = 3,
  "Recovery"   = 1
)

# Portion bounds by food category (grams)
# Upper bounds based on default_max_per_meal from R/03a_optimizer.R
portion_bounds <- list(
  grain     = c(40, 250),
  legume    = c(40, 200),
  soy       = c(40, 200),
  dairy_egg = c(30, 150),
  nut_seed  = c(10,  50),
  vegetable = c(30, 250),
  fruit     = c(30, 200),
  protein   = c(20,  80),
  sport     = c(10,  40)
)
default_bounds <- c(20, 150)

# ── Sample random foods and portions ───────────────────────────────────────

sampled <- list()

for (meal_name in names(meal_structure)) {
  n_foods <- meal_structure[[meal_name]]

  # Sample food indices without replacement
  chosen_idx <- sample(nrow(foods), n_foods, replace = FALSE)

  for (i in chosen_idx) {
    # Get portion bounds for this food's category
    cat_name <- foods$category[i]
    bounds <- if (cat_name %in% names(portion_bounds)) {
      portion_bounds[[cat_name]]
    } else {
      default_bounds
    }

    # Random portion within bounds, rounded to nearest 5g
    grams <- round(runif(1, bounds[1], bounds[2]) / 5) * 5
    grams <- max(grams, bounds[1])  # ensure at least the minimum

    sampled[[length(sampled) + 1]] <- tibble(
      meal  = meal_name,
      food  = foods$food[i],
      grams = grams
    )
  }
}

plan <- bind_rows(sampled)

# ── Evaluate amino acid coverage ───────────────────────────────────────────

coverage <- tryCatch(
  check_amino_coverage(plan),
  error = function(e) {
    cat(sprintf("Seed %d: ERROR — %s\n", seed, conditionMessage(e)))
    quit(status = 1)
  }
)

# ── Compute nutrition totals ───────────────────────────────────────────────

nutrition <- plan %>%
  left_join(foods, by = "food") %>%
  mutate(across(all_of(c(macro_cols, amino_cols)), ~ .x * grams / 100))

total_kcal    <- sum(nutrition$kcal)
total_protein <- sum(nutrition$protein_g)
min_amino_pct <- min(coverage$pct)
all_aminos_met <- all(coverage$pct >= 100)

# ── Save one-row summary ──────────────────────────────────────────────────

result <- tibble(
  seed           = seed,
  total_kcal     = round(total_kcal, 0),
  total_protein  = round(total_protein, 1),
  min_amino_pct  = round(min_amino_pct, 1),
  all_aminos_met = all_aminos_met
)

dir.create(here::here("output"), showWarnings = FALSE)
output_path <- here::here("output", sprintf("sim_%d.csv", seed))
write_csv(result, output_path)

cat(sprintf("Seed %d: %.0f kcal, %.1fg protein, min amino %.1f%%, all met: %s → %s\n",
            seed, total_kcal, total_protein, min_amino_pct,
            ifelse(all_aminos_met, "YES", "NO"), output_path))

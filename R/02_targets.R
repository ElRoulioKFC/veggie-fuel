# ============================================================================
# 02_targets.R — Athlete profile & daily nutrient targets
# ============================================================================
# Define your athlete profile and compute personalized daily targets for
# macros and essential amino acids.
#
# References:
#   - Protein: 1.6–1.8 g/kg for vegetarian endurance athletes (PMC5598028)
#   - Carbs:   6–8 g/kg for endurance (ACSM/AND/DC joint position, 2016)
#   - Fat:     25–30% of total kcal
#   - Amino acids: WHO/FAO/UNU 2007 safe intake levels (mg/kg/day)
# ============================================================================

suppressPackageStartupMessages(library(dplyr))

# ── Athlete Profile ──────────────────────────────────────────────────────────
# Edit these values to match your own stats!

athlete <- list(
  name           = "Athlete",
  weight_kg      = 60,
  sport_primary  = "trail",     # "trail" or "kayak"
  sport_secondary = "kayak",
  training_hours_week = 10,     # hours per week
  goal           = "performance" # "performance", "muscle_gain", or "weight_loss"
)

# ── Macro Targets ────────────────────────────────────────────────────────────

compute_macro_targets <- function(profile) {
  w <- profile$weight_kg

  # Protein: 1.6–1.8 g/kg for veg endurance athletes (use 1.7 midpoint)
  protein_g <- w * 1.7

  # Carbs: 6–8 g/kg for endurance training (use 7 midpoint)
  carbs_g <- w * 7

  # Estimate total kcal from protein + carbs, then derive fat
  protein_kcal <- protein_g * 4
  carbs_kcal   <- carbs_g * 4
  # Fat = ~27% of total → total = (protein_kcal + carbs_kcal) / 0.73
  total_kcal   <- (protein_kcal + carbs_kcal) / 0.73
  fat_kcal     <- total_kcal * 0.27
  fat_g        <- fat_kcal / 9

  # Fiber (25–35 g)
  fiber_g <- 30

  tibble(
    nutrient    = c("kcal", "protein_g", "carbs_g", "fat_g", "fiber_g"),
    daily_target = round(c(total_kcal, protein_g, carbs_g, fat_g, fiber_g), 0),
    unit        = c("kcal", "g", "g", "g", "g"),
    notes       = c(
      "Endurance training day estimate",
      sprintf("1.7 g/kg × %g kg", w),
      sprintf("7 g/kg × %g kg", w),
      "~27%% of total kcal",
      "Adequate intake range"
    )
  )
}

# ── Amino Acid Targets ───────────────────────────────────────────────────────
# WHO/FAO/UNU 2007 safe levels for adults (mg/kg body weight/day)

amino_requirements_per_kg <- tibble(
  amino_acid = c("leucine", "isoleucine", "valine", "lysine",
                  "methionine", "threonine", "tryptophan",
                  "phenylalanine", "histidine"),
  mg_per_kg  = c(39, 20, 26, 30, 10.4, 15, 4, 25, 10),
  csv_column = c("leucine_mg", "isoleucine_mg", "valine_mg", "lysine_mg",
                  "methionine_mg", "threonine_mg", "tryptophan_mg",
                  "phenylalanine_mg", "histidine_mg"),
  notes      = c("BCAA — muscle repair", "BCAA — energy", "BCAA — tissue repair",
                  "Often limiting in grains!", "Includes cysteine requirement",
                  "Collagen & gut health", "Serotonin precursor",
                  "Includes tyrosine requirement", "Needed for growth/repair")
)

compute_amino_targets <- function(profile) {
  amino_requirements_per_kg %>%
    mutate(
      daily_min_mg = round(mg_per_kg * profile$weight_kg, 0),
      for_weight   = sprintf("%g kg", profile$weight_kg)
    )
}

# ── Sport-specific adjustments ───────────────────────────────────────────────

sport_day_adjustments <- tibble(
  sport  = c("trail", "kayak", "rest"),
  carb_pct  = c(0.58, 0.52, 0.50),
  protein_pct = c(0.16, 0.19, 0.18),
  fat_pct   = c(0.26, 0.29, 0.32),
  kcal_mult = c(1.10, 1.00, 0.80),
  description = c(
    "Trail day: high carb for long effort, moderate protein",
    "Kayak day: higher protein for upper body, moderate carb",
    "Rest day: reduced calories, maintain protein"
  )
)

# ── Compute & display ────────────────────────────────────────────────────────

macro_targets <- compute_macro_targets(athlete)
amino_targets <- compute_amino_targets(athlete)

cat("── Athlete Profile ───────────────────────────────────────────────\n")
cat(sprintf("  Name: %s | Weight: %g kg | Sports: %s + %s\n",
            athlete$name, athlete$weight_kg,
            athlete$sport_primary, athlete$sport_secondary))
cat(sprintf("  Training: %g hrs/week | Goal: %s\n",
            athlete$training_hours_week, athlete$goal))
cat("──────────────────────────────────────────────────────────────────\n\n")

cat("Daily Macro Targets:\n")
print(macro_targets, n = Inf)
cat("\nDaily Essential Amino Acid Minimums:\n")
print(amino_targets %>% select(amino_acid, daily_min_mg, notes), n = Inf)
cat("\nSport-Day Adjustments:\n")
print(sport_day_adjustments, n = Inf)
cat("\n")

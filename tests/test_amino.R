# ============================================================================
# tests/test_amino.R — Validation tests for VeggieFuel
# ============================================================================
# Run with: Rscript tests/test_amino.R
# ============================================================================

suppressPackageStartupMessages(library(here))

cat("Running VeggieFuel tests...\n\n")

errors <- 0
tests  <- 0

# Helper
assert <- function(condition, msg) {
  tests <<- tests + 1
  if (condition) {
    cat(sprintf("  PASS: %s\n", msg))
  } else {
    cat(sprintf("  FAIL: %s\n", msg))
    errors <<- errors + 1
  }
}

# ── Test 1: Food database loads correctly ────────────────────────────────────

suppressMessages(source(here::here("R", "01_food_database.R")))

assert(nrow(foods) > 50, "Food database has 50+ entries")
assert(all(amino_cols %in% names(foods)), "All amino acid columns present")
assert(all(foods$kcal > 0), "All foods have positive calories")
assert(all(foods$protein_g >= 0), "All foods have non-negative protein")
assert("portable" %in% names(foods), "Food database has portable column")
assert("prep_minutes" %in% names(foods), "Food database has prep_minutes column")
assert(all(foods[amino_cols] >= 0), "All amino acid values are non-negative")

# ── Test 2: Targets compute correctly ────────────────────────────────────────

suppressMessages(source(here::here("R", "02_targets.R")))

assert(nrow(macro_targets) == 5, "5 macro targets computed")
assert(nrow(amino_targets) == 9, "9 amino acid targets computed")
assert(all(amino_targets$daily_min_mg > 0), "All amino targets are positive")

# For a 60 kg athlete, protein should be ~102 g (1.7 * 60)
protein_target <- macro_targets$daily_target[macro_targets$nutrient == "protein_g"]
assert(protein_target >= 90 & protein_target <= 120,
       sprintf("Protein target (%g g) is in reasonable range for 60 kg", protein_target))

# ── Test 3: Profile validation ───────────────────────────────────────────────

err <- tryCatch(compute_macro_targets(list(weight_kg = -10)), error = function(e) e)
assert(inherits(err, "error"), "Negative weight causes error")

err <- tryCatch(compute_macro_targets(list()), error = function(e) e)
assert(inherits(err, "error"), "Missing weight causes error")

err <- tryCatch(compute_amino_targets(list(weight_kg = 0)), error = function(e) e)
assert(inherits(err, "error"), "Zero weight causes error in amino targets")

# ── Test 4: Scaling works ────────────────────────────────────────────────────

tofu <- foods %>% filter(food == "Tofu (firm)")
scaled <- scale_to_serving(tofu, 200)
assert(abs(scaled$protein_g - tofu$protein_g * 2) < 0.01,
       "200g tofu has 2x the protein of 100g")

# ── Test 5: Protein efficiency handles edge cases ────────────────────────────

assert(is.data.frame(protein_efficiency()), "protein_efficiency returns data frame")
assert(nrow(protein_efficiency()) > 0, "protein_efficiency returns non-empty result")

# ── Test 6: Amino coverage function ──────────────────────────────────────────

suppressMessages(source(here::here("R", "04_amino_check.R")))

# A massive amount of food should cover all amino acids
big_combo <- tibble(
  food  = c("Tofu (firm)", "Lentils (cooked)", "Oats (dry)", "Eggs"),
  grams = c(500, 500, 200, 200)
)

coverage <- check_amino_coverage(big_combo)

assert(all(coverage$pct > 100), "Large mixed meal covers all amino acids")
assert("status" %in% names(coverage), "Coverage output has status column")

# ── Test 7: Join validation catches misspelled foods ─────────────────────────

suppressMessages(source(here::here("R", "03_meal_planner.R")))

bad_plan <- tibble(food = c("Tofuu (firm)"), grams = c(100))
err <- tryCatch(calculate_plan_nutrition(bad_plan), error = function(e) e)
assert(inherits(err, "error"), "Misspelled food name causes error in calculate_plan_nutrition")
assert(grepl("Tofuu", err$message), "Error message names the bad food")

bad_plan2 <- tibble(food = c("Tofuu (firm)"), grams = c(100))
err2 <- tryCatch(check_amino_coverage(bad_plan2), error = function(e) e)
assert(inherits(err2, "error"), "Misspelled food name causes error in check_amino_coverage")

# ── Test 8: Compare functions produce valid output ───────────────────────────

# Use the optimizer-generated trail plan (already loaded by 03_meal_planner.R)
assert(!is.null(trail_day_plan), "Optimizer generated a trail day plan")

nutrition <- calculate_plan_nutrition(trail_day_plan)
totals <- summarize_plan(nutrition)

macro_comp <- compare_macros(totals)
assert(all(macro_comp$status %in% c("OK", "LOW", "DEFICIENT")),
       "Macro comparison produces valid statuses")
assert(all(macro_comp$pct > 0), "All macro percentages are positive")

amino_comp <- compare_aminos(totals)
assert(all(amino_comp$status %in% c("OK", "LOW", "DEFICIENT")),
       "Amino comparison produces valid statuses")
assert(all(amino_comp$pct > 0), "All amino percentages are positive")

# ── Test 9: Optimizer produces valid plans ───────────────────────────────────

# Trail plan meets all amino acid targets
assert(all(amino_comp$pct >= 100), "Optimized trail plan meets all amino acid targets")

# Kayak, climbing, swimming, and rest plans exist
assert(!is.null(kayak_day_plan), "Optimizer generated a kayak day plan")
assert(!is.null(climbing_day_plan), "Optimizer generated a climbing day plan")
assert(!is.null(swimming_day_plan), "Optimizer generated a swimming day plan")
assert(!is.null(rest_day_plan), "Optimizer generated a rest day plan")

# All plans have correct columns
for (plan_name in c("trail_day_plan", "kayak_day_plan", "climbing_day_plan",
                     "swimming_day_plan", "rest_day_plan")) {
  plan <- get(plan_name)
  if (!is.null(plan)) {
    assert(all(c("meal", "food", "grams") %in% names(plan)),
           sprintf("%s has meal, food, grams columns", plan_name))
  }
}

# ── Test 10: Day-type adjusted targets ───────────────────────────────────────

trail_targets <- adjust_targets_for_day("trail")
rest_targets  <- adjust_targets_for_day("rest")
assert(trail_targets$daily_target[1] > rest_targets$daily_target[1],
       "Trail day has more kcal than rest day")

kayak_targets <- adjust_targets_for_day("kayak")
assert(kayak_targets$daily_target[1] > rest_targets$daily_target[1],
       "Kayak day has more kcal than rest day")

climbing_targets <- adjust_targets_for_day("climbing")
assert(climbing_targets$daily_target[1] > rest_targets$daily_target[1],
       "Climbing day has more kcal than rest day")

swimming_targets <- adjust_targets_for_day("swimming")
assert(swimming_targets$daily_target[1] > rest_targets$daily_target[1],
       "Swimming day has more kcal than rest day")

err <- tryCatch(adjust_targets_for_day("curling"), error = function(e) e)
assert(inherits(err, "error"), "Unknown day type causes error")

# ── Test 11: Food locks work ─────────────────────────────────────────────────

locked_plan <- optimize_day_plan(
  "trail",
  locks = tibble(food = "Oats (dry)", meal = "Breakfast", min_grams = 60)
)
assert(!is.null(locked_plan), "Locked plan is not NULL")
if (!is.null(locked_plan)) {
  oats_rows <- locked_plan %>% filter(food == "Oats (dry)", meal == "Breakfast")
  assert(nrow(oats_rows) > 0 && oats_rows$grams[1] >= 55,
         "Food lock: oats in breakfast >= 55g (after rounding)")
}

# ── Test 12: Edge case — small athlete ───────────────────────────────────────

small_athlete <- list(
  weight_kg = 40, sport_primary = "trail",
  sport_secondary = "kayak", training_hours_week = 6,
  goal = "performance"
)
small_targets <- compute_macro_targets(small_athlete)
assert(small_targets$daily_target[small_targets$nutrient == "protein_g"] > 0,
       "40kg athlete has positive protein target")

small_plan <- optimize_day_plan("trail", profile = small_athlete)
assert(!is.null(small_plan), "Optimizer handles 40kg athlete")

# ── Test 13: Male athlete profile ──────────────────────────────────────────

male_athlete <- list(
  sex = "male", height_cm = 178, weight_kg = 75, age_years = 30,
  sport_primary = "trail", sport_secondary = "kayak",
  training_hours_week = 10, goal = "performance"
)
male_targets <- compute_macro_targets(male_athlete)
female_targets <- compute_macro_targets(athlete)

assert(male_targets$daily_target[male_targets$nutrient == "kcal"] >
       female_targets$daily_target[female_targets$nutrient == "kcal"],
       "75kg male athlete has higher kcal than 60kg female athlete")

male_plan <- optimize_day_plan("trail", profile = male_athlete)
assert(!is.null(male_plan), "Optimizer handles male athlete profile")

# ── Test 14: Backward compatibility — profile without sex/height/age ──────

legacy_profile <- list(
  weight_kg = 65, sport_primary = "trail",
  sport_secondary = "kayak", training_hours_week = 8,
  goal = "performance"
)
legacy_targets <- compute_macro_targets(legacy_profile)
assert(legacy_targets$daily_target[legacy_targets$nutrient == "protein_g"] > 0,
       "Legacy profile (no sex/height/age) still works with defaults")

# ── Results ──────────────────────────────────────────────────────────────────

cat(sprintf("\n%d tests run, %d failed.\n", tests, errors))

if (errors > 0) {
  cat("SOME TESTS FAILED!\n")
  quit(status = 1)
} else {
  cat("ALL TESTS PASSED.\n")
}

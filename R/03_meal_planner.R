# ============================================================================
# 03_meal_planner.R — Generate daily meal plans for trail/kayak sportswomen
# ============================================================================
# Creates a sample daily meal plan with 6 eating occasions and checks
# whether the plan meets macro + amino acid targets.
# ============================================================================

source("R/00_setup.R")
source("R/01_food_database.R")
source("R/02_targets.R")

# ── Meal Templates ───────────────────────────────────────────────────────────
# Each meal is a list of (food, grams) pairs.
# These are hand-designed to complement amino acid profiles:
#   - Legumes + grains cover lysine + methionine
#   - Soy products are complete on their own
#   - Seeds add methionine, tryptophan, and healthy fats
#   - Dairy/eggs round out the profile for lacto-ovo vegetarians

trail_day_plan <- tribble(
  ~meal,          ~food,                     ~grams,
  # ── Breakfast: high carb + complete protein ──
  "Breakfast",    "Oats (dry)",               80,
  "Breakfast",    "Soy milk (unsweetened)",   250,
  "Breakfast",    "Banana",                   120,
  "Breakfast",    "Hemp seeds",                20,
  "Breakfast",    "Peanut butter",             20,
  # ── Morning snack: pre-trail ──
  "Snack AM",     "Whole wheat bread",         60,
  "Snack AM",     "Hummus",                    60,
  "Snack AM",     "Avocado",                   50,
  # ── Lunch: protein + carb recovery ──
  "Lunch",        "Quinoa (cooked)",          200,
  "Lunch",        "Black beans (cooked)",     150,
  "Lunch",        "Spinach (cooked)",         100,
  "Lunch",        "Pumpkin seeds",             20,
  "Lunch",        "Avocado",                   50,
  # ── Afternoon snack: during/post trail ──
  "Snack PM",     "Banana",                   120,
  "Snack PM",     "Almonds",                   30,
  "Snack PM",     "Greek yogurt",             150,
  # ── Dinner: complementary proteins ──
  "Dinner",       "Tofu (firm)",              150,
  "Dinner",       "Brown rice (cooked)",      200,
  "Dinner",       "Broccoli (cooked)",        150,
  "Dinner",       "Sesame seeds",              15,
  "Dinner",       "Edamame",                  100,
  # ── Evening recovery ──
  "Recovery",     "Cottage cheese",           150,
  "Recovery",     "Chia seeds",                15,
  "Recovery",     "Banana",                    80,
)

kayak_day_plan <- tribble(
  ~meal,          ~food,                     ~grams,
  # ── Breakfast: higher protein start ──
  "Breakfast",    "Eggs",                     120,
  "Breakfast",    "Whole wheat bread",         80,
  "Breakfast",    "Avocado",                   70,
  "Breakfast",    "Spinach (cooked)",          60,
  # ── Morning snack ──
  "Snack AM",     "Greek yogurt",             200,
  "Snack AM",     "Pumpkin seeds",             20,
  "Snack AM",     "Banana",                   100,
  # ── Lunch: legume + grain combo ──
  "Lunch",        "Lentils (cooked)",         200,
  "Lunch",        "Buckwheat groats (cooked)",150,
  "Lunch",        "Sweet potato (baked)",     150,
  "Lunch",        "Tahini",                    20,
  "Lunch",        "Broccoli (cooked)",        100,
  # ── Afternoon snack ──
  "Snack PM",     "Hummus",                    80,
  "Snack PM",     "Whole wheat bread",         50,
  "Snack PM",     "Almonds",                   25,
  # ── Dinner: tempeh stir-fry ──
  "Dinner",       "Tempeh",                   150,
  "Dinner",       "Pasta (whole wheat cooked)",180,
  "Dinner",       "Broccoli (cooked)",        100,
  "Dinner",       "Sunflower seeds",           15,
  "Dinner",       "Nutritional yeast",         10,
  # ── Recovery ──
  "Recovery",     "Cottage cheese",           150,
  "Recovery",     "Hemp seeds",                15,
  "Recovery",     "Flaxseed",                  10,
)

# ── Calculate totals for a meal plan ─────────────────────────────────────────

calculate_plan_nutrition <- function(plan, food_db = foods) {
  plan %>%
    left_join(food_db, by = "food") %>%
    mutate(
      across(all_of(c(macro_cols, amino_cols)), ~ .x * grams / 100)
    )
}

summarize_plan <- function(plan_nutrition) {
  plan_nutrition %>%
    summarize(
      across(all_of(c(macro_cols, amino_cols)), ~ round(sum(.x, na.rm = TRUE), 1))
    )
}

summarize_by_meal <- function(plan_nutrition) {
  plan_nutrition %>%
    group_by(meal) %>%
    summarize(
      foods   = paste(food, collapse = " + "),
      kcal    = round(sum(kcal, na.rm = TRUE), 0),
      protein = round(sum(protein_g, na.rm = TRUE), 1),
      carbs   = round(sum(carbs_g, na.rm = TRUE), 1),
      fat     = round(sum(fat_g, na.rm = TRUE), 1),
      .groups = "drop"
    )
}

# ── Compare plan vs targets ──────────────────────────────────────────────────

compare_macros <- function(plan_totals, targets = macro_targets) {
  tibble(
    nutrient = targets$nutrient,
    target   = targets$daily_target,
    actual   = as.numeric(plan_totals[1, targets$nutrient]),
    pct      = round(actual / target * 100, 0),
    status   = case_when(
      pct >= 90  ~ "OK",
      pct >= 75  ~ "LOW",
      TRUE       ~ "DEFICIENT"
    )
  )
}

compare_aminos <- function(plan_totals, targets = amino_targets) {
  targets %>%
    mutate(
      actual_mg = as.numeric(plan_totals[1, csv_column]),
      pct       = round(actual_mg / daily_min_mg * 100, 0),
      status    = case_when(
        pct >= 100 ~ "OK",
        pct >= 80  ~ "LOW",
        TRUE       ~ "DEFICIENT"
      )
    ) %>%
    select(amino_acid, daily_min_mg, actual_mg, pct, status)
}

# ── Run it! ──────────────────────────────────────────────────────────────────

cat("╔══════════════════════════════════════════════════════════════════╗\n")
cat("║             VeggieFuel — Daily Meal Plan Generator              ║\n")
cat("╚══════════════════════════════════════════════════════════════════╝\n\n")

for (day_type in c("trail", "kayak")) {
  plan <- if (day_type == "trail") trail_day_plan else kayak_day_plan
  cat(sprintf("━━━ %s Day Plan ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n",
              toupper(day_type)))

  nutrition <- calculate_plan_nutrition(plan)
  totals    <- summarize_plan(nutrition)
  by_meal   <- summarize_by_meal(nutrition)

  # Show meals
  cat("Meals:\n")
  for (i in seq_len(nrow(by_meal))) {
    row <- by_meal[i, ]
    cat(sprintf("  %-12s %4d kcal | P: %5.1fg | C: %5.1fg | F: %4.1fg\n",
                row$meal, row$kcal, row$protein, row$carbs, row$fat))
    cat(sprintf("               %s\n", row$foods))
  }

  # Macro comparison
  cat("\nMacro Targets vs. Actual:\n")
  macro_comp <- compare_macros(totals)
  for (i in seq_len(nrow(macro_comp))) {
    r <- macro_comp[i, ]
    flag <- if (r$status == "OK") "✓" else if (r$status == "LOW") "⚠" else "✗"
    cat(sprintf("  %s %-10s  target: %5.0f  actual: %5.0f  (%3.0f%%) %s\n",
                flag, r$nutrient, r$target, r$actual, r$pct, r$status))
  }

  # Amino comparison
  cat("\nAmino Acid Coverage:\n")
  amino_comp <- compare_aminos(totals)
  for (i in seq_len(nrow(amino_comp))) {
    r <- amino_comp[i, ]
    flag <- if (r$status == "OK") "✓" else if (r$status == "LOW") "⚠" else "✗"
    cat(sprintf("  %s %-15s  min: %5.0f mg  actual: %5.0f mg  (%3.0f%%) %s\n",
                flag, r$amino_acid, r$daily_min_mg, r$actual_mg, r$pct, r$status))
  }
  cat("\n")
}

# ── Save plans to CSV ────────────────────────────────────────────────────────

dir.create("output", showWarnings = FALSE)

trail_nutrition <- calculate_plan_nutrition(trail_day_plan)
kayak_nutrition <- calculate_plan_nutrition(kayak_day_plan)

write_csv(trail_nutrition %>% select(meal, food, grams, all_of(c(macro_cols, amino_cols))),
          "output/trail_day_plan.csv")
write_csv(kayak_nutrition %>% select(meal, food, grams, all_of(c(macro_cols, amino_cols))),
          "output/kayak_day_plan.csv")

cat("Plans saved to output/trail_day_plan.csv and output/kayak_day_plan.csv\n")

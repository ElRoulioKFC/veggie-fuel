# ============================================================================
# 01_food_database.R — Load & explore the vegetarian food nutrient database
# ============================================================================
# This script loads data/foods.csv which contains macronutrient and essential
# amino acid data per 100 g for ~40 vegetarian foods.
#
# Sources: USDA FoodData Central, nutrition research literature.
# Amino acid values are approximate and based on averages.
# ============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

# ── Load the database ────────────────────────────────────────────────────────

foods <- read_csv("data/foods.csv", show_col_types = FALSE)

# Amino acid columns for easy reference
amino_cols <- c(
  "leucine_mg", "isoleucine_mg", "valine_mg", "lysine_mg",
  "methionine_mg", "threonine_mg", "tryptophan_mg",
  "phenylalanine_mg", "histidine_mg"
)

macro_cols <- c("kcal", "protein_g", "carbs_g", "fat_g", "fiber_g")

# ── Helper functions ─────────────────────────────────────────────────────────

#' Scale nutrient values from per-100g to a given serving size
#' @param food_row A single row from the foods tibble
#' @param grams   Serving size in grams
#' @return Named list with all nutrient values scaled
scale_to_serving <- function(food_row, grams) {
  multiplier <- grams / 100
  nutrient_cols <- c(macro_cols, amino_cols)
  scaled <- food_row
  scaled[nutrient_cols] <- scaled[nutrient_cols] * multiplier
  scaled$serving_g <- grams
  scaled
}

#' Get protein per calorie ratio (higher = more protein-efficient)
#' @param df Foods dataframe
#' @return df with protein_per_100kcal column, sorted descending
protein_efficiency <- function(df = foods) {
  df %>%
    mutate(protein_per_100kcal = round(protein_g / kcal * 100, 1)) %>%
    arrange(desc(protein_per_100kcal)) %>%
    select(food, category, kcal, protein_g, protein_per_100kcal)
}

#' Find top foods for a specific amino acid
#' @param amino  Column name (e.g. "lysine_mg")
#' @param n      Number of results
top_foods_for_amino <- function(amino, n = 10, df = foods) {
  df %>%
    arrange(desc(.data[[amino]])) %>%
    select(food, category, protein_g, all_of(amino)) %>%
    head(n)
}

# ── Print summary ────────────────────────────────────────────────────────────

cat("── Food Database Loaded ──────────────────────────────────────────\n")
cat(sprintf("  %d foods across %d categories\n",
            nrow(foods), n_distinct(foods$category)))
cat("  Categories:", paste(unique(foods$category), collapse = ", "), "\n")
cat("──────────────────────────────────────────────────────────────────\n\n")

# Quick peek
cat("Top 10 most protein-efficient foods (g protein per 100 kcal):\n")
print(protein_efficiency(), n = 10)
cat("\n")

# ============================================================================
# 07_recipes.R — Recipe system for VeggieFuel
# ============================================================================
# Loads recipes from data/recipes.json, calculates nutrition from the food
# database, and matches recipes to optimizer-generated meal plans.
# ============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(jsonlite)
  library(here)
})

source(here::here("R", "01_food_database.R"))

# ── Load recipes ─────────────────────────────────────────────────────────────

load_recipes <- function(path = here::here("data", "recipes.json")) {
  raw <- tryCatch(
    fromJSON(path, simplifyVector = FALSE),
    error = function(e) {
      stop("Could not load recipes at ", path, "\n",
           "  Original error: ", conditionMessage(e), call. = FALSE)
    }
  )
  raw$recipes
}

# ── Calculate nutrition for a recipe ─────────────────────────────────────────

recipe_nutrition <- function(recipe, food_db = foods) {
  ingredients <- recipe$ingredients
  nutrient_cols <- c(macro_cols, amino_cols)

  totals <- setNames(rep(0, length(nutrient_cols)), nutrient_cols)

  for (ing in ingredients) {
    food_row <- food_db %>% filter(food == ing$food)
    if (nrow(food_row) == 0) {
      warning("Recipe '", recipe$name, "': food '", ing$food,
              "' not found in database, skipping")
      next
    }
    scale <- ing$grams / 100
    for (col in nutrient_cols) {
      totals[col] <- totals[col] + food_row[[col]][1] * scale
    }
  }

  as_tibble(as.list(round(totals, 1)))
}

# ── Per-serving nutrition ────────────────────────────────────────────────────

recipe_per_serving <- function(recipe, food_db = foods) {
  total <- recipe_nutrition(recipe, food_db)
  total %>% mutate(across(everything(), ~ round(.x / recipe$servings, 1)))
}

# ── Match recipes to a meal plan ─────────────────────────────────────────────

match_recipes_to_plan <- function(plan, recipes = NULL, food_db = foods) {
  if (is.null(recipes)) recipes <- load_recipes()

  all_plan_foods <- unique(plan$food)
  meal_slots <- unique(plan$meal)

  results <- list()

  for (slot in meal_slots) {
    slot_matches <- list()

    for (recipe in recipes) {
      meal_types <- unlist(recipe$mealTypes)
      if (!(slot %in% meal_types)) next

      ingredient_foods <- sapply(recipe$ingredients, function(i) i$food)
      matched <- intersect(ingredient_foods, all_plan_foods)
      missing <- setdiff(ingredient_foods, all_plan_foods)
      score <- length(matched) / length(ingredient_foods)

      if (score >= 0.4) {
        slot_matches <- c(slot_matches, list(list(
          recipe = recipe,
          score  = score,
          matched_foods = matched,
          missing_foods = missing
        )))
      }
    }

    # Sort by score descending, take top 3
    if (length(slot_matches) > 0) {
      scores <- sapply(slot_matches, function(m) m$score)
      slot_matches <- slot_matches[order(scores, decreasing = TRUE)]
      slot_matches <- head(slot_matches, 3)
    }

    results[[slot]] <- slot_matches
  }

  results
}

# ── Pretty-print a recipe ───────────────────────────────────────────────────

print_recipe <- function(recipe, food_db = foods) {
  total_time <- recipe$prepMinutes + recipe$cookMinutes

  cat(sprintf("\n╔══ %s ══╗\n", recipe$name))
  cat(sprintf("  %s\n", recipe$description))
  cat(sprintf("  Meal types: %s\n", paste(unlist(recipe$mealTypes), collapse = ", ")))
  cat(sprintf("  Servings: %d | Prep: %d min | Cook: %d min | Total: %d min\n",
              recipe$servings, recipe$prepMinutes, recipe$cookMinutes, total_time))

  cat("\n  Ingredients:\n")
  for (ing in recipe$ingredients) {
    cat(sprintf("    - %dg %s\n", ing$grams, ing$food))
  }

  cat("\n  Instructions:\n")
  for (i in seq_along(recipe$steps)) {
    cat(sprintf("    %d. %s\n", i, recipe$steps[[i]]))
  }

  nutrition <- recipe_per_serving(recipe, food_db)
  cat(sprintf("\n  Per serving: %d kcal | P: %.1fg | C: %.1fg | F: %.1fg | Fiber: %.1fg\n",
              round(nutrition$kcal), nutrition$protein_g, nutrition$carbs_g,
              nutrition$fat_g, nutrition$fiber_g))
  cat("╚", strrep("═", nchar(recipe$name) + 6), "╝\n", sep = "")
}

# ── Run it! (only when run directly) ─────────────────────────────────────────

if (sys.nframe() == 0) {
  cat("╔══════════════════════════════════════════════════════════════════╗\n")
  cat("║               VeggieFuel — Recipe Cookbook                      ║\n")
  cat("╚══════════════════════════════════════════════════════════════════╝\n\n")

  recipes <- load_recipes()
  cat(sprintf("Loaded %d recipes from data/recipes.json\n\n", length(recipes)))

  for (recipe in recipes) {
    print_recipe(recipe)
  }

  # ── Demo: match recipes to a plan ──────────────────────────────────────
  source(here::here("R", "02_targets.R"))
  source(here::here("R", "03a_optimizer.R"))

  cat("\n\n── Recipe Suggestions for Trail Day ────────────────────────────\n")
  trail_plan <- optimize_day_plan("trail")

  if (!is.null(trail_plan)) {
    matches <- match_recipes_to_plan(trail_plan, recipes)

    for (slot in names(matches)) {
      slot_matches <- matches[[slot]]
      if (length(slot_matches) == 0) next

      cat(sprintf("\n  %s:\n", slot))
      for (m in slot_matches) {
        cat(sprintf("    %s (%d%% match)\n", m$recipe$name,
                    round(m$score * 100)))
        cat(sprintf("      Matched: %s\n",
                    paste(m$matched_foods, collapse = ", ")))
        if (length(m$missing_foods) > 0) {
          cat(sprintf("      Missing: %s\n",
                      paste(m$missing_foods, collapse = ", ")))
        }
      }
    }
  } else {
    cat("  Could not generate trail day plan for demo.\n")
  }
}

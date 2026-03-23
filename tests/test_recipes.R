# ============================================================================
# tests/test_recipes.R — Validation tests for the recipe system
# ============================================================================
# Run with: Rscript tests/test_recipes.R
# ============================================================================

suppressPackageStartupMessages(library(here))

cat("Running VeggieFuel recipe tests...\n\n")

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

# ── Source recipe module ─────────────────────────────────────────────────────

suppressMessages(source(here::here("R", "07_recipes.R")))

# ── Test 1: Recipe loading ───────────────────────────────────────────────────

cat("\n── Test 1: Recipe loading ──\n")
recipes <- load_recipes()

assert(length(recipes) >= 10, sprintf("At least 10 recipes loaded (got %d)", length(recipes)))
assert(is.list(recipes), "Recipes is a list")

first <- recipes[[1]]
assert(!is.null(first$id), "First recipe has id field")
assert(!is.null(first$name), "First recipe has name field")
assert(!is.null(first$ingredients), "First recipe has ingredients field")
assert(!is.null(first$steps), "First recipe has steps field")
assert(!is.null(first$mealTypes), "First recipe has mealTypes field")
assert(!is.null(first$servings), "First recipe has servings field")
assert(first$servings > 0, "First recipe has positive servings")

# ── Test 2: All recipe ingredients exist in food database ────────────────────

cat("\n── Test 2: Ingredient validation ──\n")
all_food_names <- foods$food
missing_count <- 0

for (recipe in recipes) {
  for (ing in recipe$ingredients) {
    if (!(ing$food %in% all_food_names)) {
      cat(sprintf("  WARNING: Recipe '%s' references unknown food '%s'\n",
                  recipe$name, ing$food))
      missing_count <- missing_count + 1
    }
  }
}

assert(missing_count == 0,
       sprintf("All recipe ingredients found in food database (%d missing)", missing_count))

# ── Test 3: Recipe nutrition calculation ─────────────────────────────────────

cat("\n── Test 3: Nutrition calculation ──\n")

for (recipe in recipes) {
  nutrition <- recipe_nutrition(recipe)
  assert(nutrition$kcal > 0,
         sprintf("'%s' has positive calories (%g kcal)", recipe$name, nutrition$kcal))
  assert(nutrition$protein_g >= 0,
         sprintf("'%s' has non-negative protein", recipe$name))
}

# ── Test 4: Per-serving calculation ──────────────────────────────────────────

cat("\n── Test 4: Per-serving nutrition ──\n")
test_recipe <- recipes[[1]]
total <- recipe_nutrition(test_recipe)
per_srv <- recipe_per_serving(test_recipe)

assert(abs(per_srv$kcal - total$kcal / test_recipe$servings) < 1,
       sprintf("Per-serving kcal matches total / servings for '%s'", test_recipe$name))
assert(abs(per_srv$protein_g - total$protein_g / test_recipe$servings) < 0.2,
       sprintf("Per-serving protein matches total / servings for '%s'", test_recipe$name))

# ── Test 5: Recipe matching ──────────────────────────────────────────────────

cat("\n── Test 5: Recipe matching ──\n")

# Create a fake plan with known foods from the first recipe
fake_plan <- tibble::tibble(
  meal  = rep("Breakfast", length(test_recipe$ingredients)),
  food  = sapply(test_recipe$ingredients, function(i) i$food),
  grams = sapply(test_recipe$ingredients, function(i) i$grams)
)

matches <- match_recipes_to_plan(fake_plan, recipes)
assert(is.list(matches), "match_recipes_to_plan returns a list")

# The first recipe should match its own ingredients perfectly
breakfast_matches <- matches[["Breakfast"]]
if (length(breakfast_matches) > 0 && "Breakfast" %in% unlist(test_recipe$mealTypes)) {
  matched_names <- sapply(breakfast_matches, function(m) m$recipe$name)
  assert(test_recipe$name %in% matched_names,
         sprintf("Recipe '%s' matches plan with its own ingredients", test_recipe$name))

  # Find the match for this recipe and verify score
  for (m in breakfast_matches) {
    if (m$recipe$name == test_recipe$name) {
      assert(m$score == 1.0,
             sprintf("Perfect match score (1.0) for '%s' with its own ingredients", test_recipe$name))
      break
    }
  }
} else {
  cat("  SKIP: First recipe is not a Breakfast recipe, skipping self-match test\n")
}

# ── Test 6: Recipe structure validation ──────────────────────────────────────

cat("\n── Test 6: Recipe structure ──\n")
valid_meal_types <- c("Breakfast", "Snack AM", "Lunch", "Snack PM", "Dinner", "Recovery")

for (recipe in recipes) {
  meal_types <- unlist(recipe$mealTypes)
  all_valid <- all(meal_types %in% valid_meal_types)
  assert(all_valid,
         sprintf("'%s' has valid meal types: %s", recipe$name, paste(meal_types, collapse = ", ")))

  assert(length(recipe$ingredients) >= 2,
         sprintf("'%s' has at least 2 ingredients", recipe$name))

  assert(length(recipe$steps) >= 2,
         sprintf("'%s' has at least 2 steps", recipe$name))

  for (ing in recipe$ingredients) {
    assert(ing$grams > 0,
           sprintf("'%s': %s has positive grams (%g)", recipe$name, ing$food, ing$grams))
  }
}

# ── Test 7: Unique IDs ──────────────────────────────────────────────────────

cat("\n── Test 7: Unique IDs ──\n")
ids <- sapply(recipes, function(r) r$id)
assert(length(ids) == length(unique(ids)),
       sprintf("All recipe IDs are unique (%d recipes, %d unique IDs)",
               length(ids), length(unique(ids))))

# ── Summary ──────────────────────────────────────────────────────────────────

cat(sprintf("\n══ Results: %d tests, %d passed, %d failed ══\n",
            tests, tests - errors, errors))

if (errors > 0) {
  stop(sprintf("%d test(s) failed!", errors), call. = FALSE)
} else {
  cat("All recipe tests passed!\n")
}

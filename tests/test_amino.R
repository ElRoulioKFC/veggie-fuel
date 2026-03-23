# ============================================================================
# tests/test_amino.R — Basic validation tests
# ============================================================================
# Run with: Rscript tests/test_amino.R
# ============================================================================

cat("Running VeggieFuel tests...\n\n")

errors <- 0

# Helper
assert <- function(condition, msg) {
  if (condition) {
    cat(sprintf("  PASS: %s\n", msg))
  } else {
    cat(sprintf("  FAIL: %s\n", msg))
    errors <<- errors + 1
  }
}

# ── Test 1: Food database loads correctly ────────────────────────────────────

suppressMessages(source("R/01_food_database.R"))

assert(nrow(foods) > 30, "Food database has 30+ entries")
assert(all(amino_cols %in% names(foods)), "All amino acid columns present")
assert(all(foods$kcal > 0), "All foods have positive calories")
assert(all(foods$protein_g >= 0), "All foods have non-negative protein")

# ── Test 2: Targets compute correctly ────────────────────────────────────────

suppressMessages(source("R/02_targets.R"))

assert(nrow(macro_targets) == 5, "5 macro targets computed")
assert(nrow(amino_targets) == 9, "9 amino acid targets computed")
assert(all(amino_targets$daily_min_mg > 0), "All amino targets are positive")

# For a 60 kg athlete, protein should be ~102 g (1.7 * 60)
protein_target <- macro_targets$daily_target[macro_targets$nutrient == "protein_g"]
assert(protein_target >= 90 & protein_target <= 120,
       sprintf("Protein target (%g g) is in reasonable range for 60 kg", protein_target))

# ── Test 3: Scaling works ────────────────────────────────────────────────────

tofu <- foods %>% filter(food == "Tofu (firm)")
scaled <- scale_to_serving(tofu, 200)
assert(abs(scaled$protein_g - tofu$protein_g * 2) < 0.01,
       "200g tofu has 2x the protein of 100g")

# ── Test 4: Amino coverage function ─────────────────────────────────────────

# A massive amount of food should cover all amino acids
big_combo <- tibble(
  food  = c("Tofu (firm)", "Lentils (cooked)", "Oats (dry)", "Eggs"),
  grams = c(500, 500, 200, 200)
)

suppressMessages({
  coverage <- check_amino_coverage(big_combo)
})

assert(all(coverage$pct > 100), "Large mixed meal covers all amino acids")
assert("status" %in% names(coverage), "Coverage output has status column")

# ── Results ──────────────────────────────────────────────────────────────────

cat(sprintf("\n%d tests run, %d failed.\n",
            4 + 4 + 1 + 2, errors))  # count of assert calls

if (errors > 0) {
  cat("SOME TESTS FAILED!\n")
  quit(status = 1)
} else {
  cat("ALL TESTS PASSED.\n")
}

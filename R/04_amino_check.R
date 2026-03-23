# ============================================================================
# 04_amino_check.R — Amino acid coverage analysis & visualization
# ============================================================================
# Analyzes your meal plan's amino acid profile against WHO/FAO requirements.
# Generates a visual coverage chart and suggests fixes for any gaps.
# ============================================================================

if (!requireNamespace("here", quietly = TRUE)) install.packages("here", repos = "https://cloud.r-project.org")
source(here::here("R", "00_setup.R"))
source(here::here("R", "01_food_database.R"))
source(here::here("R", "02_targets.R"))

# ── Analyze amino acid coverage for a food combination ───────────────────────

#' Check amino acid coverage for a set of foods + servings
#' @param food_servings A tibble with columns: food (character), grams (numeric)
#' @param profile       Athlete profile list (needs weight_kg)
#' @return Tibble with amino acid name, target, actual, pct, status
check_amino_coverage <- function(food_servings, profile = athlete) {
  targets <- compute_amino_targets(profile)

  nutrition <- food_servings %>%
    left_join(foods, by = "food")

  unmatched <- nutrition %>% filter(is.na(kcal)) %>% pull(food) %>% unique()
  if (length(unmatched) > 0) {
    stop("Foods not found in database: ", paste(unmatched, collapse = ", "),
         "\nCheck spelling against data/foods.csv")
  }

  nutrition <- nutrition %>%
    mutate(across(all_of(amino_cols), ~ .x * grams / 100))

  actual_totals <- nutrition %>%
    summarize(across(all_of(amino_cols), ~ sum(.x)))

  targets %>%
    rowwise() %>%
    mutate(
      actual_mg = pull(actual_totals, csv_column),
      pct       = round(actual_mg / daily_min_mg * 100, 1),
      status    = case_when(
        pct >= 100 ~ "SUFFICIENT",
        pct >= 80  ~ "MARGINAL",
        TRUE       ~ "DEFICIENT"
      )
    ) %>%
    ungroup() %>%
    select(amino_acid, daily_min_mg, actual_mg, pct, status, notes)
}

# ── Suggest fixes for deficient amino acids ──────────────────────────────────

suggest_fixes <- function(coverage) {
  deficient <- coverage %>% filter(status != "SUFFICIENT")

  if (nrow(deficient) == 0) {
    cat("All essential amino acids are covered! No fixes needed.\n")
    return(invisible(NULL))
  }

  # Mapping: which foods are best for which amino acids
  fix_suggestions <- list(
    leucine       = c("Soy (tofu, tempeh, edamame)", "Pumpkin seeds", "Cheese"),
    isoleucine    = c("Tofu", "Eggs", "Lentils", "Seaweed"),
    valine        = c("Soy products", "Peanuts", "Mushrooms"),
    lysine        = c("Beans & lentils", "Tofu", "Quinoa", "Pistachios"),
    methionine    = c("Eggs", "Sesame seeds", "Brazil nuts", "Oats"),
    threonine     = c("Lentils", "Cottage cheese", "Sesame seeds", "Spirulina"),
    tryptophan    = c("Cheese", "Oats", "Tofu", "Pumpkin seeds"),
    phenylalanine = c("Soy products", "Almonds", "Eggs", "Peanuts"),
    histidine     = c("Tofu", "Wheat germ", "Rice", "Beans")
  )

  cat("\n── Suggested Fixes ────────────────────────────────────────────\n")
  for (i in seq_len(nrow(deficient))) {
    aa   <- deficient$amino_acid[i]
    gap  <- deficient$daily_min_mg[i] - deficient$actual_mg[i]
    fixes <- fix_suggestions[[aa]]
    cat(sprintf("\n  ⚠ %s — missing ~%.0f mg\n", toupper(aa), gap))
    cat(sprintf("    Add: %s\n", paste(fixes, collapse = ", ")))
  }
  cat("──────────────────────────────────────────────────────────────\n")
}

# ── Visualization ────────────────────────────────────────────────────────────

plot_amino_coverage <- function(coverage, title = "Amino Acid Coverage (% of daily minimum)") {
  coverage %>%
    mutate(
      amino_acid = factor(amino_acid, levels = rev(amino_acid)),
      fill_color = case_when(
        pct >= 100 ~ "Sufficient",
        pct >= 80  ~ "Marginal",
        TRUE       ~ "Deficient"
      )
    ) %>%
    ggplot(aes(x = pct, y = amino_acid, fill = fill_color)) +
    geom_col(width = 0.7) +
    geom_vline(xintercept = 100, linetype = "dashed", color = "gray30", linewidth = 0.5) +
    geom_text(aes(label = sprintf("%.0f%%", pct)),
              hjust = -0.2, size = 3.2, color = "gray20") +
    scale_fill_manual(
      values = c("Sufficient" = "#4caf50", "Marginal" = "#ff9800", "Deficient" = "#f44336"),
      name = "Status"
    ) +
    scale_x_continuous(limits = c(0, max(coverage$pct) * 1.15),
                       labels = scales::percent_format(scale = 1)) +
    labs(
      title    = title,
      subtitle = sprintf("Athlete: %g kg | Target: WHO/FAO safe intake levels",
                          athlete$weight_kg),
      x = "% of daily minimum",
      y = NULL
    ) +
    theme_minimal(base_size = 12) +
    theme(
      plot.title    = element_text(face = "bold", size = 14),
      plot.subtitle = element_text(color = "gray50", size = 10),
      legend.position = "bottom",
      panel.grid.major.y = element_blank()
    )
}

# ── Run analysis (only when run directly) ─────────────────────────────────────

if (sys.nframe() == 0) {
  cat("╔══════════════════════════════════════════════════════════════════╗\n")
  cat("║           VeggieFuel — Amino Acid Coverage Analysis             ║\n")
  cat("╚══════════════════════════════════════════════════════════════════╝\n\n")

  # Load meal plan from shared CSV (single source of truth)
  trail_plan <- read_csv(here::here("data", "trail_day_plan.csv"), show_col_types = FALSE)

  cat("━━━ TRAIL DAY — Amino Acid Coverage ━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n")
  trail_coverage <- check_amino_coverage(trail_plan)
  print(trail_coverage %>% select(amino_acid, daily_min_mg, actual_mg, pct, status), n = Inf)
  suggest_fixes(trail_coverage)

  # Generate chart
  dir.create(here::here("output"), showWarnings = FALSE)

  p <- plot_amino_coverage(trail_coverage, "Trail Day — Amino Acid Coverage")
  ggsave(here::here("output", "amino_coverage_trail.png"), p, width = 9, height = 5, dpi = 150)
  cat("\nChart saved to output/amino_coverage_trail.png\n")

  # ── Also check a custom food combo (interactive use) ───────────────────────

  cat("\n\n━━━ Quick Check: Custom Food Combo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
  cat("Example: checking if a single meal covers amino acids\n\n")

  example_meal <- tibble(
    food  = c("Lentils (cooked)", "Brown rice (cooked)", "Spinach (cooked)", "Pumpkin seeds"),
    grams = c(250, 200, 100, 30)
  )

  single_meal_coverage <- check_amino_coverage(example_meal)
  print(single_meal_coverage %>% select(amino_acid, daily_min_mg, actual_mg, pct, status), n = Inf)
  suggest_fixes(single_meal_coverage)

  cat("\n── Done! ──────────────────────────────────────────────────────\n")
  cat("Edit the meal plans in data/trail_day_plan.csv to customize.\n")
  cat("Use check_amino_coverage() with any food+grams tibble.\n")
}

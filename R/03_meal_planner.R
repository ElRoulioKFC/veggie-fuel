# ============================================================================
# 03_meal_planner.R — Generate daily meal plans for vegetarian athletes
# ============================================================================
# Uses the LP optimizer (03a_optimizer.R) to generate optimized daily plans
# for trail, kayak, climbing, swimming, and rest days. Falls back to
# CSV-based plans if the optimizer is not available.
# ============================================================================

if (!requireNamespace("here", quietly = TRUE)) {
  user_lib <- Sys.getenv("R_LIBS_USER")
  if (!dir.exists(user_lib)) dir.create(user_lib, recursive = TRUE)
  install.packages("here", repos = "https://cloud.r-project.org", lib = user_lib)
}
source(here::here("R", "00_setup.R"))
source(here::here("R", "01_food_database.R"))
source(here::here("R", "02_targets.R"))
source(here::here("R", "03a_optimizer.R"))

# ── Generate or load meal plans ────────────────────────────────────────────
# Optimizer is the default; CSV fallback if plans exist and optimizer fails

trail_day_plan    <- optimize_day_plan("trail")
kayak_day_plan    <- optimize_day_plan("kayak")
climbing_day_plan <- optimize_day_plan("climbing")
swimming_day_plan <- optimize_day_plan("swimming")
rest_day_plan     <- optimize_day_plan("rest")

# CSV fallback if optimizer returned NULL
for (dt in c("trail", "kayak", "climbing", "swimming")) {
  plan_var <- paste0(dt, "_day_plan")
  if (is.null(get(plan_var))) {
    csv_path <- here::here("data", paste0(dt, "_day_plan.csv"))
    if (file.exists(csv_path)) {
      assign(plan_var, read_csv(csv_path, show_col_types = FALSE), envir = .GlobalEnv)
      message("Using CSV fallback for ", dt, " day plan")
    }
  }
}

# ── Calculate totals for a meal plan ─────────────────────────────────────────

calculate_plan_nutrition <- function(plan, food_db = foods) {
  result <- plan %>% left_join(food_db, by = "food")

  unmatched <- result %>% filter(is.na(kcal)) %>% pull(food) %>% unique()
  if (length(unmatched) > 0) {
    stop("Foods not found in database: ", paste(unmatched, collapse = ", "),
         "\nCheck spelling against data/foods.csv")
  }

  result %>%
    mutate(across(all_of(c(macro_cols, amino_cols)), ~ .x * grams / 100))
}

summarize_plan <- function(plan_nutrition) {
  plan_nutrition %>%
    summarize(
      across(all_of(c(macro_cols, amino_cols)), ~ round(sum(.x), 1))
    )
}

summarize_by_meal <- function(plan_nutrition) {
  plan_nutrition %>%
    group_by(meal) %>%
    summarize(
      foods   = paste(food, collapse = " + "),
      kcal    = round(sum(kcal), 0),
      protein = round(sum(protein_g), 1),
      carbs   = round(sum(carbs_g), 1),
      fat     = round(sum(fat_g), 1),
      .groups = "drop"
    )
}

# ── Compare plan vs targets ──────────────────────────────────────────────────

compare_macros <- function(plan_totals, targets = macro_targets) {
  targets %>%
    rowwise() %>%
    mutate(
      actual = pull(plan_totals, nutrient),
      pct    = round(actual / daily_target * 100, 0),
      status = case_when(
        pct >= 90  ~ "OK",
        pct >= 75  ~ "LOW",
        TRUE       ~ "DEFICIENT"
      )
    ) %>%
    ungroup() %>%
    select(nutrient, target = daily_target, actual, pct, status)
}

compare_aminos <- function(plan_totals, targets = amino_targets) {
  targets %>%
    rowwise() %>%
    mutate(
      actual_mg = pull(plan_totals, csv_column),
      pct       = round(actual_mg / daily_min_mg * 100, 0),
      status    = case_when(
        pct >= 100 ~ "OK",
        pct >= 80  ~ "LOW",
        TRUE       ~ "DEFICIENT"
      )
    ) %>%
    ungroup() %>%
    select(amino_acid, daily_min_mg, actual_mg, pct, status)
}

# ── Run it! (only when run directly) ──────────────────────────────────────────

if (sys.nframe() == 0) {
  cat("╔══════════════════════════════════════════════════════════════════╗\n")
  cat("║             VeggieFuel — Daily Meal Plan Generator              ║\n")
  cat("╚══════════════════════════════════════════════════════════════════╝\n\n")

  plans <- list(trail = trail_day_plan, kayak = kayak_day_plan,
                climbing = climbing_day_plan, swimming = swimming_day_plan,
                rest = rest_day_plan)

  for (day_type in names(plans)) {
    plan <- plans[[day_type]]
    if (is.null(plan)) {
      cat(sprintf("━━━ %s Day Plan: NOT AVAILABLE ━━━\n\n", toupper(day_type)))
      next
    }

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

    # Macro comparison — use day-adjusted targets
    day_macro_targets <- adjust_targets_for_day(day_type)
    cat("\nMacro Targets vs. Actual:\n")
    macro_comp <- compare_macros(totals, day_macro_targets)
    for (i in seq_len(nrow(macro_comp))) {
      r <- macro_comp[i, ]
      flag <- if (r$status == "OK") "+" else if (r$status == "LOW") "~" else "!"
      cat(sprintf("  %s %-10s  target: %5.0f  actual: %5.0f  (%3.0f%%) %s\n",
                  flag, r$nutrient, r$target, r$actual, r$pct, r$status))
    }

    # Amino comparison
    cat("\nAmino Acid Coverage:\n")
    amino_comp <- compare_aminos(totals)
    for (i in seq_len(nrow(amino_comp))) {
      r <- amino_comp[i, ]
      flag <- if (r$status == "OK") "+" else if (r$status == "LOW") "~" else "!"
      cat(sprintf("  %s %-15s  min: %5.0f mg  actual: %5.0f mg  (%3.0f%%) %s\n",
                  flag, r$amino_acid, r$daily_min_mg, r$actual_mg, r$pct, r$status))
    }
    cat("\n")
  }

  # ── Recipe suggestions ────────────────────────────────────────────────────
  source(here::here("R", "07_recipes.R"))
  all_recipes <- load_recipes()

  for (day_type in names(plans)) {
    plan <- plans[[day_type]]
    if (is.null(plan)) next

    matches <- match_recipes_to_plan(plan, all_recipes)
    has_matches <- any(sapply(matches, function(m) length(m) > 0))

    if (has_matches) {
      cat(sprintf("── Recipe Suggestions for %s Day ──\n", toupper(day_type)))
      for (slot in names(matches)) {
        slot_matches <- matches[[slot]]
        if (length(slot_matches) == 0) next
        for (m in slot_matches) {
          cat(sprintf("  %s → %s (%d%% match)\n",
                      slot, m$recipe$name, round(m$score * 100)))
        }
      }
      cat("\n")
    }
  }

  # ── Save plans to CSV ──────────────────────────────────────────────────────
  dir.create(here::here("output"), showWarnings = FALSE)

  for (day_type in names(plans)) {
    plan <- plans[[day_type]]
    if (!is.null(plan)) {
      nutrition <- calculate_plan_nutrition(plan)
      write_csv(
        nutrition %>% select(meal, food, grams, all_of(c(macro_cols, amino_cols))),
        here::here("output", paste0(day_type, "_day_plan.csv"))
      )
    }
  }
  cat("Plans saved to output/\n")
}

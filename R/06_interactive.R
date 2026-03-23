# ============================================================================
# 06_interactive.R — Interactive meal plan generator
# ============================================================================
# Terminal-based interactive mode using readline() prompts.
# Asks for weight, sport, dietary preferences, then generates and
# displays an optimized meal plan.
#
# Usage: Rscript R/06_interactive.R
# ============================================================================

source(here::here("R", "03a_optimizer.R"))
source(here::here("R", "03_meal_planner.R"))
source(here::here("R", "04_amino_check.R"))

# ── Helper: read a line with validation ────────────────────────────────────

ask <- function(prompt, default = NULL, validate = NULL) {
  suffix <- if (!is.null(default)) sprintf(" [%s]: ", default) else ": "
  repeat {
    answer <- readline(paste0(prompt, suffix))
    if (answer == "" && !is.null(default)) answer <- as.character(default)
    if (is.null(validate) || validate(answer)) return(answer)
    cat("  Invalid input, try again.\n")
  }
}

ask_numeric <- function(prompt, default = NULL, min_val = NULL, max_val = NULL) {
  val <- ask(prompt, default, function(x) {
    n <- suppressWarnings(as.numeric(x))
    if (is.na(n)) return(FALSE)
    if (!is.null(min_val) && n < min_val) return(FALSE)
    if (!is.null(max_val) && n > max_val) return(FALSE)
    TRUE
  })
  as.numeric(val)
}

ask_choice <- function(prompt, choices, default = NULL) {
  choices_str <- paste(choices, collapse = "/")
  ask(sprintf("%s (%s)", prompt, choices_str), default, function(x) {
    tolower(x) %in% tolower(choices)
  })
}

# ── Main interactive session ───────────────────────────────────────────────

#' Launch an interactive meal planning session
run_interactive <- function() {
  cat("╔══════════════════════════════════════════════════════════════════╗\n")
  cat("║         VeggieFuel — Interactive Meal Planner                   ║\n")
  cat("╚══════════════════════════════════════════════════════════════════╝\n\n")

  # 1. Athlete profile
  cat("-- Your Profile --\n")
  sex    <- ask_choice("Sex", c("female", "male"), default = "female")
  height <- ask_numeric("Height (cm)", default = if (sex == "male") 178 else 165,
                        min_val = 100, max_val = 250)
  age    <- ask_numeric("Age (years)", default = 30, min_val = 10, max_val = 100)
  weight <- ask_numeric("Body weight (kg)", default = if (sex == "male") 75 else 60,
                        min_val = 30, max_val = 200)
  sport  <- ask_choice("Primary sport",
                       c("trail", "kayak", "climbing", "swimming", "all"), default = "trail")
  hours  <- ask_numeric("Training hours per week", default = 10, min_val = 1, max_val = 40)

  profile <- list(
    name              = "Athlete",
    sex               = sex,
    height_cm         = height,
    weight_kg         = weight,
    age_years         = age,
    sport_primary     = if (sport == "all") "trail" else sport,
    sport_secondary   = if (sport == "all") "kayak" else sport,
    training_hours_week = hours,
    goal              = "performance"
  )

  # 2. Food exclusions
  cat("\n-- Food Preferences --\n")
  cat("Available foods: ", paste(head(sort(foods$food), 10), collapse = ", "), ", ...\n")
  excl_input <- ask("Foods to exclude (comma-separated, or 'none')", default = "none")
  excluded <- if (tolower(excl_input) == "none") {
    NULL
  } else {
    trimws(strsplit(excl_input, ",")[[1]])
  }

  # 3. Food locks
  lock_input <- ask("Lock a food to a meal? (e.g., 'Oats (dry):Breakfast:60' or 'none')",
                    default = "none")
  locks <- NULL
  if (tolower(lock_input) != "none") {
    parts <- strsplit(lock_input, ":")[[1]]
    if (length(parts) == 3) {
      locks <- tibble(
        food      = trimws(parts[1]),
        meal      = trimws(parts[2]),
        min_grams = as.numeric(trimws(parts[3]))
      )
    } else {
      cat("  Could not parse lock, skipping.\n")
    }
  }

  # 4. Day type
  day_type <- ask_choice("Generate plan for",
                         c("trail", "kayak", "climbing", "swimming", "rest"), default = "trail")

  # 5. Generate
  repeat {
    cat(sprintf("\nOptimizing %s day plan for %.0f kg athlete...\n", day_type, weight))

    plan <- optimize_day_plan(day_type, profile = profile, excluded = excluded, locks = locks)

    if (is.null(plan)) {
      cat("Could not generate a feasible plan. Try removing some exclusions.\n")
      break
    }

    # Display
    nutrition <- calculate_plan_nutrition(plan)
    totals    <- summarize_plan(nutrition)
    by_meal   <- summarize_by_meal(nutrition)

    cat(sprintf("\n━━━ %s Day Plan ━━━\n\n", toupper(day_type)))
    for (i in seq_len(nrow(by_meal))) {
      row <- by_meal[i, ]
      cat(sprintf("  %-12s %4d kcal | P: %5.1fg | C: %5.1fg | F: %4.1fg\n",
                  row$meal, row$kcal, row$protein, row$carbs, row$fat))
      cat(sprintf("               %s\n", row$foods))
    }

    # Amino check
    cat("\nAmino Acid Coverage:\n")
    amino_comp <- compare_aminos(totals)
    for (i in seq_len(nrow(amino_comp))) {
      r <- amino_comp[i, ]
      flag <- if (r$status == "OK") "+" else if (r$status == "LOW") "~" else "!"
      cat(sprintf("  %s %-15s  %3.0f%%  %s\n", flag, r$amino_acid, r$pct, r$status))
    }

    # Regenerate?
    again <- ask_choice("\nRegenerate with different variety?", c("y", "n"), default = "n")
    if (tolower(again) != "y") break

    # Perturb by excluding a random food from the current plan to get variety
    plan_foods <- unique(plan$food)
    if (length(plan_foods) > 3) {
      drop <- sample(plan_foods, min(3, length(plan_foods)))
      excluded <- unique(c(excluded, drop))
      cat("  (Excluding ", paste(drop, collapse = ", "), " for variety)\n")
    }
  }

  cat("\nDone! Run the full pipeline with: Rscript R/03_meal_planner.R\n")
}

# ── Run (only when run directly) ──────────────────────────────────────────

if (sys.nframe() == 0) {
  run_interactive()
}

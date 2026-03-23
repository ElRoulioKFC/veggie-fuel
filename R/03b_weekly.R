# ============================================================================
# 03b_weekly.R — 7-day weekly meal planner with variety constraints
# ============================================================================
# Generates a full week of meal plans by calling the daily optimizer
# repeatedly. Enforces variety by excluding foods that appear too often.
#
# Usage:
#   weekly <- plan_week()
#   export_week_csv(weekly)
#   summarize_week(weekly)
# ============================================================================

source(here::here("R", "03_meal_planner.R"))

suppressPackageStartupMessages(library(tidyr))

# ── Weekly planner ─────────────────────────────────────────────────────────

#' Generate a 7-day meal plan with variety constraints
#'
#' @param week_structure Named vector of day types and counts (must sum to 7)
#'   e.g., c(trail = 3, kayak = 2, rest = 2)
#' @param profile        Athlete profile list
#' @param max_food_appearances Max times a single food can appear across the week
#' @param locks          Tibble(food, meal, min_grams) applied to all days, or NULL
#' @return List with $plans (list of 7 tibbles), $day_types (character vector),
#'   $summary (weekly aggregate)
plan_week <- function(
    week_structure     = default_week_structure(athlete),
    profile            = athlete,
    max_food_appearances = 10,
    locks              = NULL
) {
  if (sum(week_structure) != 7) {
    stop("week_structure must sum to 7, got ", sum(week_structure))
  }

  # Expand day types: e.g., trail, trail, trail, kayak, kayak, rest, rest
  day_types <- rep(names(week_structure), times = week_structure)

  plans      <- vector("list", 7)
  food_counts <- character()  # cumulative food appearances

  for (d in seq_along(day_types)) {
    dt <- day_types[d]

    # Determine which foods to exclude (appeared too many times already)
    if (length(food_counts) > 0) {
      freq <- table(food_counts)
      over_used <- names(freq[freq >= max_food_appearances])
    } else {
      over_used <- character()
    }

    # Try to optimize with exclusions
    plan <- optimize_day_plan(dt, profile = profile, excluded = over_used, locks = locks)

    # If infeasible due to too many exclusions, gradually relax
    if (is.null(plan) && length(over_used) > 0) {
      # Sort by frequency (least over-used first) and re-include one at a time
      freq <- sort(table(food_counts), decreasing = FALSE)
      candidates <- names(freq[freq >= max_food_appearances])
      for (k in seq_along(candidates)) {
        over_used <- over_used[over_used != candidates[k]]
        plan <- optimize_day_plan(dt, profile = profile, excluded = over_used, locks = locks)
        if (!is.null(plan)) break
      }
    }

    if (is.null(plan)) {
      warning("Could not generate plan for day ", d, " (", dt, ")")
    } else {
      # Track food appearances
      food_counts <- c(food_counts, plan$food)
    }

    plans[[d]] <- plan
  }

  list(
    plans     = plans,
    day_types = day_types
  )
}

# ── Export weekly plan to CSV ──────────────────────────────────────────────

#' Write the full weekly plan as a single CSV
#'
#' @param weekly  Output from plan_week()
#' @param path    Output file path
export_week_csv <- function(weekly, path = here::here("output", "weekly_plan.csv")) {
  rows <- list()
  for (d in seq_along(weekly$plans)) {
    plan <- weekly$plans[[d]]
    if (is.null(plan)) next

    nutrition <- calculate_plan_nutrition(plan)
    day_rows <- nutrition %>%
      select(meal, food, grams, all_of(c(macro_cols, amino_cols))) %>%
      mutate(
        day      = d,
        day_type = weekly$day_types[d],
        .before  = meal
      )
    rows[[length(rows) + 1]] <- day_rows
  }

  full <- bind_rows(rows)
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  write_csv(full, path)
  cat("Weekly plan exported to", path, "\n")
  invisible(full)
}

# ── Weekly summary ─────────────────────────────────────────────────────────

#' Summarize weekly nutrition (per-day and weekly average)
#'
#' @param weekly Output from plan_week()
#' @return List with $per_day (tibble) and $average (tibble)
summarize_week <- function(weekly) {
  day_summaries <- list()
  for (d in seq_along(weekly$plans)) {
    plan <- weekly$plans[[d]]
    if (is.null(plan)) next

    nutrition <- calculate_plan_nutrition(plan)
    totals    <- summarize_plan(nutrition)

    day_summaries[[length(day_summaries) + 1]] <- totals %>%
      mutate(day = d, day_type = weekly$day_types[d], .before = 1)
  }

  per_day <- bind_rows(day_summaries)

  # Average across the week
  average <- per_day %>%
    summarize(across(all_of(c(macro_cols, amino_cols)), ~ round(mean(.x), 1)))

  list(per_day = per_day, average = average)
}

# ── Display (only when run directly) ───────────────────────────────────────

if (sys.nframe() == 0) {
  cat("╔══════════════════════════════════════════════════════════════════╗\n")
  cat("║           VeggieFuel — Weekly Meal Planner                      ║\n")
  cat("╚══════════════════════════════════════════════════════════════════╝\n\n")

  weekly <- plan_week()

  for (d in seq_along(weekly$plans)) {
    plan <- weekly$plans[[d]]
    dt   <- weekly$day_types[d]
    cat(sprintf("━━━ Day %d (%s) ━━━\n", d, toupper(dt)))
    if (is.null(plan)) {
      cat("  No plan generated\n\n")
    } else {
      print(plan, n = Inf)
      cat("\n")
    }
  }

  # Weekly summary
  ws <- summarize_week(weekly)
  cat("━━━ Weekly Average (per day) ━━━\n")
  print(ws$average, n = Inf)
  cat("\n")

  # Amino coverage vs targets
  cat("Weekly Average Amino Coverage:\n")
  amino_comp <- compare_aminos(ws$average)
  for (i in seq_len(nrow(amino_comp))) {
    r <- amino_comp[i, ]
    flag <- if (r$status == "OK") "+" else if (r$status == "LOW") "~" else "!"
    cat(sprintf("  %s %-15s  min: %5.0f mg  avg: %5.0f mg  (%3.0f%%) %s\n",
                flag, r$amino_acid, r$daily_min_mg, r$actual_mg, r$pct, r$status))
  }

  # Export
  export_week_csv(weekly)
}

# ============================================================================
# 05_visualize.R — Visualization: radar, stacked bar, weekly heatmap
# ============================================================================
# Three chart types for analyzing meal plans:
#   1. Radar/spider chart of amino acid coverage (% of daily minimum)
#   2. Stacked bar chart of macro breakdown per meal
#   3. Weekly heatmap of amino acid coverage (days x amino acids)
#
# All plots saved to output/ as PNG.
# ============================================================================

source(here::here("R", "00_setup.R"))
source(here::here("R", "01_food_database.R"))
source(here::here("R", "02_targets.R"))

suppressPackageStartupMessages(library(tidyr))

# Color palette
colors_status <- c(SUFFICIENT = "#4caf50", MARGINAL = "#ff9800", DEFICIENT = "#f44336")
colors_macro  <- c(protein_g = "#e74c3c", carbs_g = "#3498db", fat_g = "#f39c12")

# ── Radar chart of amino acid coverage ─────────────────────────────────────

#' Create a radar/spider chart of amino acid coverage
#'
#' @param coverage Tibble from check_amino_coverage() or compare_aminos(),
#'   must have amino_acid and pct columns
#' @param title    Chart title
#' @return ggplot object
plot_amino_radar <- function(coverage, title = "Amino Acid Coverage (% of Daily Minimum)") {
  # Ensure we have the right columns
  if (!"pct" %in% names(coverage)) stop("coverage must have a 'pct' column")
  if (!"amino_acid" %in% names(coverage)) stop("coverage must have an 'amino_acid' column")

  # Prepare data for coord_polar: close the polygon by repeating first row
  df <- coverage %>%
    select(amino_acid, pct) %>%
    mutate(amino_acid = factor(amino_acid, levels = amino_acid))

  df_closed <- bind_rows(df, df[1, ])

  # Reference line at 100%
  ref <- tibble(
    amino_acid = df$amino_acid,
    pct = 100
  )
  ref_closed <- bind_rows(ref, ref[1, ])

  p <- ggplot(df_closed, aes(x = amino_acid, y = pct, group = 1)) +
    # Reference circle at 100%
    geom_polygon(data = ref_closed, aes(x = amino_acid, y = pct),
                 fill = NA, color = "gray60", linetype = "dashed", linewidth = 0.5) +
    # Actual coverage polygon
    geom_polygon(fill = alpha("#3498db", 0.3), color = "#2980b9", linewidth = 1) +
    geom_point(data = df, color = "#2980b9", size = 3) +
    # Labels
    geom_text(data = df, aes(label = paste0(pct, "%")),
              vjust = -1, size = 3, color = "gray30") +
    coord_polar() +
    scale_y_continuous(limits = c(0, max(df$pct * 1.2, 150)),
                       breaks = seq(0, 300, 50)) +
    labs(title = title, x = NULL, y = "Coverage %") +
    theme_minimal() +
    theme(
      axis.text.y = element_text(size = 7, color = "gray50"),
      plot.title = element_text(hjust = 0.5, face = "bold")
    )

  p
}

# ── Stacked bar chart of macro breakdown per meal ──────────────────────────

#' Create a stacked bar chart showing protein/carbs/fat per meal
#'
#' @param plan_nutrition Output from calculate_plan_nutrition()
#' @param title          Chart title
#' @param meal_order     Optional character vector for meal ordering
#' @return ggplot object
plot_meal_macros <- function(
    plan_nutrition,
    title = "Macro Breakdown by Meal",
    meal_order = c("Breakfast", "Snack AM", "Lunch", "Snack PM", "Dinner", "Recovery")
) {
  # Aggregate macros by meal
  by_meal <- plan_nutrition %>%
    group_by(meal) %>%
    summarize(
      protein_g = sum(protein_g),
      carbs_g   = sum(carbs_g),
      fat_g     = sum(fat_g),
      .groups = "drop"
    )

  # Order meals
  present_meals <- intersect(meal_order, by_meal$meal)
  by_meal <- by_meal %>%
    filter(meal %in% present_meals) %>%
    mutate(meal = factor(meal, levels = present_meals))

  # Pivot to long format for stacking
  long <- by_meal %>%
    pivot_longer(cols = c(protein_g, carbs_g, fat_g),
                 names_to = "macro", values_to = "grams") %>%
    mutate(macro = factor(macro, levels = c("fat_g", "carbs_g", "protein_g")))

  p <- ggplot(long, aes(x = meal, y = grams, fill = macro)) +
    geom_col(position = "stack", width = 0.7) +
    scale_fill_manual(
      values = colors_macro,
      labels = c(protein_g = "Protein", carbs_g = "Carbs", fat_g = "Fat")
    ) +
    labs(title = title, x = NULL, y = "Grams", fill = "Macro") +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 30, hjust = 1),
      plot.title = element_text(hjust = 0.5, face = "bold"),
      legend.position = "top"
    )

  p
}

# ── Weekly heatmap of amino acid coverage ──────────────────────────────────

#' Create a heatmap of amino acid coverage across a week
#'
#' @param weekly Output from plan_week() (must have $plans and $day_types)
#' @param title  Chart title
#' @return ggplot object
plot_weekly_heatmap <- function(weekly, title = "Weekly Amino Acid Coverage (%)") {
  # Compute amino coverage for each day
  rows <- list()
  for (d in seq_along(weekly$plans)) {
    plan <- weekly$plans[[d]]
    if (is.null(plan)) next

    nutrition <- calculate_plan_nutrition(plan)
    totals    <- summarize_plan(nutrition)
    amino_comp <- compare_aminos(totals)

    rows[[length(rows) + 1]] <- amino_comp %>%
      select(amino_acid, pct) %>%
      mutate(
        day = sprintf("Day %d\n(%s)", d, weekly$day_types[d]),
        .before = 1
      )
  }

  heat_data <- bind_rows(rows) %>%
    mutate(
      day = factor(day, levels = unique(day)),
      amino_acid = factor(amino_acid, levels = rev(unique(amino_acid)))
    )

  p <- ggplot(heat_data, aes(x = day, y = amino_acid, fill = pct)) +
    geom_tile(color = "white", linewidth = 0.5) +
    geom_text(aes(label = paste0(pct, "%")), size = 3) +
    scale_fill_gradient2(
      low = "#f44336", mid = "#ff9800", high = "#4caf50",
      midpoint = 100, limits = c(50, 250),
      oob = scales::squish,
      name = "Coverage %"
    ) +
    labs(title = title, x = NULL, y = NULL) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(size = 9),
      plot.title = element_text(hjust = 0.5, face = "bold"),
      panel.grid = element_blank()
    )

  p
}

# ── Save all charts ────────────────────────────────────────────────────────

#' Generate and save all visualization charts
#'
#' @param plan_nutrition  Output from calculate_plan_nutrition() (for single day)
#' @param amino_coverage  Output from compare_aminos() (for single day)
#' @param weekly          Output from plan_week() (for heatmap), or NULL
#' @param day_label       Label for the single-day charts (e.g., "trail")
#' @param output_dir      Directory for saving PNGs
save_all_charts <- function(
    plan_nutrition,
    amino_coverage,
    weekly     = NULL,
    day_label  = "trail",
    output_dir = here::here("output")
) {
  dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

  # 1. Radar chart
  p1 <- plot_amino_radar(amino_coverage,
                         title = sprintf("Amino Coverage — %s Day", tools::toTitleCase(day_label)))
  ggsave(file.path(output_dir, sprintf("amino_radar_%s.png", day_label)),
         p1, width = 8, height = 8, dpi = 150)
  cat("Saved amino_radar_", day_label, ".png\n", sep = "")

  # 2. Stacked bar chart
  p2 <- plot_meal_macros(plan_nutrition,
                         title = sprintf("Macros by Meal — %s Day", tools::toTitleCase(day_label)))
  ggsave(file.path(output_dir, sprintf("meal_macros_%s.png", day_label)),
         p2, width = 10, height = 6, dpi = 150)
  cat("Saved meal_macros_", day_label, ".png\n", sep = "")

  # 3. Weekly heatmap (if weekly data provided)
  if (!is.null(weekly)) {
    p3 <- plot_weekly_heatmap(weekly)
    ggsave(file.path(output_dir, "weekly_amino_heatmap.png"),
           p3, width = 12, height = 6, dpi = 150)
    cat("Saved weekly_amino_heatmap.png\n")
  }
}

# ── Run (only when run directly) ──────────────────────────────────────────

if (sys.nframe() == 0) {
  cat("╔══════════════════════════════════════════════════════════════════╗\n")
  cat("║           VeggieFuel — Visualization Generator                  ║\n")
  cat("╚══════════════════════════════════════════════════════════════════╝\n\n")

  # Source the planner functions we need
  source(here::here("R", "03_meal_planner.R"))

  # Generate charts for each day type
  day_plans <- list(
    trail    = trail_day_plan,
    kayak    = kayak_day_plan,
    climbing = climbing_day_plan,
    swimming = swimming_day_plan
  )

  for (day_label in names(day_plans)) {
    plan <- day_plans[[day_label]]
    if (!is.null(plan)) {
      nutr   <- calculate_plan_nutrition(plan)
      totals <- summarize_plan(nutr)
      aminos <- compare_aminos(totals)
      save_all_charts(plan_nutrition = nutr, amino_coverage = aminos, day_label = day_label)
    }
  }

  # Generate weekly heatmap
  cat("\nGenerating weekly plan for heatmap...\n")
  source(here::here("R", "03b_weekly.R"))
  weekly <- plan_week()
  p3 <- plot_weekly_heatmap(weekly)
  ggsave(here::here("output", "weekly_amino_heatmap.png"),
         p3, width = 12, height = 6, dpi = 150)
  cat("Saved weekly_amino_heatmap.png\n")

  cat("\nAll charts saved to output/\n")
}

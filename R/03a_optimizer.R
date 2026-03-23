# ============================================================================
# 03a_optimizer.R — LP-based meal plan optimizer
# ============================================================================
# Uses linear programming (lpSolve) to find daily meal plans that:
#   - Meet all 9 essential amino acid WHO/FAO minimums (hard constraints)
#   - Minimize deviation from macro targets (soft via slack variables)
#   - Encourage food diversity via per-gram cost penalties
#   - Respect portion size limits per food/category/meal
#   - Support food locks ("always oats for breakfast")
#   - Enforce portability for snack meals on active days
#
# The optimizer returns a tibble(meal, food, grams) that plugs directly
# into all existing analysis functions in 03_meal_planner.R.
# ============================================================================

if (!requireNamespace("here", quietly = TRUE)) {
  user_lib <- Sys.getenv("R_LIBS_USER")
  if (!dir.exists(user_lib)) dir.create(user_lib, recursive = TRUE)
  install.packages("here", repos = "https://cloud.r-project.org", lib = user_lib)
}
source(here::here("R", "00_setup.R"))
source(here::here("R", "01_food_database.R"))
source(here::here("R", "02_targets.R"))

suppressPackageStartupMessages(library(lpSolve))

# ── Default constraints ────────────────────────────────────────────────────

# Max grams of a food in a single meal, by category
default_max_per_meal <- c(
  grain = 250, legume = 200, soy = 200, dairy_egg = 150,
  nut_seed = 50, vegetable = 250, fruit = 200, protein = 80,
  sport = 40
)

# Meal calorie distribution targets (fraction of daily kcal)
meal_kcal_fractions <- c(
  Breakfast  = 0.25,
  `Snack AM` = 0.10,
  Lunch      = 0.30,
  `Snack PM` = 0.10,
  Dinner     = 0.20,
  Recovery   = 0.05
)

# Allowed tolerance around meal kcal fractions
meal_kcal_tolerance <- 0.12

# Meals where portability matters on active days
portable_meals <- c("Snack AM", "Snack PM", "Recovery")

# ── Build LP model ─────────────────────────────────────────────────────────

#' Build the LP constraint matrix and objective for a single day
#'
#' @param day_type      "trail", "kayak", "climbing", "swimming", or "rest"
#' @param profile       Athlete profile list
#' @param food_db       Food database tibble (with portable, prep_minutes cols)
#' @param locks         Optional tibble(food, meal, min_grams) for food locks
#' @param excluded      Character vector of food names to exclude
#' @param meal_slots    Character vector of meal names (default 6 meals)
#' @param max_per_meal  Named vector of max grams per category per meal
#' @param max_per_day   Max grams of any single food across all meals
#' @return List with obj, con_matrix, con_dir, con_rhs, n_foods, n_meals, avail_foods
build_lp_model <- function(
    day_type,
    profile      = athlete,
    food_db      = foods,
    locks        = NULL,
    excluded     = NULL,
    meal_slots   = c("Breakfast", "Snack AM", "Lunch", "Snack PM", "Dinner", "Recovery"),
    max_per_meal = default_max_per_meal,
    max_per_day  = 300
) {
  # -- Adjusted targets for this day type --
  mtargets <- adjust_targets_for_day(day_type, profile)
  atargets <- compute_amino_targets(profile)

  # -- Filter available foods --
  avail <- food_db
  if (!is.null(excluded)) avail <- avail %>% filter(!food %in% excluded)

  n_foods <- nrow(avail)
  n_meals <- length(meal_slots)
  n_x     <- n_foods * n_meals       # food-grams decision variables
  n_macros <- 5                       # kcal, protein, carbs, fat, fiber
  n_slack  <- 2 * n_macros            # under + over for each macro
  n_vars   <- n_x + n_slack

  # Index helpers
  idx <- function(i, m) (m - 1) * n_foods + i
  s_under_idx <- function(j) n_x + j
  s_over_idx  <- function(j) n_x + n_macros + j

  # -- Nutrient coefficients per gram (not per 100g!) --
  macro_per_g <- as.matrix(avail[macro_cols]) / 100   # n_foods x 5
  amino_per_g <- as.matrix(avail[amino_cols]) / 100   # n_foods x 9

  # -- Objective: minimize weighted slack + diversity penalty --
  # Slack weights: penalize under-shooting protein heavily, excess kcal moderately
  w_under <- c(1.0, 3.0, 1.0, 0.5, 0.5)  # kcal, protein, carbs, fat, fiber
  w_over  <- c(1.0, 0.5, 0.5, 1.0, 0.3)

  # Diversity penalty: small per-gram cost proportional to calorie density.
  # This encourages the LP to spread across more foods rather than
  # concentrating on a few calorie-efficient ones.
  kcal_per_g <- avail$kcal / 100
  diversity_cost <- 0.01 * (kcal_per_g / max(kcal_per_g))  # 0-0.01 range
  food_costs <- rep(diversity_cost, n_meals)  # repeat for each meal slot

  obj <- c(food_costs, w_under, w_over)

  # -- Build constraint rows --
  constraints <- list()
  dirs <- character()
  rhs  <- numeric()

  add_constraint <- function(row, dir, val) {
    constraints[[length(constraints) + 1]] <<- row
    dirs <<- c(dirs, dir)
    rhs  <<- c(rhs, val)
  }

  # 1) AMINO ACID >= constraints (9 rows)
  for (a in seq_along(amino_cols)) {
    row <- rep(0, n_vars)
    for (m in seq_len(n_meals)) {
      offset <- (m - 1) * n_foods
      row[(offset + 1):(offset + n_foods)] <- row[(offset + 1):(offset + n_foods)] + amino_per_g[, a]
    }
    add_constraint(row, ">=", atargets$daily_min_mg[a])
  }

  # 2) MACRO = target with slacks (5 equality constraints)
  for (j in seq_len(n_macros)) {
    row <- rep(0, n_vars)
    for (m in seq_len(n_meals)) {
      offset <- (m - 1) * n_foods
      row[(offset + 1):(offset + n_foods)] <- row[(offset + 1):(offset + n_foods)] + macro_per_g[, j]
    }
    row[s_under_idx(j)] <-  1
    row[s_over_idx(j)]  <- -1
    add_constraint(row, "=", mtargets$daily_target[j])
  }

  # 3) PER-FOOD-PER-MEAL upper bounds (category-based)
  for (m in seq_len(n_meals)) {
    for (i in seq_len(n_foods)) {
      cat_name <- avail$category[i]
      max_g <- if (cat_name %in% names(max_per_meal)) max_per_meal[cat_name] else 150
      row <- rep(0, n_vars)
      row[idx(i, m)] <- 1
      add_constraint(row, "<=", max_g)
    }
  }

  # 4) PER-FOOD DAILY total upper bounds
  for (i in seq_len(n_foods)) {
    row <- rep(0, n_vars)
    for (m in seq_len(n_meals)) {
      row[idx(i, m)] <- 1
    }
    add_constraint(row, "<=", max_per_day)
  }

  # 5) MEAL CALORIE DISTRIBUTION bounds
  target_kcal <- mtargets$daily_target[mtargets$nutrient == "kcal"]
  for (m in seq_len(n_meals)) {
    meal_name <- meal_slots[m]
    frac <- if (meal_name %in% names(meal_kcal_fractions)) meal_kcal_fractions[meal_name] else 0.15
    lo <- target_kcal * max(frac - meal_kcal_tolerance, 0.02)
    hi <- target_kcal * min(frac + meal_kcal_tolerance, 0.50)

    row_lo <- rep(0, n_vars)
    offset <- (m - 1) * n_foods
    row_lo[(offset + 1):(offset + n_foods)] <- macro_per_g[, 1]
    add_constraint(row_lo, ">=", lo)

    row_hi <- row_lo
    add_constraint(row_hi, "<=", hi)
  }

  # 6) PORTABILITY constraints for snack meals on active days
  if (day_type != "rest" && "portable" %in% names(avail)) {
    non_portable_idx <- which(avail$portable == FALSE)
    for (m in seq_len(n_meals)) {
      if (meal_slots[m] %in% portable_meals) {
        for (i in non_portable_idx) {
          row <- rep(0, n_vars)
          row[idx(i, m)] <- 1
          add_constraint(row, "<=", 0)
        }
      }
    }
  }

  # 7) FOOD LOCKS (lower bound constraints)
  if (!is.null(locks) && nrow(locks) > 0) {
    for (r in seq_len(nrow(locks))) {
      lock_food <- locks$food[r]
      lock_meal <- locks$meal[r]
      lock_min  <- locks$min_grams[r]

      fi <- which(avail$food == lock_food)
      mi <- which(meal_slots == lock_meal)
      if (length(fi) == 1 && length(mi) == 1) {
        row <- rep(0, n_vars)
        row[idx(fi, mi)] <- 1
        add_constraint(row, ">=", lock_min)
      } else {
        warning("Lock ignored — food '", lock_food, "' or meal '", lock_meal, "' not found")
      }
    }
  }

  # -- Assemble constraint matrix --
  con_matrix <- do.call(rbind, constraints)

  list(
    obj        = obj,
    con_matrix = con_matrix,
    con_dir    = dirs,
    con_rhs    = rhs,
    n_foods    = n_foods,
    n_meals    = n_meals,
    n_x        = n_x,
    n_vars     = n_vars,
    avail_foods = avail,
    meal_slots  = meal_slots
  )
}

# ── Format LP solution into standard plan tibble ───────────────────────────

#' Convert LP solution vector to a meal plan tibble
#'
#' @param solution   Solution vector from lpSolve
#' @param model      Model list from build_lp_model
#' @param min_grams  Drop foods below this threshold (LP noise)
#' @return Tibble with columns: meal, food, grams
format_lp_solution <- function(solution, model, min_grams = 5) {
  x_vals <- solution[1:model$n_x]

  # Reshape to matrix: rows = foods, cols = meals
  mat <- matrix(x_vals, nrow = model$n_foods, ncol = model$n_meals)

  # Build tidy result
  plan_rows <- list()
  for (m in seq_len(model$n_meals)) {
    for (i in seq_len(model$n_foods)) {
      g <- mat[i, m]
      if (g >= min_grams) {
        # Round to nearest 5g for practical portions
        g_rounded <- round(g / 5) * 5
        if (g_rounded >= min_grams) {
          plan_rows[[length(plan_rows) + 1]] <- tibble(
            meal  = model$meal_slots[m],
            food  = model$avail_foods$food[i],
            grams = g_rounded
          )
        }
      }
    }
  }

  if (length(plan_rows) == 0) return(NULL)

  meal_order <- model$meal_slots
  result <- bind_rows(plan_rows)
  result$meal <- factor(result$meal, levels = meal_order)
  result <- result %>% arrange(meal, desc(grams)) %>% mutate(meal = as.character(meal))
  result
}

# ── Main optimizer function ────────────────────────────────────────────────

#' Generate an optimized daily meal plan
#'
#' @param day_type  "trail", "kayak", "climbing", "swimming", or "rest"
#' @param ...       Passed to build_lp_model (profile, locks, excluded, etc.)
#' @return Tibble with columns: meal, food, grams (or NULL if infeasible)
optimize_day_plan <- function(day_type, ...) {
  model <- build_lp_model(day_type, ...)

  result <- lpSolve::lp(
    direction    = "min",
    objective.in = model$obj,
    const.mat    = model$con_matrix,
    const.dir    = model$con_dir,
    const.rhs    = model$con_rhs
  )

  if (result$status == 0) {
    return(format_lp_solution(result$solution, model))
  }

  # Fallback: relax amino constraints to 90% and retry
  warning("LP infeasible for ", day_type, " day — relaxing amino targets to 90%")
  n_aminos <- 9
  model$con_rhs[1:n_aminos] <- model$con_rhs[1:n_aminos] * 0.90

  result2 <- lpSolve::lp(
    direction    = "min",
    objective.in = model$obj,
    const.mat    = model$con_matrix,
    const.dir    = model$con_dir,
    const.rhs    = model$con_rhs
  )

  if (result2$status == 0) {
    warning("Plan generated with relaxed amino targets (90% of WHO/FAO minimums)")
    return(format_lp_solution(result2$solution, model))
  }

  warning("Could not generate a feasible plan for ", day_type,
          " day even with relaxed constraints")
  NULL
}

# ── Display (only when run directly) ───────────────────────────────────────

if (sys.nframe() == 0) {
  cat("╔══════════════════════════════════════════════════════════════════╗\n")
  cat("║           VeggieFuel — Meal Plan Optimizer                      ║\n")
  cat("╚══════════════════════════════════════════════════════════════════╝\n\n")

  for (dt in c("trail", "kayak", "climbing", "swimming", "rest")) {
    cat(sprintf("━━━ Optimizing %s day plan ━━━\n", toupper(dt)))
    plan <- optimize_day_plan(dt)
    if (is.null(plan)) {
      cat("  ✗ Could not generate a feasible plan\n\n")
    } else {
      cat(sprintf("  ✓ Plan with %d food items across %d meals\n",
                  nrow(plan), n_distinct(plan$meal)))
      print(plan, n = Inf)
      cat("\n")
    }
  }
}

# ============================================================================
# 02_targets.R — Athlete profile & daily nutrient targets
# ============================================================================
# Define your athlete profile and compute personalized daily targets for
# macros and essential amino acids.
#
# References:
#   - Protein: 1.6–1.8 g/kg for vegetarian endurance athletes (PMC5598028)
#   - Carbs:   6–8 g/kg for endurance (ACSM/AND/DC joint position, 2016)
#   - Fat:     25–30% of total kcal
#   - Amino acids: WHO/FAO/UNU 2007 safe intake levels (mg/kg/day)
#   - BMR: Mifflin-St Jeor equation (Mifflin et al., 1990)
# ============================================================================

suppressPackageStartupMessages(library(dplyr))

# ── Athlete Profile ──────────────────────────────────────────────────────────
# Edit these values to match your own stats!

athlete <- list(
  name              = "Athlete",
  sex               = "female",       # "female" or "male"
  height_cm         = 165,            # height in cm
  weight_kg         = 60,
  age_years         = 30,             # age in years
  sports            = c("trail", "kayak"),  # subset of: "trail", "kayak", "climbing", "swimming"
  sport_primary     = "trail",        # kept for backward compat
  sport_secondary   = "kayak",        # kept for backward compat
  training_hours_week = 10,           # hours per week
  goal              = "performance"   # "performance", "muscle_gain", "weight_loss", or "recomposition"
)

# ── Profile validation ──────────────────────────────────────────────────────

validate_profile <- function(profile) {
  if (is.null(profile$weight_kg) || !is.numeric(profile$weight_kg)) {
    stop("Athlete profile must include numeric weight_kg")
  }
  if (profile$weight_kg <= 0 || profile$weight_kg > 300) {
    stop("weight_kg must be between 0 and 300, got: ", profile$weight_kg)
  }
  # Validate sports field if present
  if (!is.null(profile$sports)) {
    valid <- c("trail", "kayak", "climbing", "swimming")
    bad <- setdiff(profile$sports, valid)
    if (length(bad) > 0) {
      stop("Unknown sport(s): ", paste(bad, collapse = ", "),
           ". Valid: ", paste(valid, collapse = ", "))
    }
  }
  # Validate goal if present
  if (!is.null(profile$goal)) {
    valid_goals <- c("performance", "weight_loss", "muscle_gain", "recomposition")
    if (!(profile$goal %in% valid_goals)) {
      stop("Unknown goal: ", profile$goal, ". Valid: ", paste(valid_goals, collapse = ", "))
    }
  }
  # Backward-compatible: apply defaults for optional fields
  if (is.null(profile$sex))        profile$sex        <- "female"
  if (is.null(profile$height_cm))  profile$height_cm  <- 165
  if (is.null(profile$age_years))  profile$age_years  <- 30
}

# ── Sport helpers ────────────────────────────────────────────────────────────

#' Extract the athlete's active sports from a profile
#' Falls back to sport_primary/sport_secondary for legacy profiles
get_athlete_sports <- function(profile) {
  valid_sports <- c("trail", "kayak", "climbing", "swimming")
  if (!is.null(profile$sports)) {
    sports <- intersect(profile$sports, valid_sports)
  } else {
    sports <- unique(c(profile$sport_primary, profile$sport_secondary))
    sports <- intersect(sports, valid_sports)
  }
  if (length(sports) == 0) sports <- "trail"
  sports
}

#' Build a default 7-day week structure from the athlete's sports
#' Distributes 5 active days across sports, plus 2 rest days
default_week_structure <- function(profile = athlete) {
  sports <- get_athlete_sports(profile)
  n_sports <- length(sports)
  active_days <- 5
  base <- active_days %/% n_sports
  remainder <- active_days %% n_sports
  counts <- rep(base, n_sports)
  if (remainder > 0) {
    counts[seq_len(remainder)] <- counts[seq_len(remainder)] + 1
  }
  structure <- setNames(counts, sports)
  c(structure, rest = 2)
}

# ── Macro Targets ────────────────────────────────────────────────────────────

compute_macro_targets <- function(profile) {
  validate_profile(profile)
  w   <- profile$weight_kg
  sex <- if (!is.null(profile$sex)) profile$sex else "female"
  h   <- if (!is.null(profile$height_cm)) profile$height_cm else 165
  age <- if (!is.null(profile$age_years)) profile$age_years else 30
  hrs <- if (!is.null(profile$training_hours_week)) profile$training_hours_week else 10

  # BMR via Mifflin-St Jeor (Mifflin et al., 1990)
  bmr <- if (sex == "male") {
    10 * w + 6.25 * h - 5 * age + 5
  } else {
    10 * w + 6.25 * h - 5 * age - 161
  }

  # Activity factor based on training hours/week
  activity_factor <- if (hrs <= 3) 1.375 else if (hrs <= 6) 1.55 else if (hrs <= 10) 1.725 else 1.9

  # Goal-based modifiers
  goal_val <- if (!is.null(profile$goal)) profile$goal else "performance"
  gm <- goal_modifiers %>% filter(goal == goal_val)
  if (nrow(gm) == 0) gm <- goal_modifiers %>% filter(goal == "performance")

  total_kcal <- bmr * activity_factor * gm$kcal_mult

  # Protein & carbs scaled by goal
  protein_g <- w * gm$protein_per_kg

  carbs_g <- w * gm$carbs_per_kg

  # Fat: remainder of calories after protein + carbs
  protein_kcal <- protein_g * 4
  carbs_kcal   <- carbs_g * 4
  fat_kcal     <- max(total_kcal - protein_kcal - carbs_kcal, total_kcal * 0.20)
  fat_g        <- fat_kcal / 9

  # Recalculate total to ensure consistency
  total_kcal <- protein_kcal + carbs_kcal + fat_kcal

  # Fiber (25–35 g)
  fiber_g <- 30

  tibble(
    nutrient    = c("kcal", "protein_g", "carbs_g", "fat_g", "fiber_g"),
    daily_target = round(c(total_kcal, protein_g, carbs_g, fat_g, fiber_g), 0),
    unit        = c("kcal", "g", "g", "g", "g"),
    notes       = c(
      sprintf("Mifflin-St Jeor BMR × %.3f × %.2f (%s, %gcm, %gyr, %s)", activity_factor, gm$kcal_mult, sex, h, age, goal_val),
      sprintf("%.1f g/kg × %g kg (%s)", gm$protein_per_kg, w, goal_val),
      sprintf("%.1f g/kg × %g kg (%s)", gm$carbs_per_kg, w, goal_val),
      sprintf("%.0f%% of total kcal", fat_kcal / total_kcal * 100),
      "Adequate intake range"
    )
  )
}

# ── Amino Acid Targets ───────────────────────────────────────────────────────
# WHO/FAO/UNU 2007 safe levels for adults (mg/kg body weight/day)

amino_requirements_per_kg <- tibble(
  amino_acid = c("leucine", "isoleucine", "valine", "lysine",
                  "methionine", "threonine", "tryptophan",
                  "phenylalanine", "histidine"),
  mg_per_kg  = c(39, 20, 26, 30, 10.4, 15, 4, 25, 10),
  csv_column = c("leucine_mg", "isoleucine_mg", "valine_mg", "lysine_mg",
                  "methionine_mg", "threonine_mg", "tryptophan_mg",
                  "phenylalanine_mg", "histidine_mg"),
  notes      = c("BCAA — muscle repair", "BCAA — energy", "BCAA — tissue repair",
                  "Often limiting in grains!", "Includes cysteine requirement",
                  "Collagen & gut health", "Serotonin precursor",
                  "Includes tyrosine requirement", "Needed for growth/repair")
)

compute_amino_targets <- function(profile) {
  validate_profile(profile)
  amino_requirements_per_kg %>%
    mutate(
      daily_min_mg = round(mg_per_kg * profile$weight_kg, 0),
      for_weight   = sprintf("%g kg", profile$weight_kg)
    )
}

# ── Sport-specific adjustments ───────────────────────────────────────────────

sport_day_adjustments <- tibble(
  sport  = c("trail", "kayak", "climbing", "swimming", "rest"),
  carb_pct  = c(0.58, 0.52, 0.50, 0.58, 0.50),
  protein_pct = c(0.16, 0.19, 0.20, 0.17, 0.18),
  fat_pct   = c(0.26, 0.29, 0.30, 0.25, 0.32),
  kcal_mult = c(1.10, 1.00, 0.95, 1.20, 0.80),
  description = c(
    "Trail day: high carb for long effort, moderate protein",
    "Kayak day: higher protein for upper body, moderate carb",
    "Climbing day: high protein for grip recovery, power-to-weight focus (ISSN/Cogent Medicine 2019)",
    "Swimming day: high carb + very high expenditure from thermoregulation (Costill 1988, PMC5772075)",
    "Rest day: reduced calories, maintain protein"
  )
)

# ── Goal modifiers ─────────────────────────────────────────────────────────
# Adjust base macro targets based on athlete's training objective.
# Applied BEFORE sport-day adjustments. Amino acid targets are unaffected.

goal_modifiers <- tibble(
  goal           = c("performance", "weight_loss", "muscle_gain", "recomposition"),
  kcal_mult      = c(1.00,          0.85,          1.10,          1.00),
  protein_per_kg = c(1.7,           2.0,           2.0,           2.2),
  carbs_per_kg   = c(7.0,           5.0,           7.0,           5.5),
  description    = c(
    "Balanced for sport performance",
    "15% deficit, high protein to preserve muscle",
    "10% surplus + high protein",
    "Maintenance kcal, highest protein, moderate carbs"
  )
)

# ── Day-type adjusted targets ──────────────────────────────────────────────
# Apply sport_day_adjustments to get day-specific macro targets.
# Amino acid targets stay fixed (WHO/FAO minimums depend on body weight only).

adjust_targets_for_day <- function(day_type, profile = athlete) {
  validate_profile(profile)
  adj <- sport_day_adjustments %>% filter(sport == day_type)
  if (nrow(adj) == 0) stop("Unknown day_type: ", day_type)

  base <- compute_macro_targets(profile)
  base_kcal <- base$daily_target[base$nutrient == "kcal"]
  adj_kcal  <- round(base_kcal * adj$kcal_mult)

  tibble(
    nutrient     = c("kcal", "protein_g", "carbs_g", "fat_g", "fiber_g"),
    daily_target = round(c(
      adj_kcal,
      adj_kcal * adj$protein_pct / 4,
      adj_kcal * adj$carb_pct / 4,
      adj_kcal * adj$fat_pct / 9,
      30
    ), 0),
    unit  = c("kcal", "g", "g", "g", "g"),
    notes = c(
      sprintf("%s day (%.2fx kcal)", day_type, adj$kcal_mult),
      sprintf("%.0f%% of kcal", adj$protein_pct * 100),
      sprintf("%.0f%% of kcal", adj$carb_pct * 100),
      sprintf("%.0f%% of kcal", adj$fat_pct * 100),
      "Adequate intake range"
    )
  )
}

# ── Compute targets (always available for importers) ─────────────────────────

macro_targets <- compute_macro_targets(athlete)
amino_targets <- compute_amino_targets(athlete)

# ── Display (only when run directly) ────────────────────────────────────────

if (sys.nframe() == 0) {
  cat("── Athlete Profile ───────────────────────────────────────────────\n")
  cat(sprintf("  Name: %s | Sex: %s | Height: %g cm | Weight: %g kg | Age: %g yr\n",
              athlete$name, athlete$sex, athlete$height_cm,
              athlete$weight_kg, athlete$age_years))
  cat(sprintf("  Sports: %s | Training: %g hrs/week | Goal: %s\n",
              paste(get_athlete_sports(athlete), collapse = ", "),
              athlete$training_hours_week, athlete$goal))
  cat("──────────────────────────────────────────────────────────────────\n\n")

  cat("Daily Macro Targets:\n")
  print(macro_targets, n = Inf)
  cat("\nDaily Essential Amino Acid Minimums:\n")
  print(amino_targets %>% select(amino_acid, daily_min_mg, notes), n = Inf)
  cat("\nSport-Day Adjustments:\n")
  print(sport_day_adjustments, n = Inf)
  cat("\n")
}

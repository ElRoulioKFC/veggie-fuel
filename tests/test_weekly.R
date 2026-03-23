# ============================================================================
# tests/test_weekly.R — Tests for weekly planner
# ============================================================================
# Run with: Rscript tests/test_weekly.R
# ============================================================================

suppressPackageStartupMessages(library(here))

cat("Running weekly planner tests...\n\n")

errors <- 0
tests  <- 0

assert <- function(condition, msg) {
  tests <<- tests + 1
  if (condition) {
    cat(sprintf("  PASS: %s\n", msg))
  } else {
    cat(sprintf("  FAIL: %s\n", msg))
    errors <<- errors + 1
  }
}

# ── Load modules ─────────────────────────────────────────────────────────────

suppressMessages(source(here::here("R", "03b_weekly.R")))

# ── Test 1: Weekly planner produces 7 days ───────────────────────────────────

weekly <- plan_week(week_structure = c(trail = 3, kayak = 2, rest = 2))

assert(length(weekly$plans) == 7, "Weekly planner returns 7 plans")
assert(length(weekly$day_types) == 7, "Weekly planner returns 7 day types")

# Count non-null plans
valid_plans <- sum(!sapply(weekly$plans, is.null))
assert(valid_plans >= 5, sprintf("At least 5 of 7 days have valid plans (got %d)", valid_plans))

# ── Test 2: Day types are correct ────────────────────────────────────────────

assert(sum(weekly$day_types == "trail") == 3, "3 trail days in week")
assert(sum(weekly$day_types == "kayak") == 2, "2 kayak days in week")
assert(sum(weekly$day_types == "rest") == 2, "2 rest days in week")

# ── Test 3: Invalid week structure ───────────────────────────────────────────

err <- tryCatch(plan_week(week_structure = c(trail = 5, kayak = 5)), error = function(e) e)
assert(inherits(err, "error"), "week_structure not summing to 7 causes error")

# ── Test 4: Weekly summary ───────────────────────────────────────────────────

ws <- summarize_week(weekly)
assert(!is.null(ws$per_day), "Weekly summary has per_day component")
assert(!is.null(ws$average), "Weekly summary has average component")
assert(nrow(ws$per_day) == valid_plans, "Per-day summary has one row per valid plan")
assert(ws$average$kcal > 0, "Average daily kcal is positive")
assert(ws$average$protein_g > 0, "Average daily protein is positive")

# ── Test 5: No single food dominates the week ────────────────────────────────

all_foods_used <- unlist(lapply(weekly$plans, function(p) {
  if (is.null(p)) character(0) else p$food
}))

if (length(all_foods_used) > 0) {
  food_freq <- table(all_foods_used)
  # A food appearing in every meal of every day = 42, that's too much
  assert(max(food_freq) <= 35,
         sprintf("Most-used food appears %d times (max 35 expected)", max(food_freq)))
  # At least some variety
  assert(length(unique(all_foods_used)) >= 5,
         sprintf("At least 5 distinct foods used in the week (got %d)", length(unique(all_foods_used))))
}

# ── Test 6: Rest day plans meet amino targets ────────────────────────────────

rest_indices <- which(weekly$day_types == "rest")
for (ri in rest_indices) {
  plan <- weekly$plans[[ri]]
  if (!is.null(plan)) {
    nutrition <- calculate_plan_nutrition(plan)
    totals    <- summarize_plan(nutrition)
    amino_comp <- compare_aminos(totals)
    # Allow some margin for rest days (relaxed constraints might kick in)
    assert(all(amino_comp$pct >= 80),
           sprintf("Rest day %d meets >= 80%% of amino targets", ri))
    break  # test at least one rest day
  }
}

# ── Test 7: Mixed week with all sport types ────────────────────────────────

weekly_all <- plan_week(week_structure = c(trail = 2, kayak = 1, climbing = 2, swimming = 1, rest = 1))
assert(length(weekly_all$plans) == 7, "Mixed-sport week returns 7 plans")
assert(sum(weekly_all$day_types == "climbing") == 2, "2 climbing days in mixed week")
assert(sum(weekly_all$day_types == "swimming") == 1, "1 swimming day in mixed week")

# ── Results ──────────────────────────────────────────────────────────────────

cat(sprintf("\n%d tests run, %d failed.\n", tests, errors))

if (errors > 0) {
  cat("SOME TESTS FAILED!\n")
  quit(status = 1)
} else {
  cat("ALL TESTS PASSED.\n")
}

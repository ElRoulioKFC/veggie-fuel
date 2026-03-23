# VeggieFuel

R-based vegetarian meal planner for athletes (trail running, kayaking, climbing, swimming) using linear programming optimization with full essential amino acid coverage. Supports male and female athletes with Mifflin-St Jeor BMR-based calorie estimation.

## Project Structure

```
R/00_setup.R          → Package installation & loading
R/01_food_database.R  → Food nutrient database & utilities
R/02_targets.R        → Athlete profile & daily nutrient targets
R/03_meal_planner.R   → Daily meal plan orchestration & analysis
R/03a_optimizer.R     → LP solver core (lpSolve)
R/03b_weekly.R        → 7-day planning with variety constraints
R/04_amino_check.R    → Amino acid coverage analysis
R/05_visualize.R      → Charts (radar, stacked bar, heatmap)
R/06_interactive.R    → Terminal-based interactive mode
data/foods.csv        → 80+ vegetarian foods with full nutrition profiles
tests/test_amino.R    → 40 core assertions
tests/test_weekly.R   → 15 weekly planner assertions
output/               → Generated plans & charts (gitignored, regenerated)
```

Scripts are numbered in dependency order. Each sources its own upstream dependencies.

## How to Run

```bash
Rscript R/03_meal_planner.R    # Generate daily plans (trail, kayak, climbing, swimming, rest)
Rscript R/03b_weekly.R         # Generate 7-day plan with variety
Rscript R/06_interactive.R     # Interactive mode (prompts for sex, height, weight, age, sport)
```

## How to Run Tests

```bash
Rscript tests/test_amino.R     # 40 assertions — database, targets, optimizer, amino coverage
Rscript tests/test_weekly.R    # 15 assertions — weekly structure, variety, amino adequacy
```

Both test files must pass before committing.

## Optimizer

- Uses `lpSolve` for linear programming
- 6 meals per day: Breakfast, Snack AM, Lunch, Snack PM, Dinner, Recovery
- Amino acid minimums are hard constraints; macros use soft constraints with slack variables
- Supports food locks (force a food into a specific meal), portability constraints (snack meals on active days), and food exclusions
- Fallback: if LP is infeasible, relaxes amino targets to 90% and retries
- Default athlete profile: female, 165 cm, 60 kg, 30 yr, trail + kayak, 10 hrs/week training
- Default week: 3 trail days, 2 kayak days, 2 rest days
- Sports supported: trail, kayak, climbing, swimming, rest

## Code Conventions

- Tidyverse style: pipes (`%>%`), tibbles, `snake_case` naming
- 2-space indentation, UTF-8 encoding
- Each script must be runnable standalone: `Rscript R/0X_script.R`
- Use `if (sys.nframe() == 0)` to guard display-only code that should not run when sourced
- Add new package dependencies to `R/00_setup.R` in the `required_packages` vector
- Use `here::here()` for all file paths (never hardcode relative paths)
- Use `tryCatch()` for graceful error handling

## Data Conventions

- All food nutrient values in `data/foods.csv` are per 100g
- 9 essential amino acids in mg, macros (protein, carbs, fat, fiber) in g, calories in kcal
- New foods must include all 17 columns — see `CONTRIBUTING.md` for the full schema
- Use USDA FoodData Central as the primary nutrient data source
- Food categories: soy, legume, grain, dairy_egg, nut_seed, vegetable, fruit, protein, sport

## Nutrition Science References

These are the sources used in the codebase for target calculations (see `R/02_targets.R`):

- **Protein 1.6–1.8 g/kg** for vegetarian endurance athletes — Jäger et al., "International Society of Sports Nutrition Position Stand: protein and exercise", JISSN 2017 (PMC5477153). The 1.6-1.7 g/kg range for endurance athletes is also supported by Morton et al., "A systematic review, meta-analysis and meta-regression of the effect of protein supplementation on resistance training-induced gains", BJSM 2018 (PMC5598028)
- **Carbohydrates 6–8 g/kg** for endurance training — Thomas et al., "Position of the Academy of Nutrition and Dietetics, Dietitians of Canada, and the American College of Sports Medicine: Nutrition and Athletic Performance", JAND 2016 (DOI: 10.1016/j.jand.2015.12.006)
- **Essential amino acid minimums** — WHO/FAO/UNU, "Protein and Amino Acid Requirements in Human Nutrition", WHO Technical Report Series 935, 2007. Table of safe intake levels in mg/kg/day used directly in `amino_requirements_per_kg`

## Key Rules

- **Always update README.md** when adding features, changing behavior, or modifying the food database
- Run both test files before committing
- Keep scripts modular — each file sources its own dependencies via `here::here()`
- Only use verified nutrient data from USDA FoodData Central; do not estimate amino acid values without noting it

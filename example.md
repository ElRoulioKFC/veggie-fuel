# Complete Example — 107 kg Male Boulderer & Trail Runner

This walkthrough shows how to use VeggieFuel for a specific athlete profile:

| Field           | Value                          |
|-----------------|--------------------------------|
| **Sex**         | Male                           |
| **Weight**      | 107 kg                         |
| **Height**      | 189 cm                         |
| **Age**         | 27 years                       |
| **Sports**      | Bouldering (1–2×/week) + Trail running (1–2×/week) |
| **Training**    | ~5 hrs/week                    |

---

## Option A: Edit the Athlete Profile Directly

Open `R/02_targets.R` and replace the default `athlete` list:

```r
athlete <- list(
  name              = "Athlete",
  sex               = "male",
  height_cm         = 189,
  weight_kg         = 107,
  age_years         = 27,
  sports            = c("climbing", "trail"),
  sport_primary     = "climbing",
  sport_secondary   = "trail",
  training_hours_week = 5,
  goal              = "performance"
)
```

Then generate your plans:

```bash
# Daily plans for all sport types
Rscript R/03_meal_planner.R

# 7-day weekly plan
Rscript R/03b_weekly.R
```

---

## Option B: Interactive Mode

Run the interactive planner and enter your details when prompted:

```bash
Rscript R/06_interactive.R
```

Session walkthrough:

```
╔══════════════════════════════════════════════════════════════════╗
║         VeggieFuel — Interactive Meal Planner                   ║
╚══════════════════════════════════════════════════════════════════╝

-- Your Profile --
Sex (female/male) [female]: male
Height (cm) [178]: 189
Age (years) [30]: 27
Body weight (kg) [75]: 107
Primary sport (trail/kayak/climbing/swimming/all) [trail]: climbing
Training hours per week [10]: 5

-- Food Preferences --
Available foods:  Almonds, Avocado, Banana, Black beans, Broccoli, ...
Foods to exclude (comma-separated, or 'none') [none]: none
Lock a food to a meal? (e.g., 'Oats (dry):Breakfast:60' or 'none') [none]: Oats (dry):Breakfast:80
Generate plan for (trail/kayak/climbing/swimming/rest) [trail]: climbing

Optimizing climbing day plan for 107 kg athlete...
```

---

## Your Computed Targets

VeggieFuel calculates these automatically from your profile using the Mifflin-St Jeor equation.

### Base Metabolic Rate

```
BMR (male) = 10 × 107 + 6.25 × 189 − 5 × 27 + 5 = 2,121 kcal
Activity factor (5 hrs/week) = 1.55
Base TDEE = 2,121 × 1.55 = 3,288 kcal
```

### Daily Macro Targets (base)

| Macro       | Target   | Calculation         |
|-------------|----------|---------------------|
| **Protein** | 182 g    | 1.7 g/kg × 107 kg  |
| **Carbs**   | 749 g    | 7 g/kg × 107 kg    |
| **Fat**     | ≥ 20% kcal | remainder (floor) |
| **Fiber**   | 30 g     | adequate intake     |

> Note: protein + carbs alone exceed the base TDEE, so the fat 20% floor kicks in and total calories are recalculated upward (~4,382 kcal base).

### Sport-Day Adjustments

| Day Type    | kcal Mult | Approx kcal | Carb % | Protein % | Fat % |
|-------------|-----------|-------------|--------|-----------|-------|
| **Trail**   | 1.10×     | ~4,820      | 58%    | 16%       | 26%   |
| **Climbing**| 0.95×     | ~4,163      | 50%    | 20%       | 30%   |
| **Rest**    | 0.80×     | ~3,506      | 50%    | 18%       | 32%   |

### Essential Amino Acid Minimums (WHO/FAO × 107 kg)

| Amino Acid      | Daily Min (mg) | Key Sources                              |
|-----------------|---------------|------------------------------------------|
| **Leucine**     | 4,173         | Soy, lentils, pumpkin seeds, cheese      |
| **Isoleucine**  | 2,140         | Tofu, eggs, lentils, seaweed             |
| **Valine**      | 2,782         | Soy, peanuts, mushrooms, grains          |
| **Lysine**      | 3,210         | Beans, lentils, tofu, quinoa             |
| **Methionine**  | 1,113         | Eggs, sesame seeds, brazil nuts, oats    |
| **Threonine**   | 1,605         | Lentils, cottage cheese, sesame          |
| **Tryptophan**  | 428           | Cheese, oats, tofu, pumpkin seeds        |
| **Phenylalanine** | 2,675       | Soy, almonds, eggs, peanuts              |
| **Histidine**   | 1,070         | Tofu, wheat germ, rice, beans            |

---

## Weekly Plan Setup

For 1–2 bouldering + 1–2 trail sessions per week, a typical week structure:

```r
weekly <- plan_week(
  week_structure = c(trail = 2, climbing = 2, rest = 3),
  profile = athlete,
  max_food_appearances = 10
)
```

This generates 7 days: 2 trail days, 2 climbing days, 3 rest days.

To export and view:

```r
# Export to CSV
export_week_csv(weekly)

# View weekly summary
ws <- summarize_week(weekly)
print(ws$per_day)    # per-day nutrition totals
print(ws$average)    # weekly average
```

Output is saved to `output/weekly_plan.csv`.

---

## Sample Output: Climbing Day

The optimizer produces 6 meals per day. Example output for a climbing day:

```
━━━ CLIMBING Day Plan ━━━

  Breakfast     620 kcal | P:  25.0g | C:  85.0g | F:  20.0g
               Oats (dry) + Soy milk (unsweetened) + Banana + Hemp seeds + Peanut butter
  Snack AM      450 kcal | P:  18.0g | C:  50.0g | F:  20.0g
               Whole wheat bread + Hummus + Almonds
  Lunch         780 kcal | P:  35.0g | C:  90.0g | F:  28.0g
               Quinoa + Black beans + Avocado + Pumpkin seeds + Spinach
  Snack PM      400 kcal | P:  20.0g | C:  40.0g | F:  18.0g
               Greek yogurt + Banana + Almonds
  Dinner        850 kcal | P:  40.0g | C:  85.0g | F:  30.0g
               Tofu + Brown rice + Broccoli + Sesame seeds + Edamame
  Recovery      450 kcal | P:  30.0g | C:  50.0g | F:  12.0g
               Cottage cheese + Chia seeds + Banana + Soy milk (unsweetened)

Amino Acid Coverage:
  + leucine           min:  4173 mg  actual:  4500 mg  (108%) OK
  + isoleucine        min:  2140 mg  actual:  2300 mg  (107%) OK
  + valine            min:  2782 mg  actual:  2950 mg  (106%) OK
  + lysine            min:  3210 mg  actual:  3400 mg  (106%) OK
  + methionine        min:  1113 mg  actual:  1200 mg  (108%) OK
  + threonine         min:  1605 mg  actual:  1750 mg  (109%) OK
  + tryptophan        min:   428 mg  actual:   500 mg  (117%) OK
  + phenylalanine     min:  2675 mg  actual:  2900 mg  (108%) OK
  + histidine         min:  1070 mg  actual:  1150 mg  (107%) OK
```

> Note: Exact foods and portions will vary each time you run the optimizer — it finds the best combination to hit your targets. The values above are illustrative.

---

## Custom R Script (All-in-One)

Save this as `my_plan.R` in the project root and run with `Rscript my_plan.R`:

```r
source(here::here("R", "03_meal_planner.R"))
source(here::here("R", "03b_weekly.R"))
source(here::here("R", "04_amino_check.R"))

# Your profile
athlete <- list(
  name              = "Athlete",
  sex               = "male",
  height_cm         = 189,
  weight_kg         = 107,
  age_years         = 27,
  sports            = c("climbing", "trail"),
  sport_primary     = "climbing",
  sport_secondary   = "trail",
  training_hours_week = 5,
  goal              = "performance"
)

# Lock oats to breakfast (80 g)
locks <- tibble(
  food      = "Oats (dry)",
  meal      = "Breakfast",
  min_grams = 80
)

# Generate a single climbing day
plan <- optimize_day_plan("climbing", profile = athlete, locks = locks)
nutrition <- calculate_plan_nutrition(plan)
totals <- summarize_plan(nutrition)
by_meal <- summarize_by_meal(nutrition)

cat("━━━ Your Climbing Day ━━━\n\n")
for (i in seq_len(nrow(by_meal))) {
  row <- by_meal[i, ]
  cat(sprintf("  %-12s %4d kcal | P: %5.1fg | C: %5.1fg | F: %4.1fg\n",
              row$meal, row$kcal, row$protein, row$carbs, row$fat))
  cat(sprintf("               %s\n", row$foods))
}

# Amino check
cat("\nAmino Acid Coverage:\n")
amino_comp <- compare_aminos(totals, compute_amino_targets(athlete))
for (i in seq_len(nrow(amino_comp))) {
  r <- amino_comp[i, ]
  flag <- if (r$status == "OK") "+" else if (r$status == "LOW") "~" else "!"
  cat(sprintf("  %s %-15s  min: %5.0f mg  actual: %5.0f mg  (%3.0f%%) %s\n",
              flag, r$amino_acid, r$daily_min_mg, r$actual_mg, r$pct, r$status))
}

# Generate full week
cat("\n━━━ Weekly Plan ━━━\n\n")
weekly <- plan_week(
  week_structure = c(trail = 2, climbing = 2, rest = 3),
  profile = athlete,
  locks = locks
)
export_week_csv(weekly)

ws <- summarize_week(weekly)
cat("\nWeekly Average (per day):\n")
print(ws$average)
```

---

## Tips for a 107 kg Climber

- **Power-to-weight**: Climbing day targets are 0.95× base kcal — slightly reduced to support lean performance. If you're actively trying to recomp, consider setting `goal = "weight_loss"` and adjusting manually.
- **Protein is high**: At 182 g/day base, you'll rely heavily on tofu, tempeh, legumes, eggs, and cottage cheese. The optimizer handles this.
- **Lysine watch**: At 3,210 mg/day minimum, make sure your grain-heavy meals are paired with legumes or soy. The optimizer enforces this as a hard constraint.
- **Food locks**: Locking 80 g oats to breakfast is a solid move — it provides a reliable base of carbs, fiber, and some amino acids every morning.
- **Recovery meal**: The 6th meal (Recovery) is designed for post-session intake. On climbing days, prioritize protein-rich recovery foods.

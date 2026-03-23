# 🌱 VeggieFuel — Vegetarian Meal Planner for Athletes

**An R project that calculates macro + amino acid proficiency for vegetarian athletes doing trail running, kayaking, climbing, and swimming.**

VeggieFuel uses linear programming to generate optimized daily and weekly meal plans that hit your protein, carb, fat, and essential amino acid targets — using only vegetarian ingredients. Supports male and female athletes with personalized BMR-based calorie estimation (Mifflin-St Jeor). Built for endurance athletes who want to perform without guessing.

---

## ⚡ Quickstart

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USER/veggie-fuel.git
cd veggie-fuel

# 2. Open the R project
# Double-click veggie-fuel.Rproj (RStudio) or:
R

# 3. Install dependencies (dplyr, readr, tidyr, ggplot2, scales, here, lpSolve)
source("R/00_setup.R")

# 4. Generate optimized daily meal plans (trail, kayak, rest)
source("R/03_meal_planner.R")

# 5. Generate a 7-day weekly plan
source("R/03b_weekly.R")

# 6. Check amino acid coverage
source("R/04_amino_check.R")

# 7. Generate visualization charts (radar, bar, heatmap)
source("R/05_visualize.R")

# 8. Interactive mode (prompts for weight, sport, preferences)
source("R/06_interactive.R")

# 9. Run tests
Rscript tests/test_amino.R
Rscript tests/test_weekly.R
```

### Optimizer Features

- **LP-optimized plans** — uses `lpSolve` to minimize macro deviation while guaranteeing all 9 amino acid WHO/FAO minimums
- **Sport-specific targets** — trail (high carb), kayak (high protein), climbing (power-to-weight), swimming (high expenditure), rest (reduced kcal)
- **Personalized profiles** — sex, height, weight, age → Mifflin-St Jeor BMR-based calorie targets
- **Food locks** — "always have oats for breakfast"
- **Portability constraints** — snack meals on active days only use portable foods
- **Weekly variety** — 7-day planner enforces food rotation across the week

---

## 📋 Copy-Paste Quicksheet

### Daily Targets (60 kg female athlete, 165 cm, 30 yr)

| Macro         | Daily Target       | Notes                                    |
|---------------|--------------------|------------------------------------------|
| **Calories**  | 2,400–2,800 kcal   | Adjust on rest vs. training days         |
| **Protein**   | 96–108 g           | 1.6–1.8 g/kg (endurance veg. athlete)    |
| **Carbs**     | 360–480 g          | 6–8 g/kg — fuel for trails & paddle      |
| **Fat**       | 67–93 g            | 25–30% of total kcal                     |
| **Fiber**     | 25–35 g            | Easy on plant-based, watch gut tolerance |

### Essential Amino Acid Minimums (mg/kg/day × 60 kg)

| Amino Acid      | Daily Min (mg) | Top Vegetarian Sources                         |
|-----------------|---------------|------------------------------------------------|
| **Leucine**     | 2,340         | Soy, lentils, pumpkin seeds, cheese             |
| **Isoleucine**  | 1,200         | Tofu, eggs, lentils, seaweed                    |
| **Valine**      | 1,560         | Soy, peanuts, mushrooms, grains                 |
| **Lysine**      | 1,800         | Beans, lentils, tofu, quinoa, pistachios        |
| **Methionine**  | 630 (+cysteine)| Eggs, sesame seeds, brazil nuts, oats           |
| **Threonine**   | 900           | Lentils, cottage cheese, sesame, spirulina      |
| **Tryptophan**  | 240           | Cheese, oats, tofu, pumpkin seeds               |
| **Phenylalanine** | 1,500 (+tyr)| Soy, almonds, eggs, peanuts                    |
| **Histidine**   | 600           | Tofu, wheat germ, rice, beans                   |

### Key Protein Combos (complementary amino acids)

```
Legumes + Grains     → rice & beans, lentil soup + bread, hummus + pita
Legumes + Seeds      → bean salad + tahini, lentils + pumpkin seeds
Grains + Dairy       → oatmeal + yogurt, pasta + cheese
Soy + anything       → tofu/tempeh are complete proteins on their own
Quinoa alone          → all 9 essential amino acids ✓
```

### Sport-Day Calorie Split

```
              TRAIL         KAYAK         CLIMBING      SWIMMING
Carbs         55–60%        50–55%        45–50%        55–60%
Protein       15–18%        18–20%        18–22%        15–18%
Fat           22–28%        25–30%        28–32%        22–28%
kcal mult     1.10x         1.00x         0.95x         1.15x
```

### Supplements to Consider

| Supplement     | Why                                           | Dose               |
|----------------|-----------------------------------------------|---------------------|
| **B12**        | Not available in plant foods                  | 250 μg/day          |
| **Creatine**   | Lower stores in vegetarians, helps power      | 3–5 g/day           |
| **Iron**       | Plant iron (non-heme) is less bioavailable    | Check bloodwork     |
| **Omega-3 DHA**| Very limited in vegetarian diets              | 250–500 mg/day algae|
| **Vitamin D**  | Often low, especially in northern climates    | 1000–2000 IU/day    |

---

## 📁 Project Structure

```
veggie-fuel/
├── README.md              ← You are here
├── CONTRIBUTING.md        ← How to add foods & contribute
├── veggie-fuel.Rproj      ← RStudio project file
├── R/
│   ├── 00_setup.R         ← Install & load packages
│   ├── 01_food_database.R ← Vegetarian food nutrient data (80+ foods)
│   ├── 02_targets.R       ← Athlete profile & daily/sport targets
│   ├── 03_meal_planner.R  ← Generate optimized daily meal plans
│   ├── 03a_optimizer.R    ← LP optimizer core (lpSolve)
│   ├── 03b_weekly.R       ← 7-day weekly planner with variety
│   ├── 04_amino_check.R   ← Amino acid coverage analysis
│   ├── 05_visualize.R     ← Radar, stacked bar & heatmap charts
│   └── 06_interactive.R   ← Terminal-based interactive mode
├── data/
│   └── foods.csv          ← Food nutrient database (macros + aminos + portable + prep_minutes)
├── output/                ← Generated plans, charts & reports
├── tests/
│   ├── test_amino.R       ← Core validation tests (40 assertions)
│   └── test_weekly.R      ← Weekly planner tests (15 assertions)
├── .gitignore
└── LICENSE
```

---

## 🏃‍♀️ How It Works

1. **`01_food_database.R`** loads a curated database of 80+ vegetarian foods with full macro and essential amino acid profiles (per 100 g), plus portability and prep time.

2. **`02_targets.R`** defines your athlete profile (sex, height, weight, age, sport, training volume) and calculates daily macro + amino acid targets using Mifflin-St Jeor BMR, WHO/FAO 2007, and ACSM guidelines. Includes sport-day adjustments (trail, kayak, climbing, swimming, rest).

3. **`03a_optimizer.R`** uses linear programming (`lpSolve`) to find the optimal daily plan: minimizes macro deviation while guaranteeing all 9 amino acids meet WHO/FAO minimums. Supports food locks, exclusions, portability constraints, and meal calorie distribution.

4. **`03_meal_planner.R`** orchestrates the optimizer for trail, kayak, climbing, swimming, and rest days. Compares results against targets and saves nutrition breakdowns to CSV.

5. **`03b_weekly.R`** generates a 7-day plan (e.g. 2 trail, 1 kayak, 2 climbing, 1 swimming, 1 rest) with variety constraints — foods that appear too often get excluded in later days.

6. **`04_amino_check.R`** scores each meal and the full day against amino acid minimums, flags any deficiencies, and suggests fixes.

7. **`05_visualize.R`** generates three chart types: amino acid radar chart, macro stacked bar chart per meal, and weekly amino acid coverage heatmap.

8. **`06_interactive.R`** provides a terminal-based interface: enter your sex, height, weight, age, sport, exclusions, and food locks — get an optimized plan instantly.

---

## 📚 Resources

### Sports Nutrition for Vegetarian Athletes

- **[Vegan Diets: Practical Advice for Athletes (PMC)](https://pmc.ncbi.nlm.nih.gov/articles/PMC5598028/)** — Comprehensive peer-reviewed guide covering protein, micronutrients, and supplementation for plant-based athletes
- **[Nutritional Considerations for Vegetarian Athletes (ScienceDirect, 2024)](https://www.sciencedirect.com/science/article/pii/S266614972400029X)** — Recent narrative review on protein quality, amino acid complementation, and muscle protein synthesis
- **[No Meat Athlete – Protein Guide](https://www.nomeatathlete.com/protein-for-athletes/)** — Practical breakdown of amino acid pools, lysine considerations, and daily planning
- **[NASM – Protein for Vegetarian & Vegan Athletes](https://blog.nasm.org/fitness/protein-vegetarian-vegan-athletes)** — Quick overview of protein needs and complementary protein strategies

### Amino Acid References

- **[No Meat Athlete – Vegan Protein Sources & Amino Acid Breakdown](https://www.nomeatathlete.com/vegetarian-protein/)** — Detailed amino acid chart per 200-calorie serving of plant foods
- **[WHO/FAO Amino Acid Scoring Patterns](https://www.who.int/publications/i/item/9241209356)** — Official reference for essential amino acid requirements

### Trail Running & Kayaking Nutrition

- **[ISSN Position Stand on Nutrient Timing](https://jissn.biomedcentral.com/articles/10.1186/s12970-017-0189-4)** — Evidence-based nutrient timing for endurance sport
- **[Nutrition for Endurance Athletes (AND)](https://www.eatright.org/)** — Academy of Nutrition and Dietetics resources

### R & Data Science

- **[R for Data Science (2e)](https://r4ds.hadley.nz/)** — Free online book by Hadley Wickham
- **[tidyverse.org](https://www.tidyverse.org/)** — Documentation for dplyr, ggplot2, readr, etc.

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add foods, run tests, and contribute.

---

## 📝 License

MIT — see [LICENSE](LICENSE)

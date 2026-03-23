# 🌱 VeggieFuel — Vegetarian Meal Planner for Trail & Kayak Athletes

**A small R project that calculates macro + amino acid proficiency for vegetarian sportswomen doing trail running and kayaking.**

VeggieFuel helps you plan meals that hit your protein, carb, fat, and essential amino acid targets — using only vegetarian ingredients. Built for endurance athletes who want to perform without guessing.

---

## ⚡ Quickstart

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USER/veggie-fuel.git
cd veggie-fuel

# 2. Open the R project
# Double-click veggie-fuel.Rproj (RStudio) or:
R

# 3. Install dependencies
source("R/00_setup.R")

# 4. Generate your weekly meal plan
source("R/03_meal_planner.R")

# 5. Check your amino acid coverage
source("R/04_amino_check.R")
```

---

## 📋 Copy-Paste Quicksheet

### Daily Targets (60 kg trail/kayak sportswoman)

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

### Trail Day vs. Kayak Day Calorie Split

```
                 TRAIL DAY (long effort)     KAYAK DAY (upper body)
Carbs            55–60%                      50–55%
Protein          15–18%                      18–20%
Fat              22–28%                      25–30%
Pre-workout      Oats + banana + nut butter  Toast + eggs + avocado
During           Dates, energy balls, gels   Bars, trail mix, banana
Recovery         Smoothie: soy milk +        Cottage cheese + quinoa
                 banana + hemp seeds          + roasted chickpeas
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
├── veggie-fuel.Rproj      ← RStudio project file
├── R/
│   ├── 00_setup.R         ← Install & load packages
│   ├── 01_food_database.R ← Vegetarian food nutrient data
│   ├── 02_targets.R       ← Athlete profile & daily targets
│   ├── 03_meal_planner.R  ← Generate daily/weekly meal plans
│   └── 04_amino_check.R   ← Amino acid coverage analysis
├── data/
│   └── foods.csv          ← Food nutrient database (macros + aminos)
├── output/                ← Generated plans & reports go here
├── tests/
│   └── test_amino.R       ← Basic validation tests
├── .gitignore
└── LICENSE
```

---

## 🏃‍♀️ How It Works

1. **`01_food_database.R`** loads a curated database of ~40 vegetarian foods with full macro and essential amino acid profiles (per 100 g).

2. **`02_targets.R`** defines your athlete profile (weight, sport, training volume) and calculates daily macro + amino acid targets based on current sports nutrition guidelines.

3. **`03_meal_planner.R`** generates a sample daily meal plan (breakfast, snack, lunch, snack, dinner, recovery) that meets your targets. It prioritizes complementary protein sources.

4. **`04_amino_check.R`** scores each meal and the full day against amino acid minimums, flags any deficiencies, and suggests fixes.

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

This is a small personal project — feel free to fork it, add foods, adjust targets, or improve the planner logic. PRs welcome!

---

## 📝 License

MIT — see [LICENSE](LICENSE)

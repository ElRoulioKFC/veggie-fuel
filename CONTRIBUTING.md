# Contributing to VeggieFuel

## Adding New Foods

1. Open `data/foods.csv`
2. Add a row with all 17 columns:

| Column | Type | Description |
|--------|------|-------------|
| `food` | text | Name with preparation in parentheses, e.g., "Farro (cooked)" |
| `category` | text | One of: `soy`, `legume`, `grain`, `dairy_egg`, `nut_seed`, `vegetable`, `fruit`, `protein`, `sport` |
| `kcal` | number | Calories per 100g |
| `protein_g` | number | Protein per 100g |
| `carbs_g` | number | Carbohydrates per 100g |
| `fat_g` | number | Fat per 100g |
| `fiber_g` | number | Fiber per 100g |
| `leucine_mg` | number | Leucine per 100g |
| `isoleucine_mg` | number | Isoleucine per 100g |
| `valine_mg` | number | Valine per 100g |
| `lysine_mg` | number | Lysine per 100g |
| `methionine_mg` | number | Methionine per 100g (includes cysteine contribution) |
| `threonine_mg` | number | Threonine per 100g |
| `tryptophan_mg` | number | Tryptophan per 100g |
| `phenylalanine_mg` | number | Phenylalanine per 100g (includes tyrosine contribution) |
| `histidine_mg` | number | Histidine per 100g |
| `portable` | TRUE/FALSE | Can the food be carried on a trail or in a kayak? |
| `prep_minutes` | integer | 0 = ready-to-eat, 5 = quick prep, 15-30 = cooking |

### Where to find nutrient data

- **Primary source**: [USDA FoodData Central](https://fdc.nal.usda.gov/) — search for your food, use the "SR Legacy" or "Foundation" dataset
- Look for the "Amino Acids" section in the USDA report for all 9 essential amino acids
- All values should be per 100g of the food as eaten (cooked weight for cooked foods)
- If amino acid data is not available for a specific food, estimate from similar foods and note it in your PR

### Category guidelines

- `sport` — energy gels, bars, and specialized sport nutrition products
- `protein` — concentrated protein sources like seitan, nutritional yeast, spirulina
- Use `(cooked)`, `(dry)`, `(baked)` etc. in the food name to clarify preparation state

## Running Tests

```bash
# Run from the project root
Rscript tests/test_amino.R      # 40 core assertions
Rscript tests/test_weekly.R     # 15 weekly planner assertions
```

All tests must pass before submitting a PR.

## Code Style

- Follow tidyverse style (pipes, tibbles, snake_case)
- Add comments for non-obvious logic — the audience is athletes who know some R
- Each script should be runnable standalone: `Rscript R/0X_script.R`
- Use `if (sys.nframe() == 0)` for display-only code that runs when the script is executed directly

## HPC & Monte Carlo

The optimizer runs in milliseconds for a single plan. For Monte Carlo sampling (generating thousands of plans with perturbed objective weights to find the most practical plan), use:

- `parallel::mclapply()` on a Linux workstation
- SLURM job arrays on a cluster (see `docs/slurm_submit.sh` if available)
- Each job runs `optimize_day_plan()` with slightly randomized diversity costs

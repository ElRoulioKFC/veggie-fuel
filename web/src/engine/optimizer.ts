import type { AthleteProfile, Food, FoodLock, MealPlanItem, MealSlot, Sport } from '../data/types';
import { MEAL_SLOTS } from '../data/types';
import { foods as defaultFoodDb } from '../data/foods';
import { adjustTargetsForDay, computeAminoTargets } from './targets';
import highs_loader from 'highs';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
let highsSolver: any = null;

async function getHighs() {
  if (!highsSolver) {
    highsSolver = await highs_loader();
  }
  return highsSolver;
}

// ── Default constraints (matching R code) ────────────────────────────────

const DEFAULT_MAX_PER_MEAL: Record<string, number> = {
  grain: 250, legume: 200, soy: 200, dairy_egg: 150,
  nut_seed: 50, vegetable: 250, fruit: 200, protein: 80,
  sport: 40,
};

const MEAL_KCAL_FRACTIONS: Record<string, number> = {
  'Breakfast': 0.25,
  'Snack AM': 0.10,
  'Lunch': 0.30,
  'Snack PM': 0.10,
  'Dinner': 0.20,
  'Recovery': 0.05,
};

const MEAL_KCAL_TOLERANCE = 0.12;
const PORTABLE_MEALS = ['Snack AM', 'Snack PM', 'Recovery'];

const AMINO_KEYS: (keyof Food)[] = [
  'leucineMg', 'isoleucineMg', 'valineMg', 'lysineMg',
  'methionineMg', 'threonineMg', 'tryptophanMg',
  'phenylalanineMg', 'histidineMg',
];

const MACRO_KEYS: (keyof Food)[] = ['kcal', 'proteinG', 'carbsG', 'fatG', 'fiberG'];

// ── Build LP problem as CPLEX LP string ─────────────────────────────────

interface LpModel {
  lpString: string;
  nFoods: number;
  nMeals: number;
  availFoods: Food[];
  mealSlots: MealSlot[];
}

function varName(foodIdx: number, mealIdx: number): string {
  return `x_${foodIdx}_${mealIdx}`;
}

function buildLpModel(
  dayType: Sport,
  profile: AthleteProfile,
  foodDb: Food[] = defaultFoodDb,
  locks: FoodLock[] = [],
  excluded: string[] = [],
  mealSlots: MealSlot[] = [...MEAL_SLOTS],
  maxPerMeal: Record<string, number> = DEFAULT_MAX_PER_MEAL,
  maxPerDay: number = 300,
  aminoRelax: number = 1.0,
): LpModel {
  const mtargets = adjustTargetsForDay(dayType, profile);
  const atargets = computeAminoTargets(profile);

  const avail = excluded.length > 0
    ? foodDb.filter(f => !excluded.includes(f.food))
    : foodDb;

  const nFoods = avail.length;
  const nMeals = mealSlots.length;
  const nMacros = 5;

  // Nutrient coefficients per gram (not per 100g)
  const macroPerG = avail.map(f => MACRO_KEYS.map(k => (f[k] as number) / 100));
  const aminoPerG = avail.map(f => AMINO_KEYS.map(k => (f[k] as number) / 100));

  // Slack weights
  const wUnder = [1.0, 3.0, 1.0, 0.5, 0.5];
  const wOver = [1.0, 0.5, 0.5, 1.0, 0.3];

  // Diversity penalty
  const maxKcal = Math.max(...avail.map(f => f.kcal / 100));
  const diversityCost = avail.map(f => 0.01 * (f.kcal / 100 / maxKcal));

  const lines: string[] = [];
  lines.push('Minimize');

  // Objective
  const objTerms: string[] = [];
  for (let m = 0; m < nMeals; m++) {
    for (let i = 0; i < nFoods; i++) {
      objTerms.push(`${diversityCost[i]} ${varName(i, m)}`);
    }
  }
  for (let j = 0; j < nMacros; j++) {
    objTerms.push(`${wUnder[j]} su_${j}`);
    objTerms.push(`${wOver[j]} so_${j}`);
  }
  lines.push('  obj: ' + objTerms.join(' + '));

  lines.push('Subject To');

  let cIdx = 0;

  // 1) AMINO ACID >= constraints (9 rows)
  for (let a = 0; a < 9; a++) {
    const terms: string[] = [];
    for (let m = 0; m < nMeals; m++) {
      for (let i = 0; i < nFoods; i++) {
        const coeff = aminoPerG[i][a];
        if (coeff > 0) terms.push(`${coeff} ${varName(i, m)}`);
      }
    }
    lines.push(`  c${cIdx++}: ${terms.join(' + ')} >= ${atargets[a].dailyMinMg * aminoRelax}`);
  }

  // 2) MACRO = target with slacks (5 equality constraints)
  const macroTargetValues = [mtargets.kcal, mtargets.proteinG, mtargets.carbsG, mtargets.fatG, mtargets.fiberG];
  for (let j = 0; j < nMacros; j++) {
    const terms: string[] = [];
    for (let m = 0; m < nMeals; m++) {
      for (let i = 0; i < nFoods; i++) {
        const coeff = macroPerG[i][j];
        if (coeff > 0) terms.push(`${coeff} ${varName(i, m)}`);
      }
    }
    terms.push(`1 su_${j}`);
    terms.push(`-1 so_${j}`);
    lines.push(`  c${cIdx++}: ${terms.join(' + ')} = ${macroTargetValues[j]}`);
  }

  // 3) PER-FOOD DAILY total upper bounds
  for (let i = 0; i < nFoods; i++) {
    const terms: string[] = [];
    for (let m = 0; m < nMeals; m++) {
      terms.push(`1 ${varName(i, m)}`);
    }
    lines.push(`  c${cIdx++}: ${terms.join(' + ')} <= ${maxPerDay}`);
  }

  // 4) MEAL CALORIE DISTRIBUTION bounds
  const targetKcal = mtargets.kcal;
  for (let m = 0; m < nMeals; m++) {
    const mealName = mealSlots[m];
    const frac = MEAL_KCAL_FRACTIONS[mealName] ?? 0.15;
    const lo = targetKcal * Math.max(frac - MEAL_KCAL_TOLERANCE, 0.02);
    const hi = targetKcal * Math.min(frac + MEAL_KCAL_TOLERANCE, 0.50);

    const terms: string[] = [];
    for (let i = 0; i < nFoods; i++) {
      const coeff = macroPerG[i][0];
      if (coeff > 0) terms.push(`${coeff} ${varName(i, m)}`);
    }

    lines.push(`  c${cIdx++}: ${terms.join(' + ')} >= ${lo}`);
    lines.push(`  c${cIdx++}: ${terms.join(' + ')} <= ${hi}`);
  }

  // 5) PORTABILITY constraints for snack meals on active days
  if (dayType !== 'rest') {
    const nonPortableIdx = avail.map((f, i) => f.portable ? -1 : i).filter(i => i >= 0);
    for (let m = 0; m < nMeals; m++) {
      if (PORTABLE_MEALS.includes(mealSlots[m])) {
        for (const i of nonPortableIdx) {
          lines.push(`  c${cIdx++}: ${varName(i, m)} <= 0`);
        }
      }
    }
  }

  // 6) FOOD LOCKS (lower bound constraints)
  for (const lock of locks) {
    const fi = avail.findIndex(f => f.food === lock.food);
    const mi = mealSlots.indexOf(lock.meal);
    if (fi >= 0 && mi >= 0) {
      lines.push(`  c${cIdx++}: ${varName(fi, mi)} >= ${lock.minGrams}`);
    }
  }

  // Bounds section
  lines.push('Bounds');
  for (let m = 0; m < nMeals; m++) {
    for (let i = 0; i < nFoods; i++) {
      const cat = avail[i].category;
      const maxG = maxPerMeal[cat] ?? 150;
      lines.push(`  0 <= ${varName(i, m)} <= ${maxG}`);
    }
  }
  for (let j = 0; j < nMacros; j++) {
    lines.push(`  0 <= su_${j} <= +inf`);
    lines.push(`  0 <= so_${j} <= +inf`);
  }

  lines.push('End');

  return {
    lpString: lines.join('\n'),
    nFoods,
    nMeals,
    availFoods: avail,
    mealSlots,
  };
}

// ── Format LP solution into standard plan ─────────────────────────────

interface HighsResult {
  Status: string;
  Columns: Record<string, { Primal: number }>;
  ObjectiveValue: number;
}

function formatSolution(
  result: HighsResult,
  model: LpModel,
  minGrams: number = 5,
): MealPlanItem[] | null {
  const items: MealPlanItem[] = [];

  for (let m = 0; m < model.nMeals; m++) {
    for (let i = 0; i < model.nFoods; i++) {
      const name = varName(i, m);
      const col = result.Columns[name];
      if (!col) continue;
      const val = col.Primal;
      if (val >= minGrams) {
        const rounded = Math.round(val / 5) * 5;
        if (rounded >= minGrams) {
          items.push({
            meal: model.mealSlots[m],
            food: model.availFoods[i].food,
            grams: rounded,
          });
        }
      }
    }
  }

  if (items.length === 0) return null;

  const mealOrder = model.mealSlots;
  items.sort((a, b) => {
    const ma = mealOrder.indexOf(a.meal);
    const mb = mealOrder.indexOf(b.meal);
    if (ma !== mb) return ma - mb;
    return b.grams - a.grams;
  });

  return items;
}

// ── Main optimizer function ───────────────────────────────────────────

export interface OptimizeOptions {
  profile: AthleteProfile;
  foodDb?: Food[];
  locks?: FoodLock[];
  excluded?: string[];
  mealSlots?: MealSlot[];
  maxPerMeal?: Record<string, number>;
  maxPerDay?: number;
}

export async function optimizeDayPlan(
  dayType: Sport,
  options: OptimizeOptions,
): Promise<MealPlanItem[] | null> {
  const highs = await getHighs();

  const model = buildLpModel(
    dayType,
    options.profile,
    options.foodDb,
    options.locks,
    options.excluded,
    options.mealSlots,
    options.maxPerMeal,
    options.maxPerDay,
  );

  try {
    const result: HighsResult = highs.solve(model.lpString);
    if (result.Status === 'Optimal') {
      return formatSolution(result, model);
    }
  } catch {
    // LP failed, try fallback
  }

  // Fallback: relax amino constraints to 90% and retry
  console.warn(`LP infeasible for ${dayType} day — relaxing amino targets to 90%`);

  const relaxedModel = buildLpModel(
    dayType,
    options.profile,
    options.foodDb,
    options.locks,
    options.excluded,
    options.mealSlots,
    options.maxPerMeal,
    options.maxPerDay,
    0.9, // aminoRelax
  );

  try {
    const result2: HighsResult = highs.solve(relaxedModel.lpString);
    if (result2.Status === 'Optimal') {
      console.warn('Plan generated with relaxed amino targets (90%)');
      return formatSolution(result2, relaxedModel);
    }
  } catch {
    // Still infeasible
  }

  console.warn(`Could not generate a feasible plan for ${dayType} day`);
  return null;
}

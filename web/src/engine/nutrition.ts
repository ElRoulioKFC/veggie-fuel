import type { Food, MealPlanItem, NutritionTotals, MealNutrition, MacroTargets, AminoTarget, MacroComparison, AminoComparison } from '../data/types';
import { MEAL_SLOTS, AMINO_COLS, MACRO_COLS } from '../data/types';
import { foods as foodDb } from '../data/foods';

export interface PlanNutritionItem extends MealPlanItem {
  kcal: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
  fiberG: number;
  leucineMg: number;
  isoleucineMg: number;
  valineMg: number;
  lysineMg: number;
  methionineMg: number;
  threonineMg: number;
  tryptophanMg: number;
  phenylalanineMg: number;
  histidineMg: number;
}

export function calculatePlanNutrition(items: MealPlanItem[], db: Food[] = foodDb): PlanNutritionItem[] {
  return items.map(item => {
    const food = db.find(f => f.food === item.food);
    if (!food) throw new Error(`Food not found in database: ${item.food}`);
    const scale = item.grams / 100;
    return {
      ...item,
      kcal: food.kcal * scale,
      proteinG: food.proteinG * scale,
      carbsG: food.carbsG * scale,
      fatG: food.fatG * scale,
      fiberG: food.fiberG * scale,
      leucineMg: food.leucineMg * scale,
      isoleucineMg: food.isoleucineMg * scale,
      valineMg: food.valineMg * scale,
      lysineMg: food.lysineMg * scale,
      methionineMg: food.methionineMg * scale,
      threonineMg: food.threonineMg * scale,
      tryptophanMg: food.tryptophanMg * scale,
      phenylalanineMg: food.phenylalanineMg * scale,
      histidineMg: food.histidineMg * scale,
    };
  });
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function asRecord(obj: any): Record<string, number> { return obj; }

export function summarizePlan(nutrition: PlanNutritionItem[]): NutritionTotals {
  const totals: NutritionTotals = {
    kcal: 0, proteinG: 0, carbsG: 0, fatG: 0, fiberG: 0,
    leucineMg: 0, isoleucineMg: 0, valineMg: 0, lysineMg: 0,
    methionineMg: 0, threonineMg: 0, tryptophanMg: 0,
    phenylalanineMg: 0, histidineMg: 0,
  };
  for (const item of nutrition) {
    for (const col of [...MACRO_COLS, ...AMINO_COLS]) {
      asRecord(totals)[col] += asRecord(item)[col];
    }
  }
  // Round
  for (const key of Object.keys(totals)) {
    asRecord(totals)[key] = Math.round(asRecord(totals)[key] * 10) / 10;
  }
  return totals;
}

export function summarizeByMeal(nutrition: PlanNutritionItem[]): MealNutrition[] {
  const mealMap = new Map<string, { foods: string[]; kcal: number; proteinG: number; carbsG: number; fatG: number }>();

  for (const slot of MEAL_SLOTS) {
    mealMap.set(slot, { foods: [], kcal: 0, proteinG: 0, carbsG: 0, fatG: 0 });
  }

  for (const item of nutrition) {
    const m = mealMap.get(item.meal);
    if (!m) continue;
    m.foods.push(item.food);
    m.kcal += item.kcal;
    m.proteinG += item.proteinG;
    m.carbsG += item.carbsG;
    m.fatG += item.fatG;
  }

  return MEAL_SLOTS
    .filter(slot => {
      const m = mealMap.get(slot);
      return m && m.foods.length > 0;
    })
    .map(slot => {
      const m = mealMap.get(slot)!;
      return {
        meal: slot,
        foods: m.foods.join(' + '),
        kcal: Math.round(m.kcal),
        proteinG: Math.round(m.proteinG * 10) / 10,
        carbsG: Math.round(m.carbsG * 10) / 10,
        fatG: Math.round(m.fatG * 10) / 10,
      };
    });
}

export function compareMacros(totals: NutritionTotals, targets: MacroTargets): MacroComparison[] {
  const entries: { nutrient: string; key: keyof MacroTargets }[] = [
    { nutrient: 'kcal', key: 'kcal' },
    { nutrient: 'protein_g', key: 'proteinG' },
    { nutrient: 'carbs_g', key: 'carbsG' },
    { nutrient: 'fat_g', key: 'fatG' },
    { nutrient: 'fiber_g', key: 'fiberG' },
  ];

  return entries.map(e => {
    const target = targets[e.key];
    const actual = asRecord(totals)[e.key];
    const pct = Math.round(actual / target * 100);
    return {
      nutrient: e.nutrient,
      target,
      actual: Math.round(actual),
      pct,
      status: pct >= 90 ? 'OK' as const : pct >= 75 ? 'LOW' as const : 'DEFICIENT' as const,
    };
  });
}

export function compareAminos(totals: NutritionTotals, targets: AminoTarget[]): AminoComparison[] {
  return targets.map(t => {
    const actual = asRecord(totals)[t.csvColumn];
    const pct = Math.round(actual / t.dailyMinMg * 100);
    return {
      aminoAcid: t.aminoAcid,
      dailyMinMg: t.dailyMinMg,
      actualMg: Math.round(actual),
      pct,
      status: pct >= 100 ? 'OK' as const : pct >= 80 ? 'LOW' as const : 'DEFICIENT' as const,
    };
  });
}

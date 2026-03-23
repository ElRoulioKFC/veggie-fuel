import type { Recipe, RecipeMatch, DayPlan, MealSlot, NutritionTotals } from '../data/types';
import { MEAL_SLOTS, AMINO_COLS, MACRO_COLS } from '../data/types';
import { foods as foodDb } from '../data/foods';

export function calculateRecipeNutrition(recipe: Recipe): NutritionTotals {
  const totals: NutritionTotals = {
    kcal: 0, proteinG: 0, carbsG: 0, fatG: 0, fiberG: 0,
    leucineMg: 0, isoleucineMg: 0, valineMg: 0, lysineMg: 0,
    methionineMg: 0, threonineMg: 0, tryptophanMg: 0,
    phenylalanineMg: 0, histidineMg: 0,
  };

  for (const ing of recipe.ingredients) {
    const food = foodDb.find(f => f.food === ing.food);
    if (!food) continue;
    const scale = ing.grams / 100;
    for (const col of [...MACRO_COLS, ...AMINO_COLS]) {
      (totals as unknown as Record<string, number>)[col] += (food as unknown as Record<string, number>)[col] * scale;
    }
  }

  for (const key of Object.keys(totals)) {
    (totals as unknown as Record<string, number>)[key] = Math.round((totals as unknown as Record<string, number>)[key] * 10) / 10;
  }

  return totals;
}

export function calculatePerServing(recipe: Recipe): NutritionTotals {
  const total = calculateRecipeNutrition(recipe);
  for (const key of Object.keys(total)) {
    (total as unknown as Record<string, number>)[key] = Math.round((total as unknown as Record<string, number>)[key] / recipe.servings * 10) / 10;
  }
  return total;
}

export function matchRecipesToPlan(plan: DayPlan, allRecipes: Recipe[]): Map<MealSlot, RecipeMatch[]> {
  const allFoodsInPlan = new Set(plan.items.map(item => item.food));
  const foodsByMeal = new Map<MealSlot, Set<string>>();

  for (const slot of MEAL_SLOTS) {
    foodsByMeal.set(slot, new Set(
      plan.items.filter(item => item.meal === slot).map(item => item.food)
    ));
  }

  const result = new Map<MealSlot, RecipeMatch[]>();

  for (const slot of MEAL_SLOTS) {
    const matches: RecipeMatch[] = [];

    for (const recipe of allRecipes) {
      if (!recipe.mealTypes.includes(slot)) continue;

      const ingredientFoods = recipe.ingredients.map(i => i.food);
      const matchedFoods = ingredientFoods.filter(f => allFoodsInPlan.has(f));
      const missingFoods = ingredientFoods.filter(f => !allFoodsInPlan.has(f));
      const overlapScore = matchedFoods.length / ingredientFoods.length;

      if (overlapScore >= 0.4) {
        matches.push({ recipe, overlapScore, matchedFoods, missingFoods });
      }
    }

    matches.sort((a, b) => b.overlapScore - a.overlapScore);
    result.set(slot, matches.slice(0, 3));
  }

  return result;
}

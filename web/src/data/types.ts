export type Sport = 'trail' | 'kayak' | 'climbing' | 'swimming' | 'rest';
export type MealSlot = 'Breakfast' | 'Snack AM' | 'Lunch' | 'Snack PM' | 'Dinner' | 'Recovery';
export type Goal = 'performance' | 'muscle_gain' | 'weight_loss' | 'recomposition';
export type FoodCategory = 'soy' | 'legume' | 'grain' | 'dairy_egg' | 'nut_seed' | 'vegetable' | 'fruit' | 'protein' | 'sport';

export interface AthleteProfile {
  name: string;
  sex: 'female' | 'male';
  heightCm: number;
  weightKg: number;
  ageYears: number;
  sportPrimary: Sport;
  sportSecondary: Sport | null;
  trainingHoursWeek: number;
  goal: Goal;
}

export interface Food {
  food: string;
  category: FoodCategory;
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
  portable: boolean;
  prepMinutes: number;
}

export interface MealPlanItem {
  meal: MealSlot;
  food: string;
  grams: number;
}

export interface DayPlan {
  dayType: Sport;
  items: MealPlanItem[];
}

export interface MacroTargets {
  kcal: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
  fiberG: number;
}

export interface AminoTarget {
  aminoAcid: string;
  mgPerKg: number;
  csvColumn: string;
  dailyMinMg: number;
  notes: string;
}

export interface MacroComparison {
  nutrient: string;
  target: number;
  actual: number;
  pct: number;
  status: 'OK' | 'LOW' | 'DEFICIENT';
}

export interface AminoComparison {
  aminoAcid: string;
  dailyMinMg: number;
  actualMg: number;
  pct: number;
  status: 'OK' | 'LOW' | 'DEFICIENT';
}

export interface AminoCoverage {
  aminoAcid: string;
  dailyMinMg: number;
  actualMg: number;
  pct: number;
  status: 'SUFFICIENT' | 'MARGINAL' | 'DEFICIENT';
  notes: string;
}

export interface FoodLock {
  food: string;
  meal: MealSlot;
  minGrams: number;
}

export interface WeekStructure {
  [sport: string]: number;
}

export interface WeekPlan {
  plans: (DayPlan | null)[];
  dayTypes: Sport[];
}

export interface WeekSummary {
  perDay: DayNutrition[];
  average: NutritionTotals;
}

export interface NutritionTotals {
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

export interface DayNutrition extends NutritionTotals {
  day: number;
  dayType: Sport;
}

export interface MealNutrition {
  meal: MealSlot;
  foods: string;
  kcal: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
}

export interface RecipeIngredient {
  food: string;
  grams: number;
}

export interface Recipe {
  id: string;
  name: string;
  description: string;
  mealTypes: MealSlot[];
  servings: number;
  prepMinutes: number;
  cookMinutes: number;
  ingredients: RecipeIngredient[];
  steps: string[];
  tags: string[];
}

export interface RecipeMatch {
  recipe: Recipe;
  overlapScore: number;
  matchedFoods: string[];
  missingFoods: string[];
}

export const MEAL_SLOTS: MealSlot[] = ['Breakfast', 'Snack AM', 'Lunch', 'Snack PM', 'Dinner', 'Recovery'];
export const SPORTS: Sport[] = ['trail', 'kayak', 'climbing', 'swimming', 'rest'];
export const AMINO_COLS = ['leucineMg', 'isoleucineMg', 'valineMg', 'lysineMg', 'methionineMg', 'threonineMg', 'tryptophanMg', 'phenylalanineMg', 'histidineMg'] as const;
export const MACRO_COLS = ['kcal', 'proteinG', 'carbsG', 'fatG', 'fiberG'] as const;

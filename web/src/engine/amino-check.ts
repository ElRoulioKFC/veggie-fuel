import type { AthleteProfile, MealPlanItem, AminoCoverage } from '../data/types';
import { AMINO_COLS } from '../data/types';
import { foods as foodDb } from '../data/foods';
import { computeAminoTargets } from './targets';

export function checkAminoCoverage(foodServings: MealPlanItem[], profile: AthleteProfile): AminoCoverage[] {
  const targets = computeAminoTargets(profile);

  // Sum amino acids from all food servings
  const aminoTotals: Record<string, number> = {};
  for (const col of AMINO_COLS) aminoTotals[col] = 0;

  for (const item of foodServings) {
    const food = foodDb.find(f => f.food === item.food);
    if (!food) throw new Error(`Food not found in database: ${item.food}`);
    const scale = item.grams / 100;
    for (const col of AMINO_COLS) {
      aminoTotals[col] += food[col] * scale;
    }
  }

  return targets.map(t => {
    const actual = aminoTotals[t.csvColumn] || 0;
    const pct = Math.round(actual / t.dailyMinMg * 1000) / 10;
    return {
      aminoAcid: t.aminoAcid,
      dailyMinMg: t.dailyMinMg,
      actualMg: Math.round(actual),
      pct,
      status: pct >= 100 ? 'SUFFICIENT' as const : pct >= 80 ? 'MARGINAL' as const : 'DEFICIENT' as const,
      notes: t.notes,
    };
  });
}

const FIX_SUGGESTIONS: Record<string, string[]> = {
  leucine: ['Soy (tofu, tempeh, edamame)', 'Pumpkin seeds', 'Cheese'],
  isoleucine: ['Tofu', 'Eggs', 'Lentils', 'Seaweed'],
  valine: ['Soy products', 'Peanuts', 'Mushrooms'],
  lysine: ['Beans & lentils', 'Tofu', 'Quinoa', 'Pistachios'],
  methionine: ['Eggs', 'Sesame seeds', 'Brazil nuts', 'Oats'],
  threonine: ['Lentils', 'Cottage cheese', 'Sesame seeds', 'Spirulina'],
  tryptophan: ['Cheese', 'Oats', 'Tofu', 'Pumpkin seeds'],
  phenylalanine: ['Soy products', 'Almonds', 'Eggs', 'Peanuts'],
  histidine: ['Tofu', 'Wheat germ', 'Rice', 'Beans'],
};

export function suggestFixes(coverage: AminoCoverage[]): { aminoAcid: string; gapMg: number; suggestions: string[] }[] {
  return coverage
    .filter(c => c.status !== 'SUFFICIENT')
    .map(c => ({
      aminoAcid: c.aminoAcid,
      gapMg: Math.round(c.dailyMinMg - c.actualMg),
      suggestions: FIX_SUGGESTIONS[c.aminoAcid] || [],
    }));
}

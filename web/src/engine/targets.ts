import type { AthleteProfile, MacroTargets, AminoTarget, Sport, Goal } from '../data/types';

const AMINO_REQUIREMENTS_PER_KG: { aminoAcid: string; mgPerKg: number; csvColumn: string; notes: string }[] = [
  { aminoAcid: 'leucine', mgPerKg: 39, csvColumn: 'leucineMg', notes: 'BCAA — muscle repair' },
  { aminoAcid: 'isoleucine', mgPerKg: 20, csvColumn: 'isoleucineMg', notes: 'BCAA — energy' },
  { aminoAcid: 'valine', mgPerKg: 26, csvColumn: 'valineMg', notes: 'BCAA — tissue repair' },
  { aminoAcid: 'lysine', mgPerKg: 30, csvColumn: 'lysineMg', notes: 'Often limiting in grains!' },
  { aminoAcid: 'methionine', mgPerKg: 10.4, csvColumn: 'methionineMg', notes: 'Includes cysteine requirement' },
  { aminoAcid: 'threonine', mgPerKg: 15, csvColumn: 'threonineMg', notes: 'Collagen & gut health' },
  { aminoAcid: 'tryptophan', mgPerKg: 4, csvColumn: 'tryptophanMg', notes: 'Serotonin precursor' },
  { aminoAcid: 'phenylalanine', mgPerKg: 25, csvColumn: 'phenylalanineMg', notes: 'Includes tyrosine requirement' },
  { aminoAcid: 'histidine', mgPerKg: 10, csvColumn: 'histidineMg', notes: 'Needed for growth/repair' },
];

interface SportDayAdjustment {
  sport: Sport;
  carbPct: number;
  proteinPct: number;
  fatPct: number;
  kcalMult: number;
  description: string;
}

const SPORT_DAY_ADJUSTMENTS: SportDayAdjustment[] = [
  { sport: 'trail', carbPct: 0.58, proteinPct: 0.16, fatPct: 0.26, kcalMult: 1.10, description: 'Trail day: high carb for long effort, moderate protein' },
  { sport: 'kayak', carbPct: 0.52, proteinPct: 0.19, fatPct: 0.29, kcalMult: 1.00, description: 'Kayak day: higher protein for upper body, moderate carb' },
  { sport: 'climbing', carbPct: 0.50, proteinPct: 0.20, fatPct: 0.30, kcalMult: 0.95, description: 'Climbing day: high protein for grip recovery' },
  { sport: 'swimming', carbPct: 0.58, proteinPct: 0.17, fatPct: 0.25, kcalMult: 1.20, description: 'Swimming day: high carb + high expenditure' },
  { sport: 'rest', carbPct: 0.50, proteinPct: 0.18, fatPct: 0.32, kcalMult: 0.80, description: 'Rest day: reduced calories, maintain protein' },
];

interface GoalModifier {
  goal: Goal;
  kcalMult: number;
  proteinPerKg: number;
  carbsPerKg: number;
  description: string;
}

const GOAL_MODIFIERS: GoalModifier[] = [
  { goal: 'performance',   kcalMult: 1.00, proteinPerKg: 1.7, carbsPerKg: 7.0, description: 'Balanced for sport performance' },
  { goal: 'weight_loss',   kcalMult: 0.85, proteinPerKg: 2.0, carbsPerKg: 5.0, description: '15% deficit, high protein to preserve muscle' },
  { goal: 'muscle_gain',   kcalMult: 1.10, proteinPerKg: 2.0, carbsPerKg: 7.0, description: '10% surplus + high protein' },
  { goal: 'recomposition', kcalMult: 1.00, proteinPerKg: 2.2, carbsPerKg: 5.5, description: 'Maintenance kcal, highest protein, moderate carbs' },
];

export function getGoalModifiers() {
  return GOAL_MODIFIERS;
}

export function validateProfile(profile: AthleteProfile): void {
  if (profile.weightKg <= 0 || profile.weightKg > 300) {
    throw new Error(`weight must be between 0 and 300, got: ${profile.weightKg}`);
  }
}

export function computeMacroTargets(profile: AthleteProfile): MacroTargets {
  validateProfile(profile);
  const w = profile.weightKg;
  const h = profile.heightCm;
  const age = profile.ageYears;
  const hrs = profile.trainingHoursWeek;

  // BMR via Mifflin-St Jeor
  const bmr = profile.sex === 'male'
    ? 10 * w + 6.25 * h - 5 * age + 5
    : 10 * w + 6.25 * h - 5 * age - 161;

  // Activity factor based on training hours/week
  const activityFactor = hrs <= 3 ? 1.375 : hrs <= 6 ? 1.55 : hrs <= 10 ? 1.725 : 1.9;

  // Goal-based modifiers
  const gm = GOAL_MODIFIERS.find(g => g.goal === profile.goal) ?? GOAL_MODIFIERS[0];

  let totalKcal = bmr * activityFactor * gm.kcalMult;

  // Protein & carbs scaled by goal
  const proteinG = Math.round(w * gm.proteinPerKg);
  const carbsG = Math.round(w * gm.carbsPerKg);
  // Fat: remainder of calories
  const proteinKcal = proteinG * 4;
  const carbsKcal = carbsG * 4;
  const fatKcal = Math.max(totalKcal - proteinKcal - carbsKcal, totalKcal * 0.20);
  const fatG = Math.round(fatKcal / 9);

  // Recalculate for consistency
  totalKcal = proteinKcal + carbsKcal + fatKcal;

  return {
    kcal: Math.round(totalKcal),
    proteinG,
    carbsG,
    fatG,
    fiberG: 30,
  };
}

export function computeAminoTargets(profile: AthleteProfile): AminoTarget[] {
  validateProfile(profile);
  return AMINO_REQUIREMENTS_PER_KG.map(r => ({
    aminoAcid: r.aminoAcid,
    mgPerKg: r.mgPerKg,
    csvColumn: r.csvColumn,
    dailyMinMg: Math.round(r.mgPerKg * profile.weightKg),
    notes: r.notes,
  }));
}

export function adjustTargetsForDay(dayType: Sport, profile: AthleteProfile): MacroTargets {
  validateProfile(profile);
  const adj = SPORT_DAY_ADJUSTMENTS.find(a => a.sport === dayType);
  if (!adj) throw new Error(`Unknown day_type: ${dayType}`);

  const base = computeMacroTargets(profile);
  const adjKcal = Math.round(base.kcal * adj.kcalMult);

  return {
    kcal: adjKcal,
    proteinG: Math.round(adjKcal * adj.proteinPct / 4),
    carbsG: Math.round(adjKcal * adj.carbPct / 4),
    fatG: Math.round(adjKcal * adj.fatPct / 9),
    fiberG: 30,
  };
}

export function getSportAdjustments() {
  return SPORT_DAY_ADJUSTMENTS;
}

export function getAminoRequirements() {
  return AMINO_REQUIREMENTS_PER_KG;
}

export const DEFAULT_PROFILE: AthleteProfile = {
  name: 'Athlete',
  sex: 'female',
  heightCm: 165,
  weightKg: 60,
  ageYears: 30,
  sportPrimary: 'trail',
  sportSecondary: 'kayak',
  trainingHoursWeek: 10,
  goal: 'performance',
};

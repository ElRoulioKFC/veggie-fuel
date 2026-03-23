import type { AthleteProfile, DayPlan, FoodLock, Sport, WeekPlan, WeekStructure } from '../data/types';
import { optimizeDayPlan } from './optimizer';

export async function planWeek(
  weekStructure: WeekStructure = { trail: 3, kayak: 2, rest: 2 },
  profile: AthleteProfile,
  maxFoodAppearances: number = 10,
  locks: FoodLock[] = [],
): Promise<WeekPlan> {
  const total = Object.values(weekStructure).reduce((a, b) => a + b, 0);
  if (total !== 7) throw new Error(`week_structure must sum to 7, got ${total}`);

  // Expand day types
  const dayTypes: Sport[] = [];
  for (const [sport, count] of Object.entries(weekStructure)) {
    for (let i = 0; i < count; i++) {
      dayTypes.push(sport as Sport);
    }
  }

  const plans: (DayPlan | null)[] = [];
  const foodCounts: Record<string, number> = {};

  for (let d = 0; d < 7; d++) {
    const dt = dayTypes[d];

    // Determine overused foods
    const overUsed = Object.entries(foodCounts)
      .filter(([, count]) => count >= maxFoodAppearances)
      .map(([food]) => food);

    let plan = await optimizeDayPlan(dt, {
      profile,
      excluded: overUsed,
      locks,
    });

    // If infeasible due to too many exclusions, gradually relax
    if (!plan && overUsed.length > 0) {
      const sorted = [...overUsed].sort((a, b) => (foodCounts[a] || 0) - (foodCounts[b] || 0));
      const remaining = [...overUsed];
      for (const candidate of sorted) {
        const idx = remaining.indexOf(candidate);
        if (idx >= 0) remaining.splice(idx, 1);
        plan = await optimizeDayPlan(dt, {
          profile,
          excluded: remaining,
          locks,
        });
        if (plan) break;
      }
    }

    if (plan) {
      for (const item of plan) {
        foodCounts[item.food] = (foodCounts[item.food] || 0) + 1;
      }
      plans.push({ dayType: dt, items: plan });
    } else {
      plans.push(null);
    }
  }

  return { plans, dayTypes };
}

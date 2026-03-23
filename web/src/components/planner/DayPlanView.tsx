import { Box, Typography } from '@mui/material';
import type { MealPlanItem, MealSlot } from '../../data/types';
import { MEAL_SLOTS } from '../../data/types';
import type { PlanNutritionItem } from '../../engine/nutrition';
import { calculatePlanNutrition } from '../../engine/nutrition';
import MealCard from './MealCard';

interface Props {
  items: MealPlanItem[];
}

export default function DayPlanView({ items }: Props) {
  const nutrition = calculatePlanNutrition(items);

  // Group by meal
  const byMeal = new Map<MealSlot, PlanNutritionItem[]>();
  for (const slot of MEAL_SLOTS) byMeal.set(slot, []);
  for (const item of nutrition) {
    byMeal.get(item.meal)?.push(item);
  }

  return (
    <Box>
      <Typography variant="h6" gutterBottom>Meal Plan</Typography>
      {MEAL_SLOTS.map(slot => {
        const mealItems = byMeal.get(slot) || [];
        if (mealItems.length === 0) return null;
        return <MealCard key={slot} meal={slot} items={mealItems} />;
      })}
    </Box>
  );
}

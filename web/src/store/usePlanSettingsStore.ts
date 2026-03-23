import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { FoodLock, MealSlot } from '../data/types';

interface PlanSettingsState {
  excludedFoods: string[];
  foodLocks: FoodLock[];
  maxFoodAppearances: number;
  addExclusion: (food: string) => void;
  removeExclusion: (food: string) => void;
  addLock: (lock: FoodLock) => void;
  removeLock: (food: string, meal: MealSlot) => void;
  setMaxFoodAppearances: (n: number) => void;
  clearAll: () => void;
}

export const usePlanSettingsStore = create<PlanSettingsState>()(
  persist(
    (set) => ({
      excludedFoods: [],
      foodLocks: [],
      maxFoodAppearances: 10,
      addExclusion: (food) =>
        set((s) => ({
          excludedFoods: s.excludedFoods.includes(food)
            ? s.excludedFoods
            : [...s.excludedFoods, food],
        })),
      removeExclusion: (food) =>
        set((s) => ({
          excludedFoods: s.excludedFoods.filter((f) => f !== food),
        })),
      addLock: (lock) =>
        set((s) => ({
          foodLocks: [
            ...s.foodLocks.filter(
              (l) => !(l.food === lock.food && l.meal === lock.meal),
            ),
            lock,
          ],
        })),
      removeLock: (food, meal) =>
        set((s) => ({
          foodLocks: s.foodLocks.filter(
            (l) => !(l.food === food && l.meal === meal),
          ),
        })),
      setMaxFoodAppearances: (n) => set({ maxFoodAppearances: n }),
      clearAll: () =>
        set({ excludedFoods: [], foodLocks: [], maxFoodAppearances: 10 }),
    }),
    { name: 'veggiefuel-plan-settings' },
  ),
);

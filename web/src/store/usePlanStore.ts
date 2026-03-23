import { create } from 'zustand';
import type { DayPlan, Sport, WeekPlan } from '../data/types';

interface PlanState {
  currentDayPlan: DayPlan | null;
  currentDayType: Sport;
  weekPlan: WeekPlan | null;
  isOptimizing: boolean;
  error: string | null;
  setDayPlan: (plan: DayPlan | null) => void;
  setDayType: (dayType: Sport) => void;
  setWeekPlan: (plan: WeekPlan | null) => void;
  setOptimizing: (val: boolean) => void;
  setError: (error: string | null) => void;
}

export const usePlanStore = create<PlanState>()((set) => ({
  currentDayPlan: null,
  currentDayType: 'trail',
  weekPlan: null,
  isOptimizing: false,
  error: null,
  setDayPlan: (plan) => set({ currentDayPlan: plan, error: null }),
  setDayType: (dayType) => set({ currentDayType: dayType }),
  setWeekPlan: (plan) => set({ weekPlan: plan, error: null }),
  setOptimizing: (val) => set({ isOptimizing: val }),
  setError: (error) => set({ error }),
}));

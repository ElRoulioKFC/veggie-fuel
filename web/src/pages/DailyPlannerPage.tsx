import { useState, useCallback } from 'react';
import {
  Box, Typography, Button, FormControl, InputLabel, Select, MenuItem,
  CircularProgress, Alert, Fade, Tabs, Tab, Chip, Skeleton,
} from '@mui/material';
import PlayArrowIcon from '@mui/icons-material/PlayArrow';
import ShuffleIcon from '@mui/icons-material/Shuffle';
import TuneIcon from '@mui/icons-material/Tune';
import ProfileSummaryBar from '../components/profile/ProfileSummaryBar';
import DayPlanView from '../components/planner/DayPlanView';
import MacroComparisonView from '../components/results/MacroComparison';
import AminoComparisonView from '../components/results/AminoComparison';
import AminoRadarChart from '../components/charts/AminoRadarChart';
import MealMacroBarChart from '../components/charts/MealMacroBarChart';
import RecipeSuggestions from '../components/recipes/RecipeSuggestions';
import FoodPreferencesDrawer from '../components/planner/FoodPreferencesDrawer';
import EmptyPlanState from '../components/planner/EmptyPlanState';
import { useProfileStore } from '../store/useProfileStore';
import { usePlanStore } from '../store/usePlanStore';
import { usePlanSettingsStore } from '../store/usePlanSettingsStore';
import { useSnackbarStore } from '../store/useSnackbarStore';
import { optimizeDayPlan } from '../engine/optimizer';
import { calculatePlanNutrition, summarizePlan, summarizeByMeal, compareMacros, compareAminos } from '../engine/nutrition';
import { adjustTargetsForDay, computeAminoTargets } from '../engine/targets';
import type { Sport, MealSlot } from '../data/types';
import { SPORTS } from '../data/types';

export default function DailyPlannerPage() {
  const { profile } = useProfileStore();
  const { currentDayPlan, currentDayType, isOptimizing, error, setDayPlan, setDayType, setOptimizing, setError } = usePlanStore();
  const { excludedFoods, foodLocks, addExclusion } = usePlanSettingsStore();
  const showSnack = useSnackbarStore((s) => s.show);

  const [localDayType, setLocalDayType] = useState<Sport>(currentDayType);
  const [resultTab, setResultTab] = useState(0);
  const [drawerOpen, setDrawerOpen] = useState(false);

  const handleGenerate = useCallback(async (extraExcluded: string[] = []) => {
    setOptimizing(true);
    setError(null);
    setDayType(localDayType);
    try {
      const allExcluded = [...excludedFoods, ...extraExcluded];
      const items = await optimizeDayPlan(localDayType, {
        profile,
        excluded: allExcluded.length > 0 ? allExcluded : undefined,
        locks: foodLocks.length > 0 ? foodLocks : undefined,
      });
      if (items) {
        setDayPlan({ dayType: localDayType, items });
      } else {
        setError('Could not generate a feasible plan. Try adjusting your profile or food preferences.');
        setDayPlan(null);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Optimization failed');
      setDayPlan(null);
    }
    setOptimizing(false);
  }, [localDayType, profile, excludedFoods, foodLocks, setOptimizing, setError, setDayType, setDayPlan]);

  const handleRegenerate = useCallback(() => {
    if (!currentDayPlan) return;
    // Temporarily exclude the most-used food for variety
    const foodCounts: Record<string, number> = {};
    for (const item of currentDayPlan.items) {
      foodCounts[item.food] = (foodCounts[item.food] || 0) + item.grams;
    }
    const topFood = Object.entries(foodCounts).sort((a, b) => b[1] - a[1])[0]?.[0];
    handleGenerate(topFood ? [topFood] : []);
    showSnack('Regenerating with new variety...', 'info');
  }, [currentDayPlan, handleGenerate, showSnack]);

  const handleSwapFood = useCallback(async (food: string, _meal: MealSlot) => {
    handleGenerate([food]);
    showSnack(`Swapping out ${food}...`, 'info');
  }, [handleGenerate, showSnack]);

  const handleExcludeFood = useCallback((food: string) => {
    addExclusion(food);
    showSnack(`${food} excluded from future plans`, 'success');
  }, [addExclusion, showSnack]);

  // Compute analysis if plan exists
  let macroComps = null;
  let aminoComps = null;
  let mealSummary = null;

  if (currentDayPlan) {
    const nutrition = calculatePlanNutrition(currentDayPlan.items);
    const totals = summarizePlan(nutrition);
    mealSummary = summarizeByMeal(nutrition);
    const dayTargets = adjustTargetsForDay(currentDayPlan.dayType, profile);
    const aminoTargets = computeAminoTargets(profile);
    macroComps = compareMacros(totals, dayTargets);
    aminoComps = compareAminos(totals, aminoTargets);
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom>Daily Meal Planner</Typography>

      {/* Zone 1: Collapsible Profile */}
      <ProfileSummaryBar />

      {/* Zone 2: Sticky Action Bar */}
      <Box
        sx={{
          position: 'sticky',
          top: 64,
          zIndex: (t) => t.zIndex.appBar - 1,
          bgcolor: 'background.default',
          py: 1.5,
          display: 'flex',
          gap: 1.5,
          alignItems: 'center',
          flexWrap: 'wrap',
          borderBottom: 1,
          borderColor: 'divider',
          mb: 2,
        }}
      >
        <FormControl size="small" sx={{ minWidth: 140 }}>
          <InputLabel>Day Type</InputLabel>
          <Select
            value={localDayType}
            label="Day Type"
            onChange={(e) => setLocalDayType(e.target.value as Sport)}
          >
            {SPORTS.map((s) => (
              <MenuItem key={s} value={s}>{s.charAt(0).toUpperCase() + s.slice(1)}</MenuItem>
            ))}
          </Select>
        </FormControl>
        <Button
          variant="contained"
          startIcon={isOptimizing ? <CircularProgress size={18} color="inherit" /> : <PlayArrowIcon />}
          onClick={() => handleGenerate()}
          disabled={isOptimizing}
        >
          {isOptimizing ? 'Optimizing...' : 'Generate Plan'}
        </Button>
        {currentDayPlan && (
          <Button
            variant="outlined"
            startIcon={<ShuffleIcon />}
            onClick={handleRegenerate}
            disabled={isOptimizing}
            size="small"
          >
            Regenerate
          </Button>
        )}
        <Chip
          icon={<TuneIcon />}
          label={`Preferences${excludedFoods.length + foodLocks.length > 0 ? ` (${excludedFoods.length + foodLocks.length})` : ''}`}
          variant="outlined"
          onClick={() => setDrawerOpen(true)}
          sx={{ cursor: 'pointer' }}
        />
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      {/* Zone 3: Results */}
      {!currentDayPlan && !isOptimizing && (
        <EmptyPlanState onGenerate={() => handleGenerate()} isOptimizing={isOptimizing} />
      )}

      {isOptimizing && !currentDayPlan && (
        <Box sx={{ mt: 2 }}>
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} variant="rounded" height={80} sx={{ mb: 1.5, borderRadius: 2 }} />
          ))}
        </Box>
      )}

      {currentDayPlan && (
        <Fade in timeout={400}>
          <Box>
            <Tabs
              value={resultTab}
              onChange={(_, v) => setResultTab(v)}
              sx={{ mb: 2, borderBottom: 1, borderColor: 'divider' }}
            >
              <Tab label="Meals" sx={{ textTransform: 'none' }} />
              <Tab label="Nutrition" sx={{ textTransform: 'none' }} />
              <Tab label="Recipes" sx={{ textTransform: 'none' }} />
            </Tabs>

            {resultTab === 0 && (
              <DayPlanView
                items={currentDayPlan.items}
                onSwapFood={handleSwapFood}
                onExcludeFood={handleExcludeFood}
              />
            )}

            {resultTab === 1 && (
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                {macroComps && <MacroComparisonView comparisons={macroComps} />}
                {aminoComps && <AminoComparisonView comparisons={aminoComps} />}
                <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
                  <Box sx={{ flex: 1, minWidth: 300 }}>
                    {aminoComps && <AminoRadarChart comparisons={aminoComps} />}
                  </Box>
                  <Box sx={{ flex: 1, minWidth: 300 }}>
                    {mealSummary && <MealMacroBarChart meals={mealSummary} />}
                  </Box>
                </Box>
              </Box>
            )}

            {resultTab === 2 && (
              <RecipeSuggestions plan={currentDayPlan} />
            )}
          </Box>
        </Fade>
      )}

      <FoodPreferencesDrawer open={drawerOpen} onClose={() => setDrawerOpen(false)} />
    </Box>
  );
}

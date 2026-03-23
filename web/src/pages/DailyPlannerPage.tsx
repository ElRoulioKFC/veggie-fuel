import { useState } from 'react';
import {
  Box, Typography, Button, FormControl, InputLabel, Select, MenuItem,
  CircularProgress, Alert, Grid,
} from '@mui/material';
import PlayArrowIcon from '@mui/icons-material/PlayArrow';
import AthleteForm from '../components/profile/AthleteForm';
import DayPlanView from '../components/planner/DayPlanView';
import MacroComparisonView from '../components/results/MacroComparison';
import AminoComparisonView from '../components/results/AminoComparison';
import AminoRadarChart from '../components/charts/AminoRadarChart';
import MealMacroBarChart from '../components/charts/MealMacroBarChart';
import { useProfileStore } from '../store/useProfileStore';
import { usePlanStore } from '../store/usePlanStore';
import { optimizeDayPlan } from '../engine/optimizer';
import { calculatePlanNutrition, summarizePlan, summarizeByMeal, compareMacros, compareAminos } from '../engine/nutrition';
import { adjustTargetsForDay, computeAminoTargets } from '../engine/targets';
import type { Sport } from '../data/types';
import { SPORTS } from '../data/types';

export default function DailyPlannerPage() {
  const { profile } = useProfileStore();
  const { currentDayPlan, currentDayType, isOptimizing, error, setDayPlan, setDayType, setOptimizing, setError } = usePlanStore();
  const [localDayType, setLocalDayType] = useState<Sport>(currentDayType);

  const handleGenerate = async () => {
    setOptimizing(true);
    setError(null);
    setDayType(localDayType);
    try {
      const items = await optimizeDayPlan(localDayType, { profile });
      if (items) {
        setDayPlan({ dayType: localDayType, items });
      } else {
        setError('Could not generate a feasible plan. Try adjusting your profile or sport.');
        setDayPlan(null);
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Optimization failed');
      setDayPlan(null);
    }
    setOptimizing(false);
  };

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

      <AthleteForm />

      <Box sx={{ display: 'flex', gap: 2, alignItems: 'center', my: 2 }}>
        <FormControl size="small" sx={{ minWidth: 150 }}>
          <InputLabel>Day Type</InputLabel>
          <Select
            value={localDayType}
            label="Day Type"
            onChange={e => setLocalDayType(e.target.value as Sport)}
          >
            {SPORTS.map(s => (
              <MenuItem key={s} value={s}>{s.charAt(0).toUpperCase() + s.slice(1)}</MenuItem>
            ))}
          </Select>
        </FormControl>
        <Button
          variant="contained"
          startIcon={isOptimizing ? <CircularProgress size={18} color="inherit" /> : <PlayArrowIcon />}
          onClick={handleGenerate}
          disabled={isOptimizing}
        >
          {isOptimizing ? 'Optimizing...' : 'Generate Plan'}
        </Button>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      {currentDayPlan && (
        <Grid container spacing={2}>
          <Grid size={{ xs: 12, md: 6 }}>
            <DayPlanView items={currentDayPlan.items} />
          </Grid>
          <Grid size={{ xs: 12, md: 6 }}>
            {macroComps && <MacroComparisonView comparisons={macroComps} />}
            <Box sx={{ mt: 2 }}>
              {aminoComps && <AminoComparisonView comparisons={aminoComps} />}
            </Box>
          </Grid>
          <Grid size={{ xs: 12, md: 6 }}>
            {aminoComps && <AminoRadarChart comparisons={aminoComps} />}
          </Grid>
          <Grid size={{ xs: 12, md: 6 }}>
            {mealSummary && <MealMacroBarChart meals={mealSummary} />}
          </Grid>
        </Grid>
      )}
    </Box>
  );
}

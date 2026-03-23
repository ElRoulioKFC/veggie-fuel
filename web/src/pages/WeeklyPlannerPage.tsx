import { useState, useCallback } from 'react';
import {
  Box, Typography, Button, CircularProgress, Alert, Chip,
  Card, CardContent, LinearProgress, Fade, Collapse, Tabs, Tab,
  TextField, Grid,
} from '@mui/material';
import CalendarMonthIcon from '@mui/icons-material/CalendarMonth';
import TuneIcon from '@mui/icons-material/Tune';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import ExpandLessIcon from '@mui/icons-material/ExpandLess';
import ProfileSummaryBar from '../components/profile/ProfileSummaryBar';
import DayPlanView from '../components/planner/DayPlanView';
import FoodPreferencesDrawer from '../components/planner/FoodPreferencesDrawer';
import WeekOverviewDashboard from '../components/weekly/WeekOverviewDashboard';
import WeeklyAminoHeatmap from '../components/charts/WeeklyAminoHeatmap';
import MacroComparisonView from '../components/results/MacroComparison';
import AminoComparisonView from '../components/results/AminoComparison';
import AminoRadarChart from '../components/charts/AminoRadarChart';
import { useProfileStore } from '../store/useProfileStore';
import { usePlanStore } from '../store/usePlanStore';
import { usePlanSettingsStore } from '../store/usePlanSettingsStore';
import { planWeek } from '../engine/weekly';
import { calculatePlanNutrition, summarizePlan, compareMacros, compareAminos } from '../engine/nutrition';
import { adjustTargetsForDay, computeAminoTargets } from '../engine/targets';
import type { Sport, WeekStructure } from '../data/types';

const SPORT_OPTIONS: { value: Sport; label: string; color: string }[] = [
  { value: 'trail', label: 'Trail', color: '#4caf50' },
  { value: 'kayak', label: 'Kayak', color: '#2196f3' },
  { value: 'climbing', label: 'Climb', color: '#ff9800' },
  { value: 'swimming', label: 'Swim', color: '#00bcd4' },
  { value: 'rest', label: 'Rest', color: '#9e9e9e' },
];

const SPORT_LABELS: Record<string, string> = {
  trail: 'Trail', kayak: 'Kayak', climbing: 'Climbing', swimming: 'Swimming', rest: 'Rest',
};

export default function WeeklyPlannerPage() {
  const { profile } = useProfileStore();
  const { weekPlan, isOptimizing, error, setWeekPlan, setOptimizing, setError } = usePlanStore();
  const { excludedFoods, foodLocks, maxFoodAppearances } = usePlanSettingsStore();

  // Visual week selector: array of 7 sport values
  const [weekDays, setWeekDays] = useState<Sport[]>(['trail', 'trail', 'trail', 'kayak', 'kayak', 'rest', 'rest']);
  const [activeDay, setActiveDay] = useState(0);
  const [dayDetailTab, setDayDetailTab] = useState(0);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [progress, setProgress] = useState(0);

  // Convert weekDays array to WeekStructure
  const toStructure = (days: Sport[]): WeekStructure => {
    const s: WeekStructure = {};
    for (const d of days) {
      s[d] = (s[d] || 0) + 1;
    }
    return s;
  };

  // Advanced: number inputs
  const [advStructure, setAdvStructure] = useState<WeekStructure>({ trail: 3, kayak: 2, rest: 2 });
  const advTotal = Object.values(advStructure).reduce((a, b) => a + b, 0);

  const cycleSport = (idx: number) => {
    setWeekDays((prev) => {
      const next = [...prev];
      const currentIdx = SPORT_OPTIONS.findIndex((s) => s.value === next[idx]);
      next[idx] = SPORT_OPTIONS[(currentIdx + 1) % SPORT_OPTIONS.length].value;
      return next;
    });
  };

  const handleGenerate = useCallback(async () => {
    setOptimizing(true);
    setError(null);
    setProgress(0);
    try {
      const structure = showAdvanced ? advStructure : toStructure(weekDays);
      const week = await planWeek(
        structure,
        profile,
        maxFoodAppearances,
        foodLocks.length > 0 ? foodLocks : [],
        excludedFoods.length > 0 ? excludedFoods : [],
        (day) => setProgress(day),
      );
      setWeekPlan(week);
      setActiveDay(0);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Weekly planning failed');
    }
    setOptimizing(false);
    setProgress(0);
  }, [weekDays, advStructure, showAdvanced, profile, maxFoodAppearances, foodLocks, excludedFoods, setOptimizing, setError, setWeekPlan]);

  // Per-day nutrition analysis
  const activePlan = weekPlan?.plans[activeDay];
  let macroComps = null;
  let aminoComps = null;

  if (activePlan) {
    const nutrition = calculatePlanNutrition(activePlan.items);
    const totals = summarizePlan(nutrition);
    const dayTargets = adjustTargetsForDay(activePlan.dayType, profile);
    const aminoTargets = computeAminoTargets(profile);
    macroComps = compareMacros(totals, dayTargets);
    aminoComps = compareAminos(totals, aminoTargets);
  }

  return (
    <Box>
      <Typography variant="h4" gutterBottom>Weekly Meal Planner</Typography>

      <ProfileSummaryBar />

      {/* Visual Week Selector */}
      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>Week Structure</Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
            Click each day to cycle through sports.
          </Typography>

          <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap', mb: 1 }}>
            {weekDays.map((sport, i) => {
              const opt = SPORT_OPTIONS.find((s) => s.value === sport)!;
              return (
                <Chip
                  key={i}
                  label={`D${i + 1}: ${opt.label}`}
                  onClick={() => cycleSport(i)}
                  sx={{
                    bgcolor: opt.color,
                    color: '#fff',
                    fontWeight: 600,
                    cursor: 'pointer',
                    '&:hover': { opacity: 0.85 },
                    minWidth: 90,
                  }}
                />
              );
            })}
          </Box>

          {/* Advanced toggle */}
          <Button
            size="small"
            onClick={() => setShowAdvanced(!showAdvanced)}
            startIcon={showAdvanced ? <ExpandLessIcon /> : <ExpandMoreIcon />}
            sx={{ textTransform: 'none', color: 'text.secondary', mt: 0.5 }}
          >
            Advanced (number inputs)
          </Button>
          <Collapse in={showAdvanced}>
            <Grid container spacing={2} alignItems="center" sx={{ mt: 1 }}>
              {Object.keys(SPORT_LABELS).map((sport) => (
                <Grid size={{ xs: 4, sm: 2 }} key={sport}>
                  <TextField
                    label={SPORT_LABELS[sport]}
                    type="number"
                    size="small"
                    fullWidth
                    value={advStructure[sport] || 0}
                    onChange={(e) =>
                      setAdvStructure((prev) => ({ ...prev, [sport]: Math.max(0, Number(e.target.value)) }))
                    }
                    slotProps={{ htmlInput: { min: 0, max: 7 } }}
                  />
                </Grid>
              ))}
              <Grid size={{ xs: 12, sm: 2 }}>
                <Typography
                  variant="body2"
                  color={advTotal === 7 ? 'success.main' : 'error.main'}
                  fontWeight={600}
                >
                  Total: {advTotal}/7
                </Typography>
              </Grid>
            </Grid>
          </Collapse>
        </CardContent>
      </Card>

      {/* Action Bar */}
      <Box sx={{ display: 'flex', gap: 1.5, alignItems: 'center', flexWrap: 'wrap', mb: 2 }}>
        <Button
          variant="contained"
          startIcon={isOptimizing ? <CircularProgress size={18} color="inherit" /> : <CalendarMonthIcon />}
          onClick={handleGenerate}
          disabled={isOptimizing || (showAdvanced && advTotal !== 7)}
        >
          {isOptimizing ? 'Generating...' : 'Generate Weekly Plan'}
        </Button>
        <Chip
          icon={<TuneIcon />}
          label={`Preferences${excludedFoods.length + foodLocks.length > 0 ? ` (${excludedFoods.length + foodLocks.length})` : ''}`}
          variant="outlined"
          onClick={() => setDrawerOpen(true)}
          sx={{ cursor: 'pointer' }}
        />
      </Box>

      {/* Progress */}
      {isOptimizing && progress > 0 && (
        <Box sx={{ mb: 2 }}>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 0.5 }}>
            Generating Day {progress} of 7...
          </Typography>
          <LinearProgress variant="determinate" value={(progress / 7) * 100} sx={{ height: 6, borderRadius: 3 }} />
        </Box>
      )}

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      {weekPlan && (
        <Fade in timeout={400}>
          <Box>
            {/* Week Overview */}
            <WeekOverviewDashboard
              weekPlan={weekPlan}
              activeDay={activeDay}
              onSelectDay={setActiveDay}
              profile={profile}
            />

            {/* Amino Heatmap */}
            <WeeklyAminoHeatmap weekPlan={weekPlan} profile={profile} />

            {/* Day Detail */}
            {activePlan ? (
              <Card sx={{ mt: 2 }}>
                <CardContent>
                  <Typography variant="h6" gutterBottom>
                    Day {activeDay + 1} — {weekPlan.dayTypes[activeDay].charAt(0).toUpperCase() + weekPlan.dayTypes[activeDay].slice(1)}
                  </Typography>

                  <Tabs
                    value={dayDetailTab}
                    onChange={(_, v) => setDayDetailTab(v)}
                    sx={{ mb: 2, borderBottom: 1, borderColor: 'divider' }}
                  >
                    <Tab label="Meals" sx={{ textTransform: 'none' }} />
                    <Tab label="Nutrition" sx={{ textTransform: 'none' }} />
                  </Tabs>

                  {dayDetailTab === 0 && (
                    <DayPlanView items={activePlan.items} />
                  )}

                  {dayDetailTab === 1 && (
                    <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                      {macroComps && <MacroComparisonView comparisons={macroComps} />}
                      {aminoComps && <AminoComparisonView comparisons={aminoComps} />}
                      <Box sx={{ flex: 1, minWidth: 300 }}>
                        {aminoComps && <AminoRadarChart comparisons={aminoComps} />}
                      </Box>
                    </Box>
                  )}
                </CardContent>
              </Card>
            ) : (
              <Alert severity="warning" sx={{ mt: 2 }}>No plan could be generated for Day {activeDay + 1}.</Alert>
            )}
          </Box>
        </Fade>
      )}

      <FoodPreferencesDrawer open={drawerOpen} onClose={() => setDrawerOpen(false)} showWeeklyVariety />
    </Box>
  );
}

import { useState } from 'react';
import {
  Box, Typography, Button, CircularProgress, Alert, Grid,
  TextField, Card, CardContent, Tabs, Tab,
} from '@mui/material';
import CalendarMonthIcon from '@mui/icons-material/CalendarMonth';
import DayPlanView from '../components/planner/DayPlanView';
import { useProfileStore } from '../store/useProfileStore';
import { usePlanStore } from '../store/usePlanStore';
import { planWeek } from '../engine/weekly';
import type { WeekStructure } from '../data/types';

const SPORT_LABELS: Record<string, string> = {
  trail: 'Trail', kayak: 'Kayak', climbing: 'Climbing', swimming: 'Swimming', rest: 'Rest',
};

export default function WeeklyPlannerPage() {
  const { profile } = useProfileStore();
  const { weekPlan, isOptimizing, error, setWeekPlan, setOptimizing, setError } = usePlanStore();

  const [structure, setStructure] = useState<WeekStructure>({ trail: 3, kayak: 2, rest: 2 });
  const [activeDay, setActiveDay] = useState(0);

  const total = Object.values(structure).reduce((a, b) => a + b, 0);

  const handleGenerate = async () => {
    if (total !== 7) {
      setError('Days must sum to 7');
      return;
    }
    setOptimizing(true);
    setError(null);
    try {
      const week = await planWeek(structure, profile);
      setWeekPlan(week);
      setActiveDay(0);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Weekly planning failed');
    }
    setOptimizing(false);
  };

  const updateSport = (sport: string, value: number) => {
    setStructure(prev => ({ ...prev, [sport]: Math.max(0, value) }));
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>Weekly Meal Planner</Typography>

      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>Week Structure</Typography>
          <Grid container spacing={2} alignItems="center">
            {Object.keys(SPORT_LABELS).map(sport => (
              <Grid size={{ xs: 4, sm: 2 }} key={sport}>
                <TextField
                  label={SPORT_LABELS[sport]}
                  type="number"
                  size="small"
                  fullWidth
                  value={structure[sport] || 0}
                  onChange={e => updateSport(sport, Number(e.target.value))}
                  slotProps={{ htmlInput: { min: 0, max: 7 } }}
                />
              </Grid>
            ))}
            <Grid size={{ xs: 12, sm: 2 }}>
              <Typography variant="body2" color={total === 7 ? 'success.main' : 'error.main'} fontWeight={600}>
                Total: {total}/7
              </Typography>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      <Button
        variant="contained"
        startIcon={isOptimizing ? <CircularProgress size={18} color="inherit" /> : <CalendarMonthIcon />}
        onClick={handleGenerate}
        disabled={isOptimizing || total !== 7}
        sx={{ mb: 2 }}
      >
        {isOptimizing ? 'Generating Week...' : 'Generate Weekly Plan'}
      </Button>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      {weekPlan && (
        <Box>
          <Tabs
            value={activeDay}
            onChange={(_, v) => setActiveDay(v)}
            variant="scrollable"
            scrollButtons="auto"
            sx={{ mb: 2 }}
          >
            {weekPlan.dayTypes.map((dt, i) => (
              <Tab
                key={i}
                label={`Day ${i + 1} (${dt})`}
                sx={{ textTransform: 'capitalize' }}
              />
            ))}
          </Tabs>

          {weekPlan.plans[activeDay] ? (
            <DayPlanView items={weekPlan.plans[activeDay]!.items} />
          ) : (
            <Alert severity="warning">No plan could be generated for this day.</Alert>
          )}
        </Box>
      )}
    </Box>
  );
}

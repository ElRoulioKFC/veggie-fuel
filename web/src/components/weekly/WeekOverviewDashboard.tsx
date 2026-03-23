import { Box, Card, CardActionArea, CardContent, Typography, Chip } from '@mui/material';
import DirectionsRunIcon from '@mui/icons-material/DirectionsRun';
import KayakingIcon from '@mui/icons-material/Kayaking';
import HikingIcon from '@mui/icons-material/Hiking';
import PoolIcon from '@mui/icons-material/Pool';
import WeekendIcon from '@mui/icons-material/Weekend';
import type { WeekPlan, AthleteProfile } from '../../data/types';
import { calculatePlanNutrition, summarizePlan } from '../../engine/nutrition';

const SPORT_ICONS: Record<string, React.ReactNode> = {
  trail: <DirectionsRunIcon fontSize="small" />,
  kayak: <KayakingIcon fontSize="small" />,
  climbing: <HikingIcon fontSize="small" />,
  swimming: <PoolIcon fontSize="small" />,
  rest: <WeekendIcon fontSize="small" />,
};

interface Props {
  weekPlan: WeekPlan;
  activeDay: number;
  onSelectDay: (day: number) => void;
  profile: AthleteProfile;
}

interface DaySummary {
  kcal: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
}

function computeDaySummary(weekPlan: WeekPlan): (DaySummary | null)[] {
  return weekPlan.plans.map((plan) => {
    if (!plan) return null;
    const nutrition = calculatePlanNutrition(plan.items);
    const totals = summarizePlan(nutrition);
    return {
      kcal: Math.round(totals.kcal),
      proteinG: Math.round(totals.proteinG),
      carbsG: Math.round(totals.carbsG),
      fatG: Math.round(totals.fatG),
    };
  });
}

export default function WeekOverviewDashboard({ weekPlan, activeDay, onSelectDay }: Props) {
  const summaries = computeDaySummary(weekPlan);

  // Weekly averages
  const validSummaries = summaries.filter((s): s is DaySummary => s !== null);
  const avg = validSummaries.length > 0 ? {
    kcal: Math.round(validSummaries.reduce((a, s) => a + s.kcal, 0) / validSummaries.length),
    proteinG: Math.round(validSummaries.reduce((a, s) => a + s.proteinG, 0) / validSummaries.length),
    carbsG: Math.round(validSummaries.reduce((a, s) => a + s.carbsG, 0) / validSummaries.length),
    fatG: Math.round(validSummaries.reduce((a, s) => a + s.fatG, 0) / validSummaries.length),
  } : null;

  return (
    <Box sx={{ mb: 3 }}>
      {/* Day cards */}
      <Box
        sx={{
          display: 'flex',
          gap: 1.5,
          overflowX: 'auto',
          pb: 1,
          scrollSnapType: 'x mandatory',
          '&::-webkit-scrollbar': { height: 6 },
          '&::-webkit-scrollbar-thumb': { bgcolor: 'action.disabled', borderRadius: 3 },
        }}
      >
        {weekPlan.dayTypes.map((dt, i) => {
          const summary = summaries[i];
          const isActive = i === activeDay;
          return (
            <Card
              key={i}
              variant={isActive ? 'elevation' : 'outlined'}
              sx={{
                minWidth: 130,
                flexShrink: 0,
                scrollSnapAlign: 'start',
                border: isActive ? 2 : 1,
                borderColor: isActive ? 'primary.main' : 'divider',
                transition: 'border-color 0.2s, box-shadow 0.2s',
              }}
            >
              <CardActionArea onClick={() => onSelectDay(i)}>
                <CardContent sx={{ py: 1.5, px: 2, '&:last-child': { pb: 1.5 } }}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mb: 0.5 }}>
                    {SPORT_ICONS[dt]}
                    <Typography variant="caption" fontWeight={600}>
                      Day {i + 1}
                    </Typography>
                  </Box>
                  <Typography variant="body2" sx={{ textTransform: 'capitalize', mb: 0.5 }}>
                    {dt}
                  </Typography>
                  {summary ? (
                    <>
                      <Typography variant="h6" sx={{ fontSize: '1rem', fontWeight: 700 }}>
                        {summary.kcal} kcal
                      </Typography>
                      {/* Mini macro bar */}
                      <Box sx={{ display: 'flex', height: 6, borderRadius: 3, overflow: 'hidden', mt: 0.5 }}>
                        <Box sx={{ flex: summary.proteinG * 4, bgcolor: '#4caf50' }} />
                        <Box sx={{ flex: summary.carbsG * 4, bgcolor: '#ff9800' }} />
                        <Box sx={{ flex: summary.fatG * 9, bgcolor: '#e91e63' }} />
                      </Box>
                    </>
                  ) : (
                    <Typography variant="caption" color="text.secondary">No plan</Typography>
                  )}
                </CardContent>
              </CardActionArea>
            </Card>
          );
        })}
      </Box>

      {/* Weekly averages */}
      {avg && (
        <Box sx={{ display: 'flex', gap: 1, mt: 2, flexWrap: 'wrap', alignItems: 'center' }}>
          <Typography variant="body2" fontWeight={600} color="text.secondary">
            Weekly Avg:
          </Typography>
          <Chip label={`${avg.kcal} kcal`} size="small" variant="outlined" />
          <Chip label={`P ${avg.proteinG}g`} size="small" sx={{ bgcolor: '#e8f5e9' }} />
          <Chip label={`C ${avg.carbsG}g`} size="small" sx={{ bgcolor: '#fff3e0' }} />
          <Chip label={`F ${avg.fatG}g`} size="small" sx={{ bgcolor: '#fce4ec' }} />
        </Box>
      )}
    </Box>
  );
}

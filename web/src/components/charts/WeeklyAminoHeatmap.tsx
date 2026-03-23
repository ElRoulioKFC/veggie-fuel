import { Box, Typography, Tooltip } from '@mui/material';
import type { WeekPlan, AthleteProfile, AminoComparison } from '../../data/types';
import { calculatePlanNutrition, summarizePlan, compareAminos } from '../../engine/nutrition';
import { computeAminoTargets } from '../../engine/targets';

interface Props {
  weekPlan: WeekPlan;
  profile: AthleteProfile;
}

const AMINO_LABELS: Record<string, string> = {
  leucine: 'Leu',
  isoleucine: 'Ile',
  valine: 'Val',
  lysine: 'Lys',
  methionine: 'Met',
  threonine: 'Thr',
  tryptophan: 'Trp',
  phenylalanine: 'Phe',
  histidine: 'His',
};

function cellColor(pct: number): string {
  if (pct >= 100) return '#c8e6c9';
  if (pct >= 80) return '#fff9c4';
  return '#ffcdd2';
}

function textColor(pct: number): string {
  if (pct >= 100) return '#2e7d32';
  if (pct >= 80) return '#f57f17';
  return '#c62828';
}

export default function WeeklyAminoHeatmap({ weekPlan, profile }: Props) {
  const aminoTargets = computeAminoTargets(profile);

  const dayComparisons: (AminoComparison[] | null)[] = weekPlan.plans.map((plan) => {
    if (!plan) return null;
    const nutrition = calculatePlanNutrition(plan.items);
    const totals = summarizePlan(nutrition);
    return compareAminos(totals, aminoTargets);
  });

  const aminoNames = dayComparisons.find((d) => d !== null)?.map((a) => a.aminoAcid) ?? [];

  return (
    <Box sx={{ mb: 3 }}>
      <Typography variant="h6" gutterBottom>Amino Acid Coverage</Typography>
      <Box
        sx={{
          display: 'grid',
          gridTemplateColumns: `100px repeat(7, 1fr)`,
          gap: 0.5,
          overflowX: 'auto',
        }}
      >
        {/* Header row */}
        <Box />
        {weekPlan.dayTypes.map((dt, i) => (
          <Box key={i} sx={{ textAlign: 'center', py: 0.5 }}>
            <Typography variant="caption" fontWeight={600}>
              D{i + 1}
            </Typography>
            <Typography variant="caption" display="block" color="text.secondary" sx={{ textTransform: 'capitalize', fontSize: '0.65rem' }}>
              {dt}
            </Typography>
          </Box>
        ))}

        {/* Amino rows */}
        {aminoNames.map((amino, aIdx) => (
          <Box key={amino} sx={{ display: 'contents' }}>
            <Box sx={{ display: 'flex', alignItems: 'center', pr: 1 }}>
              <Typography variant="caption" fontWeight={500}>
                {AMINO_LABELS[amino] || amino}
              </Typography>
            </Box>
            {dayComparisons.map((comps, dIdx) => {
              const comp = comps?.[aIdx];
              if (!comp) {
                return (
                  <Box
                    key={dIdx}
                    sx={{
                      bgcolor: 'action.disabledBackground',
                      borderRadius: 1,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      minHeight: 32,
                    }}
                  >
                    <Typography variant="caption" color="text.disabled">-</Typography>
                  </Box>
                );
              }
              return (
                <Tooltip
                  key={dIdx}
                  title={`${amino}: ${comp.actualMg}mg / ${comp.dailyMinMg}mg (${comp.pct}%)`}
                  arrow
                >
                  <Box
                    sx={{
                      bgcolor: cellColor(comp.pct),
                      color: textColor(comp.pct),
                      borderRadius: 1,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      minHeight: 32,
                      fontWeight: 600,
                      fontSize: '0.75rem',
                      cursor: 'default',
                      transition: 'transform 0.15s',
                      '&:hover': { transform: 'scale(1.05)' },
                    }}
                  >
                    {comp.pct}%
                  </Box>
                </Tooltip>
              );
            })}
          </Box>
        ))}
      </Box>
    </Box>
  );
}

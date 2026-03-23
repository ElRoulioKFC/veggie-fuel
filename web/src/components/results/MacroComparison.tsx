import { Card, CardContent, Typography, Box, LinearProgress, Chip } from '@mui/material';
import type { MacroComparison as MacroComp } from '../../data/types';

const statusColor = (status: string) =>
  status === 'OK' ? 'success' : status === 'LOW' ? 'warning' : 'error';

const LABELS: Record<string, string> = {
  'kcal': 'Calories',
  'protein_g': 'Protein',
  'carbs_g': 'Carbs',
  'fat_g': 'Fat',
  'fiber_g': 'Fiber',
};

interface Props {
  comparisons: MacroComp[];
}

export default function MacroComparison({ comparisons }: Props) {
  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>Macro Targets vs Actual</Typography>
        {comparisons.map(c => (
          <Box key={c.nutrient} sx={{ mb: 1.5 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 0.5 }}>
              <Typography variant="body2" fontWeight={500}>
                {LABELS[c.nutrient] || c.nutrient}
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Typography variant="body2" color="text.secondary">
                  {c.actual} / {c.target} {c.nutrient === 'kcal' ? 'kcal' : 'g'}
                </Typography>
                <Chip label={`${c.pct}%`} size="small" color={statusColor(c.status)} />
              </Box>
            </Box>
            <LinearProgress
              variant="determinate"
              value={Math.min(c.pct, 100)}
              color={statusColor(c.status)}
              sx={{ height: 8, borderRadius: 4 }}
            />
          </Box>
        ))}
      </CardContent>
    </Card>
  );
}

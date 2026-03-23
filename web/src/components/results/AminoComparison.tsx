import { Card, CardContent, Typography, Box, LinearProgress, Chip } from '@mui/material';
import type { AminoComparison as AminoComp } from '../../data/types';

const statusColor = (status: string) =>
  status === 'OK' ? 'success' : status === 'LOW' ? 'warning' : 'error';

interface Props {
  comparisons: AminoComp[];
}

export default function AminoComparison({ comparisons }: Props) {
  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>Amino Acid Coverage</Typography>
        {comparisons.map(c => (
          <Box key={c.aminoAcid} sx={{ mb: 1 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 0.3 }}>
              <Typography variant="body2" fontWeight={500} sx={{ textTransform: 'capitalize' }}>
                {c.aminoAcid}
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Typography variant="caption" color="text.secondary">
                  {c.actualMg} / {c.dailyMinMg} mg
                </Typography>
                <Chip label={`${c.pct}%`} size="small" color={statusColor(c.status)} />
              </Box>
            </Box>
            <LinearProgress
              variant="determinate"
              value={Math.min(c.pct, 100)}
              color={statusColor(c.status)}
              sx={{ height: 6, borderRadius: 3 }}
            />
          </Box>
        ))}
      </CardContent>
    </Card>
  );
}

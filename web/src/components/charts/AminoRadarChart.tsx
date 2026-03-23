import { Card, CardContent, Typography } from '@mui/material';
import { RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, Radar, ResponsiveContainer, Tooltip } from 'recharts';
import type { AminoComparison } from '../../data/types';

interface Props {
  comparisons: AminoComparison[];
  title?: string;
}

export default function AminoRadarChart({ comparisons, title = 'Amino Acid Coverage' }: Props) {
  const data = comparisons.map(c => ({
    name: c.aminoAcid.charAt(0).toUpperCase() + c.aminoAcid.slice(1),
    pct: c.pct,
    fullMark: 150,
  }));

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>{title}</Typography>
        <ResponsiveContainer width="100%" height={300}>
          <RadarChart data={data}>
            <PolarGrid />
            <PolarAngleAxis dataKey="name" tick={{ fontSize: 11 }} />
            <PolarRadiusAxis angle={30} domain={[0, 150]} tick={{ fontSize: 10 }} />
            <Radar
              name="Coverage %"
              dataKey="pct"
              stroke="#2e7d32"
              fill="#2e7d32"
              fillOpacity={0.3}
            />
            <Tooltip formatter={(val) => `${val}%`} />
          </RadarChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}

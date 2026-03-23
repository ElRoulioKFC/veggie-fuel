import { Card, CardContent, Typography } from '@mui/material';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import type { MealNutrition } from '../../data/types';

interface Props {
  meals: MealNutrition[];
  title?: string;
}

export default function MealMacroBarChart({ meals, title = 'Macros by Meal' }: Props) {
  const data = meals.map(m => ({
    name: m.meal,
    Protein: m.proteinG,
    Carbs: m.carbsG,
    Fat: m.fatG,
  }));

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>{title}</Typography>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" tick={{ fontSize: 11 }} />
            <YAxis label={{ value: 'grams', angle: -90, position: 'insideLeft', style: { fontSize: 11 } }} />
            <Tooltip />
            <Legend />
            <Bar dataKey="Protein" stackId="a" fill="#4caf50" />
            <Bar dataKey="Carbs" stackId="a" fill="#ff9800" />
            <Bar dataKey="Fat" stackId="a" fill="#e91e63" />
          </BarChart>
        </ResponsiveContainer>
      </CardContent>
    </Card>
  );
}

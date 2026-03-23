import { Card, CardContent, Typography, Table, TableBody, TableRow, TableCell, Chip, Box } from '@mui/material';
import type { MealSlot } from '../../data/types';
import type { PlanNutritionItem } from '../../engine/nutrition';

interface Props {
  meal: MealSlot;
  items: PlanNutritionItem[];
}

export default function MealCard({ meal, items }: Props) {
  const totalKcal = Math.round(items.reduce((s, i) => s + i.kcal, 0));
  const totalProtein = Math.round(items.reduce((s, i) => s + i.proteinG, 0) * 10) / 10;
  const totalCarbs = Math.round(items.reduce((s, i) => s + i.carbsG, 0) * 10) / 10;
  const totalFat = Math.round(items.reduce((s, i) => s + i.fatG, 0) * 10) / 10;

  return (
    <Card variant="outlined" sx={{ mb: 1.5 }}>
      <CardContent sx={{ py: 1.5, '&:last-child': { pb: 1.5 } }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
          <Typography variant="subtitle1" fontWeight={600}>{meal}</Typography>
          <Box sx={{ display: 'flex', gap: 0.5 }}>
            <Chip label={`${totalKcal} kcal`} size="small" color="primary" variant="outlined" />
            <Chip label={`P ${totalProtein}g`} size="small" sx={{ bgcolor: '#e8f5e9' }} />
            <Chip label={`C ${totalCarbs}g`} size="small" sx={{ bgcolor: '#fff3e0' }} />
            <Chip label={`F ${totalFat}g`} size="small" sx={{ bgcolor: '#fce4ec' }} />
          </Box>
        </Box>
        <Table size="small">
          <TableBody>
            {items.map((item, idx) => (
              <TableRow key={idx} sx={{ '&:last-child td': { borderBottom: 0 } }}>
                <TableCell sx={{ py: 0.5 }}>{item.food}</TableCell>
                <TableCell align="right" sx={{ py: 0.5, whiteSpace: 'nowrap' }}>{item.grams}g</TableCell>
                <TableCell align="right" sx={{ py: 0.5, whiteSpace: 'nowrap', color: 'text.secondary' }}>
                  {Math.round(item.kcal)} kcal
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  );
}

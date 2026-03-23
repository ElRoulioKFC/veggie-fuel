import {
  Card, CardContent, CardActionArea, Typography, Chip, Box, Stack,
} from '@mui/material';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import type { Recipe } from '../../data/types';
import { calculatePerServing } from '../../engine/recipes';

interface RecipeCardProps {
  recipe: Recipe;
  onClick: () => void;
}

export default function RecipeCard({ recipe, onClick }: RecipeCardProps) {
  const perServing = calculatePerServing(recipe);
  const totalTime = recipe.prepMinutes + recipe.cookMinutes;

  return (
    <Card>
      <CardActionArea onClick={onClick}>
        <CardContent>
          <Typography variant="h6" gutterBottom>{recipe.name}</Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 1.5 }}>
            {recipe.description}
          </Typography>

          <Stack direction="row" spacing={0.5} sx={{ mb: 1.5, flexWrap: 'wrap', gap: 0.5 }}>
            {recipe.mealTypes.map(mt => (
              <Chip key={mt} label={mt} size="small" color="primary" variant="outlined" />
            ))}
          </Stack>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mb: 1 }}>
            <AccessTimeIcon fontSize="small" color="action" />
            <Typography variant="body2" color="text.secondary">
              {totalTime} min · {recipe.servings} serving{recipe.servings > 1 ? 's' : ''}
            </Typography>
          </Box>

          <Stack direction="row" spacing={1}>
            <Chip label={`${Math.round(perServing.kcal)} kcal`} size="small" />
            <Chip label={`${Math.round(perServing.proteinG)}g protein`} size="small" />
            <Chip label={`${Math.round(perServing.carbsG)}g carbs`} size="small" />
            <Chip label={`${Math.round(perServing.fatG)}g fat`} size="small" />
          </Stack>
        </CardContent>
      </CardActionArea>
    </Card>
  );
}

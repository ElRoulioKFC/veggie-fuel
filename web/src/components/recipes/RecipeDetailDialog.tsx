import {
  Dialog, DialogTitle, DialogContent, IconButton, Typography, Chip, Box,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper,
  Stack, Divider,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import AccessTimeIcon from '@mui/icons-material/AccessTime';
import type { Recipe } from '../../data/types';
import { calculateRecipeNutrition, calculatePerServing } from '../../engine/recipes';
import { foods as foodDb } from '../../data/foods';

interface RecipeDetailDialogProps {
  recipe: Recipe | null;
  open: boolean;
  onClose: () => void;
}

export default function RecipeDetailDialog({ recipe, open, onClose }: RecipeDetailDialogProps) {
  if (!recipe) return null;

  const totalNutrition = calculateRecipeNutrition(recipe);
  const perServing = calculatePerServing(recipe);
  const totalTime = recipe.prepMinutes + recipe.cookMinutes;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <Typography variant="h5" component="span">{recipe.name}</Typography>
        <IconButton onClick={onClose} size="small"><CloseIcon /></IconButton>
      </DialogTitle>
      <DialogContent dividers>
        <Typography variant="body1" color="text.secondary" sx={{ mb: 2 }}>
          {recipe.description}
        </Typography>

        <Stack direction="row" spacing={1} sx={{ mb: 2, flexWrap: 'wrap', gap: 0.5 }}>
          {recipe.mealTypes.map(mt => (
            <Chip key={mt} label={mt} color="primary" variant="outlined" />
          ))}
          {recipe.tags.map(tag => (
            <Chip key={tag} label={tag} size="small" />
          ))}
        </Stack>

        <Box sx={{ display: 'flex', gap: 3, mb: 3 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
            <AccessTimeIcon fontSize="small" />
            <Typography variant="body2">Prep: {recipe.prepMinutes} min</Typography>
          </Box>
          {recipe.cookMinutes > 0 && (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              <AccessTimeIcon fontSize="small" />
              <Typography variant="body2">Cook: {recipe.cookMinutes} min</Typography>
            </Box>
          )}
          <Typography variant="body2">Total: {totalTime} min</Typography>
          <Typography variant="body2">Servings: {recipe.servings}</Typography>
        </Box>

        <Typography variant="h6" gutterBottom>Ingredients</Typography>
        <TableContainer component={Paper} variant="outlined" sx={{ mb: 3 }}>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Food</TableCell>
                <TableCell align="right">Grams</TableCell>
                <TableCell align="right">kcal</TableCell>
                <TableCell align="right">Protein (g)</TableCell>
                <TableCell align="right">Carbs (g)</TableCell>
                <TableCell align="right">Fat (g)</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {recipe.ingredients.map(ing => {
                const food = foodDb.find(f => f.food === ing.food);
                const scale = ing.grams / 100;
                return (
                  <TableRow key={ing.food}>
                    <TableCell>{ing.food}</TableCell>
                    <TableCell align="right">{ing.grams}</TableCell>
                    <TableCell align="right">{food ? Math.round(food.kcal * scale) : '—'}</TableCell>
                    <TableCell align="right">{food ? Math.round(food.proteinG * scale * 10) / 10 : '—'}</TableCell>
                    <TableCell align="right">{food ? Math.round(food.carbsG * scale * 10) / 10 : '—'}</TableCell>
                    <TableCell align="right">{food ? Math.round(food.fatG * scale * 10) / 10 : '—'}</TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </TableContainer>

        <Divider sx={{ mb: 2 }} />

        <Typography variant="h6" gutterBottom>Instructions</Typography>
        <Box component="ol" sx={{ pl: 2.5, mb: 3 }}>
          {recipe.steps.map((step, i) => (
            <Typography component="li" variant="body2" key={i} sx={{ mb: 1 }}>
              {step}
            </Typography>
          ))}
        </Box>

        <Divider sx={{ mb: 2 }} />

        <Typography variant="h6" gutterBottom>Nutrition Summary</Typography>
        <TableContainer component={Paper} variant="outlined">
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell />
                <TableCell align="right">kcal</TableCell>
                <TableCell align="right">Protein (g)</TableCell>
                <TableCell align="right">Carbs (g)</TableCell>
                <TableCell align="right">Fat (g)</TableCell>
                <TableCell align="right">Fiber (g)</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              <TableRow>
                <TableCell>Total recipe</TableCell>
                <TableCell align="right">{Math.round(totalNutrition.kcal)}</TableCell>
                <TableCell align="right">{Math.round(totalNutrition.proteinG * 10) / 10}</TableCell>
                <TableCell align="right">{Math.round(totalNutrition.carbsG * 10) / 10}</TableCell>
                <TableCell align="right">{Math.round(totalNutrition.fatG * 10) / 10}</TableCell>
                <TableCell align="right">{Math.round(totalNutrition.fiberG * 10) / 10}</TableCell>
              </TableRow>
              <TableRow>
                <TableCell>Per serving</TableCell>
                <TableCell align="right">{Math.round(perServing.kcal)}</TableCell>
                <TableCell align="right">{Math.round(perServing.proteinG * 10) / 10}</TableCell>
                <TableCell align="right">{Math.round(perServing.carbsG * 10) / 10}</TableCell>
                <TableCell align="right">{Math.round(perServing.fatG * 10) / 10}</TableCell>
                <TableCell align="right">{Math.round(perServing.fiberG * 10) / 10}</TableCell>
              </TableRow>
            </TableBody>
          </Table>
        </TableContainer>
      </DialogContent>
    </Dialog>
  );
}

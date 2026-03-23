import { useState } from 'react';
import {
  Box, Typography, Card, CardContent, CardActionArea, Chip, Stack, Alert,
} from '@mui/material';
import type { DayPlan, Recipe } from '../../data/types';
import { MEAL_SLOTS } from '../../data/types';
import { recipes } from '../../data/recipes';
import { matchRecipesToPlan } from '../../engine/recipes';
import RecipeDetailDialog from './RecipeDetailDialog';

interface RecipeSuggestionsProps {
  plan: DayPlan;
}

export default function RecipeSuggestions({ plan }: RecipeSuggestionsProps) {
  const [selectedRecipe, setSelectedRecipe] = useState<Recipe | null>(null);
  const matches = matchRecipesToPlan(plan, recipes);

  const hasAny = MEAL_SLOTS.some(slot => (matches.get(slot)?.length ?? 0) > 0);

  if (!hasAny) return null;

  return (
    <Box sx={{ mt: 3 }}>
      <Typography variant="h5" gutterBottom>Recipe Suggestions</Typography>
      <Alert severity="info" sx={{ mb: 2 }}>
        Based on the foods in your meal plan, here are recipes you can make.
      </Alert>

      {MEAL_SLOTS.map(slot => {
        const slotMatches = matches.get(slot) ?? [];
        if (slotMatches.length === 0) return null;

        return (
          <Box key={slot} sx={{ mb: 2 }}>
            <Typography variant="h6" sx={{ mb: 1 }}>{slot}</Typography>
            <Stack direction="row" spacing={2} sx={{ overflowX: 'auto', pb: 1 }}>
              {slotMatches.map(match => (
                <Card key={match.recipe.id} sx={{ minWidth: 260, maxWidth: 300, flexShrink: 0 }}>
                  <CardActionArea onClick={() => setSelectedRecipe(match.recipe)}>
                    <CardContent>
                      <Typography variant="subtitle1" gutterBottom>
                        {match.recipe.name}
                      </Typography>
                      <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                        {Math.round(match.overlapScore * 100)}% ingredient match
                      </Typography>
                      <Stack direction="row" spacing={0.5} sx={{ flexWrap: 'wrap', gap: 0.5 }}>
                        {match.matchedFoods.map(f => (
                          <Chip key={f} label={f} size="small" color="success" variant="outlined" />
                        ))}
                        {match.missingFoods.map(f => (
                          <Chip key={f} label={f} size="small" color="default" variant="outlined" />
                        ))}
                      </Stack>
                    </CardContent>
                  </CardActionArea>
                </Card>
              ))}
            </Stack>
          </Box>
        );
      })}

      <RecipeDetailDialog
        recipe={selectedRecipe}
        open={selectedRecipe !== null}
        onClose={() => setSelectedRecipe(null)}
      />
    </Box>
  );
}

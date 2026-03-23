import { useState } from 'react';
import {
  Box, Typography, TextField, FormControl, InputLabel, Select, MenuItem,
  Chip, Stack, Grid,
} from '@mui/material';
import type { Recipe, MealSlot } from '../data/types';
import { MEAL_SLOTS } from '../data/types';
import { recipes } from '../data/recipes';
import RecipeCard from '../components/recipes/RecipeCard';
import RecipeDetailDialog from '../components/recipes/RecipeDetailDialog';

const ALL_TAGS = [...new Set(recipes.flatMap(r => r.tags))].sort();

export default function RecipesPage() {
  const [search, setSearch] = useState('');
  const [mealFilter, setMealFilter] = useState<MealSlot | 'all'>('all');
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [selectedRecipe, setSelectedRecipe] = useState<Recipe | null>(null);

  const filtered = recipes.filter(r => {
    if (search && !r.name.toLowerCase().includes(search.toLowerCase()) &&
        !r.description.toLowerCase().includes(search.toLowerCase())) return false;
    if (mealFilter !== 'all' && !r.mealTypes.includes(mealFilter)) return false;
    if (selectedTags.length > 0 && !selectedTags.some(t => r.tags.includes(t))) return false;
    return true;
  });

  const toggleTag = (tag: string) => {
    setSelectedTags(prev =>
      prev.includes(tag) ? prev.filter(t => t !== tag) : [...prev, tag]
    );
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>Recipe Cookbook</Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        {recipes.length} recipes using foods from the database. Click any recipe for full details.
      </Typography>

      <Box sx={{ display: 'flex', gap: 2, mb: 2, flexWrap: 'wrap' }}>
        <TextField
          size="small"
          label="Search recipes"
          value={search}
          onChange={e => setSearch(e.target.value)}
          sx={{ minWidth: 200 }}
        />
        <FormControl size="small" sx={{ minWidth: 150 }}>
          <InputLabel>Meal Type</InputLabel>
          <Select
            value={mealFilter}
            label="Meal Type"
            onChange={e => setMealFilter(e.target.value as MealSlot | 'all')}
          >
            <MenuItem value="all">All</MenuItem>
            {MEAL_SLOTS.map(s => (
              <MenuItem key={s} value={s}>{s}</MenuItem>
            ))}
          </Select>
        </FormControl>
      </Box>

      <Stack direction="row" spacing={0.5} sx={{ mb: 3, flexWrap: 'wrap', gap: 0.5 }}>
        {ALL_TAGS.map(tag => (
          <Chip
            key={tag}
            label={tag}
            size="small"
            color={selectedTags.includes(tag) ? 'primary' : 'default'}
            onClick={() => toggleTag(tag)}
          />
        ))}
      </Stack>

      <Grid container spacing={2}>
        {filtered.map(recipe => (
          <Grid size={{ xs: 12, sm: 6, md: 4 }} key={recipe.id}>
            <RecipeCard recipe={recipe} onClick={() => setSelectedRecipe(recipe)} />
          </Grid>
        ))}
      </Grid>

      {filtered.length === 0 && (
        <Typography variant="body1" color="text.secondary" sx={{ mt: 2 }}>
          No recipes match your filters.
        </Typography>
      )}

      <RecipeDetailDialog
        recipe={selectedRecipe}
        open={selectedRecipe !== null}
        onClose={() => setSelectedRecipe(null)}
      />
    </Box>
  );
}

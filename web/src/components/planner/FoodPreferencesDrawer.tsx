import { useState } from 'react';
import {
  Drawer, Box, Typography, IconButton, Autocomplete, TextField, Chip, Button,
  FormControl, InputLabel, Select, MenuItem, Slider, Divider,
  useMediaQuery, useTheme, List, ListItem, ListItemText, ListItemSecondaryAction,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import DeleteIcon from '@mui/icons-material/Delete';
import AddIcon from '@mui/icons-material/Add';
import { foods } from '../../data/foods';
import { MEAL_SLOTS } from '../../data/types';
import type { MealSlot } from '../../data/types';
import { usePlanSettingsStore } from '../../store/usePlanSettingsStore';

interface Props {
  open: boolean;
  onClose: () => void;
  showWeeklyVariety?: boolean;
}

const foodOptions = foods.map((f) => ({ label: f.food, category: f.category }));

export default function FoodPreferencesDrawer({ open, onClose, showWeeklyVariety = false }: Props) {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const {
    excludedFoods, foodLocks, maxFoodAppearances,
    addExclusion, removeExclusion,
    addLock, removeLock,
    setMaxFoodAppearances,
  } = usePlanSettingsStore();

  const [lockFood, setLockFood] = useState<string>('');
  const [lockMeal, setLockMeal] = useState<MealSlot>('Breakfast');
  const [lockGrams, setLockGrams] = useState<number>(50);

  const handleAddLock = () => {
    if (lockFood) {
      addLock({ food: lockFood, meal: lockMeal, minGrams: lockGrams });
      setLockFood('');
    }
  };

  return (
    <Drawer
      anchor={isMobile ? 'bottom' : 'right'}
      open={open}
      onClose={onClose}
      sx={{
        '& .MuiDrawer-paper': {
          width: isMobile ? '100%' : 380,
          maxHeight: isMobile ? '85vh' : '100%',
          borderRadius: isMobile ? '16px 16px 0 0' : 0,
        },
      }}
    >
      <Box sx={{ p: 2.5 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Typography variant="h6">Food Preferences</Typography>
          <IconButton onClick={onClose} size="small"><CloseIcon /></IconButton>
        </Box>

        {/* Excluded Foods */}
        <Typography variant="subtitle2" gutterBottom>Excluded Foods</Typography>
        <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 1 }}>
          These foods will never appear in generated plans.
        </Typography>
        <Autocomplete
          multiple
          size="small"
          options={foodOptions.map((f) => f.label)}
          groupBy={(option) => {
            const found = foodOptions.find((f) => f.label === option);
            return found ? found.category.replace('_', ' ') : '';
          }}
          value={excludedFoods}
          onChange={(_, newVal) => {
            // Sync with store
            const toAdd = newVal.filter((f) => !excludedFoods.includes(f));
            const toRemove = excludedFoods.filter((f) => !newVal.includes(f));
            toAdd.forEach(addExclusion);
            toRemove.forEach(removeExclusion);
          }}
          renderTags={(value, getTagProps) =>
            value.map((option, index) => {
              const { key, ...rest } = getTagProps({ index });
              return <Chip key={key} label={option} size="small" {...rest} />;
            })
          }
          renderInput={(params) => (
            <TextField {...params} placeholder="Search foods to exclude..." />
          )}
          sx={{ mb: 3 }}
        />

        <Divider sx={{ mb: 2 }} />

        {/* Food Locks */}
        <Typography variant="subtitle2" gutterBottom>Food Locks</Typography>
        <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 1 }}>
          Force a food into a specific meal with a minimum portion.
        </Typography>

        {foodLocks.length > 0 && (
          <List dense sx={{ mb: 1 }}>
            {foodLocks.map((lock) => (
              <ListItem key={`${lock.food}-${lock.meal}`} sx={{ px: 0 }}>
                <ListItemText
                  primary={lock.food}
                  secondary={`${lock.meal} — min ${lock.minGrams}g`}
                />
                <ListItemSecondaryAction>
                  <IconButton edge="end" size="small" onClick={() => removeLock(lock.food, lock.meal)}>
                    <DeleteIcon fontSize="small" />
                  </IconButton>
                </ListItemSecondaryAction>
              </ListItem>
            ))}
          </List>
        )}

        <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap', alignItems: 'flex-end', mb: 1 }}>
          <Autocomplete
            size="small"
            options={foodOptions.map((f) => f.label)}
            value={lockFood || null}
            onChange={(_, v) => setLockFood(v || '')}
            renderInput={(params) => <TextField {...params} label="Food" />}
            sx={{ flex: 2, minWidth: 140 }}
          />
          <FormControl size="small" sx={{ flex: 1, minWidth: 100 }}>
            <InputLabel>Meal</InputLabel>
            <Select value={lockMeal} label="Meal" onChange={(e) => setLockMeal(e.target.value as MealSlot)}>
              {MEAL_SLOTS.map((s) => (
                <MenuItem key={s} value={s}>{s}</MenuItem>
              ))}
            </Select>
          </FormControl>
          <TextField
            size="small"
            type="number"
            label="Min g"
            value={lockGrams}
            onChange={(e) => setLockGrams(Number(e.target.value))}
            slotProps={{ htmlInput: { min: 5, max: 300, step: 5 } }}
            sx={{ width: 80 }}
          />
          <Button
            variant="outlined"
            size="small"
            startIcon={<AddIcon />}
            onClick={handleAddLock}
            disabled={!lockFood}
            sx={{ minHeight: 40 }}
          >
            Add
          </Button>
        </Box>

        {showWeeklyVariety && (
          <>
            <Divider sx={{ my: 2 }} />
            <Typography variant="subtitle2" gutterBottom>Weekly Variety</Typography>
            <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mb: 1 }}>
              Max times a food can appear across the week. Lower = more variety.
            </Typography>
            <Box sx={{ px: 1 }}>
              <Slider
                value={maxFoodAppearances}
                onChange={(_, v) => setMaxFoodAppearances(v as number)}
                min={3}
                max={14}
                step={1}
                size="small"
                valueLabelDisplay="auto"
                marks={[
                  { value: 3, label: '3' },
                  { value: 7, label: '7' },
                  { value: 10, label: '10' },
                  { value: 14, label: '14' },
                ]}
              />
            </Box>
          </>
        )}
      </Box>
    </Drawer>
  );
}

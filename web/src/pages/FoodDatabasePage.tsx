import { useState, useMemo } from 'react';
import {
  Box, Typography, TextField, FormControl, InputLabel, Select, MenuItem,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper,
  Chip, TableSortLabel,
} from '@mui/material';
import { foods } from '../data/foods';
import type { FoodCategory } from '../data/types';

type SortKey = 'food' | 'category' | 'kcal' | 'proteinG' | 'carbsG' | 'fatG';

const CATEGORIES: (FoodCategory | 'all')[] = ['all', 'soy', 'legume', 'grain', 'dairy_egg', 'nut_seed', 'vegetable', 'fruit', 'protein', 'sport'];

export default function FoodDatabasePage() {
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState<FoodCategory | 'all'>('all');
  const [sortKey, setSortKey] = useState<SortKey>('food');
  const [sortDir, setSortDir] = useState<'asc' | 'desc'>('asc');

  const filtered = useMemo(() => {
    let result = [...foods];
    if (search) {
      const lower = search.toLowerCase();
      result = result.filter(f => f.food.toLowerCase().includes(lower));
    }
    if (category !== 'all') {
      result = result.filter(f => f.category === category);
    }
    result.sort((a, b) => {
      const va = a[sortKey];
      const vb = b[sortKey];
      const cmp = typeof va === 'string' ? va.localeCompare(vb as string) : (va as number) - (vb as number);
      return sortDir === 'asc' ? cmp : -cmp;
    });
    return result;
  }, [search, category, sortKey, sortDir]);

  const handleSort = (key: SortKey) => {
    if (sortKey === key) {
      setSortDir(d => d === 'asc' ? 'desc' : 'asc');
    } else {
      setSortKey(key);
      setSortDir(key === 'food' ? 'asc' : 'desc');
    }
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>Food Database</Typography>
      <Typography variant="body2" color="text.secondary" gutterBottom>
        {foods.length} vegetarian foods with full nutrition profiles (per 100g)
      </Typography>

      <Box sx={{ display: 'flex', gap: 2, mb: 2, flexWrap: 'wrap' }}>
        <TextField
          label="Search"
          size="small"
          value={search}
          onChange={e => setSearch(e.target.value)}
          sx={{ minWidth: 200 }}
        />
        <FormControl size="small" sx={{ minWidth: 150 }}>
          <InputLabel>Category</InputLabel>
          <Select value={category} label="Category" onChange={e => setCategory(e.target.value as FoodCategory | 'all')}>
            {CATEGORIES.map(c => (
              <MenuItem key={c} value={c}>{c === 'all' ? 'All' : c.replace('_', ' ')}</MenuItem>
            ))}
          </Select>
        </FormControl>
      </Box>

      <TableContainer component={Paper} sx={{ maxHeight: 600 }}>
        <Table stickyHeader size="small">
          <TableHead>
            <TableRow>
              {([
                ['food', 'Food'],
                ['category', 'Category'],
                ['kcal', 'Kcal'],
                ['proteinG', 'Protein (g)'],
                ['carbsG', 'Carbs (g)'],
                ['fatG', 'Fat (g)'],
              ] as [SortKey, string][]).map(([key, label]) => (
                <TableCell key={key}>
                  <TableSortLabel
                    active={sortKey === key}
                    direction={sortKey === key ? sortDir : 'asc'}
                    onClick={() => handleSort(key)}
                  >
                    {label}
                  </TableSortLabel>
                </TableCell>
              ))}
              <TableCell>Portable</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filtered.map(f => (
              <TableRow key={f.food} hover>
                <TableCell>{f.food}</TableCell>
                <TableCell>
                  <Chip label={f.category.replace('_', ' ')} size="small" variant="outlined" />
                </TableCell>
                <TableCell>{f.kcal}</TableCell>
                <TableCell>{f.proteinG}</TableCell>
                <TableCell>{f.carbsG}</TableCell>
                <TableCell>{f.fatG}</TableCell>
                <TableCell>{f.portable ? 'Yes' : ''}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
}

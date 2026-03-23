import {
  Card, CardContent, Typography, Grid, TextField, MenuItem,
  FormControl, InputLabel, Select, Slider, Box,
} from '@mui/material';
import { useProfileStore } from '../../store/useProfileStore';
import { SPORTS } from '../../data/types';

export default function AthleteForm() {
  const { profile, updateField } = useProfileStore();

  return (
    <Card>
      <CardContent>
        <Typography variant="h6" gutterBottom>Athlete Profile</Typography>
        <Grid container spacing={2}>
          <Grid size={{ xs: 6, sm: 3 }}>
            <FormControl fullWidth size="small">
              <InputLabel>Sex</InputLabel>
              <Select value={profile.sex} label="Sex" onChange={e => updateField('sex', e.target.value as 'female' | 'male')}>
                <MenuItem value="female">Female</MenuItem>
                <MenuItem value="male">Male</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid size={{ xs: 6, sm: 3 }}>
            <TextField
              label="Height (cm)"
              type="number"
              size="small"
              fullWidth
              value={profile.heightCm}
              onChange={e => updateField('heightCm', Number(e.target.value))}
              slotProps={{ htmlInput: { min: 100, max: 250 } }}
            />
          </Grid>
          <Grid size={{ xs: 6, sm: 3 }}>
            <TextField
              label="Weight (kg)"
              type="number"
              size="small"
              fullWidth
              value={profile.weightKg}
              onChange={e => updateField('weightKg', Number(e.target.value))}
              slotProps={{ htmlInput: { min: 30, max: 200 } }}
            />
          </Grid>
          <Grid size={{ xs: 6, sm: 3 }}>
            <TextField
              label="Age"
              type="number"
              size="small"
              fullWidth
              value={profile.ageYears}
              onChange={e => updateField('ageYears', Number(e.target.value))}
              slotProps={{ htmlInput: { min: 14, max: 80 } }}
            />
          </Grid>
          <Grid size={{ xs: 6, sm: 4 }}>
            <FormControl fullWidth size="small">
              <InputLabel>Primary Sport</InputLabel>
              <Select
                value={profile.sportPrimary}
                label="Primary Sport"
                onChange={e => updateField('sportPrimary', e.target.value as typeof profile.sportPrimary)}
              >
                {SPORTS.filter(s => s !== 'rest').map(s => (
                  <MenuItem key={s} value={s}>{s.charAt(0).toUpperCase() + s.slice(1)}</MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>
          <Grid size={{ xs: 6, sm: 4 }}>
            <FormControl fullWidth size="small">
              <InputLabel>Secondary Sport</InputLabel>
              <Select
                value={profile.sportSecondary || ''}
                label="Secondary Sport"
                onChange={e => updateField('sportSecondary', (e.target.value || null) as typeof profile.sportSecondary)}
              >
                <MenuItem value="">None</MenuItem>
                {SPORTS.filter(s => s !== 'rest').map(s => (
                  <MenuItem key={s} value={s}>{s.charAt(0).toUpperCase() + s.slice(1)}</MenuItem>
                ))}
              </Select>
            </FormControl>
          </Grid>
          <Grid size={{ xs: 12, sm: 4 }}>
            <Box sx={{ px: 1 }}>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                Training: {profile.trainingHoursWeek} hrs/week
              </Typography>
              <Slider
                value={profile.trainingHoursWeek}
                onChange={(_, v) => updateField('trainingHoursWeek', v as number)}
                min={1}
                max={25}
                step={1}
                size="small"
                valueLabelDisplay="auto"
              />
            </Box>
          </Grid>
        </Grid>
      </CardContent>
    </Card>
  );
}

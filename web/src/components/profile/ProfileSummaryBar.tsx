import { useState } from 'react';
import {
  Card, CardContent, Box, Typography, IconButton, Collapse, Chip, useMediaQuery, useTheme,
} from '@mui/material';
import EditIcon from '@mui/icons-material/Edit';
import ExpandLessIcon from '@mui/icons-material/ExpandLess';
import PersonIcon from '@mui/icons-material/Person';
import { useProfileStore } from '../../store/useProfileStore';
import AthleteForm from './AthleteForm';

export default function ProfileSummaryBar() {
  const { profile } = useProfileStore();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

  // Start expanded if profile has never been saved (no localStorage entry)
  const hasStoredProfile = typeof window !== 'undefined' && localStorage.getItem('veggiefuel-profile') !== null;
  const [expanded, setExpanded] = useState(!hasStoredProfile);

  const sportLabel = (s: string | null) => s ? s.charAt(0).toUpperCase() + s.slice(1) : null;
  const sports = [sportLabel(profile.sportPrimary), sportLabel(profile.sportSecondary)].filter(Boolean);

  return (
    <Card sx={{ mb: 2 }}>
      <CardContent sx={{ py: 1.5, '&:last-child': { pb: 1.5 } }}>
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            flexWrap: isMobile ? 'wrap' : 'nowrap',
            gap: 1,
          }}
        >
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
            <PersonIcon color="action" fontSize="small" />
            <Typography variant="body2" fontWeight={600}>
              {profile.sex === 'female' ? 'Female' : 'Male'}, {profile.weightKg}kg, {profile.heightCm}cm, {profile.ageYears}yr
            </Typography>
            <Box sx={{ display: 'flex', gap: 0.5 }}>
              {sports.map((s) => (
                <Chip key={s} label={s} size="small" color="primary" variant="outlined" />
              ))}
            </Box>
            <Typography variant="body2" color="text.secondary">
              {profile.trainingHoursWeek}h/wk
            </Typography>
          </Box>
          <IconButton
            size="small"
            onClick={() => setExpanded(!expanded)}
            aria-label={expanded ? 'Collapse profile' : 'Edit profile'}
          >
            {expanded ? <ExpandLessIcon /> : <EditIcon fontSize="small" />}
          </IconButton>
        </Box>
        <Collapse in={expanded} timeout={300}>
          <Box sx={{ mt: 2 }}>
            <AthleteForm />
          </Box>
        </Collapse>
      </CardContent>
    </Card>
  );
}

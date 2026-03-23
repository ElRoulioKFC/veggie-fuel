import { Box, Typography, Button } from '@mui/material';
import PersonOutlineIcon from '@mui/icons-material/PersonOutline';
import TuneIcon from '@mui/icons-material/Tune';
import PlayArrowIcon from '@mui/icons-material/PlayArrow';
import ArrowForwardIcon from '@mui/icons-material/ArrowForward';

interface Props {
  onGenerate: () => void;
  isOptimizing?: boolean;
}

const steps = [
  { icon: <PersonOutlineIcon sx={{ fontSize: 32 }} />, label: 'Set your profile' },
  { icon: <TuneIcon sx={{ fontSize: 32 }} />, label: 'Choose day type' },
  { icon: <PlayArrowIcon sx={{ fontSize: 32 }} />, label: 'Generate plan' },
];

export default function EmptyPlanState({ onGenerate, isOptimizing }: Props) {
  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        py: 8,
        px: 2,
        textAlign: 'center',
      }}
    >
      <Typography variant="h5" gutterBottom sx={{ mb: 1 }}>
        Ready to fuel your training?
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 4, maxWidth: 400 }}>
        Get a personalized vegetarian meal plan optimized for your sport, body, and amino acid needs.
      </Typography>

      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 4, flexWrap: 'wrap', justifyContent: 'center' }}>
        {steps.map((step, i) => (
          <Box key={step.label} sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Box
              sx={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                gap: 0.5,
                color: 'text.secondary',
              }}
            >
              {step.icon}
              <Typography variant="caption">{step.label}</Typography>
            </Box>
            {i < steps.length - 1 && (
              <ArrowForwardIcon sx={{ color: 'text.disabled', mx: 1 }} />
            )}
          </Box>
        ))}
      </Box>

      <Button
        variant="contained"
        size="large"
        startIcon={<PlayArrowIcon />}
        onClick={onGenerate}
        disabled={isOptimizing}
      >
        Generate Your First Plan
      </Button>
    </Box>
  );
}

import { Box, Typography, Card, CardContent, Link, List, ListItem, ListItemText } from '@mui/material';

export default function AboutPage() {
  return (
    <Box sx={{ maxWidth: 800 }}>
      <Typography variant="h4" gutterBottom>About VeggieFuel</Typography>
      <Typography variant="body1" paragraph>
        VeggieFuel is a vegetarian meal planner for endurance athletes (trail running, kayaking, climbing, swimming).
        It uses linear programming optimization to generate daily and weekly meal plans that meet all essential amino acid
        requirements while hitting your macro targets.
      </Typography>

      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>How It Works</Typography>
          <List dense>
            <ListItem>
              <ListItemText
                primary="Linear Programming Optimizer"
                secondary="Uses HiGHS (state-of-the-art LP solver) running directly in your browser via WebAssembly. No server needed."
              />
            </ListItem>
            <ListItem>
              <ListItemText
                primary="6 Meals Per Day"
                secondary="Breakfast, Snack AM, Lunch, Snack PM, Dinner, Recovery — with calorie distribution targets."
              />
            </ListItem>
            <ListItem>
              <ListItemText
                primary="9 Essential Amino Acids"
                secondary="Hard constraints ensure WHO/FAO minimum safe intake levels are met for all 9 essential amino acids."
              />
            </ListItem>
            <ListItem>
              <ListItemText
                primary="Sport-Specific Adjustments"
                secondary="Calorie and macro ratios are adjusted per sport: higher carbs for trail/swimming, higher protein for climbing/kayak."
              />
            </ListItem>
          </List>
        </CardContent>
      </Card>

      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>Nutrition Science References</Typography>
          <List dense>
            <ListItem>
              <ListItemText
                primary="Protein 1.6-1.8 g/kg for vegetarian endurance athletes"
                secondary={
                  <>
                    Jäger et al., JISSN 2017 (
                    <Link href="https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5477153/" target="_blank" rel="noopener">PMC5477153</Link>
                    )
                  </>
                }
              />
            </ListItem>
            <ListItem>
              <ListItemText
                primary="Carbohydrates 6-8 g/kg for endurance training"
                secondary="Thomas et al., JAND 2016 — ACSM/AND/DC Joint Position Statement"
              />
            </ListItem>
            <ListItem>
              <ListItemText
                primary="Essential amino acid minimums"
                secondary="WHO/FAO/UNU, Protein and Amino Acid Requirements in Human Nutrition, Technical Report Series 935, 2007"
              />
            </ListItem>
            <ListItem>
              <ListItemText
                primary="BMR: Mifflin-St Jeor equation"
                secondary="Mifflin et al., 1990 — most accurate BMR prediction equation"
              />
            </ListItem>
          </List>
        </CardContent>
      </Card>

      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>Privacy</Typography>
          <Typography variant="body2">
            VeggieFuel runs entirely in your browser. Your athlete profile is saved to localStorage only.
            No data is sent to any server. No cookies, no tracking, no accounts.
          </Typography>
        </CardContent>
      </Card>
    </Box>
  );
}

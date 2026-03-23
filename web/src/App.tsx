import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { ThemeProvider, CssBaseline } from '@mui/material';
import { theme } from './theme';
import AppShell from './components/layout/AppShell';
import DailyPlannerPage from './pages/DailyPlannerPage';
import WeeklyPlannerPage from './pages/WeeklyPlannerPage';
import FoodDatabasePage from './pages/FoodDatabasePage';
import RecipesPage from './pages/RecipesPage';
import AboutPage from './pages/AboutPage';

export default function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <BrowserRouter>
        <AppShell>
          <Routes>
            <Route path="/" element={<DailyPlannerPage />} />
            <Route path="/weekly" element={<WeeklyPlannerPage />} />
            <Route path="/foods" element={<FoodDatabasePage />} />
            <Route path="/recipes" element={<RecipesPage />} />
            <Route path="/about" element={<AboutPage />} />
          </Routes>
        </AppShell>
      </BrowserRouter>
    </ThemeProvider>
  );
}

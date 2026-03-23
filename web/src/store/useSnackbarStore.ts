import { create } from 'zustand';

interface SnackbarState {
  message: string;
  open: boolean;
  severity: 'success' | 'info' | 'warning' | 'error';
  show: (message: string, severity?: 'success' | 'info' | 'warning' | 'error') => void;
  close: () => void;
}

export const useSnackbarStore = create<SnackbarState>()((set) => ({
  message: '',
  open: false,
  severity: 'success',
  show: (message, severity = 'success') => set({ message, severity, open: true }),
  close: () => set({ open: false }),
}));

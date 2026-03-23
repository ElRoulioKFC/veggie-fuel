import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { AthleteProfile } from '../data/types';
import { DEFAULT_PROFILE } from '../engine/targets';

interface ProfileState {
  profile: AthleteProfile;
  setProfile: (profile: AthleteProfile) => void;
  updateField: <K extends keyof AthleteProfile>(key: K, value: AthleteProfile[K]) => void;
  reset: () => void;
}

export const useProfileStore = create<ProfileState>()(
  persist(
    (set) => ({
      profile: { ...DEFAULT_PROFILE },
      setProfile: (profile) => set({ profile }),
      updateField: (key, value) =>
        set((state) => ({ profile: { ...state.profile, [key]: value } })),
      reset: () => set({ profile: { ...DEFAULT_PROFILE } }),
    }),
    { name: 'veggiefuel-profile' }
  )
);

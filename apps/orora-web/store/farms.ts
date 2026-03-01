import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import type { Farm } from '@/lib/api/farms';
import { farmsApi } from '@/lib/api/farms';

interface FarmStore {
  /** Farms cached per account_id */
  farmsByAccount: Record<string, Farm[]>;
  /** Selected farm id per account_id (null = all farms) */
  selectedFarmByAccount: Record<string, string | null>;
  setFarms: (accountId: string, farms: Farm[]) => void;
  setSelectedFarm: (accountId: string, farmId: string | null) => void;
  loadFarms: (accountId: string) => Promise<void>;
}

export const useFarmStore = create<FarmStore>()(
  persist(
    (set, get) => ({
      farmsByAccount: {},
      selectedFarmByAccount: {},

      setFarms: (accountId: string, farms: Farm[]) => {
        set((state) => ({
          farmsByAccount: {
            ...state.farmsByAccount,
            [accountId]: farms,
          },
        }));
      },

      setSelectedFarm: (accountId: string, farmId: string | null) => {
        set((state) => ({
          selectedFarmByAccount: {
            ...state.selectedFarmByAccount,
            [accountId]: farmId,
          },
        }));
      },

      loadFarms: async (accountId: string) => {
        if (!accountId) return;
        const { farmsByAccount } = get();
        if (farmsByAccount[accountId]) {
          // Already loaded in this session; skip to avoid extra calls.
          return;
        }
        try {
          const res = await farmsApi.list(accountId);
          if (res.code === 200 && Array.isArray(res.data)) {
            const farms = res.data;
            set((state) => ({
              farmsByAccount: {
                ...state.farmsByAccount,
                [accountId]: farms,
              },
            }));
            // If no selected farm for this account yet and there is at least one farm, default to the first.
            const { selectedFarmByAccount } = get();
            if (!(accountId in selectedFarmByAccount) && farms.length > 0) {
              set((state) => ({
                selectedFarmByAccount: {
                  ...state.selectedFarmByAccount,
                  [accountId]: farms[0].id,
                },
              }));
            }
          }
        } catch {
          // Swallow for now; callers can show errors based on their own fetch.
        }
      },
    }),
    {
      name: 'orora-farms-storage',
      storage: createJSONStorage(() =>
        typeof window !== 'undefined'
          ? localStorage
          : ({ getItem: () => null, setItem: () => {}, removeItem: () => {}, length: 0, clear: () => {}, key: () => null } as unknown as Storage)
      ),
      partialize: (state) => ({
        farmsByAccount: state.farmsByAccount,
        selectedFarmByAccount: state.selectedFarmByAccount,
      }),
    },
  ),
);


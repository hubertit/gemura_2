import { apiClient } from './client';

export type AnimalGender = 'male' | 'female';
export type AnimalSource = 'born_on_farm' | 'purchased' | 'donated' | 'other';
export type AnimalStatus =
  | 'active'
  | 'lactating'
  | 'dry'
  | 'pregnant'
  | 'sick'
  | 'sold'
  | 'dead'
  | 'culled';
export type HealthEventType =
  | 'vaccination'
  | 'treatment'
  | 'deworming'
  | 'examination'
  | 'surgery'
  | 'injury'
  | 'illness'
  | 'other';

export interface Animal {
  id: string;
  account_id: string;
  farm_id: string | null;
  tag_number: string;
  name: string | null;
  /** Breed relation from API; use breed?.name for display */
  breed?: { id: string; name: string; code: string | null } | null;
  gender: AnimalGender;
  date_of_birth: string;
  source: AnimalSource;
  purchase_date: string | null;
  purchase_price: string | null;
  mother_id: string | null;
  father_id: string | null;
  status: AnimalStatus;
  photo_url: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
  created_by: string | null;
  farm?: { id: string; name: string; code: string | null } | null;
  mother?: { id: string; tag_number: string; name: string | null } | null;
  father?: { id: string; tag_number: string; name: string | null } | null;
  weights?: AnimalWeight[];
  health_records?: AnimalHealth[];
}

export interface AnimalWeight {
  id: string;
  animal_id: string;
  weight_kg: string;
  recorded_at: string;
  notes: string | null;
  created_at: string;
  created_by: string | null;
}

export interface AnimalHealth {
  id: string;
  animal_id: string;
  event_type: HealthEventType;
  event_date: string;
  description: string;
  diagnosis: string | null;
  treatment: string | null;
  medicine_name: string | null;
  dosage: string | null;
  administered_by: string | null;
  next_due_date: string | null;
  cost: string | null;
  notes: string | null;
  created_at: string;
  created_by: string | null;
}

export interface CreateAnimalData {
  tag_number: string;
  name?: string;
  breed_id: string;
  gender: AnimalGender;
  date_of_birth: string;
  source: AnimalSource;
  purchase_date?: string;
  purchase_price?: number;
  mother_id?: string;
  father_id?: string;
  status?: AnimalStatus;
  photo_url?: string;
  notes?: string;
  farm_id?: string;
}

export interface UpdateAnimalData {
  tag_number?: string;
  name?: string;
  breed_id?: string;
  gender?: AnimalGender;
  date_of_birth?: string;
  source?: AnimalSource;
  purchase_date?: string;
  purchase_price?: number;
  mother_id?: string;
  father_id?: string;
  status?: AnimalStatus;
  photo_url?: string;
  notes?: string;
  farm_id?: string;
}

export interface CreateWeightData {
  weight_kg: number;
  recorded_at: string;
  notes?: string;
}

export interface CreateHealthData {
  event_type: HealthEventType;
  event_date: string;
  description: string;
  diagnosis?: string;
  treatment?: string;
  medicine_name?: string;
  dosage?: string;
  administered_by?: string;
  next_due_date?: string;
  cost?: number;
  notes?: string;
}

export interface ApiResponse<T> {
  code: number;
  status: string;
  message: string;
  data: T;
}

const params = (
  accountId?: string,
  filters?: { status?: string; breed_id?: string; gender?: string; search?: string; farm_id?: string },
) => {
  const p: Record<string, string> = {};
  if (accountId) p.account_id = accountId;
  if (filters?.status) p.status = filters.status;
  if (filters?.breed_id) p.breed_id = filters.breed_id;
  if (filters?.gender) p.gender = filters.gender;
  if (filters?.search) p.search = filters.search;
  if (filters?.farm_id) p.farm_id = filters.farm_id;
  return p;
};

export const animalsApi = {
  getList: (
    accountId?: string,
    filters?: { status?: string; breed_id?: string; gender?: string; search?: string; farm_id?: string },
  ) =>
    apiClient.get<ApiResponse<Animal[]>>('/animals', { params: params(accountId, filters) }),

  getById: (id: string, accountId?: string) =>
    apiClient.get<ApiResponse<Animal>>(`/animals/${id}`, { params: accountId ? { account_id: accountId } : {} }),

  getHistory: (id: string, accountId?: string) =>
    apiClient.get<ApiResponse<Animal & { weights: AnimalWeight[]; health_records: AnimalHealth[] }>>(
      `/animals/${id}/history`,
      { params: accountId ? { account_id: accountId } : {} }
    ),

  create: (data: CreateAnimalData, accountId?: string) =>
    apiClient.post<ApiResponse<Animal>>('/animals', data, {
      params: accountId ? { account_id: accountId } : {},
    }),

  update: (id: string, data: UpdateAnimalData, accountId?: string) =>
    apiClient.patch<ApiResponse<Animal>>(`/animals/${id}`, data, {
      params: accountId ? { account_id: accountId } : {},
    }),

  delete: (id: string, accountId?: string) =>
    apiClient.delete<ApiResponse<{ message: string }>>(`/animals/${id}`, {
      params: accountId ? { account_id: accountId } : {},
    }),

  // Weights
  addWeight: (animalId: string, data: CreateWeightData, accountId?: string) =>
    apiClient.post<ApiResponse<AnimalWeight>>(`/animals/${animalId}/weights`, data, {
      params: accountId ? { account_id: accountId } : {},
    }),

  getWeights: (animalId: string, accountId?: string) =>
    apiClient.get<ApiResponse<AnimalWeight[]>>(`/animals/${animalId}/weights`, {
      params: accountId ? { account_id: accountId } : {},
    }),

  deleteWeight: (animalId: string, weightId: string, accountId?: string) =>
    apiClient.delete<ApiResponse<{ message: string }>>(`/animals/${animalId}/weights/${weightId}`, {
      params: accountId ? { account_id: accountId } : {},
    }),

  // Health
  addHealth: (animalId: string, data: CreateHealthData, accountId?: string) =>
    apiClient.post<ApiResponse<AnimalHealth>>(`/animals/${animalId}/health`, data, {
      params: accountId ? { account_id: accountId } : {},
    }),

  getHealth: (animalId: string, accountId?: string) =>
    apiClient.get<ApiResponse<AnimalHealth[]>>(`/animals/${animalId}/health`, {
      params: accountId ? { account_id: accountId } : {},
    }),

  deleteHealth: (animalId: string, healthId: string, accountId?: string) =>
    apiClient.delete<ApiResponse<{ message: string }>>(`/animals/${animalId}/health/${healthId}`, {
      params: accountId ? { account_id: accountId } : {},
    }),
};

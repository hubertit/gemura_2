import { apiClient } from './client';

export interface Breed {
  id: string;
  name: string;
  code: string | null;
  description?: string | null;
}

export interface ApiResponse<T> {
  code: number;
  status: string;
  message: string;
  data: T;
}

export const breedsApi = {
  getList: () =>
    apiClient.get<ApiResponse<Breed[]>>('/breeds'),
};

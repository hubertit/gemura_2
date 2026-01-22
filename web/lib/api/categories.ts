import { apiClient } from './client';

export interface Category {
  id: string;
  name: string;
  description?: string;
  created_at: string;
  updated_at: string;
}

export interface CategoriesResponse {
  code: number;
  status: string;
  message: string;
  data: Category[];
}

export const categoriesApi = {
  getCategories: async (): Promise<CategoriesResponse> => {
    return apiClient.get('/market/categories');
  },
};

/**
 * Utility functions for handling and formatting errors
 */

export interface ApiError {
  message: string;
  code?: number;
  status?: string;
  errors?: Record<string, string[]>;
}

/**
 * Extract user-friendly error message from API error
 */
export function getErrorMessage(error: any): string {
  if (!error) {
    return 'An unexpected error occurred';
  }

  // Handle Axios errors
  if (error.response) {
    const data = error.response.data;
    
    if (data?.message) {
      return data.message;
    }
    
    if (data?.error) {
      return data.error;
    }

    // Handle validation errors
    if (data?.errors && typeof data.errors === 'object') {
      const errorMessages = Object.values(data.errors).flat();
      if (errorMessages.length > 0) {
        return errorMessages.join(', ');
      }
    }

    // HTTP status code messages
    switch (error.response.status) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Unauthorized. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'A conflict occurred. The resource may already exist.';
      case 422:
        return 'Validation failed. Please check your input.';
      case 500:
        return 'Server error. Please try again later.';
      case 503:
        return 'Service temporarily unavailable. Please try again later.';
      default:
        return data?.message || `Error ${error.response.status}: ${error.response.statusText || 'Unknown error'}`;
    }
  }

  // Handle network errors
  if (error.request) {
    return 'Network error. Please check your internet connection.';
  }

  // Handle standard Error objects
  if (error instanceof Error) {
    return error.message;
  }

  // Handle string errors
  if (typeof error === 'string') {
    return error;
  }

  // Fallback
  return 'An unexpected error occurred. Please try again.';
}

/**
 * Check if error is a network error
 */
export function isNetworkError(error: any): boolean {
  return error?.code === 'ECONNABORTED' || 
         error?.message?.includes('Network Error') ||
         error?.message?.includes('timeout') ||
         (error?.request && !error?.response);
}

/**
 * Check if error is an authentication error
 */
export function isAuthError(error: any): boolean {
  return error?.response?.status === 401 || 
         error?.response?.status === 403;
}

/**
 * Format error for display
 */
export function formatError(error: any): ApiError {
  return {
    message: getErrorMessage(error),
    code: error?.response?.status,
    status: error?.response?.statusText,
    errors: error?.response?.data?.errors,
  };
}

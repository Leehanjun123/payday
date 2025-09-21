import { API_BASE_URL, API_CONFIG } from '../config/api';
import * as SecureStore from 'expo-secure-store';

class ApiClient {
  private baseUrl: string;
  private defaultHeaders: Record<string, string>;
  private timeout: number;

  constructor() {
    this.baseUrl = API_BASE_URL;
    this.defaultHeaders = API_CONFIG.headers;
    this.timeout = API_CONFIG.timeout;
  }

  private async getAuthHeaders(): Promise<Record<string, string>> {
    try {
      const token = await SecureStore.getItemAsync('auth_token');
      if (token) {
        return { Authorization: `Bearer ${token}` };
      }
    } catch (error) {
      console.error('Error getting auth headers:', error);
    }
    return {};
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {},
  ): Promise<T> {
    const url = `${this.baseUrl}${endpoint}`;
    const authHeaders = await this.getAuthHeaders();
    const config: RequestInit = {
      ...options,
      headers: {
        ...this.defaultHeaders,
        ...authHeaders,
        ...options.headers,
      },
    };

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.timeout);

      const response = await fetch(url, {
        ...config,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      return data as T;
    } catch (error) {
      if (error instanceof Error) {
        if (error.name === 'AbortError') {
          throw new Error('Request timeout');
        }
        throw error;
      }
      throw new Error('An unknown error occurred');
    }
  }

  async get<T>(endpoint: string, params?: Record<string, any>): Promise<T> {
    const queryString = params
      ? '?' + new URLSearchParams(params).toString()
      : '';
    return this.request<T>(`${endpoint}${queryString}`, {
      method: 'GET',
    });
  }

  async post<T>(endpoint: string, data?: any): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async put<T>(endpoint: string, data?: any): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  }

  async delete<T>(endpoint: string): Promise<T> {
    return this.request<T>(endpoint, {
      method: 'DELETE',
    });
  }

  async healthCheck(): Promise<{ status: string; timestamp: string }> {
    return this.get('/health');
  }
}

export default new ApiClient();
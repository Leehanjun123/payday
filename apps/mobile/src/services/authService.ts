import * as SecureStore from 'expo-secure-store';
import AsyncStorage from '@react-native-async-storage/async-storage';
import apiClient from './apiClient';

const TOKEN_KEY = 'auth_token';
const REFRESH_TOKEN_KEY = 'refresh_token';
const USER_KEY = 'user_data';

export interface User {
  id: string;
  email: string;
  name: string;
  role: string;
  level: number;
  points: number;
  profileImage?: string;
  bio?: string;
}

export interface AuthResponse {
  message: string;
  user: User;
  token: string;
  refreshToken: string;
}

class AuthService {
  async register(email: string, password: string, name: string): Promise<AuthResponse> {
    const response = await apiClient.post<AuthResponse>('/api/v1/auth/register', {
      email,
      password,
      name,
    });

    await this.saveAuthData(response);
    return response;
  }

  async login(email: string, password: string): Promise<AuthResponse> {
    const response = await apiClient.post<AuthResponse>('/api/v1/auth/login', {
      email,
      password,
    });

    await this.saveAuthData(response);
    return response;
  }

  async logout(): Promise<void> {
    try {
      await apiClient.post('/api/v1/auth/logout', {});
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      await this.clearAuthData();
    }
  }

  async refreshToken(): Promise<string | null> {
    try {
      const refreshToken = await this.getRefreshToken();
      if (!refreshToken) return null;

      const response = await apiClient.post<{ token: string; refreshToken: string }>(
        '/api/v1/auth/refresh',
        { refreshToken }
      );

      await this.saveTokens(response.token, response.refreshToken);
      return response.token;
    } catch (error) {
      console.error('Token refresh error:', error);
      await this.clearAuthData();
      return null;
    }
  }

  async getCurrentUser(): Promise<User | null> {
    try {
      const userString = await AsyncStorage.getItem(USER_KEY);
      if (!userString) return null;
      return JSON.parse(userString);
    } catch (error) {
      console.error('Get user error:', error);
      return null;
    }
  }

  async getToken(): Promise<string | null> {
    try {
      return await SecureStore.getItemAsync(TOKEN_KEY);
    } catch (error) {
      console.error('Get token error:', error);
      return null;
    }
  }

  private async getRefreshToken(): Promise<string | null> {
    try {
      return await SecureStore.getItemAsync(REFRESH_TOKEN_KEY);
    } catch (error) {
      console.error('Get refresh token error:', error);
      return null;
    }
  }

  private async saveAuthData(authData: AuthResponse): Promise<void> {
    await this.saveTokens(authData.token, authData.refreshToken);
    await AsyncStorage.setItem(USER_KEY, JSON.stringify(authData.user));
  }

  private async saveTokens(token: string, refreshToken: string): Promise<void> {
    await SecureStore.setItemAsync(TOKEN_KEY, token);
    await SecureStore.setItemAsync(REFRESH_TOKEN_KEY, refreshToken);
  }

  private async clearAuthData(): Promise<void> {
    await SecureStore.deleteItemAsync(TOKEN_KEY);
    await SecureStore.deleteItemAsync(REFRESH_TOKEN_KEY);
    await AsyncStorage.removeItem(USER_KEY);
  }

  async isAuthenticated(): Promise<boolean> {
    const token = await this.getToken();
    return !!token;
  }
}

export default new AuthService();
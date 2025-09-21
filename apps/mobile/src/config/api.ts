// 로컬 네트워크 IP 주소로 설정 - 휴대폰에서 테스트 가능
const DEV_API_URL = 'http://192.168.45.250:3000';
const PROD_API_URL = 'https://api.payday.com';

export const API_BASE_URL = __DEV__ ? DEV_API_URL : PROD_API_URL;

export const API_ENDPOINTS = {
  health: '/health',
  api: '/api/v1',
  users: '/api/v1/users',
  tasks: '/api/v1/tasks',
  earnings: '/api/v1/earnings',
  payments: '/api/v1/payments',
};

export const API_CONFIG = {
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
};
import apiClient from './apiClient';

export interface EarningsSummary {
  totalEarnings: number;
  availableBalance: number;
  pendingAmount: number;
  completedTasks: number;
  thisMonthEarnings: number;
  lastMonthEarnings: number;
}

export interface Transaction {
  id: string;
  type: 'EARNING' | 'WITHDRAWAL' | 'REFUND' | 'BONUS';
  amount: number;
  description: string;
  status: 'COMPLETED' | 'PENDING' | 'FAILED';
  createdAt: string;
  taskId?: string;
  task?: {
    id: string;
    title: string;
  };
}

export interface WithdrawalRequest {
  amount: number;
  bankName: string;
  accountNumber: string;
  accountHolder: string;
}

export interface EarningsAnalytics {
  dailyEarnings: Array<{
    date: string;
    amount: number;
  }>;
  categoryBreakdown: Array<{
    category: string;
    amount: number;
    count: number;
  }>;
  averageTaskEarning: number;
  bestMonth: {
    month: string;
    amount: number;
  };
}

class EarningsService {
  async getEarningsSummary(): Promise<EarningsSummary> {
    return apiClient.get('/api/v1/earnings/summary');
  }

  async getTransactionHistory(
    page = 1,
    limit = 20
  ): Promise<{
    transactions: Transaction[];
    pagination: {
      page: number;
      limit: number;
      total: number;
      pages: number;
    };
  }> {
    return apiClient.get(`/api/v1/earnings/transactions?page=${page}&limit=${limit}`);
  }

  async getEarningsAnalytics(period: 'week' | 'month' | 'year' = 'month'): Promise<EarningsAnalytics> {
    return apiClient.get(`/api/v1/earnings/analytics?period=${period}`);
  }

  async requestWithdrawal(request: WithdrawalRequest): Promise<{
    message: string;
    withdrawalId: string;
  }> {
    return apiClient.post('/api/v1/earnings/withdraw', request);
  }

  async getWithdrawalHistory(): Promise<Transaction[]> {
    return apiClient.get('/api/v1/earnings/withdrawals');
  }
}

export default new EarningsService();
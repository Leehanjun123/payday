import apiClient from './apiClient';

export interface Portfolio {
  id: string;
  userId: string;
  name: string;
  description?: string;
  totalValue: number;
  totalCost: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
  holdings: Holding[];
  _count: {
    holdings: number;
    transactions: number;
  };
}

export interface Holding {
  id: string;
  portfolioId: string;
  symbol: string;
  name: string;
  type: AssetType;
  quantity: number;
  averagePrice: number;
  currentPrice: number;
  totalValue: number;
  profitLoss: number;
  profitLossRate: number;
  createdAt: string;
  updatedAt: string;
}

export interface Transaction {
  id: string;
  portfolioId: string;
  holdingId?: string;
  symbol: string;
  type: TransactionType;
  quantity: number;
  price: number;
  totalAmount: number;
  fee: number;
  note?: string;
  executedAt: string;
  createdAt: string;
}

export interface MarketData {
  id: string;
  symbol: string;
  name: string;
  type: AssetType;
  currentPrice: number;
  change: number;
  changePercent: number;
  volume: number;
  marketCap?: number;
  high52w?: number;
  low52w?: number;
  updatedAt: string;
}

export interface WatchlistItem {
  id: string;
  userId: string;
  symbol: string;
  name: string;
  type: AssetType;
  createdAt: string;
  marketData?: MarketData;
}

export interface PortfolioAnalytics {
  totalValue: number;
  totalCost: number;
  totalProfitLoss: number;
  totalProfitLossRate: number;
  assetAllocation: {
    [key: string]: {
      value: number;
      percentage: number;
    };
  };
  topHoldings: Holding[];
}

export type AssetType = 'STOCK_KR' | 'STOCK_US' | 'CRYPTO' | 'REAL_ESTATE' | 'FUND' | 'BOND' | 'COMMODITY' | 'ETF';
export type TransactionType = 'BUY' | 'SELL' | 'DIVIDEND' | 'SPLIT' | 'DEPOSIT' | 'WITHDRAWAL';

export interface CreatePortfolioData {
  name: string;
  description?: string;
}

export interface AddHoldingData {
  symbol: string;
  name: string;
  type: AssetType;
  quantity: number;
  price: number;
}

export interface AddTransactionData {
  holdingId?: string;
  symbol: string;
  type: TransactionType;
  quantity: number;
  price: number;
  fee?: number;
  note?: string;
  executedAt: Date;
}

class InvestmentService {
  // Portfolio Management
  async createPortfolio(data: CreatePortfolioData): Promise<{ message: string; portfolio: Portfolio }> {
    return apiClient.post('/api/v1/investments/portfolios', data);
  }

  async getUserPortfolios(): Promise<{ portfolios: Portfolio[] }> {
    return apiClient.get('/api/v1/investments/portfolios');
  }

  async getPortfolio(portfolioId: string): Promise<{ portfolio: Portfolio }> {
    return apiClient.get(`/api/v1/investments/portfolios/${portfolioId}`);
  }

  async updatePortfolio(portfolioId: string, data: Partial<CreatePortfolioData>): Promise<{ message: string; portfolio: Portfolio }> {
    return apiClient.put(`/api/v1/investments/portfolios/${portfolioId}`, data);
  }

  async deletePortfolio(portfolioId: string): Promise<{ message: string }> {
    return apiClient.delete(`/api/v1/investments/portfolios/${portfolioId}`);
  }

  async getPortfolioAnalytics(portfolioId: string): Promise<{ analytics: PortfolioAnalytics }> {
    return apiClient.get(`/api/v1/investments/portfolios/${portfolioId}/analytics`);
  }

  // Holdings Management
  async addHolding(portfolioId: string, data: AddHoldingData): Promise<{ message: string; holding: Holding }> {
    return apiClient.post(`/api/v1/investments/portfolios/${portfolioId}/holdings`, data);
  }

  async updateHolding(holdingId: string, currentPrice: number): Promise<{ message: string; holding: Holding }> {
    return apiClient.put(`/api/v1/investments/holdings/${holdingId}`, { currentPrice });
  }

  async removeHolding(holdingId: string): Promise<{ message: string }> {
    return apiClient.delete(`/api/v1/investments/holdings/${holdingId}`);
  }

  // Transaction Management
  async addTransaction(portfolioId: string, data: AddTransactionData): Promise<{ message: string; transaction: Transaction }> {
    return apiClient.post(`/api/v1/investments/portfolios/${portfolioId}/transactions`, {
      ...data,
      executedAt: data.executedAt.toISOString(),
    });
  }

  async getTransactionHistory(portfolioId: string, page = 1, limit = 20): Promise<{
    transactions: Transaction[];
    pagination: {
      page: number;
      limit: number;
      total: number;
      pages: number;
    };
  }> {
    const params = new URLSearchParams({
      page: String(page),
      limit: String(limit),
    });

    return apiClient.get(`/api/v1/investments/portfolios/${portfolioId}/transactions?${params.toString()}`);
  }

  // Market Data
  async searchMarketData(query: string, type?: AssetType): Promise<{ results: MarketData[] }> {
    const params = new URLSearchParams({ q: query });
    if (type) {
      params.append('type', type);
    }

    return apiClient.get(`/api/v1/investments/market/search?${params.toString()}`);
  }

  async getMarketData(symbols: string[]): Promise<{ data: MarketData[] }> {
    const params = new URLSearchParams({
      symbols: symbols.join(','),
    });

    return apiClient.get(`/api/v1/investments/market/data?${params.toString()}`);
  }

  async simulateMarketUpdate(): Promise<{ message: string }> {
    return apiClient.post('/api/v1/investments/market/simulate');
  }

  async initDemoData(): Promise<{ message: string; count: number }> {
    return apiClient.post('/api/v1/investments/market/init-demo');
  }

  // Watchlist Management
  async addToWatchlist(symbol: string, name: string, type: AssetType): Promise<{ message: string; watchlistItem: WatchlistItem }> {
    return apiClient.post('/api/v1/investments/watchlist', { symbol, name, type });
  }

  async removeFromWatchlist(symbol: string): Promise<{ message: string }> {
    return apiClient.delete(`/api/v1/investments/watchlist/${symbol}`);
  }

  async getUserWatchlist(): Promise<{ watchlist: WatchlistItem[] }> {
    return apiClient.get('/api/v1/investments/watchlist');
  }

  // Utility Functions
  formatPrice(price: number, currency = '₩'): string {
    if (currency === '₩') {
      return `₩${price.toLocaleString('ko-KR')}`;
    } else {
      return `$${price.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    }
  }

  formatChange(change: number, changePercent: number, currency = '₩'): {
    changeText: string;
    changePercentText: string;
    color: string;
    isPositive: boolean;
  } {
    const isPositive = change >= 0;
    const color = isPositive ? '#4CAF50' : '#F44336';

    const changeText = currency === '₩'
      ? `${isPositive ? '+' : ''}₩${Math.abs(change).toLocaleString('ko-KR')}`
      : `${isPositive ? '+' : ''}$${Math.abs(change).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

    const changePercentText = `${isPositive ? '+' : ''}${changePercent.toFixed(2)}%`;

    return {
      changeText,
      changePercentText,
      color,
      isPositive,
    };
  }

  getAssetTypeText(type: AssetType): string {
    switch (type) {
      case 'STOCK_KR':
        return '국내 주식';
      case 'STOCK_US':
        return '미국 주식';
      case 'CRYPTO':
        return '암호화폐';
      case 'REAL_ESTATE':
        return '부동산';
      case 'FUND':
        return '펀드';
      case 'BOND':
        return '채권';
      case 'COMMODITY':
        return '원자재';
      case 'ETF':
        return 'ETF';
      default:
        return type;
    }
  }

  getAssetTypeColor(type: AssetType): string {
    switch (type) {
      case 'STOCK_KR':
        return '#1976D2';
      case 'STOCK_US':
        return '#388E3C';
      case 'CRYPTO':
        return '#FF9800';
      case 'REAL_ESTATE':
        return '#8BC34A';
      case 'FUND':
        return '#9C27B0';
      case 'BOND':
        return '#607D8B';
      case 'COMMODITY':
        return '#795548';
      case 'ETF':
        return '#E91E63';
      default:
        return '#666';
    }
  }

  getTransactionTypeText(type: TransactionType): string {
    switch (type) {
      case 'BUY':
        return '매수';
      case 'SELL':
        return '매도';
      case 'DIVIDEND':
        return '배당';
      case 'SPLIT':
        return '분할';
      case 'DEPOSIT':
        return '입금';
      case 'WITHDRAWAL':
        return '출금';
      default:
        return type;
    }
  }

  getTransactionTypeColor(type: TransactionType): string {
    switch (type) {
      case 'BUY':
        return '#F44336';
      case 'SELL':
        return '#4CAF50';
      case 'DIVIDEND':
        return '#2196F3';
      case 'SPLIT':
        return '#FF9800';
      case 'DEPOSIT':
        return '#4CAF50';
      case 'WITHDRAWAL':
        return '#F44336';
      default:
        return '#666';
    }
  }

  getCurrencyByAssetType(type: AssetType): string {
    switch (type) {
      case 'STOCK_KR':
      case 'REAL_ESTATE':
        return '₩';
      case 'STOCK_US':
      case 'ETF':
        return '$';
      case 'CRYPTO':
        return '$';
      case 'FUND':
      case 'BOND':
      case 'COMMODITY':
        return '₩';
      default:
        return '₩';
    }
  }

  calculatePortfolioSummary(portfolios: Portfolio[]) {
    const totalValue = portfolios.reduce((sum, portfolio) => sum + portfolio.totalValue, 0);
    const totalCost = portfolios.reduce((sum, portfolio) => sum + portfolio.totalCost, 0);
    const totalProfitLoss = totalValue - totalCost;
    const totalProfitLossRate = totalCost > 0 ? (totalProfitLoss / totalCost) * 100 : 0;

    return {
      totalValue,
      totalCost,
      totalProfitLoss,
      totalProfitLossRate,
      portfolioCount: portfolios.length,
    };
  }

  formatDateTime(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('ko-KR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  formatDateShort(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('ko-KR', {
      month: 'short',
      day: 'numeric',
    });
  }
}

export default new InvestmentService();
import apiClient from './apiClient';

export interface Prediction {
  id: string;
  symbol: string;
  type: PredictionType;
  timeframe: string;
  currentPrice: number;
  predictedPrice: number;
  confidence: number;
  reasoning: string;
  factors: any;
  status: PredictionStatus;
  actualPrice?: number;
  accuracy?: number;
  createdAt: string;
  updatedAt: string;
  validUntil: string;
}

export interface MarketAnalysis {
  id: string;
  symbol?: string;
  title: string;
  summary: string;
  content: string;
  category: AnalysisCategory;
  sentiment: MarketSentiment;
  riskLevel: RiskLevel;
  tags: string[];
  metrics: any;
  recommendations: string;
  isPublished: boolean;
  authorId?: string;
  viewCount: number;
  likeCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface PriceAlert {
  id: string;
  userId: string;
  symbol: string;
  name: string;
  type: AlertType;
  targetPrice: number;
  currentPrice: number;
  condition: AlertCondition;
  isActive: boolean;
  isTriggered: boolean;
  triggeredAt?: string;
  message?: string;
  createdAt: string;
  updatedAt: string;
}

export interface PortfolioPerformance {
  id: string;
  portfolioId: string;
  date: string;
  totalValue: number;
  totalCost: number;
  dayChange: number;
  dayChangePercent: number;
  benchmark?: string;
  benchmarkReturn?: number;
  createdAt: string;
}

export type PredictionType = 'PRICE_TARGET' | 'TREND_ANALYSIS' | 'VOLATILITY' | 'SUPPORT_RESISTANCE' | 'SENTIMENT';
export type PredictionStatus = 'ACTIVE' | 'EXPIRED' | 'VERIFIED' | 'FAILED';
export type AnalysisCategory = 'TECHNICAL_ANALYSIS' | 'FUNDAMENTAL_ANALYSIS' | 'MARKET_OVERVIEW' | 'SECTOR_ANALYSIS' | 'ECONOMIC_INDICATOR' | 'NEWS_IMPACT';
export type MarketSentiment = 'VERY_BULLISH' | 'BULLISH' | 'NEUTRAL' | 'BEARISH' | 'VERY_BEARISH';
export type RiskLevel = 'VERY_LOW' | 'LOW' | 'MODERATE' | 'HIGH' | 'VERY_HIGH';
export type AlertType = 'PRICE_TARGET' | 'PERCENTAGE_CHANGE' | 'VOLUME_SPIKE' | 'TECHNICAL_SIGNAL';
export type AlertCondition = 'ABOVE' | 'BELOW' | 'EQUALS';

export interface CreatePriceAlertData {
  symbol: string;
  name: string;
  type: AlertType;
  targetPrice: number;
  currentPrice: number;
  condition: AlertCondition;
  message?: string;
}

class PredictionService {
  // AI Predictions
  async getPredictions(symbol?: string, type?: string, limit = 20): Promise<{ predictions: Prediction[] }> {
    const params = new URLSearchParams();
    if (symbol) params.append('symbol', symbol);
    if (type) params.append('type', type);
    params.append('limit', String(limit));

    return apiClient.get(`/api/v1/predictions/predictions?${params.toString()}`);
  }

  async getPredictionById(id: string): Promise<{ prediction: Prediction }> {
    return apiClient.get(`/api/v1/predictions/predictions/${id}`);
  }

  // Market Analysis
  async getAnalyses(symbol?: string, category?: string, limit = 20): Promise<{ analyses: MarketAnalysis[] }> {
    const params = new URLSearchParams();
    if (symbol) params.append('symbol', symbol);
    if (category) params.append('category', category);
    params.append('limit', String(limit));

    return apiClient.get(`/api/v1/predictions/analyses?${params.toString()}`);
  }

  async getAnalysisById(id: string): Promise<{ analysis: MarketAnalysis }> {
    return apiClient.get(`/api/v1/predictions/analyses/${id}`);
  }

  async likeAnalysis(id: string): Promise<{ message: string; analysis: MarketAnalysis }> {
    return apiClient.post(`/api/v1/predictions/analyses/${id}/like`);
  }

  // Price Alerts
  async createPriceAlert(data: CreatePriceAlertData): Promise<{ message: string; alert: PriceAlert }> {
    return apiClient.post('/api/v1/predictions/alerts', data);
  }

  async getUserPriceAlerts(): Promise<{ alerts: PriceAlert[] }> {
    return apiClient.get('/api/v1/predictions/alerts');
  }

  async updatePriceAlert(id: string, data: Partial<CreatePriceAlertData & { isActive?: boolean }>): Promise<{ message: string; alert: PriceAlert }> {
    return apiClient.put(`/api/v1/predictions/alerts/${id}`, data);
  }

  async deletePriceAlert(id: string): Promise<{ message: string }> {
    return apiClient.delete(`/api/v1/predictions/alerts/${id}`);
  }

  // Portfolio Performance
  async getPortfolioPerformance(portfolioId: string, days = 30): Promise<{ performance: PortfolioPerformance[] }> {
    const params = new URLSearchParams();
    params.append('days', String(days));

    return apiClient.get(`/api/v1/predictions/portfolios/${portfolioId}/performance?${params.toString()}`);
  }

  // Analytics
  async getPredictionAccuracy(): Promise<{ accuracy: { averageAccuracy: number; totalPredictions: number; successRate: number } }> {
    return apiClient.get('/api/v1/predictions/analytics/accuracy');
  }

  async getMarketSentiment(): Promise<{ sentiment: Record<string, number> }> {
    return apiClient.get('/api/v1/predictions/analytics/sentiment');
  }

  // Demo Data
  async initDemoPredictions(): Promise<{ message: string; count: number; predictions: Prediction[] }> {
    return apiClient.post('/api/v1/predictions/demo/predictions');
  }

  async initDemoAnalyses(): Promise<{ message: string; count: number; analyses: MarketAnalysis[] }> {
    return apiClient.post('/api/v1/predictions/demo/analyses');
  }

  // Utility Functions
  getPredictionTypeText(type: PredictionType): string {
    switch (type) {
      case 'PRICE_TARGET':
        return '목표가 예측';
      case 'TREND_ANALYSIS':
        return '추세 분석';
      case 'VOLATILITY':
        return '변동성 예측';
      case 'SUPPORT_RESISTANCE':
        return '지지/저항선';
      case 'SENTIMENT':
        return '시장 심리';
      default:
        return type;
    }
  }

  getPredictionTypeColor(type: PredictionType): string {
    switch (type) {
      case 'PRICE_TARGET':
        return '#4CAF50';
      case 'TREND_ANALYSIS':
        return '#2196F3';
      case 'VOLATILITY':
        return '#FF9800';
      case 'SUPPORT_RESISTANCE':
        return '#9C27B0';
      case 'SENTIMENT':
        return '#F44336';
      default:
        return '#666';
    }
  }

  getAnalysisCategoryText(category: AnalysisCategory): string {
    switch (category) {
      case 'TECHNICAL_ANALYSIS':
        return '기술적 분석';
      case 'FUNDAMENTAL_ANALYSIS':
        return '기본적 분석';
      case 'MARKET_OVERVIEW':
        return '시장 전망';
      case 'SECTOR_ANALYSIS':
        return '섹터 분석';
      case 'ECONOMIC_INDICATOR':
        return '경제 지표';
      case 'NEWS_IMPACT':
        return '뉴스 영향';
      default:
        return category;
    }
  }

  getSentimentText(sentiment: MarketSentiment): string {
    switch (sentiment) {
      case 'VERY_BULLISH':
        return '매우 강세';
      case 'BULLISH':
        return '강세';
      case 'NEUTRAL':
        return '중립';
      case 'BEARISH':
        return '약세';
      case 'VERY_BEARISH':
        return '매우 약세';
      default:
        return sentiment;
    }
  }

  getSentimentColor(sentiment: MarketSentiment): string {
    switch (sentiment) {
      case 'VERY_BULLISH':
        return '#2E7D32';
      case 'BULLISH':
        return '#4CAF50';
      case 'NEUTRAL':
        return '#757575';
      case 'BEARISH':
        return '#F44336';
      case 'VERY_BEARISH':
        return '#C62828';
      default:
        return '#666';
    }
  }

  getRiskLevelText(risk: RiskLevel): string {
    switch (risk) {
      case 'VERY_LOW':
        return '매우 낮음';
      case 'LOW':
        return '낮음';
      case 'MODERATE':
        return '보통';
      case 'HIGH':
        return '높음';
      case 'VERY_HIGH':
        return '매우 높음';
      default:
        return risk;
    }
  }

  getRiskLevelColor(risk: RiskLevel): string {
    switch (risk) {
      case 'VERY_LOW':
        return '#4CAF50';
      case 'LOW':
        return '#8BC34A';
      case 'MODERATE':
        return '#FF9800';
      case 'HIGH':
        return '#FF5722';
      case 'VERY_HIGH':
        return '#F44336';
      default:
        return '#666';
    }
  }

  getAlertTypeText(type: AlertType): string {
    switch (type) {
      case 'PRICE_TARGET':
        return '목표가 알림';
      case 'PERCENTAGE_CHANGE':
        return '등락률 알림';
      case 'VOLUME_SPIKE':
        return '거래량 급증';
      case 'TECHNICAL_SIGNAL':
        return '기술적 신호';
      default:
        return type;
    }
  }

  getConditionText(condition: AlertCondition): string {
    switch (condition) {
      case 'ABOVE':
        return '이상';
      case 'BELOW':
        return '이하';
      case 'EQUALS':
        return '도달';
      default:
        return condition;
    }
  }

  formatConfidence(confidence: number): string {
    return `${confidence.toFixed(1)}%`;
  }

  formatAccuracy(accuracy: number): string {
    return `${accuracy.toFixed(1)}%`;
  }

  formatChange(change: number): {
    changeText: string;
    color: string;
    isPositive: boolean;
  } {
    const isPositive = change >= 0;
    const color = isPositive ? '#4CAF50' : '#F44336';
    const changeText = `${isPositive ? '+' : ''}${change.toFixed(2)}%`;

    return {
      changeText,
      color,
      isPositive,
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

  formatTimeframe(timeframe: string): string {
    return timeframe;
  }

  isValidUntil(validUntil: string): boolean {
    return new Date(validUntil) > new Date();
  }

  getDaysUntilExpiry(validUntil: string): number {
    const now = new Date();
    const expiry = new Date(validUntil);
    const diffTime = expiry.getTime() - now.getTime();
    return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  }
}

export default new PredictionService();
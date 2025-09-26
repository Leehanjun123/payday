import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export interface CreatePredictionData {
  symbol: string;
  type: 'PRICE_TARGET' | 'TREND_ANALYSIS' | 'VOLATILITY' | 'SUPPORT_RESISTANCE' | 'SENTIMENT';
  timeframe: string;
  currentPrice: number;
  predictedPrice: number;
  confidence: number;
  reasoning: string;
  factors: any;
  validUntil: Date;
}

export interface CreateAnalysisData {
  symbol?: string;
  title: string;
  summary: string;
  content: string;
  category: 'TECHNICAL_ANALYSIS' | 'FUNDAMENTAL_ANALYSIS' | 'MARKET_OVERVIEW' | 'SECTOR_ANALYSIS' | 'ECONOMIC_INDICATOR' | 'NEWS_IMPACT';
  sentiment: 'VERY_BULLISH' | 'BULLISH' | 'NEUTRAL' | 'BEARISH' | 'VERY_BEARISH';
  riskLevel: 'VERY_LOW' | 'LOW' | 'MODERATE' | 'HIGH' | 'VERY_HIGH';
  tags: any;
  metrics: any;
  recommendations: string;
  authorId?: string;
}

export interface CreatePriceAlertData {
  userId: string;
  symbol: string;
  name: string;
  type: 'PRICE_TARGET' | 'PERCENTAGE_CHANGE' | 'VOLUME_SPIKE' | 'TECHNICAL_SIGNAL';
  targetPrice: number;
  currentPrice: number;
  condition: 'ABOVE' | 'BELOW' | 'EQUALS';
  message?: string;
}

class PredictionService {
  // AI Predictions
  async createPrediction(data: CreatePredictionData) {
    return await prisma.prediction.create({
      data,
    });
  }

  async getPredictions(symbol?: string, type?: string, limit = 20) {
    const where: any = {};
    if (symbol) where.symbol = symbol;
    if (type) where.type = type;

    return await prisma.prediction.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }

  async getPredictionById(id: string) {
    return await prisma.prediction.findUnique({
      where: { id },
      include: {
        alerts: true,
      },
    });
  }

  async updatePrediction(id: string, data: Partial<CreatePredictionData & { actualPrice?: number; accuracy?: number; status?: string }>) {
    return await prisma.prediction.update({
      where: { id },
      data: data as any,
    });
  }

  async verifyPredictions() {
    const predictions = await prisma.prediction.findMany({
      where: {
        status: 'ACTIVE',
        validUntil: {
          lte: new Date(),
        },
      },
    });

    for (const prediction of predictions) {
      const marketData = await prisma.marketData.findUnique({
        where: { symbol: prediction.symbol },
      });

      if (marketData) {
        const actualPrice = marketData.currentPrice;
        const accuracy = this.calculateAccuracy(prediction.predictedPrice, actualPrice, prediction.currentPrice);

        await this.updatePrediction(prediction.id, {
          actualPrice,
          accuracy,
          status: accuracy > 70 ? 'VERIFIED' : 'FAILED',
        });
      }
    }
  }

  private calculateAccuracy(predicted: number, actual: number, initial: number): number {
    const predictedChange = predicted - initial;
    const actualChange = actual - initial;

    if (predictedChange === 0 && actualChange === 0) return 100;
    if (predictedChange === 0 || actualChange === 0) return 0;

    const accuracy = 100 - Math.abs((predictedChange - actualChange) / Math.abs(predictedChange)) * 100;
    return Math.max(0, Math.min(100, accuracy));
  }

  // Market Analysis
  async createAnalysis(data: CreateAnalysisData) {
    return await prisma.marketAnalysis.create({
      data: {
        ...data,
        isPublished: true,
      },
    });
  }

  async getAnalyses(symbol?: string, category?: string, limit = 20) {
    const where: any = { isPublished: true };
    if (symbol) where.symbol = symbol;
    if (category) where.category = category;

    return await prisma.marketAnalysis.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: limit,
    });
  }

  async getAnalysisById(id: string) {
    const analysis = await prisma.marketAnalysis.findUnique({
      where: { id },
      include: {
        alerts: true,
      },
    });

    if (analysis) {
      await prisma.marketAnalysis.update({
        where: { id },
        data: { viewCount: { increment: 1 } },
      });
    }

    return analysis;
  }

  async likeAnalysis(id: string) {
    return await prisma.marketAnalysis.update({
      where: { id },
      data: { likeCount: { increment: 1 } },
    });
  }

  // Price Alerts
  async createPriceAlert(data: CreatePriceAlertData) {
    return await prisma.priceAlert.create({
      data,
    });
  }

  async getUserPriceAlerts(userId: string) {
    return await prisma.priceAlert.findMany({
      where: { userId, isActive: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updatePriceAlert(id: string, data: Partial<CreatePriceAlertData & { isActive?: boolean; isTriggered?: boolean }>) {
    return await prisma.priceAlert.update({
      where: { id },
      data,
    });
  }

  async deletePriceAlert(id: string) {
    return await prisma.priceAlert.delete({
      where: { id },
    });
  }

  async checkPriceAlerts() {
    const alerts = await prisma.priceAlert.findMany({
      where: {
        isActive: true,
        isTriggered: false,
      },
      include: {
        user: true,
      },
    });

    for (const alert of alerts) {
      const marketData = await prisma.marketData.findUnique({
        where: { symbol: alert.symbol },
      });

      if (marketData) {
        const shouldTrigger = this.shouldTriggerAlert(alert, marketData.currentPrice);

        if (shouldTrigger) {
          await this.updatePriceAlert(alert.id, {
            isTriggered: true,
            currentPrice: marketData.currentPrice,
          });

          // Create notification
          await prisma.notification.create({
            data: {
              userId: alert.userId,
              type: 'SYSTEM',
              title: '가격 알림',
              message: `${alert.name}이(가) ${alert.targetPrice.toLocaleString()}원 ${this.getConditionText(alert.condition)}에 도달했습니다.`,
              data: {
                alertId: alert.id,
                symbol: alert.symbol,
                currentPrice: marketData.currentPrice,
                targetPrice: alert.targetPrice,
              },
            },
          });
        }
      }
    }
  }

  private shouldTriggerAlert(alert: any, currentPrice: number): boolean {
    switch (alert.condition) {
      case 'ABOVE':
        return currentPrice >= alert.targetPrice;
      case 'BELOW':
        return currentPrice <= alert.targetPrice;
      case 'EQUALS':
        return Math.abs(currentPrice - alert.targetPrice) / alert.targetPrice < 0.01; // 1% 오차 허용
      default:
        return false;
    }
  }

  private getConditionText(condition: string): string {
    switch (condition) {
      case 'ABOVE': return '이상';
      case 'BELOW': return '이하';
      case 'EQUALS': return '도달';
      default: return '';
    }
  }

  // Portfolio Performance Tracking
  async recordPortfolioPerformance(portfolioId: string) {
    const portfolio = await prisma.portfolio.findUnique({
      where: { id: portfolioId },
      include: {
        holdings: true,
      },
    });

    if (!portfolio) return null;

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Check if performance already recorded for today
    const existingRecord = await prisma.portfolioPerformance.findUnique({
      where: {
        portfolioId_date: {
          portfolioId,
          date: today,
        },
      },
    });

    if (existingRecord) return existingRecord;

    // Calculate performance metrics
    let totalValue = 0;
    for (const holding of portfolio.holdings) {
      const marketData = await prisma.marketData.findUnique({
        where: { symbol: holding.symbol },
      });
      if (marketData) {
        totalValue += holding.quantity * marketData.currentPrice;
      }
    }

    // Get yesterday's performance for comparison
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    const yesterdayPerformance = await prisma.portfolioPerformance.findUnique({
      where: {
        portfolioId_date: {
          portfolioId,
          date: yesterday,
        },
      },
    });

    const dayChange = yesterdayPerformance ? totalValue - yesterdayPerformance.totalValue : 0;
    const dayChangePercent = yesterdayPerformance && yesterdayPerformance.totalValue > 0
      ? (dayChange / yesterdayPerformance.totalValue) * 100
      : 0;

    return await prisma.portfolioPerformance.create({
      data: {
        portfolioId,
        date: today,
        totalValue,
        totalCost: portfolio.totalCost,
        dayChange,
        dayChangePercent,
        benchmark: 'KOSPI', // Default benchmark
        benchmarkReturn: 0, // Would calculate from actual index data
      },
    });
  }

  async getPortfolioPerformanceHistory(portfolioId: string, days = 30) {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    return await prisma.portfolioPerformance.findMany({
      where: {
        portfolioId,
        date: {
          gte: startDate,
          lte: endDate,
        },
      },
      orderBy: { date: 'asc' },
    });
  }

  // Demo Data Creation
  async initDemoPredictions() {
    const symbols = ['AAPL', 'TSLA', 'NVDA', '삼성전자', '네이버', 'BTC', 'ETH'];
    const predictions = [];

    for (const symbol of symbols) {
      const marketData = await prisma.marketData.findUnique({
        where: { symbol },
      });

      if (marketData) {
        // Create price target prediction
        const targetPrice = marketData.currentPrice * (1 + (Math.random() * 0.4 - 0.2)); // ±20% variation
        const confidence = 60 + Math.random() * 35; // 60-95% confidence

        const prediction = await this.createPrediction({
          symbol,
          type: 'PRICE_TARGET',
          timeframe: '1개월',
          currentPrice: marketData.currentPrice,
          predictedPrice: targetPrice,
          confidence,
          reasoning: this.generateDemoReasoning(symbol, targetPrice > marketData.currentPrice),
          factors: {
            technical: ['이동평균선 돌파', 'RSI 과매도 구간'],
            fundamental: ['실적 개선 전망', '신규 사업 확장'],
            market: ['시장 심리 개선', '기관 투자자 유입'],
          },
          validUntil: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30 days
        });

        predictions.push(prediction);
      }
    }

    return predictions;
  }

  async initDemoAnalyses() {
    const analyses = [];

    // Market overview analysis
    analyses.push(await this.createAnalysis({
      title: '2024년 4분기 글로벌 시장 전망',
      summary: '연말 랠리 기대감과 금리 인하 가능성으로 긍정적 전망',
      content: `글로벌 주식시장이 연말을 앞두고 상승 모멘텀을 보이고 있습니다. 주요 요인은 다음과 같습니다:

1. 중앙은행 금리 정책 변화 기대
2. 기업 실적 개선 전망
3. 지정학적 리스크 완화
4. 연말 포트폴리오 리밸런싱 수요

투자 전략: 성장주와 가치주 균형 투자, 변동성에 대비한 리스크 관리`,
      category: 'MARKET_OVERVIEW',
      sentiment: 'BULLISH',
      riskLevel: 'MODERATE',
      tags: ['글로벌시장', '연말랠리', '금리정책', '투자전략'],
      metrics: {
        sp500_target: 4800,
        kospi_target: 2650,
        usd_krw_target: 1280,
      },
      recommendations: '성장주 50%, 가치주 30%, 현금 20% 비중 권장',
    }));

    // Tech sector analysis
    analyses.push(await this.createAnalysis({
      symbol: 'AAPL',
      title: '애플(AAPL) 기술적 분석 - 상승 트렌드 지속',
      summary: '200일 이동평균선 상향 돌파로 상승 모멘텀 강화',
      content: `애플 주가가 주요 기술적 저항선을 돌파하며 상승세를 보이고 있습니다.

기술적 지표 분석:
- RSI: 65 (중립-강세 구간)
- MACD: 골든크로스 형성
- 볼린저밴드: 상단 밴드 접근
- 거래량: 평균 대비 120% 증가

목표가: $195 (현재가 대비 +8%)
지지선: $175, $170
저항선: $185, $190`,
      category: 'TECHNICAL_ANALYSIS',
      sentiment: 'BULLISH',
      riskLevel: 'LOW',
      tags: ['애플', '기술적분석', '상승돌파', '목표가'],
      metrics: {
        rsi: 65,
        macd: 'bullish',
        volume: 1.2,
        target_price: 195,
      },
      recommendations: '단기 매수 적기, 익절 목표 $190-195',
    }));

    return analyses;
  }

  private generateDemoReasoning(symbol: string, isPositive: boolean): string {
    const positive = [
      '기술적 지표 상승 신호 감지',
      '거래량 증가로 매수세 유입',
      '주요 이동평균선 상향 돌파',
      '시장 심리 개선으로 상승 모멘텀 기대',
    ];

    const negative = [
      '과매수 구간 진입으로 조정 가능성',
      '거래량 감소로 상승 동력 약화',
      '주요 저항선 접근으로 매도압력 예상',
      '시장 불확실성 증가로 하락 리스크',
    ];

    const reasons = isPositive ? positive : negative;
    return reasons[Math.floor(Math.random() * reasons.length)];
  }

  // Analytics and Insights
  async getPredictionAccuracy() {
    const verifiedPredictions = await prisma.prediction.findMany({
      where: {
        status: { in: ['VERIFIED', 'FAILED'] },
        accuracy: { not: null },
      },
    });

    if (verifiedPredictions.length === 0) return { averageAccuracy: 0, totalPredictions: 0 };

    const totalAccuracy = verifiedPredictions.reduce((sum, p) => sum + (p.accuracy || 0), 0);
    return {
      averageAccuracy: totalAccuracy / verifiedPredictions.length,
      totalPredictions: verifiedPredictions.length,
      successRate: verifiedPredictions.filter(p => p.status === 'VERIFIED').length / verifiedPredictions.length * 100,
    };
  }

  async getMarketSentimentOverview() {
    const recentAnalyses = await prisma.marketAnalysis.findMany({
      where: {
        isPublished: true,
        createdAt: {
          gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), // Last 7 days
        },
      },
      select: { sentiment: true },
    });

    const sentimentCounts = recentAnalyses.reduce((acc, analysis) => {
      acc[analysis.sentiment] = (acc[analysis.sentiment] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    return sentimentCounts;
  }
}

export default new PredictionService();
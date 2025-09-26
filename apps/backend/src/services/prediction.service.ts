import { prisma } from '../lib/prisma';

interface PredictionMarket {
  id: string;
  title: string;
  description: string;
  category: 'STOCK' | 'CRYPTO' | 'SPORTS' | 'WEATHER' | 'POLITICS' | 'ENTERTAINMENT';
  options: PredictionOption[];
  endDate: Date;
  totalPool: number;
  status: 'OPEN' | 'CLOSED' | 'RESOLVED';
}

interface PredictionOption {
  id: string;
  title: string;
  odds: number;
  totalBets: number;
  probability: number;
}

interface UserPrediction {
  userId: string;
  marketId: string;
  optionId: string;
  amount: number;
  potentialReturn: number;
  timestamp: Date;
}

class PredictionService {
  private static instance: PredictionService;

  static getInstance(): PredictionService {
    if (!PredictionService.instance) {
      PredictionService.instance = new PredictionService();
    }
    return PredictionService.instance;
  }

  // 예측 마켓 생성
  async createMarket(market: Omit<PredictionMarket, 'id' | 'totalPool' | 'status'>): Promise<PredictionMarket> {
    const newMarket: PredictionMarket = {
      id: `market_${Date.now()}`,
      ...market,
      totalPool: 0,
      status: 'OPEN'
    };

    // 실제 한국 시장 예시
    const examples = [
      {
        title: "내일 KOSPI 상승/하락",
        category: "STOCK",
        reward: { min: 0.05, max: 0.20 }, // $0.05~0.20 (65원~260원)
      },
      {
        title: "이번 주 비트코인 가격",
        category: "CRYPTO",
        reward: { min: 0.10, max: 0.50 }, // $0.10~0.50 (130원~650원)
      },
      {
        title: "K리그 경기 결과",
        category: "SPORTS",
        reward: { min: 0.10, max: 1.00 }, // $0.10~1.00 (130원~1,300원)
      }
    ];

    console.log('Market created:', newMarket);
    return newMarket;
  }

  // 사용자 예측 참여
  async placePrediction(prediction: UserPrediction): Promise<{success: boolean, potential: number}> {
    // 최소 베팅: $0.01 (13원)
    // 최대 베팅: $10.00 (13,000원)
    const minBet = 0.01;
    const maxBet = 10.00;

    if (prediction.amount < minBet || prediction.amount > maxBet) {
      throw new Error(`베팅 금액은 $${minBet}~$${maxBet} 사이여야 합니다`);
    }

    // 배당률 계산 (2~10배)
    const odds = this.calculateOdds(prediction.optionId);
    const potentialReturn = prediction.amount * odds;

    // 플랫폼 수수료 5%
    const platformFee = prediction.amount * 0.05;

    return {
      success: true,
      potential: potentialReturn
    };
  }

  private calculateOdds(optionId: string): number {
    // 실제 확률 기반 배당률 계산
    // 인기 없는 선택지일수록 높은 배당률
    return Math.random() * 8 + 2; // 2~10배
  }
}

export default PredictionService;
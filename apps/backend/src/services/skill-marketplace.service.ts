import { prisma } from '../lib/prisma';

// 재능/시간 거래 플랫폼 (크몽, 숨고 형태)
interface SkillListing {
  id: string;
  sellerId: string;
  title: string;
  category: 'TRANSLATION' | 'DESIGN' | 'CODING' | 'TUTORING' | 'CONSULTING';
  pricePerHour: number; // $5~50 (6,500~65,000원)
  description: string;
  deliveryTime: number; // hours
  rating: number;
  completedOrders: number;
}

interface MicroTask {
  id: string;
  title: string;
  description: string;
  reward: number; // $0.10~5.00
  timeEstimate: number; // minutes
  category: 'DATA_ENTRY' | 'TRANSCRIPTION' | 'REVIEW' | 'SURVEY' | 'TESTING';
  requiredSkills: string[];
}

class SkillMarketplaceService {
  private static instance: SkillMarketplaceService;

  static getInstance(): SkillMarketplaceService {
    if (!SkillMarketplaceService.instance) {
      SkillMarketplaceService.instance = new SkillMarketplaceService();
    }
    return SkillMarketplaceService.instance;
  }

  // 마이크로 태스크 완료
  async completeMicroTask(userId: string, taskId: string): Promise<number> {
    const tasks = {
      'EXCEL_데이터정리': { reward: 2.00, time: 30 }, // $2 (2,600원)
      'PDF_텍스트변환': { reward: 1.00, time: 15 }, // $1 (1,300원)
      '음성_텍스트변환': { reward: 3.00, time: 20 }, // $3 (3,900원)
      '이미지_태깅': { reward: 0.50, time: 5 }, // $0.50 (650원)
      '번역_검수': { reward: 5.00, time: 60 }, // $5 (6,500원)
    };

    // 플랫폼 수수료 20%
    const platformFee = 0.20;
    const userReward = 2.00 * (1 - platformFee); // 예시

    return userReward;
  }

  // 시간 거래 (Time Banking)
  async tradeTime(userId: string, hours: number, skill: string): Promise<number> {
    // 1시간 봉사 = 1 타임크레딧
    // 1 타임크레딧 = $5 가치
    const timeCredit = hours;
    const creditValue = 5.00; // $5 per hour

    return timeCredit * creditValue;
  }
}
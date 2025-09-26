import { prisma } from '../lib/prisma';

// 합법적인 리워드형 크라우드펀딩 (금융투자 아님)
interface CrowdfundingProject {
  id: string;
  title: string;
  description: string;
  targetAmount: number;
  currentAmount: number;
  minContribution: number; // 최소 $1 (1,300원)
  maxContribution: number; // 최대 $100 (130,000원)
  rewards: ProjectReward[];
  deadline: Date;
  status: 'ACTIVE' | 'FUNDED' | 'FAILED';
}

interface ProjectReward {
  contributionAmount: number;
  rewardDescription: string;
  estimatedDelivery: Date;
  limitedQuantity?: number;
}

class CrowdfundingService {
  private static instance: CrowdfundingService;

  static getInstance(): CrowdfundingService {
    if (!CrowdfundingService.instance) {
      CrowdfundingService.instance = new CrowdfundingService();
    }
    return CrowdfundingService.instance;
  }

  // 리워드형 펀딩 참여 (투자가 아닌 구매)
  async participateInProject(userId: string, projectId: string, amount: number) {
    // 리워드형은 합법 (상품 선구매 개념)
    // 사용자: 할인된 가격으로 상품 구매
    // 플랫폼: 중개 수수료 5~10%

    const platformFee = amount * 0.08;
    const projectContribution = amount - platformFee;

    return {
      userId,
      projectId,
      contribution: projectContribution,
      platformFee,
      expectedReward: '프로젝트 성공 시 리워드 발송'
    };
  }
}
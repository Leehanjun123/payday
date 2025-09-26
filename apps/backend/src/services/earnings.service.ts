import AdMobService from './admob.service';
import SurveyService from './survey.service';
import FirebaseService from './firebase.service';
import { prisma } from '../lib/prisma';

interface EarningStream {
  id: string;
  type: 'AD_REWARD' | 'SURVEY' | 'CASHBACK' | 'REFERRAL' | 'DAILY_BONUS' | 'STREAK_BONUS' | 'ACHIEVEMENT' | 'PROMOTION';
  amount: number;
  currency: string;
  timestamp: Date;
  status: 'pending' | 'confirmed' | 'paid';
  metadata?: any;
}

interface UserBalance {
  userId: string;
  totalBalance: number;
  pendingBalance: number;
  lifetimeEarnings: number;
  lastUpdated: Date;
}

interface WithdrawalRequest {
  userId: string;
  amount: number;
  method: 'TOSS_PAY' | 'BANK_TRANSFER' | 'PAYPAL';
  status: 'pending' | 'processing' | 'completed' | 'failed';
  requestedAt: Date;
  processedAt?: Date;
}

class EarningsService {
  private static instance: EarningsService;
  private adMobService: AdMobService;
  private surveyService: SurveyService;
  private firebaseService: FirebaseService;

  private constructor() {
    this.adMobService = AdMobService.getInstance();
    this.surveyService = SurveyService.getInstance();
    this.firebaseService = FirebaseService.getInstance();
  }

  static getInstance(): EarningsService {
    if (!EarningsService.instance) {
      EarningsService.instance = new EarningsService();
    }
    return EarningsService.instance;
  }

  // Process ad reward
  async processAdReward(userId: string, adUnitId: string, adType: string): Promise<EarningStream> {
    try {
      const reward = await this.adMobService.processRewardedAd(userId, adUnitId);

      const earning: EarningStream = {
        id: this.generateEarningId(),
        type: 'AD_REWARD',
        amount: reward.rewardAmount,
        currency: 'USD',
        timestamp: new Date(),
        status: 'confirmed',
        metadata: {
          adUnitId,
          adType,
          provider: 'GOOGLE_ADMOB',
        },
      };

      await this.recordEarning(userId, earning);
      await this.updateUserBalance(userId, earning.amount);

      // Send notification
      await this.sendEarningNotification(userId, earning);

      return earning;
    } catch (error) {
      console.error('Error processing ad reward:', error);
      throw error;
    }
  }

  // Process survey completion
  async processSurveyReward(
    userId: string,
    surveyId: string,
    provider: string,
    transactionId: string
  ): Promise<EarningStream> {
    try {
      const completion = await this.surveyService.processSurveyCompletion(
        userId,
        surveyId,
        provider,
        transactionId
      );

      const earning: EarningStream = {
        id: this.generateEarningId(),
        type: 'SURVEY',
        amount: completion.reward,
        currency: 'USD',
        timestamp: new Date(),
        status: completion.verified ? 'confirmed' : 'pending',
        metadata: {
          surveyId,
          provider,
          transactionId,
        },
      };

      await this.recordEarning(userId, earning);

      if (earning.status === 'confirmed') {
        await this.updateUserBalance(userId, earning.amount);
        await this.sendEarningNotification(userId, earning);
      }

      return earning;
    } catch (error) {
      console.error('Error processing survey reward:', error);
      throw error;
    }
  }

  // Process referral bonus
  async processReferralBonus(referrerId: string, refereeId: string, bonusType: string): Promise<EarningStream> {
    try {
      let bonusAmount = 0;

      switch (bonusType) {
        case 'SIGNUP':
          bonusAmount = 5.00; // $5 for successful referral signup
          break;
        case 'FIRST_EARNING':
          bonusAmount = 2.00; // $2 when referee earns their first dollar
          break;
        case 'MILESTONE':
          bonusAmount = 10.00; // $10 when referee reaches $25 earned
          break;
        default:
          bonusAmount = 1.00;
      }

      const earning: EarningStream = {
        id: this.generateEarningId(),
        type: 'REFERRAL',
        amount: bonusAmount,
        currency: 'USD',
        timestamp: new Date(),
        status: 'confirmed',
        metadata: {
          refereeId,
          bonusType,
        },
      };

      await this.recordEarning(referrerId, earning);
      await this.updateUserBalance(referrerId, earning.amount);
      await this.sendEarningNotification(referrerId, earning);

      return earning;
    } catch (error) {
      console.error('Error processing referral bonus:', error);
      throw error;
    }
  }

  // Process daily login bonus
  async processDailyBonus(userId: string, streakDays: number): Promise<EarningStream> {
    try {
      // 실제 앱들의 일일 보너스 (캐시워크, 허니스크린 참고)
      let bonusAmount = 0.001; // Base $0.001 (1.3원)

      if (streakDays >= 7) bonusAmount = 0.002; // $0.002 for week streak (2.6원)
      if (streakDays >= 30) bonusAmount = 0.003; // $0.003 for month streak (3.9원)
      if (streakDays >= 100) bonusAmount = 0.005; // $0.005 for 100 day streak (6.5원)

      const earning: EarningStream = {
        id: this.generateEarningId(),
        type: 'DAILY_BONUS',
        amount: bonusAmount,
        currency: 'USD',
        timestamp: new Date(),
        status: 'confirmed',
        metadata: {
          bonusType: 'DAILY_LOGIN',
          streakDays,
        },
      };

      await this.recordEarning(userId, earning);
      await this.updateUserBalance(userId, earning.amount);

      return earning;
    } catch (error) {
      console.error('Error processing daily bonus:', error);
      throw error;
    }
  }

  // Get user balance
  async getUserBalance(userId: string): Promise<UserBalance> {
    try {
      let balance = await prisma.userBalance.findUnique({
        where: { userId }
      });

      if (!balance) {
        // Create initial balance for new user
        balance = await prisma.userBalance.create({
          data: {
            userId,
            totalBalance: 0,
            pendingBalance: 0,
            lifetimeEarnings: 0,
            withdrawnAmount: 0,
            currency: 'USD'
          }
        });
      }

      return {
        userId: balance.userId,
        totalBalance: balance.totalBalance,
        pendingBalance: balance.pendingBalance,
        lifetimeEarnings: balance.lifetimeEarnings,
        lastUpdated: balance.lastUpdated,
      };
    } catch (error) {
      console.error('Error getting user balance:', error);
      throw error;
    }
  }

  // Get earning history
  async getEarningHistory(userId: string, limit: number = 50): Promise<EarningStream[]> {
    try {
      const earnings = await prisma.earning.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: limit
      });

      return earnings.map(earning => ({
        id: earning.id,
        type: earning.type as EarningStream['type'],
        amount: earning.amount,
        currency: earning.currency,
        timestamp: earning.createdAt,
        status: earning.status.toLowerCase() as EarningStream['status'],
        metadata: earning.metadata || { source: earning.source },
      }));
    } catch (error) {
      console.error('Error getting earning history:', error);
      throw error;
    }
  }

  // Request withdrawal
  async requestWithdrawal(
    userId: string,
    amount: number,
    method: 'TOSS_PAY' | 'BANK_TRANSFER' | 'PAYPAL'
  ): Promise<WithdrawalRequest> {
    try {
      // Validate withdrawal request
      const balance = await this.getUserBalance(userId);
      if (amount > balance.totalBalance) {
        throw new Error('Insufficient balance');
      }

      if (amount < 10.00) {
        throw new Error('Minimum withdrawal amount is $10');
      }

      const withdrawalRequest: WithdrawalRequest = {
        userId,
        amount,
        method,
        status: 'pending',
        requestedAt: new Date(),
      };

      // In production, this would:
      // 1. Save to database
      // 2. Deduct from user balance
      // 3. Queue for processing
      // 4. Send confirmation notification

      console.log('Withdrawal Request Created:', withdrawalRequest);

      return withdrawalRequest;
    } catch (error) {
      console.error('Error requesting withdrawal:', error);
      throw error;
    }
  }

  // Get earning statistics
  async getEarningStats(userId: string, period: 'daily' | 'weekly' | 'monthly' = 'daily') {
    try {
      const mockStats = {
        daily: {
          totalEarnings: 8.45,
          adRewards: 2.15,
          surveyRewards: 5.50,
          bonuses: 0.80,
          transactionCount: 12,
        },
        weekly: {
          totalEarnings: 52.30,
          adRewards: 15.75,
          surveyRewards: 31.50,
          bonuses: 5.05,
          transactionCount: 78,
        },
        monthly: {
          totalEarnings: 234.25,
          adRewards: 67.80,
          surveyRewards: 145.60,
          bonuses: 20.85,
          transactionCount: 342,
        },
      };

      return mockStats[period];
    } catch (error) {
      console.error('Error getting earning stats:', error);
      throw error;
    }
  }

  // Private helper methods
  private generateEarningId(): string {
    return `earn_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  private async recordEarning(userId: string, earning: EarningStream) {
    try {
      await prisma.earning.create({
        data: {
          id: earning.id,
          userId,
          type: earning.type,
          amount: earning.amount,
          currency: earning.currency,
          status: earning.status.toUpperCase() as any,
          source: earning.metadata?.provider || earning.metadata?.source || 'UNKNOWN',
          transactionId: earning.metadata?.transactionId,
          metadata: earning.metadata,
        }
      });

      console.log('Earning recorded successfully:', earning.id);
    } catch (error) {
      console.error('Error recording earning:', error);
      throw error;
    }
  }

  private async updateUserBalance(userId: string, amount: number) {
    try {
      await prisma.userBalance.upsert({
        where: { userId },
        update: {
          totalBalance: { increment: amount },
          lifetimeEarnings: { increment: amount },
        },
        create: {
          userId,
          totalBalance: amount,
          pendingBalance: 0,
          lifetimeEarnings: amount,
          withdrawnAmount: 0,
          currency: 'USD'
        }
      });

      console.log('User balance updated:', { userId, amount });
    } catch (error) {
      console.error('Error updating user balance:', error);
      throw error;
    }
  }

  private async sendEarningNotification(userId: string, earning: EarningStream) {
    try {
      const title = this.getNotificationTitle(earning.type);
      const body = `You earned $${earning.amount.toFixed(2)}!`;

      // In production, this would send via Firebase
      console.log('Sending Earning Notification:', {
        userId,
        title,
        body,
        earning: earning.id,
      });
    } catch (error) {
      console.error('Error sending earning notification:', error);
    }
  }

  private getNotificationTitle(type: EarningStream['type']): string {
    switch (type) {
      case 'AD_REWARD':
        return '💰 Ad Reward Earned!';
      case 'SURVEY':
        return '📋 Survey Completed!';
      case 'CASHBACK':
        return '💳 Cashback Earned!';
      case 'REFERRAL':
        return '👥 Referral Bonus!';
      case 'DAILY_BONUS':
      case 'STREAK_BONUS':
        return '🎁 Bonus Earned!';
      case 'ACHIEVEMENT':
        return '🏆 Achievement Unlocked!';
      case 'PROMOTION':
        return '🎉 Promotion Reward!';
      default:
        return '💰 Reward Earned!';
    }
  }
}

export default EarningsService;
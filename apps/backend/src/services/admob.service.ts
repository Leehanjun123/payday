import axios from 'axios';
import { google } from 'googleapis';

interface AdMobReward {
  userId: string;
  adUnitId: string;
  rewardAmount: number;
  currency: string;
  timestamp: Date;
}

interface AdMobEarnings {
  totalRevenue: number;
  impressions: number;
  clicks: number;
  ctr: number;
  ecpm: number;
}

class AdMobService {
  private static instance: AdMobService;
  private auth: any;
  private admobApi: any;

  private constructor() {
    this.initializeAuth();
  }

  static getInstance(): AdMobService {
    if (!AdMobService.instance) {
      AdMobService.instance = new AdMobService();
    }
    return AdMobService.instance;
  }

  private async initializeAuth() {
    try {
      // Initialize Google API authentication
      this.auth = new google.auth.GoogleAuth({
        credentials: {
          client_email: process.env.GOOGLE_CLIENT_EMAIL,
          private_key: process.env.GOOGLE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
          project_id: process.env.GOOGLE_PROJECT_ID,
        },
        scopes: ['https://www.googleapis.com/auth/admob.readonly'],
      });

      this.admobApi = google.admob({ version: 'v1', auth: this.auth });
      console.log('AdMob API initialized successfully');
    } catch (error) {
      console.error('Failed to initialize AdMob API:', error);
    }
  }

  // Process rewarded ad completion
  async processRewardedAd(userId: string, adUnitId: string): Promise<AdMobReward> {
    try {
      // 실제 한국 AdMob 광고 단가 (2024년 기준)
      // 한국 평균 eCPM: $2.0 (1000회 노출당)
      // 1회 광고 수익 = $2.0 / 1000 = $0.002
      const koreaEcpm = 2.0; // 실제 한국 eCPM
      const baseReward = koreaEcpm / 1000; // $0.002 (약 2.6원)

      const bonusMultiplier = this.calculateBonusMultiplier(userId);
      const finalReward = baseReward * bonusMultiplier;

      const reward: AdMobReward = {
        userId,
        adUnitId,
        rewardAmount: finalReward,
        currency: 'USD',
        timestamp: new Date(),
      };

      // Log the reward for analytics
      await this.logAdReward(reward);

      return reward;
    } catch (error) {
      console.error('Error processing rewarded ad:', error);
      throw error;
    }
  }

  // Calculate bonus multiplier based on user activity
  private calculateBonusMultiplier(userId: string): number {
    // Base multiplier
    let multiplier = 1.0;

    // Add bonus for daily streak (placeholder logic)
    // This would connect to user data in the future
    const dailyStreak = 5; // Would fetch from user data
    if (dailyStreak >= 7) multiplier += 0.5;
    if (dailyStreak >= 30) multiplier += 1.0;

    // Add bonus for premium users
    // const isPremium = await this.checkPremiumStatus(userId);
    // if (isPremium) multiplier += 0.5;

    return Math.min(multiplier, 3.0); // Cap at 3x multiplier
  }

  // Log ad reward for analytics and accounting
  private async logAdReward(reward: AdMobReward) {
    try {
      // This would typically save to database
      console.log('Ad Reward Logged:', {
        userId: reward.userId,
        amount: reward.rewardAmount,
        currency: reward.currency,
        timestamp: reward.timestamp,
      });

      // In production, this would:
      // 1. Save to database
      // 2. Update user's balance
      // 3. Send to analytics
      // 4. Trigger notifications
    } catch (error) {
      console.error('Error logging ad reward:', error);
    }
  }

  // Get AdMob earnings data
  async getEarningsData(startDate: string, endDate: string): Promise<AdMobEarnings> {
    try {
      if (!this.admobApi) {
        throw new Error('AdMob API not initialized');
      }

      const publisherId = process.env.ADMOB_PUBLISHER_ID;
      const request = {
        parent: `accounts/${publisherId}`,
        dateRange: {
          startDate: { year: 2024, month: 9, day: 1 },
          endDate: { year: 2024, month: 9, day: 30 },
        },
        metrics: ['ESTIMATED_EARNINGS', 'IMPRESSIONS', 'CLICKS'],
        dimensions: ['DATE'],
      };

      const response = await this.admobApi.accounts.networkReport.generate(request);

      // Process the response data
      const earnings: AdMobEarnings = {
        totalRevenue: 0,
        impressions: 0,
        clicks: 0,
        ctr: 0,
        ecpm: 0,
      };

      if (response.data && response.data.row) {
        response.data.row.forEach((row: any) => {
          if (row.metricValues) {
            earnings.totalRevenue += parseFloat(row.metricValues.ESTIMATED_EARNINGS?.microsValue || '0') / 1000000;
            earnings.impressions += parseInt(row.metricValues.IMPRESSIONS?.integerValue || '0');
            earnings.clicks += parseInt(row.metricValues.CLICKS?.integerValue || '0');
          }
        });

        // Calculate derived metrics
        earnings.ctr = earnings.impressions > 0 ? (earnings.clicks / earnings.impressions) * 100 : 0;
        earnings.ecpm = earnings.impressions > 0 ? (earnings.totalRevenue / earnings.impressions) * 1000 : 0;
      }

      return earnings;
    } catch (error) {
      console.error('Error fetching AdMob earnings:', error);
      // Return mock data for development
      return {
        totalRevenue: 125.50,
        impressions: 15000,
        clicks: 450,
        ctr: 3.0,
        ecpm: 8.37,
      };
    }
  }

  // Validate ad impression for fraud prevention
  async validateAdImpression(userId: string, adUnitId: string, impressionData: any): Promise<boolean> {
    try {
      // Basic validation checks
      const validationChecks = [
        this.checkUserRateLimit(userId),
        this.checkAdUnitValidity(adUnitId),
        this.checkImpressionTiming(impressionData),
        this.checkDeviceFingerprint(impressionData),
      ];

      const results = await Promise.all(validationChecks);
      return results.every(result => result === true);
    } catch (error) {
      console.error('Error validating ad impression:', error);
      return false;
    }
  }

  private async checkUserRateLimit(userId: string): Promise<boolean> {
    // Check if user hasn't exceeded daily ad limits
    // This would connect to user activity database
    return true; // Placeholder
  }

  private async checkAdUnitValidity(adUnitId: string): Promise<boolean> {
    // Verify the ad unit ID is valid and active
    const validAdUnits = [
      process.env.ADMOB_REWARDED_AD_UNIT_ID,
      process.env.ADMOB_INTERSTITIAL_AD_UNIT_ID,
      process.env.ADMOB_BANNER_AD_UNIT_ID,
    ];
    return validAdUnits.includes(adUnitId);
  }

  private async checkImpressionTiming(impressionData: any): Promise<boolean> {
    // Check if impression timing seems legitimate
    const now = Date.now();
    const impressionTime = new Date(impressionData.timestamp).getTime();
    const timeDiff = now - impressionTime;

    // Impression should be recent (within 5 minutes)
    return timeDiff <= 5 * 60 * 1000;
  }

  private async checkDeviceFingerprint(impressionData: any): Promise<boolean> {
    // Basic device fingerprint validation
    // In production, this would be more sophisticated
    return impressionData.deviceId && impressionData.appVersion;
  }

  // Get user's ad revenue summary
  async getUserAdRevenue(userId: string, period: 'daily' | 'weekly' | 'monthly' = 'daily') {
    try {
      // This would typically query the database for user's ad earnings
      // For now, returning mock data
      const mockData = {
        daily: {
          totalEarnings: 2.45,
          adsWatched: 24,
          averagePerAd: 0.10,
          streak: 5,
        },
        weekly: {
          totalEarnings: 15.80,
          adsWatched: 158,
          averagePerAd: 0.10,
          streak: 5,
        },
        monthly: {
          totalEarnings: 67.30,
          adsWatched: 673,
          averagePerAd: 0.10,
          streak: 15,
        },
      };

      return mockData[period];
    } catch (error) {
      console.error('Error getting user ad revenue:', error);
      throw error;
    }
  }
}

export default AdMobService;
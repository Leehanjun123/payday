import axios from 'axios';

interface Survey {
  id: string;
  title: string;
  description: string;
  estimatedMinutes: number;
  reward: number;
  currency: string;
  provider: 'CPX_RESEARCH' | 'PANEL_NOW' | 'POLLFISH' | 'THEOREM_REACH';
  category: string;
  targetCountry: string;
  minimumAge: number;
  status: 'available' | 'completed' | 'expired';
}

interface SurveyCompletion {
  userId: string;
  surveyId: string;
  provider: string;
  completedAt: Date;
  reward: number;
  verified: boolean;
}

class SurveyService {
  private static instance: SurveyService;
  private apiEndpoints = {
    CPX_RESEARCH: 'https://offers.cpx-research.com/index.php',
    PANEL_NOW: 'https://api.panelnow.com',
    POLLFISH: 'https://api.pollfish.com',
    THEOREM_REACH: 'https://www.theoremreach.com/api',
  };

  private constructor() {}

  static getInstance(): SurveyService {
    if (!SurveyService.instance) {
      SurveyService.instance = new SurveyService();
    }
    return SurveyService.instance;
  }

  // Get available surveys for user
  async getAvailableSurveys(userId: string, userProfile: any): Promise<Survey[]> {
    try {
      const surveys: Survey[] = [];

      // Fetch from multiple providers in parallel
      const providers = [
        this.fetchCPXResearchSurveys(userProfile),
        this.fetchPanelNowSurveys(userProfile),
        this.fetchPollfishSurveys(userProfile),
        this.fetchTheoremReachSurveys(userProfile),
      ];

      const results = await Promise.allSettled(providers);

      results.forEach((result, index) => {
        if (result.status === 'fulfilled') {
          surveys.push(...result.value);
        } else {
          console.error(`Error fetching surveys from provider ${index}:`, result.reason);
        }
      });

      // Sort by reward amount (highest first)
      return surveys.sort((a, b) => b.reward - a.reward);
    } catch (error) {
      console.error('Error getting available surveys:', error);
      // Return mock surveys for development
      return this.getMockSurveys();
    }
  }

  // CPX Research API integration
  private async fetchCPXResearchSurveys(userProfile: any): Promise<Survey[]> {
    try {
      const response = await axios.get(this.apiEndpoints.CPX_RESEARCH, {
        params: {
          app_id: process.env.CPX_RESEARCH_APP_ID,
          ext_user_id: userProfile.id,
          username: userProfile.username,
          email: userProfile.email,
          subid_1: 'payday_app',
          format: 'json',
        },
        timeout: 10000,
      });

      if (response.data && response.data.surveys) {
        return response.data.surveys.map((survey: any) => ({
          id: survey.id,
          title: survey.title || 'Consumer Survey',
          description: survey.description || 'Share your opinion and earn rewards',
          estimatedMinutes: survey.loi || 10,
          reward: (survey.payout || 50) / 100, // Convert cents to dollars
          currency: 'USD',
          provider: 'CPX_RESEARCH' as const,
          category: survey.category || 'General',
          targetCountry: 'US',
          minimumAge: 18,
          status: 'available' as const,
        }));
      }

      return [];
    } catch (error) {
      console.error('CPX Research API error:', error);
      return [];
    }
  }

  // Panel Now API integration
  private async fetchPanelNowSurveys(userProfile: any): Promise<Survey[]> {
    try {
      // Panel Now API integration would go here
      // For now, return mock data
      return [
        {
          id: 'pn_001',
          title: 'Shopping Habits Survey',
          description: 'Tell us about your shopping preferences',
          estimatedMinutes: 15,
          reward: 2.50,
          currency: 'USD',
          provider: 'PANEL_NOW' as const,
          category: 'Shopping',
          targetCountry: 'US',
          minimumAge: 18,
          status: 'available' as const,
        },
      ];
    } catch (error) {
      console.error('Panel Now API error:', error);
      return [];
    }
  }

  // Pollfish API integration
  private async fetchPollfishSurveys(userProfile: any): Promise<Survey[]> {
    try {
      // Pollfish API integration would go here
      return [
        {
          id: 'pf_001',
          title: 'Technology Usage Survey',
          description: 'Share your thoughts on technology trends',
          estimatedMinutes: 8,
          reward: 1.75,
          currency: 'USD',
          provider: 'POLLFISH' as const,
          category: 'Technology',
          targetCountry: 'US',
          minimumAge: 16,
          status: 'available' as const,
        },
      ];
    } catch (error) {
      console.error('Pollfish API error:', error);
      return [];
    }
  }

  // Theorem Reach API integration
  private async fetchTheoremReachSurveys(userProfile: any): Promise<Survey[]> {
    try {
      // Theorem Reach API integration would go here
      return [
        {
          id: 'tr_001',
          title: 'Entertainment Preferences',
          description: 'Help us understand your entertainment choices',
          estimatedMinutes: 12,
          reward: 2.00,
          currency: 'USD',
          provider: 'THEOREM_REACH' as const,
          category: 'Entertainment',
          targetCountry: 'US',
          minimumAge: 18,
          status: 'available' as const,
        },
      ];
    } catch (error) {
      console.error('Theorem Reach API error:', error);
      return [];
    }
  }

  // Process survey completion
  async processSurveyCompletion(
    userId: string,
    surveyId: string,
    provider: string,
    transactionId: string
  ): Promise<SurveyCompletion> {
    try {
      // Verify the completion with the provider
      const verified = await this.verifySurveyCompletion(surveyId, provider, transactionId);

      if (!verified) {
        throw new Error('Survey completion could not be verified');
      }

      // Get survey details to determine reward
      const survey = await this.getSurveyDetails(surveyId, provider);

      const completion: SurveyCompletion = {
        userId,
        surveyId,
        provider,
        completedAt: new Date(),
        reward: survey.reward,
        verified: true,
      };

      // Log completion and update user balance
      await this.logSurveyCompletion(completion);

      return completion;
    } catch (error) {
      console.error('Error processing survey completion:', error);
      throw error;
    }
  }

  // Verify survey completion with provider
  private async verifySurveyCompletion(
    surveyId: string,
    provider: string,
    transactionId: string
  ): Promise<boolean> {
    try {
      switch (provider) {
        case 'CPX_RESEARCH':
          return await this.verifyCPXCompletion(surveyId, transactionId);
        case 'PANEL_NOW':
          return await this.verifyPanelNowCompletion(surveyId, transactionId);
        default:
          return true; // For development, assume all completions are valid
      }
    } catch (error) {
      console.error('Error verifying survey completion:', error);
      return false;
    }
  }

  private async verifyCPXCompletion(surveyId: string, transactionId: string): Promise<boolean> {
    try {
      // CPX Research verification API call would go here
      return true; // Placeholder
    } catch (error) {
      console.error('CPX verification error:', error);
      return false;
    }
  }

  private async verifyPanelNowCompletion(surveyId: string, transactionId: string): Promise<boolean> {
    try {
      // Panel Now verification API call would go here
      return true; // Placeholder
    } catch (error) {
      console.error('Panel Now verification error:', error);
      return false;
    }
  }

  // Get survey details
  private async getSurveyDetails(surveyId: string, provider: string): Promise<Survey> {
    // This would typically fetch from cache or provider API
    // For now, return mock data
    return {
      id: surveyId,
      title: 'Sample Survey',
      description: 'Sample Description',
      estimatedMinutes: 10,
      reward: 1.50,
      currency: 'USD',
      provider: provider as any,
      category: 'General',
      targetCountry: 'US',
      minimumAge: 18,
      status: 'available',
    };
  }

  // Log survey completion
  private async logSurveyCompletion(completion: SurveyCompletion) {
    try {
      console.log('Survey Completion Logged:', {
        userId: completion.userId,
        surveyId: completion.surveyId,
        provider: completion.provider,
        reward: completion.reward,
        completedAt: completion.completedAt,
      });

      // In production, this would:
      // 1. Save to database
      // 2. Update user's balance
      // 3. Send confirmation notification
      // 4. Update analytics
    } catch (error) {
      console.error('Error logging survey completion:', error);
    }
  }

  // Get user's survey statistics
  async getUserSurveyStats(userId: string) {
    try {
      // This would typically query the database
      return {
        totalCompleted: 45,
        totalEarnings: 67.50,
        averageReward: 1.50,
        completionRate: 85,
        favoriteCategory: 'Shopping',
        currentStreak: 7,
      };
    } catch (error) {
      console.error('Error getting user survey stats:', error);
      throw error;
    }
  }

  // Mock surveys for development
  private getMockSurveys(): Survey[] {
    return [
      {
        id: 'mock_001',
        title: 'Consumer Preferences Survey',
        description: 'Share your shopping and lifestyle preferences',
        estimatedMinutes: 12,
        reward: 3.00,
        currency: 'USD',
        provider: 'CPX_RESEARCH',
        category: 'Shopping',
        targetCountry: 'US',
        minimumAge: 18,
        status: 'available',
      },
      {
        id: 'mock_002',
        title: 'Tech Product Feedback',
        description: 'Help improve technology products with your feedback',
        estimatedMinutes: 8,
        reward: 2.25,
        currency: 'USD',
        provider: 'POLLFISH',
        category: 'Technology',
        targetCountry: 'US',
        minimumAge: 16,
        status: 'available',
      },
      {
        id: 'mock_003',
        title: 'Health & Wellness Study',
        description: 'Share your thoughts on health and wellness trends',
        estimatedMinutes: 15,
        reward: 4.50,
        currency: 'USD',
        provider: 'PANEL_NOW',
        category: 'Health',
        targetCountry: 'US',
        minimumAge: 21,
        status: 'available',
      },
    ];
  }
}

export default SurveyService;
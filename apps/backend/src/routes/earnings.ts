import express, { Request, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { prisma } from '../lib/prisma';
import EarningsService from '../services/earnings.service';
import SurveyService from '../services/survey.service';
import AdMobService from '../services/admob.service';

const router = express.Router();
const earningsService = EarningsService.getInstance();
const surveyService = SurveyService.getInstance();
const adMobService = AdMobService.getInstance();

// Get user earnings summary
router.get('/summary', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;

    // For now, return mock data since Earning model may not exist yet
    // This will be replaced with real data once the database schema is updated
    const mockEarnings = {
      totalEarnings: 5000,
      availableBalance: 3500,
      pendingWithdrawals: 0,
      totalWithdrawn: 1500,
      earningsCount: 12,
    };

    res.json(mockEarnings);
  } catch (error) {
    console.error('Error fetching earnings summary:', error);
    res.status(500).json({ error: 'Failed to fetch earnings summary' });
  }
});

// Get earnings history
router.get('/', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;
    const { page = 1, limit = 10 } = req.query;

    // Mock earnings data
    const mockEarnings = [
      {
        id: '1',
        amount: 500,
        description: 'AI 예측 수익',
        createdAt: new Date('2025-09-20'),
        task: {
          title: 'AAPL 예측 성공',
          amount: 500,
        },
      },
      {
        id: '2',
        amount: 300,
        description: '투자 수익',
        createdAt: new Date('2025-09-19'),
        task: {
          title: 'BTC 투자 수익',
          amount: 300,
        },
      },
      {
        id: '3',
        amount: 250,
        description: '태스크 완료',
        createdAt: new Date('2025-09-18'),
        task: {
          title: '데이터 분석 태스크',
          amount: 250,
        },
      },
    ];

    res.json({
      earnings: mockEarnings,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total: 3,
        totalPages: 1,
      },
    });
  } catch (error) {
    console.error('Error fetching earnings:', error);
    res.status(500).json({ error: 'Failed to fetch earnings' });
  }
});

// Request withdrawal
router.post('/withdraw', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;
    const { amount, method, accountDetails } = req.body;

    // Mock available balance check
    const availableBalance = 3500;

    if (amount > availableBalance) {
      return res.status(400).json({
        error: 'Insufficient balance',
        availableBalance
      });
    }

    // Mock withdrawal creation
    const mockWithdrawal = {
      id: Date.now().toString(),
      userId,
      amount,
      method,
      accountDetails,
      status: 'PENDING',
      createdAt: new Date(),
    };

    res.status(201).json({
      message: 'Withdrawal request created successfully',
      withdrawal: mockWithdrawal,
    });
  } catch (error) {
    console.error('Error creating withdrawal:', error);
    res.status(500).json({ error: 'Failed to create withdrawal request' });
  }
});

// Get withdrawal history
router.get('/withdrawals', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    // Mock withdrawals data
    const mockWithdrawals = [
      {
        id: '1',
        amount: 1000,
        method: 'BANK_TRANSFER',
        status: 'COMPLETED',
        createdAt: new Date('2025-09-15'),
      },
      {
        id: '2',
        amount: 500,
        method: 'PAYPAL',
        status: 'COMPLETED',
        createdAt: new Date('2025-09-10'),
      },
    ];

    res.json({ withdrawals: mockWithdrawals });
  } catch (error) {
    console.error('Error fetching withdrawals:', error);
    res.status(500).json({ error: 'Failed to fetch withdrawals' });
  }
});

// ===== NEW MONETIZATION FEATURES =====

// Process ad reward
router.post('/ad-reward', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;
    const { adUnitId, adType } = req.body;

    if (!adUnitId || !adType) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const earning = await earningsService.processAdReward(userId, adUnitId, adType);
    res.json({ success: true, data: earning });
  } catch (error) {
    console.error('Error processing ad reward:', error);
    res.status(500).json({ error: 'Failed to process ad reward' });
  }
});

// Process survey completion
router.post('/survey-completion', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;
    const { surveyId, provider, transactionId } = req.body;

    if (!surveyId || !provider || !transactionId) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const earning = await earningsService.processSurveyReward(
      userId,
      surveyId,
      provider,
      transactionId
    );
    res.json({ success: true, data: earning });
  } catch (error) {
    console.error('Error processing survey completion:', error);
    res.status(500).json({ error: 'Failed to process survey completion' });
  }
});

// Process daily login bonus
router.post('/daily-bonus', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;
    const { streakDays } = req.body;

    const earning = await earningsService.processDailyBonus(userId, streakDays || 1);
    res.json({ success: true, data: earning });
  } catch (error) {
    console.error('Error processing daily bonus:', error);
    res.status(500).json({ error: 'Failed to process daily bonus' });
  }
});

// Get available surveys
router.get('/surveys', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;

    // Mock user profile - in production, this would come from database
    const userProfile = {
      id: userId,
      username: 'user123',
      email: 'user@example.com',
      age: 25,
      country: 'US',
      interests: ['technology', 'shopping'],
    };

    const surveys = await surveyService.getAvailableSurveys(userId, userProfile);
    res.json({ success: true, data: surveys });
  } catch (error) {
    console.error('Error getting surveys:', error);
    res.status(500).json({ error: 'Failed to get surveys' });
  }
});

// Get survey statistics
router.get('/survey-stats', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;

    const stats = await surveyService.getUserSurveyStats(userId);
    res.json({ success: true, data: stats });
  } catch (error) {
    console.error('Error getting survey stats:', error);
    res.status(500).json({ error: 'Failed to get survey stats' });
  }
});

// Get user's ad revenue summary
router.get('/ad-revenue', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;
    const period = req.query.period as 'daily' | 'weekly' | 'monthly' || 'daily';

    const revenue = await adMobService.getUserAdRevenue(userId, period);
    res.json({ success: true, data: revenue });
  } catch (error) {
    console.error('Error getting ad revenue:', error);
    res.status(500).json({ error: 'Failed to get ad revenue' });
  }
});

// Get detailed earning statistics
router.get('/stats', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;
    const period = req.query.period as 'daily' | 'weekly' | 'monthly' || 'daily';

    const stats = await earningsService.getEarningStats(userId, period);
    res.json({ success: true, data: stats });
  } catch (error) {
    console.error('Error getting earning stats:', error);
    res.status(500).json({ error: 'Failed to get earning stats' });
  }
});

// Get real-time balance
router.get('/balance', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;

    const balance = await earningsService.getUserBalance(userId);
    res.json({ success: true, data: balance });
  } catch (error) {
    console.error('Error getting balance:', error);
    res.status(500).json({ error: 'Failed to get balance' });
  }
});

// Get earning history with real data
router.get('/history', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.userId!;
    const limit = parseInt(req.query.limit as string) || 50;

    const history = await earningsService.getEarningHistory(userId, limit);
    res.json({ success: true, data: history });
  } catch (error) {
    console.error('Error getting earning history:', error);
    res.status(500).json({ error: 'Failed to get earning history' });
  }
});

export default router;
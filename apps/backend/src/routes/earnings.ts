import express, { Request, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import { prisma } from '../lib/prisma';

const router = express.Router();

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

export default router;
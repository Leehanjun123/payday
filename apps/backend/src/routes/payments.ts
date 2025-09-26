import { Router, Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import { authenticate, AuthRequest } from '../middleware/auth';
import crypto from 'crypto';

const router = Router();
const prisma = new PrismaClient();

// Payment configuration (using mock for development)
const PAYMENT_CONFIG = {
  platformFeeRate: 0.1, // 10% platform fee
  minAmount: 10000, // Minimum 10,000 KRW
  maxAmount: 10000000, // Maximum 10,000,000 KRW
};

// Initialize payment for a task
router.post('/initialize', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { taskId } = req.body;

    // Validate task
    const task = await prisma.task.findUnique({
      where: { id: taskId },
      include: {
        poster: true,
        assignee: true,
        payment: true,
      },
    });

    if (!task) {
      return res.status(404).json({ error: 'Task not found' });
    }

    if (task.posterId !== req.userId) {
      return res.status(403).json({ error: 'Only task poster can initialize payment' });
    }

    if (!task.assigneeId) {
      return res.status(400).json({ error: 'Task must have an assignee' });
    }

    if (task.status !== 'UNDER_REVIEW' && task.status !== 'COMPLETED') {
      return res.status(400).json({ error: 'Task must be under review or completed' });
    }

    if (task.payment) {
      return res.status(400).json({ error: 'Payment already initialized' });
    }

    // Calculate fees
    const platformFee = Math.floor(task.budget * PAYMENT_CONFIG.platformFeeRate);
    const netAmount = task.budget - platformFee;

    // Create payment record
    const payment = await prisma.payment.create({
      data: {
        taskId,
        amount: task.budget,
        fee: platformFee,
        netAmount,
        status: 'PENDING',
        method: 'CARD', // Default to card
        transactionId: `PAY_${Date.now()}_${crypto.randomBytes(4).toString('hex')}`,
      },
    });

    res.json({
      message: 'Payment initialized',
      payment: {
        ...payment,
        task: {
          id: task.id,
          title: task.title,
          assignee: {
            id: task.assignee.id,
            name: task.assignee.name,
          },
        },
      },
    });
  } catch (error) {
    console.error('Error initializing payment:', error);
    res.status(500).json({ error: 'Failed to initialize payment' });
  }
});

// Process payment (mock implementation)
router.post('/process/:paymentId', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { paymentId } = req.params;
    const { paymentMethod, paymentData } = req.body;

    const payment = await prisma.payment.findUnique({
      where: { id: paymentId },
      include: {
        task: {
          include: {
            poster: true,
            assignee: true,
          },
        },
      },
    });

    if (!payment) {
      return res.status(404).json({ error: 'Payment not found' });
    }

    if (payment.task.posterId !== req.userId) {
      return res.status(403).json({ error: 'Unauthorized to process this payment' });
    }

    if (payment.status !== 'PENDING') {
      return res.status(400).json({ error: 'Payment is not pending' });
    }

    // Mock payment processing
    // In production, integrate with payment gateway here
    const isPaymentSuccessful = Math.random() > 0.1; // 90% success rate for testing

    if (isPaymentSuccessful) {
      // Update payment status
      const updatedPayment = await prisma.payment.update({
        where: { id: paymentId },
        data: {
          status: 'COMPLETED',
          method: paymentMethod,
          paidAt: new Date(),
        },
      });

      // Create earning record for assignee
      await prisma.earning.create({
        data: {
          userId: payment.task.assigneeId!,
          paymentId,
          amount: payment.netAmount,
          status: 'AVAILABLE',
          type: 'TASK' as any,
          source: 'Task completion' as any,
        },
      });

      // Update task status
      await prisma.task.update({
        where: { id: payment.taskId },
        data: {
          status: 'COMPLETED',
          completedAt: new Date(),
        },
      });

      // Create notifications
      await prisma.notification.createMany({
        data: [
          {
            userId: payment.task.assigneeId!,
            type: 'PAYMENT_RECEIVED',
            title: '결제 완료',
            message: `${payment.task.title} 작업의 대금 ${payment.netAmount.toLocaleString()}원이 지급되었습니다.`,
            data: JSON.stringify({ taskId: payment.taskId, paymentId }),
          },
          {
            userId: payment.task.posterId,
            type: 'TASK_COMPLETED',
            title: '작업 완료',
            message: `${payment.task.title} 작업이 완료되었습니다.`,
            data: JSON.stringify({ taskId: payment.taskId }),
          },
        ],
      });

      res.json({
        message: 'Payment processed successfully',
        payment: updatedPayment,
      });
    } else {
      // Payment failed
      await prisma.payment.update({
        where: { id: paymentId },
        data: {
          status: 'FAILED',
        },
      });

      res.status(400).json({ error: 'Payment processing failed' });
    }
  } catch (error) {
    console.error('Error processing payment:', error);
    res.status(500).json({ error: 'Failed to process payment' });
  }
});

// Get payment status
router.get('/:paymentId', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { paymentId } = req.params;

    const payment = await prisma.payment.findUnique({
      where: { id: paymentId },
      include: {
        task: {
          include: {
            poster: {
              select: { id: true, name: true },
            },
            assignee: {
              select: { id: true, name: true },
            },
          },
        },
        earning: true,
      },
    });

    if (!payment) {
      return res.status(404).json({ error: 'Payment not found' });
    }

    // Check authorization
    const isAuthorized =
      payment.task.posterId === req.userId ||
      payment.task.assigneeId === req.userId;

    if (!isAuthorized) {
      return res.status(403).json({ error: 'Unauthorized to view this payment' });
    }

    res.json(payment);
  } catch (error) {
    console.error('Error fetching payment:', error);
    res.status(500).json({ error: 'Failed to fetch payment' });
  }
});

// Request refund
router.post('/:paymentId/refund', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { paymentId } = req.params;
    const { reason } = req.body;

    const payment = await prisma.payment.findUnique({
      where: { id: paymentId },
      include: {
        task: true,
      },
    });

    if (!payment) {
      return res.status(404).json({ error: 'Payment not found' });
    }

    if (payment.task.posterId !== req.userId) {
      return res.status(403).json({ error: 'Only task poster can request refund' });
    }

    if (payment.status !== 'COMPLETED') {
      return res.status(400).json({ error: 'Can only refund completed payments' });
    }

    // Check if refund is within time limit (e.g., 7 days)
    const daysSincePaid = payment.paidAt
      ? Math.floor((Date.now() - payment.paidAt.getTime()) / (1000 * 60 * 60 * 24))
      : 0;

    if (daysSincePaid > 7) {
      return res.status(400).json({ error: 'Refund period has expired (7 days)' });
    }

    // Process refund (mock)
    const refundedPayment = await prisma.payment.update({
      where: { id: paymentId },
      data: {
        status: 'REFUNDED',
      },
    });

    // Update earning status
    await prisma.earning.updateMany({
      where: { paymentId },
      data: {
        status: 'PENDING', // Revert to pending
      },
    });

    // Create notification
    await prisma.notification.create({
      data: {
        userId: payment.task.assigneeId!,
        type: 'SYSTEM',
        title: '환불 처리',
        message: `${payment.task.title} 작업의 대금이 환불 처리되었습니다. 사유: ${reason}`,
        data: JSON.stringify({ taskId: payment.taskId, paymentId }),
      },
    });

    res.json({
      message: 'Refund processed successfully',
      payment: refundedPayment,
    });
  } catch (error) {
    console.error('Error processing refund:', error);
    res.status(500).json({ error: 'Failed to process refund' });
  }
});

// Get payment history
router.get('/history/user', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { page = 1, limit = 20, type = 'all' } = req.query;
    const skip = (Number(page) - 1) * Number(limit);

    const whereClause: any = {};

    if (type === 'sent') {
      whereClause.task = { posterId: req.userId };
    } else if (type === 'received') {
      whereClause.task = { assigneeId: req.userId };
    } else {
      whereClause.OR = [
        { task: { posterId: req.userId } },
        { task: { assigneeId: req.userId } },
      ];
    }

    const [payments, total] = await Promise.all([
      prisma.payment.findMany({
        where: whereClause,
        include: {
          task: {
            select: {
              id: true,
              title: true,
              poster: {
                select: { id: true, name: true },
              },
              assignee: {
                select: { id: true, name: true },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: Number(limit),
      }),
      prisma.payment.count({ where: whereClause }),
    ]);

    res.json({
      payments,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        pages: Math.ceil(total / Number(limit)),
      },
    });
  } catch (error) {
    console.error('Error fetching payment history:', error);
    res.status(500).json({ error: 'Failed to fetch payment history' });
  }
});

export default router;
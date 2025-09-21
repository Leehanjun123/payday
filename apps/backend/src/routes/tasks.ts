import express, { Response } from 'express';
import { prisma } from '../lib/prisma';
import { authenticate, AuthRequest } from '../middleware/auth';

const router = express.Router();

// Get all tasks (with filters)
router.get('/', async (req: AuthRequest, res: Response) => {
  try {
    const {
      category,
      status = 'OPEN',
      minBudget,
      maxBudget,
      search,
      page = 1,
      limit = 20,
    } = req.query;

    const skip = (Number(page) - 1) * Number(limit);

    const where: any = {};

    if (status) {
      where.status = status;
    }

    if (category) {
      where.category = category;
    }

    if (minBudget || maxBudget) {
      where.budget = {};
      if (minBudget) where.budget.gte = Number(minBudget);
      if (maxBudget) where.budget.lte = Number(maxBudget);
    }

    if (search) {
      where.OR = [
        { title: { contains: search as string } },
        { description: { contains: search as string } },
      ];
    }

    const [tasks, total] = await Promise.all([
      prisma.task.findMany({
        where,
        skip,
        take: Number(limit),
        orderBy: { createdAt: 'desc' },
        include: {
          poster: {
            select: {
              id: true,
              name: true,
              profileImage: true,
              level: true,
            },
          },
          skills: {
            include: {
              skill: true,
            },
          },
          _count: {
            select: {
              applications: true,
            },
          },
        },
      }),
      prisma.task.count({ where }),
    ]);

    res.json({
      tasks,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        pages: Math.ceil(total / Number(limit)),
      },
    });
  } catch (error) {
    console.error('Error fetching tasks:', error);
    res.status(500).json({
      error: 'Failed to fetch tasks',
    });
  }
});

// Get task by ID
router.get('/:taskId', async (req: AuthRequest, res: Response) => {
  try {
    const { taskId } = req.params;

    const task = await prisma.task.findUnique({
      where: { id: taskId },
      include: {
        poster: {
          select: {
            id: true,
            name: true,
            profileImage: true,
            bio: true,
            level: true,
            createdAt: true,
            _count: {
              select: {
                postedTasks: true,
                reviewsReceived: true,
              },
            },
          },
        },
        assignee: {
          select: {
            id: true,
            name: true,
            profileImage: true,
            level: true,
          },
        },
        skills: {
          include: {
            skill: true,
          },
        },
        applications: {
          include: {
            user: {
              select: {
                id: true,
                name: true,
                profileImage: true,
                level: true,
              },
            },
          },
        },
        reviews: {
          include: {
            reviewer: {
              select: {
                id: true,
                name: true,
                profileImage: true,
              },
            },
          },
        },
      },
    });

    if (!task) {
      return res.status(404).json({
        error: 'Task not found',
      });
    }

    res.json(task);
  } catch (error) {
    console.error('Error fetching task:', error);
    res.status(500).json({
      error: 'Failed to fetch task',
    });
  }
});

// Create new task
router.post('/', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const {
      title,
      description,
      category,
      budget,
      duration,
      priority = 'NORMAL',
      deadline,
      skillIds = [],
    } = req.body;

    if (!title || !description || !category || !budget || !duration) {
      return res.status(400).json({
        error: 'Missing required fields',
      });
    }

    const task = await prisma.task.create({
      data: {
        title,
        description,
        category,
        budget: Number(budget),
        duration: Number(duration),
        priority,
        deadline: deadline ? new Date(deadline) : undefined,
        posterId: req.user!.userId,
        skills: {
          create: skillIds.map((skillId: string) => ({
            skillId,
          })),
        },
      },
      include: {
        poster: {
          select: {
            id: true,
            name: true,
            profileImage: true,
          },
        },
        skills: {
          include: {
            skill: true,
          },
        },
      },
    });

    res.status(201).json({
      message: 'Task created successfully',
      task,
    });
  } catch (error) {
    console.error('Error creating task:', error);
    res.status(500).json({
      error: 'Failed to create task',
    });
  }
});

// Update task
router.put('/:taskId', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { taskId } = req.params;
    const {
      title,
      description,
      category,
      budget,
      duration,
      priority,
      deadline,
      status,
    } = req.body;

    // Check if user owns the task
    const existingTask = await prisma.task.findUnique({
      where: { id: taskId },
      select: { posterId: true },
    });

    if (!existingTask) {
      return res.status(404).json({
        error: 'Task not found',
      });
    }

    if (existingTask.posterId !== req.user!.userId) {
      return res.status(403).json({
        error: 'You can only edit your own tasks',
      });
    }

    const updatedTask = await prisma.task.update({
      where: { id: taskId },
      data: {
        ...(title && { title }),
        ...(description && { description }),
        ...(category && { category }),
        ...(budget && { budget: Number(budget) }),
        ...(duration && { duration: Number(duration) }),
        ...(priority && { priority }),
        ...(deadline !== undefined && {
          deadline: deadline ? new Date(deadline) : null
        }),
        ...(status && { status }),
      },
      include: {
        poster: {
          select: {
            id: true,
            name: true,
            profileImage: true,
          },
        },
        skills: {
          include: {
            skill: true,
          },
        },
      },
    });

    res.json({
      message: 'Task updated successfully',
      task: updatedTask,
    });
  } catch (error) {
    console.error('Error updating task:', error);
    res.status(500).json({
      error: 'Failed to update task',
    });
  }
});

// Delete task
router.delete('/:taskId', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { taskId } = req.params;

    // Check if user owns the task
    const existingTask = await prisma.task.findUnique({
      where: { id: taskId },
      select: {
        posterId: true,
        status: true,
      },
    });

    if (!existingTask) {
      return res.status(404).json({
        error: 'Task not found',
      });
    }

    if (existingTask.posterId !== req.user!.userId) {
      return res.status(403).json({
        error: 'You can only delete your own tasks',
      });
    }

    if (existingTask.status !== 'OPEN') {
      return res.status(400).json({
        error: 'Cannot delete task that is in progress or completed',
      });
    }

    // Delete related records first
    await prisma.$transaction([
      prisma.taskApplication.deleteMany({ where: { taskId } }),
      prisma.taskSkill.deleteMany({ where: { taskId } }),
      prisma.task.delete({ where: { id: taskId } }),
    ]);

    res.json({
      message: 'Task deleted successfully',
    });
  } catch (error) {
    console.error('Error deleting task:', error);
    res.status(500).json({
      error: 'Failed to delete task',
    });
  }
});

// Apply to task
router.post('/:taskId/apply', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { taskId } = req.params;
    const { proposal, bidAmount } = req.body;

    if (!proposal || !bidAmount) {
      return res.status(400).json({
        error: 'Proposal and bid amount are required',
      });
    }

    // Check if task exists and is open
    const task = await prisma.task.findUnique({
      where: { id: taskId },
      select: {
        status: true,
        posterId: true,
      },
    });

    if (!task) {
      return res.status(404).json({
        error: 'Task not found',
      });
    }

    if (task.status !== 'OPEN') {
      return res.status(400).json({
        error: 'Task is not open for applications',
      });
    }

    if (task.posterId === req.user!.userId) {
      return res.status(400).json({
        error: 'You cannot apply to your own task',
      });
    }

    // Check if already applied
    const existingApplication = await prisma.taskApplication.findUnique({
      where: {
        taskId_userId: {
          taskId,
          userId: req.user!.userId,
        },
      },
    });

    if (existingApplication) {
      return res.status(409).json({
        error: 'You have already applied to this task',
      });
    }

    const application = await prisma.taskApplication.create({
      data: {
        taskId,
        userId: req.user!.userId,
        proposal,
        bidAmount: Number(bidAmount),
      },
      include: {
        user: {
          select: {
            id: true,
            name: true,
            profileImage: true,
            level: true,
          },
        },
      },
    });

    // Create notification for task owner
    await prisma.notification.create({
      data: {
        userId: task.posterId,
        type: 'APPLICATION_RECEIVED',
        title: '새로운 지원자',
        message: `${application.user.name}님이 작업에 지원했습니다`,
        data: {
          taskId,
          applicationId: application.id,
        },
      },
    });

    res.status(201).json({
      message: 'Application submitted successfully',
      application,
    });
  } catch (error) {
    console.error('Error applying to task:', error);
    res.status(500).json({
      error: 'Failed to apply to task',
    });
  }
});

// Accept application
router.post(
  '/:taskId/applications/:applicationId/accept',
  authenticate,
  async (req: AuthRequest, res: Response) => {
    try {
      const { taskId, applicationId } = req.params;

      // Check if task exists and user owns it
      const task = await prisma.task.findUnique({
        where: { id: taskId },
        select: {
          posterId: true,
          status: true,
        },
      });

      if (!task) {
        return res.status(404).json({
          error: 'Task not found',
        });
      }

      if (task.posterId !== req.user!.userId) {
        return res.status(403).json({
          error: 'Only task owner can accept applications',
        });
      }

      if (task.status !== 'OPEN') {
        return res.status(400).json({
          error: 'Task is not open for accepting applications',
        });
      }

      // Get application
      const application = await prisma.taskApplication.findUnique({
        where: { id: applicationId },
        include: {
          user: {
            select: {
              id: true,
              name: true,
            },
          },
        },
      });

      if (!application || application.taskId !== taskId) {
        return res.status(404).json({
          error: 'Application not found',
        });
      }

      // Update application and task in transaction
      await prisma.$transaction([
        // Accept this application
        prisma.taskApplication.update({
          where: { id: applicationId },
          data: {
            status: 'ACCEPTED',
            respondedAt: new Date(),
          },
        }),
        // Reject other applications
        prisma.taskApplication.updateMany({
          where: {
            taskId,
            id: { not: applicationId },
            status: 'PENDING',
          },
          data: {
            status: 'REJECTED',
            respondedAt: new Date(),
          },
        }),
        // Update task
        prisma.task.update({
          where: { id: taskId },
          data: {
            status: 'IN_PROGRESS',
            assigneeId: application.userId,
          },
        }),
        // Create notifications
        prisma.notification.create({
          data: {
            userId: application.userId,
            type: 'APPLICATION_ACCEPTED',
            title: '지원 승인됨',
            message: '작업 지원이 승인되었습니다!',
            data: { taskId },
          },
        }),
      ]);

      res.json({
        message: 'Application accepted successfully',
      });
    } catch (error) {
      console.error('Error accepting application:', error);
      res.status(500).json({
        error: 'Failed to accept application',
      });
    }
  }
);

// Get my tasks (posted by me)
router.get('/my/posted', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const tasks = await prisma.task.findMany({
      where: { posterId: req.user!.userId },
      orderBy: { createdAt: 'desc' },
      include: {
        _count: {
          select: {
            applications: true,
          },
        },
        assignee: {
          select: {
            id: true,
            name: true,
            profileImage: true,
          },
        },
      },
    });

    res.json(tasks);
  } catch (error) {
    console.error('Error fetching posted tasks:', error);
    res.status(500).json({
      error: 'Failed to fetch posted tasks',
    });
  }
});

// Get my assigned tasks
router.get('/my/assigned', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const tasks = await prisma.task.findMany({
      where: { assigneeId: req.user!.userId },
      orderBy: { createdAt: 'desc' },
      include: {
        poster: {
          select: {
            id: true,
            name: true,
            profileImage: true,
          },
        },
      },
    });

    res.json(tasks);
  } catch (error) {
    console.error('Error fetching assigned tasks:', error);
    res.status(500).json({
      error: 'Failed to fetch assigned tasks',
    });
  }
});

export default router;
import express, { Response } from 'express';
import { prisma } from '../lib/prisma';
import { authenticate, AuthRequest } from '../middleware/auth';
import { hashPassword } from '../lib/auth';
import { validatePassword } from '../middleware/validation';

const router = express.Router();

// Get current user profile
router.get('/me', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user!.userId },
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        profileImage: true,
        bio: true,
        level: true,
        points: true,
        role: true,
        isVerified: true,
        createdAt: true,
        skills: {
          include: {
            skill: true,
          },
        },
        _count: {
          select: {
            postedTasks: true,
            assignedTasks: true,
            reviews: true,
          },
        },
      },
    });

    if (!user) {
      return res.status(404).json({
        error: 'User not found',
      });
    }

    res.json(user);
  } catch (error) {
    console.error('Error fetching user profile:', error);
    res.status(500).json({
      error: 'Failed to fetch user profile',
    });
  }
});

// Update user profile
router.put('/me', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { name, phone, bio, profileImage } = req.body;

    const updatedUser = await prisma.user.update({
      where: { id: req.user!.userId },
      data: {
        ...(name && { name }),
        ...(phone && { phone }),
        ...(bio !== undefined && { bio }),
        ...(profileImage !== undefined && { profileImage }),
      },
      select: {
        id: true,
        email: true,
        name: true,
        phone: true,
        profileImage: true,
        bio: true,
        level: true,
        points: true,
      },
    });

    res.json({
      message: 'Profile updated successfully',
      user: updatedUser,
    });
  } catch (error) {
    console.error('Error updating profile:', error);
    res.status(500).json({
      error: 'Failed to update profile',
    });
  }
});

// Change password
router.put('/me/password', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        error: 'Current and new passwords are required',
      });
    }

    // Validate new password
    const passwordValidation = validatePassword(newPassword);
    if (!passwordValidation.isValid) {
      return res.status(400).json({
        error: 'Invalid new password',
        errors: passwordValidation.errors,
      });
    }

    // Verify current password
    const user = await prisma.user.findUnique({
      where: { id: req.user!.userId },
      select: { password: true },
    });

    if (!user) {
      return res.status(404).json({
        error: 'User not found',
      });
    }

    const { comparePassword } = await import('../lib/auth');
    const isValidPassword = await comparePassword(currentPassword, user.password);

    if (!isValidPassword) {
      return res.status(401).json({
        error: 'Current password is incorrect',
      });
    }

    // Update password
    const hashedPassword = await hashPassword(newPassword);
    await prisma.user.update({
      where: { id: req.user!.userId },
      data: { password: hashedPassword },
    });

    res.json({
      message: 'Password updated successfully',
    });
  } catch (error) {
    console.error('Error changing password:', error);
    res.status(500).json({
      error: 'Failed to change password',
    });
  }
});

// Get user's skills
router.get('/me/skills', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const skills = await prisma.userSkill.findMany({
      where: { userId: req.user!.userId },
      include: {
        skill: true,
      },
    });

    res.json(skills);
  } catch (error) {
    console.error('Error fetching user skills:', error);
    res.status(500).json({
      error: 'Failed to fetch skills',
    });
  }
});

// Add skill to user
router.post('/me/skills', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { skillId, level = 1 } = req.body;

    if (!skillId) {
      return res.status(400).json({
        error: 'Skill ID is required',
      });
    }

    // Check if skill exists
    const skill = await prisma.skill.findUnique({
      where: { id: skillId },
    });

    if (!skill) {
      return res.status(404).json({
        error: 'Skill not found',
      });
    }

    // Check if user already has this skill
    const existingUserSkill = await prisma.userSkill.findUnique({
      where: {
        userId_skillId: {
          userId: req.user!.userId,
          skillId,
        },
      },
    });

    if (existingUserSkill) {
      return res.status(409).json({
        error: 'User already has this skill',
      });
    }

    // Add skill to user
    const userSkill = await prisma.userSkill.create({
      data: {
        userId: req.user!.userId,
        skillId,
        level: Math.min(Math.max(level, 1), 5), // Ensure level is between 1-5
      },
      include: {
        skill: true,
      },
    });

    res.status(201).json({
      message: 'Skill added successfully',
      skill: userSkill,
    });
  } catch (error) {
    console.error('Error adding skill:', error);
    res.status(500).json({
      error: 'Failed to add skill',
    });
  }
});

// Update skill level
router.put('/me/skills/:skillId', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { skillId } = req.params;
    const { level } = req.body;

    if (!level || level < 1 || level > 5) {
      return res.status(400).json({
        error: 'Level must be between 1 and 5',
      });
    }

    const userSkill = await prisma.userSkill.update({
      where: {
        userId_skillId: {
          userId: req.user!.userId,
          skillId,
        },
      },
      data: { level },
      include: {
        skill: true,
      },
    });

    res.json({
      message: 'Skill level updated successfully',
      skill: userSkill,
    });
  } catch (error) {
    console.error('Error updating skill level:', error);
    res.status(500).json({
      error: 'Failed to update skill level',
    });
  }
});

// Remove skill from user
router.delete('/me/skills/:skillId', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { skillId } = req.params;

    await prisma.userSkill.delete({
      where: {
        userId_skillId: {
          userId: req.user!.userId,
          skillId,
        },
      },
    });

    res.json({
      message: 'Skill removed successfully',
    });
  } catch (error) {
    console.error('Error removing skill:', error);
    res.status(500).json({
      error: 'Failed to remove skill',
    });
  }
});

// Get user by ID (public profile)
router.get('/:userId', async (req: AuthRequest, res: Response) => {
  try {
    const { userId } = req.params;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        name: true,
        profileImage: true,
        bio: true,
        level: true,
        createdAt: true,
        skills: {
          include: {
            skill: true,
          },
        },
        _count: {
          select: {
            postedTasks: true,
            assignedTasks: true,
            reviewsReceived: true,
          },
        },
      },
    });

    if (!user) {
      return res.status(404).json({
        error: 'User not found',
      });
    }

    // Calculate average rating
    const reviews = await prisma.review.findMany({
      where: { receiverId: userId },
      select: { rating: true },
    });

    const averageRating =
      reviews.length > 0
        ? reviews.reduce((acc, r) => acc + r.rating, 0) / reviews.length
        : 0;

    res.json({
      ...user,
      averageRating,
      totalReviews: reviews.length,
    });
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({
      error: 'Failed to fetch user',
    });
  }
});

export default router;
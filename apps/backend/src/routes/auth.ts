import express, { Request, Response } from 'express';
import { prisma } from '../lib/prisma';
import {
  hashPassword,
  comparePassword,
  generateToken,
  generateRefreshToken,
  verifyToken,
} from '../lib/auth';
import {
  validateEmail,
  validatePhone,
  validatePassword,
  validateRequest,
} from '../middleware/validation';

const router = express.Router();

// Register new user
router.post(
  '/register',
  validateRequest(['email', 'password', 'name']),
  async (req: Request, res: Response) => {
    try {
      const { email, password, name, phone } = req.body;

      // Validate email
      if (!validateEmail(email)) {
        return res.status(400).json({
          error: 'Invalid email format',
        });
      }

      // Validate password
      const passwordValidation = validatePassword(password);
      if (!passwordValidation.isValid) {
        return res.status(400).json({
          error: 'Password validation failed',
          errors: passwordValidation.errors,
        });
      }

      // Validate phone if provided
      if (phone && !validatePhone(phone)) {
        return res.status(400).json({
          error: 'Invalid phone number format',
        });
      }

      // Check if user already exists
      const existingUser = await prisma.user.findFirst({
        where: {
          OR: [
            { email },
            ...(phone ? [{ phone }] : []),
          ],
        },
      });

      if (existingUser) {
        return res.status(409).json({
          error: 'User already exists',
          message: existingUser.email === email
            ? 'Email is already registered'
            : 'Phone number is already registered',
        });
      }

      // Create user
      const hashedPassword = await hashPassword(password);
      const user = await prisma.user.create({
        data: {
          email,
          password: hashedPassword,
          name,
          phone,
        },
        select: {
          id: true,
          email: true,
          name: true,
          role: true,
          createdAt: true,
        },
      });

      // Generate tokens
      const token = generateToken({
        userId: user.id,
        email: user.email,
        role: user.role,
      });

      const refreshToken = generateRefreshToken(user.id);

      res.status(201).json({
        message: 'User registered successfully',
        user,
        token,
        refreshToken,
      });
    } catch (error) {
      console.error('Registration error:', error);
      res.status(500).json({
        error: 'Registration failed',
        message: 'An error occurred during registration',
      });
    }
  }
);

// Login
router.post(
  '/login',
  validateRequest(['email', 'password']),
  async (req: Request, res: Response) => {
    try {
      const { email, password } = req.body;

      // Find user
      const user = await prisma.user.findUnique({
        where: { email },
        select: {
          id: true,
          email: true,
          password: true,
          name: true,
          role: true,
          isActive: true,
          isVerified: true,
          level: true,
          points: true,
        },
      });

      if (!user || !user.isActive) {
        return res.status(401).json({
          error: 'Invalid credentials',
          message: 'Email or password is incorrect',
        });
      }

      // Verify password
      const isValidPassword = await comparePassword(password, user.password);
      if (!isValidPassword) {
        return res.status(401).json({
          error: 'Invalid credentials',
          message: 'Email or password is incorrect',
        });
      }

      // Generate tokens
      const token = generateToken({
        userId: user.id,
        email: user.email,
        role: user.role,
      });

      const refreshToken = generateRefreshToken(user.id);

      // Update last login
      await prisma.user.update({
        where: { id: user.id },
        data: { updatedAt: new Date() },
      });

      // Remove password from response
      const { password: _, ...userWithoutPassword } = user;

      res.json({
        message: 'Login successful',
        user: userWithoutPassword,
        token,
        refreshToken,
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        error: 'Login failed',
        message: 'An error occurred during login',
      });
    }
  }
);

// Refresh token
router.post('/refresh', async (req: Request, res: Response): Promise<Response> => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        error: 'Refresh token required',
      });
    }

    // In a production app, you would verify the refresh token
    // and possibly store it in the database or Redis
    // For now, we'll just decode it and generate new tokens

    const decoded = verifyToken(refreshToken);

    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        role: true,
        isActive: true,
      },
    });

    if (!user || !user.isActive) {
      return res.status(401).json({
        error: 'Invalid refresh token',
      });
    }

    const token = generateToken({
      userId: user.id,
      email: user.email,
      role: user.role,
    });

    const newRefreshToken = generateRefreshToken(user.id);

    res.json({
      token,
      refreshToken: newRefreshToken,
    });
  } catch (error) {
    console.error('Token refresh error:', error);
    res.status(401).json({
      error: 'Invalid refresh token',
    });
  }
});

// Logout (optional - mainly for client-side token cleanup)
router.post('/logout', async (_req: Request, res: Response) => {
  // In a production app, you might want to blacklist the token
  // or remove it from a token whitelist in Redis
  res.json({
    message: 'Logout successful',
  });
});

export default router;
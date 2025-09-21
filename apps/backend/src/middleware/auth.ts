import { Request, Response, NextFunction } from 'express';
import { verifyToken } from '../lib/auth';
import { prisma } from '../lib/prisma';

export interface AuthRequest extends Request {
  user?: {
    userId: string;
    email: string;
    role: string;
  };
  userId?: string; // 라우트에서 쉽게 접근하기 위해 추가
}

export const authenticate = async (
  req: AuthRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) {
      return res.status(401).json({
        error: 'Authentication required',
        message: 'No token provided',
      });
    }

    const decoded = verifyToken(token);

    // Verify user still exists
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: { id: true, email: true, role: true, isActive: true },
    });

    if (!user || !user.isActive) {
      return res.status(401).json({
        error: 'Invalid token',
        message: 'User not found or inactive',
      });
    }

    req.user = {
      userId: user.id,
      email: user.email,
      role: user.role,
    };

    // 라우트에서 쉽게 접근할 수 있도록 userId 직접 설정
    req.userId = user.id;

    next();
  } catch (error) {
    console.error('Authentication error:', error);
    return res.status(401).json({
      error: 'Invalid token',
      message: 'Token verification failed',
    });
  }
};

export const authorize = (...roles: string[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({
        error: 'Authentication required',
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        error: 'Insufficient permissions',
        message: `Requires one of the following roles: ${roles.join(', ')}`,
      });
    }

    next();
  };
};
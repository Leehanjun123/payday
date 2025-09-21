import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import { createServer } from 'http';
import { initializeSocket } from './socket/socketServer';

// Load environment variables
dotenv.config();

// Import routes
import authRoutes from './routes/auth';
import userRoutes from './routes/users';
import taskRoutes from './routes/tasks';
import skillRoutes from './routes/skills';
import paymentRoutes from './routes/payments';
import earningsRoutes from './routes/earnings';
import marketplaceRoutes from './routes/marketplace';
import auctionRoutes from './routes/auctions';
import investmentRoutes from './routes/investments';
import predictionRoutes from './routes/predictions';

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get('/health', (_req: Request, res: Response) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'payday-backend',
    version: '1.0.0',
  });
});

// Root endpoint
app.get('/', (_req: Request, res: Response) => {
  res.json({
    message: 'PayDay API Server',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      api: '/api/v1',
    },
  });
});

// API v1 routes placeholder
app.get('/api/v1', (_req: Request, res: Response) => {
  res.json({
    message: 'PayDay API v1',
    available_endpoints: [
      '/api/v1/auth/register',
      '/api/v1/auth/login',
      '/api/v1/users/me',
      '/api/v1/tasks',
      '/api/v1/earnings',
      '/api/v1/payments',
      '/api/v1/marketplace',
      '/api/v1/auctions',
      '/api/v1/investments',
      '/api/v1/predictions',
    ],
  });
});

// API Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/tasks', taskRoutes);
app.use('/api/v1/skills', skillRoutes);
app.use('/api/v1/payments', paymentRoutes);
app.use('/api/v1/earnings', earningsRoutes);
app.use('/api/v1/marketplace', marketplaceRoutes);
app.use('/api/v1/auctions', auctionRoutes);
app.use('/api/v1/investments', investmentRoutes);
app.use('/api/v1/predictions', predictionRoutes);

// Error handling middleware
app.use((err: Error, _req: Request, res: Response, _next: Function) => {
  console.error('Error:', err.stack);
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

// Create HTTP server
const httpServer = createServer(app);

// Initialize Socket.IO
initializeSocket(httpServer);

// Start server
httpServer.listen(PORT, () => {
  console.log(`✅ Server is running on port ${PORT}`);
  console.log(`🌐 Health check: http://localhost:${PORT}/health`);
  console.log(`📡 API endpoint: http://localhost:${PORT}/api/v1`);
  console.log(`🔌 Socket.IO server is running`);
});

export default app;
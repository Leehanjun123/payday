import express, { Request, Response } from 'express';
import predictionService from '../services/predictionService';
import { authenticate, AuthRequest } from '../middleware/auth';

const router = express.Router();

// AI Predictions Routes
router.get('/predictions', async (req: Request, res: Response) => {
  try {
    const { symbol, type, limit } = req.query;
    const predictions = await predictionService.getPredictions(
      symbol as string,
      type as string,
      limit ? parseInt(limit as string) : undefined
    );

    res.json({ predictions });
  } catch (error) {
    console.error('Error fetching predictions:', error);
    res.status(500).json({ error: 'Failed to fetch predictions' });
  }
});

router.get('/predictions/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const prediction = await predictionService.getPredictionById(id);

    if (!prediction) {
      return res.status(404).json({ error: 'Prediction not found' });
    }

    res.json({ prediction });
  } catch (error) {
    console.error('Error fetching prediction:', error);
    res.status(500).json({ error: 'Failed to fetch prediction' });
  }
});

router.post('/predictions', async (req: Request, res: Response) => {
  try {
    const predictionData = req.body;
    predictionData.validUntil = new Date(predictionData.validUntil);

    const prediction = await predictionService.createPrediction(predictionData);
    res.status(201).json({ message: 'Prediction created successfully', prediction });
  } catch (error) {
    console.error('Error creating prediction:', error);
    res.status(500).json({ error: 'Failed to create prediction' });
  }
});

router.put('/predictions/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    if (updateData.validUntil) {
      updateData.validUntil = new Date(updateData.validUntil);
    }

    const prediction = await predictionService.updatePrediction(id, updateData);
    res.json({ message: 'Prediction updated successfully', prediction });
  } catch (error) {
    console.error('Error updating prediction:', error);
    res.status(500).json({ error: 'Failed to update prediction' });
  }
});

router.post('/predictions/verify', async (req: Request, res: Response) => {
  try {
    await predictionService.verifyPredictions();
    res.json({ message: 'Predictions verification completed' });
  } catch (error) {
    console.error('Error verifying predictions:', error);
    res.status(500).json({ error: 'Failed to verify predictions' });
  }
});

// Market Analysis Routes
router.get('/analyses', async (req: Request, res: Response) => {
  try {
    const { symbol, category, limit } = req.query;
    const analyses = await predictionService.getAnalyses(
      symbol as string,
      category as string,
      limit ? parseInt(limit as string) : undefined
    );

    res.json({ analyses });
  } catch (error) {
    console.error('Error fetching analyses:', error);
    res.status(500).json({ error: 'Failed to fetch analyses' });
  }
});

router.get('/analyses/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const analysis = await predictionService.getAnalysisById(id);

    if (!analysis) {
      return res.status(404).json({ error: 'Analysis not found' });
    }

    res.json({ analysis });
  } catch (error) {
    console.error('Error fetching analysis:', error);
    res.status(500).json({ error: 'Failed to fetch analysis' });
  }
});

router.post('/analyses', async (req: Request, res: Response) => {
  try {
    const analysisData = req.body;
    const analysis = await predictionService.createAnalysis(analysisData);
    res.status(201).json({ message: 'Analysis created successfully', analysis });
  } catch (error) {
    console.error('Error creating analysis:', error);
    res.status(500).json({ error: 'Failed to create analysis' });
  }
});

router.post('/analyses/:id/like', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const analysis = await predictionService.likeAnalysis(id);
    res.json({ message: 'Analysis liked successfully', analysis });
  } catch (error) {
    console.error('Error liking analysis:', error);
    res.status(500).json({ error: 'Failed to like analysis' });
  }
});

// Price Alerts Routes
router.post('/alerts', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const alertData = { ...req.body, userId: req.userId };
    const alert = await predictionService.createPriceAlert(alertData);
    res.status(201).json({ message: 'Price alert created successfully', alert });
  } catch (error) {
    console.error('Error creating price alert:', error);
    res.status(500).json({ error: 'Failed to create price alert' });
  }
});

router.get('/alerts', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const alerts = await predictionService.getUserPriceAlerts(req.userId!);
    res.json({ alerts });
  } catch (error) {
    console.error('Error fetching price alerts:', error);
    res.status(500).json({ error: 'Failed to fetch price alerts' });
  }
});

router.put('/alerts/:id', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    const alert = await predictionService.updatePriceAlert(id, updateData);
    res.json({ message: 'Price alert updated successfully', alert });
  } catch (error) {
    console.error('Error updating price alert:', error);
    res.status(500).json({ error: 'Failed to update price alert' });
  }
});

router.delete('/alerts/:id', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    await predictionService.deletePriceAlert(id);
    res.json({ message: 'Price alert deleted successfully' });
  } catch (error) {
    console.error('Error deleting price alert:', error);
    res.status(500).json({ error: 'Failed to delete price alert' });
  }
});

router.post('/alerts/check', async (req: Request, res: Response) => {
  try {
    await predictionService.checkPriceAlerts();
    res.json({ message: 'Price alerts check completed' });
  } catch (error) {
    console.error('Error checking price alerts:', error);
    res.status(500).json({ error: 'Failed to check price alerts' });
  }
});

// Portfolio Performance Routes
router.post('/portfolios/:id/performance', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const performance = await predictionService.recordPortfolioPerformance(id);
    res.json({ message: 'Portfolio performance recorded', performance });
  } catch (error) {
    console.error('Error recording portfolio performance:', error);
    res.status(500).json({ error: 'Failed to record portfolio performance' });
  }
});

router.get('/portfolios/:id/performance', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { days } = req.query;
    const performance = await predictionService.getPortfolioPerformanceHistory(
      id,
      days ? parseInt(days as string) : undefined
    );
    res.json({ performance });
  } catch (error) {
    console.error('Error fetching portfolio performance:', error);
    res.status(500).json({ error: 'Failed to fetch portfolio performance' });
  }
});

// Analytics Routes
router.get('/analytics/accuracy', async (req: Request, res: Response) => {
  try {
    const accuracy = await predictionService.getPredictionAccuracy();
    res.json({ accuracy });
  } catch (error) {
    console.error('Error fetching prediction accuracy:', error);
    res.status(500).json({ error: 'Failed to fetch prediction accuracy' });
  }
});

router.get('/analytics/sentiment', async (req: Request, res: Response) => {
  try {
    const sentiment = await predictionService.getMarketSentimentOverview();
    res.json({ sentiment });
  } catch (error) {
    console.error('Error fetching market sentiment:', error);
    res.status(500).json({ error: 'Failed to fetch market sentiment' });
  }
});

// Demo Data Routes
router.post('/demo/predictions', async (req: Request, res: Response) => {
  try {
    const predictions = await predictionService.initDemoPredictions();
    res.json({
      message: 'Demo predictions initialized',
      count: predictions.length,
      predictions
    });
  } catch (error) {
    console.error('Error initializing demo predictions:', error);
    res.status(500).json({ error: 'Failed to initialize demo predictions' });
  }
});

router.post('/demo/analyses', async (req: Request, res: Response) => {
  try {
    const analyses = await predictionService.initDemoAnalyses();
    res.json({
      message: 'Demo analyses initialized',
      count: analyses.length,
      analyses
    });
  } catch (error) {
    console.error('Error initializing demo analyses:', error);
    res.status(500).json({ error: 'Failed to initialize demo analyses' });
  }
});

export default router;
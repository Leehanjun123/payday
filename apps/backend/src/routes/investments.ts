import express, { Request, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import investmentService from '../services/investmentService';

const router = express.Router();

// Portfolio Routes
router.post('/portfolios', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const portfolio = await investmentService.createPortfolio(req.userId!, req.body);
    res.status(201).json({ message: 'Portfolio created successfully', portfolio });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/portfolios', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const portfolios = await investmentService.getUserPortfolios(req.userId!);
    res.json({ portfolios });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/portfolios/:portfolioId', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { portfolioId } = req.params;
    const portfolio = await investmentService.getPortfolio(portfolioId, req.userId!);
    res.json({ portfolio });
  } catch (error: any) {
    res.status(404).json({ error: error.message });
  }
});

router.put('/portfolios/:portfolioId', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { portfolioId } = req.params;
    const portfolio = await investmentService.updatePortfolio(portfolioId, req.userId!, req.body);
    res.json({ message: 'Portfolio updated successfully', portfolio });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.delete('/portfolios/:portfolioId', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { portfolioId } = req.params;
    await investmentService.deletePortfolio(portfolioId, req.userId!);
    res.json({ message: 'Portfolio deleted successfully' });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Portfolio Analytics
router.get('/portfolios/:portfolioId/analytics', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { portfolioId } = req.params;
    const analytics = await investmentService.getPortfolioAnalytics(portfolioId, req.userId!);
    res.json({ analytics });
  } catch (error: any) {
    res.status(404).json({ error: error.message });
  }
});

// Holdings Routes
router.post('/portfolios/:portfolioId/holdings', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { portfolioId } = req.params;
    const holding = await investmentService.addHolding(portfolioId, req.userId!, req.body);
    res.status(201).json({ message: 'Holding added successfully', holding });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.put('/holdings/:holdingId', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { holdingId } = req.params;
    const { currentPrice } = req.body;
    const holding = await investmentService.updateHolding(holdingId, req.userId!, currentPrice);
    res.json({ message: 'Holding updated successfully', holding });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.delete('/holdings/:holdingId', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { holdingId } = req.params;
    await investmentService.removeHolding(holdingId, req.userId!);
    res.json({ message: 'Holding removed successfully' });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Transaction Routes
router.post('/portfolios/:portfolioId/transactions', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { portfolioId } = req.params;
    const transaction = await investmentService.addTransaction(portfolioId, req.userId!, req.body);
    res.status(201).json({ message: 'Transaction added successfully', transaction });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/portfolios/:portfolioId/transactions', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { portfolioId } = req.params;
    const { page = '1', limit = '20' } = req.query;
    const result = await investmentService.getTransactionHistory(
      portfolioId,
      req.userId!,
      parseInt(page as string),
      parseInt(limit as string)
    );
    res.json(result);
  } catch (error: any) {
    res.status(404).json({ error: error.message });
  }
});

// Market Data Routes
router.get('/market/search', async (req: Request, res: Response) => {
  try {
    const { q: query, type } = req.query;
    if (!query) {
      return res.status(400).json({ error: 'Query parameter is required' });
    }
    const results = await investmentService.searchMarketData(query as string, type as string);
    res.json({ results });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/market/data', async (req: Request, res: Response) => {
  try {
    const { symbols } = req.query;
    if (!symbols) {
      return res.status(400).json({ error: 'Symbols parameter is required' });
    }
    const symbolArray = (symbols as string).split(',');
    const data = await investmentService.getMarketData(symbolArray);
    res.json({ data });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/market/data', async (req: Request, res: Response) => {
  try {
    const marketData = await investmentService.updateMarketData(req.body);
    res.json({ message: 'Market data updated successfully', marketData });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Simulate market update (for demo purposes)
router.post('/market/simulate', async (req: Request, res: Response) => {
  try {
    await investmentService.simulateMarketUpdate();
    res.json({ message: 'Market simulation completed' });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Watchlist Routes
router.post('/watchlist', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { symbol, name, type } = req.body;
    const watchlistItem = await investmentService.addToWatchlist(req.userId!, symbol, name, type);
    res.status(201).json({ message: 'Added to watchlist', watchlistItem });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.delete('/watchlist/:symbol', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { symbol } = req.params;
    await investmentService.removeFromWatchlist(req.userId!, symbol);
    res.json({ message: 'Removed from watchlist' });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

router.get('/watchlist', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const watchlist = await investmentService.getUserWatchlist(req.userId!);
    res.json({ watchlist });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Initialize some demo market data
router.post('/market/init-demo', async (req: Request, res: Response) => {
  try {
    const demoData = [
      // Korean Stocks
      { symbol: '005930', name: '삼성전자', type: 'STOCK_KR', currentPrice: 75000, change: 1000, changePercent: 1.35 },
      { symbol: '000660', name: 'SK하이닉스', type: 'STOCK_KR', currentPrice: 132000, change: -2000, changePercent: -1.49 },
      { symbol: '035420', name: 'NAVER', type: 'STOCK_KR', currentPrice: 192000, change: 3000, changePercent: 1.58 },
      { symbol: '051910', name: 'LG화학', type: 'STOCK_KR', currentPrice: 485000, change: -5000, changePercent: -1.02 },

      // US Stocks
      { symbol: 'AAPL', name: 'Apple Inc.', type: 'STOCK_US', currentPrice: 175.50, change: 2.30, changePercent: 1.33 },
      { symbol: 'GOOGL', name: 'Alphabet Inc.', type: 'STOCK_US', currentPrice: 2850.20, change: -15.80, changePercent: -0.55 },
      { symbol: 'MSFT', name: 'Microsoft Corp.', type: 'STOCK_US', currentPrice: 415.30, change: 8.20, changePercent: 2.01 },
      { symbol: 'TSLA', name: 'Tesla Inc.', type: 'STOCK_US', currentPrice: 245.80, change: -5.40, changePercent: -2.15 },

      // Crypto
      { symbol: 'BTC', name: 'Bitcoin', type: 'CRYPTO', currentPrice: 45000, change: 1200, changePercent: 2.74 },
      { symbol: 'ETH', name: 'Ethereum', type: 'CRYPTO', currentPrice: 2800, change: -80, changePercent: -2.78 },
      { symbol: 'XRP', name: 'Ripple', type: 'CRYPTO', currentPrice: 0.55, change: 0.02, changePercent: 3.77 },

      // ETF
      { symbol: 'SPY', name: 'SPDR S&P 500 ETF', type: 'ETF', currentPrice: 445.20, change: 3.50, changePercent: 0.79 },
      { symbol: 'QQQ', name: 'Invesco QQQ Trust', type: 'ETF', currentPrice: 385.40, change: -2.10, changePercent: -0.54 },
    ];

    for (const data of demoData) {
      await investmentService.updateMarketData(data);
    }

    res.json({ message: 'Demo market data initialized', count: demoData.length });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
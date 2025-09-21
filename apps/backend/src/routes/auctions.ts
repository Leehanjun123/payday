import express, { Request, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import auctionService from '../services/auctionService';

const router = express.Router();

// Get auctions with optional status filter
router.get('/', async (req: Request, res: Response) => {
  try {
    const { status, page = '1', limit = '20' } = req.query;

    const result = await auctionService.getAuctions(
      status as string,
      parseInt(page as string),
      parseInt(limit as string)
    );

    res.json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Create auction for marketplace item
router.post('/', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const auction = await auctionService.createAuction(req.userId!, req.body);
    res.status(201).json({ message: 'Auction created successfully', auction });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Get specific auction
router.get('/:auctionId', async (req: Request, res: Response) => {
  try {
    const { auctionId } = req.params;
    const auction = await auctionService.getAuction(auctionId);
    res.json({ auction });
  } catch (error: any) {
    res.status(404).json({ error: error.message });
  }
});

// Place bid on auction
router.post('/:auctionId/bids', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { auctionId } = req.params;
    const bid = await auctionService.placeBid(auctionId, req.userId!, req.body);
    res.status(201).json({ message: 'Bid placed successfully', bid });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// End auction manually (seller only)
router.post('/:auctionId/end', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { auctionId } = req.params;

    // Verify seller ownership through auction service
    const auction = await auctionService.getAuction(auctionId);
    if (auction.item.sellerId !== req.userId) {
      return res.status(403).json({ error: 'Unauthorized' });
    }

    const endedAuction = await auctionService.endAuction(auctionId);
    res.json({ message: 'Auction ended successfully', auction: endedAuction });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Get user's bids
router.get('/user/bids', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { page = '1', limit = '20' } = req.query;
    const result = await auctionService.getUserBids(
      req.userId!,
      parseInt(page as string),
      parseInt(limit as string)
    );
    res.json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get user's auctions
router.get('/user/auctions', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { page = '1', limit = '20' } = req.query;
    const result = await auctionService.getUserAuctions(
      req.userId!,
      parseInt(page as string),
      parseInt(limit as string)
    );
    res.json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get time remaining for auction (utility endpoint)
router.get('/:auctionId/time-remaining', async (req: Request, res: Response) => {
  try {
    const { auctionId } = req.params;
    const auction = await auctionService.getAuction(auctionId);
    const timeRemaining = auctionService.getTimeRemaining(auction.endTime);
    res.json({ timeRemaining });
  } catch (error: any) {
    res.status(404).json({ error: error.message });
  }
});

// System endpoint to check and update auction statuses (should be called by cron job)
router.post('/system/update-statuses', async (req: Request, res: Response) => {
  try {
    // TODO: Add API key authentication for system calls
    const updatedCount = await auctionService.checkAndUpdateAuctionStatuses();
    res.json({
      message: `Updated ${updatedCount} auction statuses`,
      updatedCount
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

export default router;
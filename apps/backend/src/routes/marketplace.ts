import express, { Request, Response } from 'express';
import { authenticate, AuthRequest } from '../middleware/auth';
import marketplaceService from '../services/marketplaceService';
import offerService from '../services/offerService';

const router = express.Router();

// Get marketplace items with filters
router.get('/', async (req: Request, res: Response) => {
  try {
    const {
      category,
      condition,
      minPrice,
      maxPrice,
      location,
      isNegotiable,
      status,
      search,
      page = '1',
      limit = '20',
    } = req.query;

    const filters = {
      category: category as string,
      condition: condition as string,
      minPrice: minPrice ? parseFloat(minPrice as string) : undefined,
      maxPrice: maxPrice ? parseFloat(maxPrice as string) : undefined,
      location: location as string,
      isNegotiable: isNegotiable ? isNegotiable === 'true' : undefined,
      status: status as string,
      search: search as string,
    };

    const result = await marketplaceService.getItems(
      filters,
      parseInt(page as string),
      parseInt(limit as string)
    );

    res.json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Get marketplace categories
router.get('/categories', async (req: Request, res: Response) => {
  try {
    const categories = await marketplaceService.getCategories();
    res.json({ categories });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Create marketplace item
router.post('/', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const item = await marketplaceService.createItem(req.userId!, req.body);
    res.status(201).json({ message: 'Item created successfully', item });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Get specific marketplace item
router.get('/:itemId', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { itemId } = req.params;
    const item = await marketplaceService.getItem(itemId, req.userId);
    res.json({ item });
  } catch (error: any) {
    res.status(404).json({ error: error.message });
  }
});

// Update marketplace item
router.put('/:itemId', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { itemId } = req.params;
    const item = await marketplaceService.updateItem(itemId, req.userId!, req.body);
    res.json({ message: 'Item updated successfully', item });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Delete marketplace item
router.delete('/:itemId', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { itemId } = req.params;
    await marketplaceService.deleteItem(itemId, req.userId!);
    res.json({ message: 'Item deleted successfully' });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Get user's marketplace items
router.get('/user/items', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { page = '1', limit = '20' } = req.query;
    const result = await marketplaceService.getUserItems(
      req.userId!,
      parseInt(page as string),
      parseInt(limit as string)
    );
    res.json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Add item to favorites
router.post('/:itemId/favorite', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { itemId } = req.params;
    await marketplaceService.addToFavorites(req.userId!, itemId);
    res.json({ message: 'Item added to favorites' });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Remove item from favorites
router.delete('/:itemId/favorite', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { itemId } = req.params;
    await marketplaceService.removeFromFavorites(req.userId!, itemId);
    res.json({ message: 'Item removed from favorites' });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Get user's favorite items
router.get('/user/favorites', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { page = '1', limit = '20' } = req.query;
    const result = await marketplaceService.getUserFavorites(
      req.userId!,
      parseInt(page as string),
      parseInt(limit as string)
    );
    res.json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Create offer on item
router.post('/:itemId/offers', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { itemId } = req.params;
    const offer = await offerService.createOffer(req.userId!, {
      itemId,
      ...req.body,
    });
    res.status(201).json({ message: 'Offer created successfully', offer });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Get offers for item (seller only)
router.get('/:itemId/offers', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { itemId } = req.params;
    const offers = await offerService.getOffers(itemId, req.userId);
    res.json({ offers });
  } catch (error: any) {
    res.status(403).json({ error: error.message });
  }
});

// Get user's offers (sent or received)
router.get('/user/offers/:type', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { type } = req.params;
    const { page = '1', limit = '20' } = req.query;

    if (type !== 'sent' && type !== 'received') {
      return res.status(400).json({ error: 'Type must be "sent" or "received"' });
    }

    const result = await offerService.getUserOffers(
      req.userId!,
      type as 'sent' | 'received',
      parseInt(page as string),
      parseInt(limit as string)
    );
    res.json(result);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Update offer
router.put('/offers/:offerId', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { offerId } = req.params;
    const offer = await offerService.updateOffer(offerId, req.userId!, req.body);
    res.json({ message: 'Offer updated successfully', offer });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Accept offer
router.post('/offers/:offerId/accept', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { offerId } = req.params;
    const offer = await offerService.acceptOffer(offerId, req.userId!);
    res.json({ message: 'Offer accepted successfully', offer });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Reject offer
router.post('/offers/:offerId/reject', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { offerId } = req.params;
    const offer = await offerService.rejectOffer(offerId, req.userId!);
    res.json({ message: 'Offer rejected successfully', offer });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

// Withdraw offer
router.post('/offers/:offerId/withdraw', authenticate, async (req: AuthRequest, res: Response) => {
  try {
    const { offerId } = req.params;
    const offer = await offerService.withdrawOffer(offerId, req.userId!);
    res.json({ message: 'Offer withdrawn successfully', offer });
  } catch (error: any) {
    res.status(400).json({ error: error.message });
  }
});

export default router;
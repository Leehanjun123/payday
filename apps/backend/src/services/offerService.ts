import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export interface CreateOfferData {
  itemId: string;
  amount: number;
  message?: string;
}

export interface UpdateOfferData {
  amount?: number;
  message?: string;
}

class OfferService {
  async createOffer(buyerId: string, data: CreateOfferData) {
    const item = await prisma.marketplaceItem.findUnique({
      where: { id: data.itemId },
    });

    if (!item) {
      throw new Error('Item not found');
    }

    if (item.sellerId === buyerId) {
      throw new Error('Cannot make offer on your own item');
    }

    if (item.status !== 'ACTIVE') {
      throw new Error('Item is not available for offers');
    }

    if (!item.isNegotiable) {
      throw new Error('Item is not negotiable');
    }

    // Check if user already has a pending offer
    const existingOffer = await prisma.offer.findFirst({
      where: {
        itemId: data.itemId,
        buyerId,
        status: 'PENDING',
      },
    });

    if (existingOffer) {
      throw new Error('You already have a pending offer on this item');
    }

    return await prisma.offer.create({
      data: {
        ...data,
        buyerId,
      },
      include: {
        buyer: {
          select: {
            id: true,
            name: true,
            profileImage: true,
            level: true,
          },
        },
        item: {
          include: {
            seller: {
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
  }

  async getOffers(itemId: string, sellerId?: string) {
    const item = await prisma.marketplaceItem.findUnique({
      where: { id: itemId },
    });

    if (!item) {
      throw new Error('Item not found');
    }

    if (sellerId && item.sellerId !== sellerId) {
      throw new Error('Unauthorized');
    }

    return await prisma.offer.findMany({
      where: { itemId },
      include: {
        buyer: {
          select: {
            id: true,
            name: true,
            profileImage: true,
            level: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getUserOffers(userId: string, type: 'sent' | 'received', page = 1, limit = 20) {
    const where = type === 'sent'
      ? { buyerId: userId }
      : { item: { sellerId: userId } };

    const [offers, total] = await Promise.all([
      prisma.offer.findMany({
        where,
        include: {
          buyer: {
            select: {
              id: true,
              name: true,
              profileImage: true,
              level: true,
            },
          },
          item: {
            include: {
              seller: {
                select: {
                  id: true,
                  name: true,
                  profileImage: true,
                  level: true,
                },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.offer.count({ where }),
    ]);

    return {
      offers,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  async updateOffer(offerId: string, buyerId: string, data: UpdateOfferData) {
    const offer = await prisma.offer.findUnique({
      where: { id: offerId },
    });

    if (!offer) {
      throw new Error('Offer not found');
    }

    if (offer.buyerId !== buyerId) {
      throw new Error('Unauthorized');
    }

    if (offer.status !== 'PENDING') {
      throw new Error('Cannot update non-pending offer');
    }

    return await prisma.offer.update({
      where: { id: offerId },
      data,
      include: {
        buyer: {
          select: {
            id: true,
            name: true,
            profileImage: true,
            level: true,
          },
        },
        item: {
          include: {
            seller: {
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
  }

  async acceptOffer(offerId: string, sellerId: string) {
    const offer = await prisma.offer.findUnique({
      where: { id: offerId },
      include: {
        item: true,
      },
    });

    if (!offer) {
      throw new Error('Offer not found');
    }

    if (offer.item.sellerId !== sellerId) {
      throw new Error('Unauthorized');
    }

    if (offer.status !== 'PENDING') {
      throw new Error('Offer is not pending');
    }

    if (offer.item.status !== 'ACTIVE') {
      throw new Error('Item is no longer available');
    }

    // Accept the offer and reject all other pending offers for this item
    await prisma.$transaction([
      // Accept this offer
      prisma.offer.update({
        where: { id: offerId },
        data: { status: 'ACCEPTED' },
      }),
      // Reject all other pending offers for this item
      prisma.offer.updateMany({
        where: {
          itemId: offer.itemId,
          id: { not: offerId },
          status: 'PENDING',
        },
        data: { status: 'REJECTED' },
      }),
      // Update item status to reserved
      prisma.marketplaceItem.update({
        where: { id: offer.itemId },
        data: { status: 'RESERVED' },
      }),
    ]);

    return await prisma.offer.findUnique({
      where: { id: offerId },
      include: {
        buyer: {
          select: {
            id: true,
            name: true,
            profileImage: true,
            level: true,
          },
        },
        item: {
          include: {
            seller: {
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
  }

  async rejectOffer(offerId: string, sellerId: string) {
    const offer = await prisma.offer.findUnique({
      where: { id: offerId },
      include: {
        item: true,
      },
    });

    if (!offer) {
      throw new Error('Offer not found');
    }

    if (offer.item.sellerId !== sellerId) {
      throw new Error('Unauthorized');
    }

    if (offer.status !== 'PENDING') {
      throw new Error('Offer is not pending');
    }

    return await prisma.offer.update({
      where: { id: offerId },
      data: { status: 'REJECTED' },
      include: {
        buyer: {
          select: {
            id: true,
            name: true,
            profileImage: true,
            level: true,
          },
        },
        item: {
          include: {
            seller: {
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
  }

  async withdrawOffer(offerId: string, buyerId: string) {
    const offer = await prisma.offer.findUnique({
      where: { id: offerId },
    });

    if (!offer) {
      throw new Error('Offer not found');
    }

    if (offer.buyerId !== buyerId) {
      throw new Error('Unauthorized');
    }

    if (offer.status !== 'PENDING') {
      throw new Error('Cannot withdraw non-pending offer');
    }

    return await prisma.offer.update({
      where: { id: offerId },
      data: { status: 'WITHDRAWN' },
      include: {
        item: {
          include: {
            seller: {
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
  }

  async getOffer(offerId: string, userId: string) {
    const offer = await prisma.offer.findUnique({
      where: { id: offerId },
      include: {
        buyer: {
          select: {
            id: true,
            name: true,
            profileImage: true,
            level: true,
          },
        },
        item: {
          include: {
            seller: {
              select: {
                id: true,
                name: true,
                profileImage: true,
                level: true,
              },
            },
          },
        },
      },
    });

    if (!offer) {
      throw new Error('Offer not found');
    }

    // Check if user is authorized to view this offer
    if (offer.buyerId !== userId && offer.item.sellerId !== userId) {
      throw new Error('Unauthorized');
    }

    return offer;
  }

  async expireOldOffers() {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const expiredOffers = await prisma.offer.updateMany({
      where: {
        status: 'PENDING',
        createdAt: { lt: sevenDaysAgo },
      },
      data: { status: 'EXPIRED' },
    });

    return expiredOffers.count;
  }
}

export default new OfferService();
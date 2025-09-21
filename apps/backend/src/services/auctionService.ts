import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export interface CreateAuctionData {
  itemId: string;
  startPrice: number;
  buyNowPrice?: number;
  startTime: Date;
  endTime: Date;
}

export interface PlaceBidData {
  amount: number;
}

class AuctionService {
  async createAuction(sellerId: string, data: CreateAuctionData) {
    // Verify the item belongs to the seller
    const item = await prisma.marketplaceItem.findUnique({
      where: { id: data.itemId },
    });

    if (!item) {
      throw new Error('Item not found');
    }

    if (item.sellerId !== sellerId) {
      throw new Error('Unauthorized');
    }

    if (item.status !== 'ACTIVE') {
      throw new Error('Item is not active');
    }

    // Check if auction already exists
    const existingAuction = await prisma.auction.findUnique({
      where: { itemId: data.itemId },
    });

    if (existingAuction) {
      throw new Error('Auction already exists for this item');
    }

    return await prisma.auction.create({
      data: {
        ...data,
        status: data.startTime <= new Date() ? 'ACTIVE' : 'SCHEDULED',
      },
      include: {
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
        bids: {
          include: {
            bidder: {
              select: {
                id: true,
                name: true,
                profileImage: true,
              },
            },
          },
          orderBy: { createdAt: 'desc' },
          take: 5,
        },
      },
    });
  }

  async getAuctions(status?: string, page = 1, limit = 20) {
    const where: any = {};

    if (status) {
      where.status = status;
    }

    const [auctions, total] = await Promise.all([
      prisma.auction.findMany({
        where,
        include: {
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
          winner: {
            select: {
              id: true,
              name: true,
              profileImage: true,
            },
          },
          _count: {
            select: {
              bids: true,
            },
          },
        },
        orderBy: { endTime: 'asc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.auction.count({ where }),
    ]);

    return {
      auctions,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  async getAuction(auctionId: string) {
    const auction = await prisma.auction.findUnique({
      where: { id: auctionId },
      include: {
        item: {
          include: {
            seller: {
              select: {
                id: true,
                name: true,
                profileImage: true,
                level: true,
                createdAt: true,
              },
            },
          },
        },
        winner: {
          select: {
            id: true,
            name: true,
            profileImage: true,
          },
        },
        bids: {
          include: {
            bidder: {
              select: {
                id: true,
                name: true,
                profileImage: true,
              },
            },
          },
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!auction) {
      throw new Error('Auction not found');
    }

    return auction;
  }

  async placeBid(auctionId: string, bidderId: string, data: PlaceBidData) {
    const auction = await prisma.auction.findUnique({
      where: { id: auctionId },
      include: {
        item: true,
        bids: {
          orderBy: { amount: 'desc' },
          take: 1,
        },
      },
    });

    if (!auction) {
      throw new Error('Auction not found');
    }

    if (auction.status !== 'ACTIVE') {
      throw new Error('Auction is not active');
    }

    if (new Date() > auction.endTime) {
      throw new Error('Auction has ended');
    }

    if (auction.item.sellerId === bidderId) {
      throw new Error('Cannot bid on your own item');
    }

    // Check if bid amount is valid
    const minimumBid = auction.currentBid ? auction.currentBid + 1000 : auction.startPrice; // Minimum increment of 1000 KRW
    if (data.amount < minimumBid) {
      throw new Error(`Bid must be at least ₩${minimumBid.toLocaleString()}`);
    }

    // Mark all previous bids as non-winning
    if (auction.bids.length > 0) {
      await prisma.bid.updateMany({
        where: { auctionId },
        data: { isWinning: false },
      });
    }

    // Create new bid
    const bid = await prisma.bid.create({
      data: {
        itemId: auction.itemId,
        auctionId,
        bidderId,
        amount: data.amount,
        isWinning: true,
      },
      include: {
        bidder: {
          select: {
            id: true,
            name: true,
            profileImage: true,
          },
        },
      },
    });

    // Update auction current bid
    await prisma.auction.update({
      where: { id: auctionId },
      data: { currentBid: data.amount },
    });

    return bid;
  }

  async endAuction(auctionId: string) {
    const auction = await prisma.auction.findUnique({
      where: { id: auctionId },
      include: {
        bids: {
          where: { isWinning: true },
          include: {
            bidder: true,
          },
        },
        item: true,
      },
    });

    if (!auction) {
      throw new Error('Auction not found');
    }

    if (auction.status === 'ENDED') {
      throw new Error('Auction already ended');
    }

    const winningBid = auction.bids[0];
    const updateData: any = {
      status: 'ENDED',
    };

    if (winningBid) {
      updateData.winnerId = winningBid.bidderId;

      // Update item status to sold
      await prisma.marketplaceItem.update({
        where: { id: auction.itemId },
        data: { status: 'SOLD' },
      });
    }

    return await prisma.auction.update({
      where: { id: auctionId },
      data: updateData,
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
        winner: {
          select: {
            id: true,
            name: true,
            profileImage: true,
          },
        },
      },
    });
  }

  async getUserBids(userId: string, page = 1, limit = 20) {
    const [bids, total] = await Promise.all([
      prisma.bid.findMany({
        where: { bidderId: userId },
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
          auction: {
            select: {
              id: true,
              endTime: true,
              status: true,
              winnerId: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.bid.count({ where: { bidderId: userId } }),
    ]);

    return {
      bids,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  async getUserAuctions(userId: string, page = 1, limit = 20) {
    const [auctions, total] = await Promise.all([
      prisma.auction.findMany({
        where: {
          item: {
            sellerId: userId,
          },
        },
        include: {
          item: true,
          winner: {
            select: {
              id: true,
              name: true,
              profileImage: true,
            },
          },
          _count: {
            select: {
              bids: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.auction.count({
        where: {
          item: {
            sellerId: userId,
          },
        },
      }),
    ]);

    return {
      auctions,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  async checkAndUpdateAuctionStatuses() {
    const now = new Date();

    // Start scheduled auctions
    await prisma.auction.updateMany({
      where: {
        status: 'SCHEDULED',
        startTime: { lte: now },
      },
      data: {
        status: 'ACTIVE',
      },
    });

    // End active auctions that have passed their end time
    const expiredAuctions = await prisma.auction.findMany({
      where: {
        status: 'ACTIVE',
        endTime: { lte: now },
      },
      include: {
        bids: {
          where: { isWinning: true },
          include: {
            bidder: true,
          },
        },
      },
    });

    for (const auction of expiredAuctions) {
      await this.endAuction(auction.id);
    }

    return expiredAuctions.length;
  }

  getTimeRemaining(endTime: Date): {
    days: number;
    hours: number;
    minutes: number;
    seconds: number;
    isExpired: boolean;
  } {
    const now = new Date();
    const timeLeft = endTime.getTime() - now.getTime();

    if (timeLeft <= 0) {
      return {
        days: 0,
        hours: 0,
        minutes: 0,
        seconds: 0,
        isExpired: true,
      };
    }

    const days = Math.floor(timeLeft / (1000 * 60 * 60 * 24));
    const hours = Math.floor((timeLeft % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const minutes = Math.floor((timeLeft % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((timeLeft % (1000 * 60)) / 1000);

    return {
      days,
      hours,
      minutes,
      seconds,
      isExpired: false,
    };
  }
}

export default new AuctionService();
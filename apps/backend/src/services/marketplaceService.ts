import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export interface CreateMarketplaceItemData {
  title: string;
  description: string;
  category: string;
  condition: 'NEW' | 'LIKE_NEW' | 'GOOD' | 'FAIR' | 'POOR';
  price: number;
  images: string[];
  location?: string;
  isNegotiable?: boolean;
}

export interface UpdateMarketplaceItemData {
  title?: string;
  description?: string;
  price?: number;
  condition?: 'NEW' | 'LIKE_NEW' | 'GOOD' | 'FAIR' | 'POOR';
  location?: string;
  isNegotiable?: boolean;
  status?: 'ACTIVE' | 'SOLD' | 'RESERVED' | 'INACTIVE';
}

export interface MarketplaceFilters {
  category?: string;
  condition?: string;
  minPrice?: number;
  maxPrice?: number;
  location?: string;
  isNegotiable?: boolean;
  status?: string;
  search?: string;
}

class MarketplaceService {
  async createItem(sellerId: string, data: CreateMarketplaceItemData) {
    return await prisma.marketplaceItem.create({
      data: {
        ...data,
        images: data.images,
        sellerId,
      },
      include: {
        seller: {
          select: {
            id: true,
            name: true,
            profileImage: true,
            level: true,
          },
        },
        _count: {
          select: {
            bids: true,
            offers: true,
            favorites: true,
          },
        },
      },
    });
  }

  async getItems(filters: MarketplaceFilters = {}, page = 1, limit = 20) {
    const where: any = {};

    if (filters.category) {
      where.category = filters.category;
    }
    if (filters.condition) {
      where.condition = filters.condition;
    }
    if (filters.minPrice !== undefined || filters.maxPrice !== undefined) {
      where.price = {};
      if (filters.minPrice !== undefined) {
        where.price.gte = filters.minPrice;
      }
      if (filters.maxPrice !== undefined) {
        where.price.lte = filters.maxPrice;
      }
    }
    if (filters.location) {
      where.location = {
        contains: filters.location,
        mode: 'insensitive',
      };
    }
    if (filters.isNegotiable !== undefined) {
      where.isNegotiable = filters.isNegotiable;
    }
    if (filters.status) {
      where.status = filters.status;
    } else {
      where.status = 'ACTIVE'; // Default to active items
    }
    if (filters.search) {
      where.OR = [
        { title: { contains: filters.search, mode: 'insensitive' } },
        { description: { contains: filters.search, mode: 'insensitive' } },
      ];
    }

    const [items, total] = await Promise.all([
      prisma.marketplaceItem.findMany({
        where,
        include: {
          seller: {
            select: {
              id: true,
              name: true,
              profileImage: true,
              level: true,
            },
          },
          auction: {
            select: {
              id: true,
              currentBid: true,
              endTime: true,
              status: true,
            },
          },
          _count: {
            select: {
              bids: true,
              offers: true,
              favorites: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.marketplaceItem.count({ where }),
    ]);

    return {
      items,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  async getItem(itemId: string, viewerId?: string) {
    // Increment view count
    await prisma.marketplaceItem.update({
      where: { id: itemId },
      data: { views: { increment: 1 } },
    });

    const item = await prisma.marketplaceItem.findUnique({
      where: { id: itemId },
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
        auction: {
          include: {
            bids: {
              include: {
                bidder: {
                  select: {
                    id: true,
                    name: true,
                  },
                },
              },
              orderBy: { createdAt: 'desc' },
              take: 5,
            },
          },
        },
        offers: {
          where: viewerId ? { buyerId: viewerId } : undefined,
          include: {
            buyer: {
              select: {
                id: true,
                name: true,
              },
            },
          },
          orderBy: { createdAt: 'desc' },
        },
        _count: {
          select: {
            bids: true,
            offers: true,
            favorites: true,
          },
        },
      },
    });

    if (!item) {
      throw new Error('Item not found');
    }

    return item;
  }

  async updateItem(itemId: string, sellerId: string, data: UpdateMarketplaceItemData) {
    const item = await prisma.marketplaceItem.findUnique({
      where: { id: itemId },
    });

    if (!item) {
      throw new Error('Item not found');
    }

    if (item.sellerId !== sellerId) {
      throw new Error('Unauthorized');
    }

    return await prisma.marketplaceItem.update({
      where: { id: itemId },
      data,
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
    });
  }

  async deleteItem(itemId: string, sellerId: string) {
    const item = await prisma.marketplaceItem.findUnique({
      where: { id: itemId },
    });

    if (!item) {
      throw new Error('Item not found');
    }

    if (item.sellerId !== sellerId) {
      throw new Error('Unauthorized');
    }

    // Soft delete by updating status
    return await prisma.marketplaceItem.update({
      where: { id: itemId },
      data: { status: 'DELETED' },
    });
  }

  async getUserItems(userId: string, page = 1, limit = 20) {
    const [items, total] = await Promise.all([
      prisma.marketplaceItem.findMany({
        where: {
          sellerId: userId,
          status: { not: 'DELETED' },
        },
        include: {
          auction: {
            select: {
              id: true,
              currentBid: true,
              endTime: true,
              status: true,
            },
          },
          _count: {
            select: {
              bids: true,
              offers: true,
              favorites: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.marketplaceItem.count({
        where: {
          sellerId: userId,
          status: { not: 'DELETED' },
        },
      }),
    ]);

    return {
      items,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  async addToFavorites(userId: string, itemId: string) {
    try {
      return await prisma.userFavorite.create({
        data: {
          userId,
          itemId,
        },
      });
    } catch (error: any) {
      if (error.code === 'P2002') {
        throw new Error('Item already in favorites');
      }
      throw error;
    }
  }

  async removeFromFavorites(userId: string, itemId: string) {
    return await prisma.userFavorite.delete({
      where: {
        userId_itemId: {
          userId,
          itemId,
        },
      },
    });
  }

  async getUserFavorites(userId: string, page = 1, limit = 20) {
    const [favorites, total] = await Promise.all([
      prisma.userFavorite.findMany({
        where: { userId },
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
              auction: {
                select: {
                  id: true,
                  currentBid: true,
                  endTime: true,
                  status: true,
                },
              },
              _count: {
                select: {
                  bids: true,
                  offers: true,
                  favorites: true,
                },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.userFavorite.count({ where: { userId } }),
    ]);

    return {
      items: favorites.map(fav => fav.item),
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  async getCategories() {
    const categories = await prisma.marketplaceItem.groupBy({
      by: ['category'],
      where: {
        status: 'ACTIVE',
      },
      _count: {
        category: true,
      },
      orderBy: {
        _count: {
          category: 'desc',
        },
      },
    });

    return categories.map(cat => ({
      name: cat.category,
      count: cat._count.category,
    }));
  }
}

export default new MarketplaceService();
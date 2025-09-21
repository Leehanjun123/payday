import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export interface CreatePortfolioData {
  name: string;
  description?: string;
}

export interface AddHoldingData {
  symbol: string;
  name: string;
  type: 'STOCK_KR' | 'STOCK_US' | 'CRYPTO' | 'REAL_ESTATE' | 'FUND' | 'BOND' | 'COMMODITY' | 'ETF';
  quantity: number;
  price: number;
}

export interface AddTransactionData {
  holdingId?: string;
  symbol: string;
  type: 'BUY' | 'SELL' | 'DIVIDEND' | 'SPLIT' | 'DEPOSIT' | 'WITHDRAWAL';
  quantity: number;
  price: number;
  fee?: number;
  note?: string;
  executedAt: Date;
}

export interface MarketDataUpdate {
  symbol: string;
  name: string;
  type: string;
  currentPrice: number;
  change?: number;
  changePercent?: number;
  volume?: number;
  marketCap?: number;
  high52w?: number;
  low52w?: number;
}

class InvestmentService {
  // Portfolio Management
  async createPortfolio(userId: string, data: CreatePortfolioData) {
    return await prisma.portfolio.create({
      data: {
        userId,
        ...data,
      },
      include: {
        holdings: true,
        _count: {
          select: {
            holdings: true,
            transactions: true,
          },
        },
      },
    });
  }

  async getUserPortfolios(userId: string) {
    return await prisma.portfolio.findMany({
      where: {
        userId,
        isActive: true,
      },
      include: {
        holdings: true,
        _count: {
          select: {
            holdings: true,
            transactions: true,
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getPortfolio(portfolioId: string, userId: string) {
    const portfolio = await prisma.portfolio.findFirst({
      where: {
        id: portfolioId,
        userId,
      },
      include: {
        holdings: {
          include: {
            transactions: {
              orderBy: { executedAt: 'desc' },
              take: 5,
            },
          },
        },
        transactions: {
          orderBy: { executedAt: 'desc' },
          take: 10,
        },
      },
    });

    if (!portfolio) {
      throw new Error('Portfolio not found');
    }

    return portfolio;
  }

  async updatePortfolio(portfolioId: string, userId: string, data: Partial<CreatePortfolioData>) {
    const portfolio = await prisma.portfolio.findFirst({
      where: { id: portfolioId, userId },
    });

    if (!portfolio) {
      throw new Error('Portfolio not found');
    }

    return await prisma.portfolio.update({
      where: { id: portfolioId },
      data,
    });
  }

  async deletePortfolio(portfolioId: string, userId: string) {
    const portfolio = await prisma.portfolio.findFirst({
      where: { id: portfolioId, userId },
    });

    if (!portfolio) {
      throw new Error('Portfolio not found');
    }

    return await prisma.portfolio.update({
      where: { id: portfolioId },
      data: { isActive: false },
    });
  }

  // Holdings Management
  async addHolding(portfolioId: string, userId: string, data: AddHoldingData) {
    // Verify portfolio ownership
    const portfolio = await prisma.portfolio.findFirst({
      where: { id: portfolioId, userId },
    });

    if (!portfolio) {
      throw new Error('Portfolio not found');
    }

    // Check if holding already exists
    const existingHolding = await prisma.holding.findUnique({
      where: {
        portfolioId_symbol: {
          portfolioId,
          symbol: data.symbol,
        },
      },
    });

    if (existingHolding) {
      throw new Error('Holding already exists for this symbol');
    }

    const totalCost = data.quantity * data.price;

    const holding = await prisma.holding.create({
      data: {
        portfolioId,
        symbol: data.symbol,
        name: data.name,
        type: data.type,
        quantity: data.quantity,
        averagePrice: data.price,
        currentPrice: data.price,
        totalValue: totalCost,
        profitLoss: 0,
        profitLossRate: 0,
      },
    });

    // Create initial transaction
    await this.addTransaction(portfolioId, userId, {
      holdingId: holding.id,
      symbol: data.symbol,
      type: 'BUY',
      quantity: data.quantity,
      price: data.price,
      executedAt: new Date(),
    });

    await this.updatePortfolioValue(portfolioId);

    return holding;
  }

  async updateHolding(holdingId: string, userId: string, currentPrice: number) {
    const holding = await prisma.holding.findFirst({
      where: {
        id: holdingId,
        portfolio: { userId },
      },
    });

    if (!holding) {
      throw new Error('Holding not found');
    }

    const totalValue = holding.quantity * currentPrice;
    const totalCost = holding.quantity * holding.averagePrice;
    const profitLoss = totalValue - totalCost;
    const profitLossRate = totalCost > 0 ? (profitLoss / totalCost) * 100 : 0;

    return await prisma.holding.update({
      where: { id: holdingId },
      data: {
        currentPrice,
        totalValue,
        profitLoss,
        profitLossRate,
      },
    });
  }

  async removeHolding(holdingId: string, userId: string) {
    const holding = await prisma.holding.findFirst({
      where: {
        id: holdingId,
        portfolio: { userId },
      },
    });

    if (!holding) {
      throw new Error('Holding not found');
    }

    await prisma.holding.delete({
      where: { id: holdingId },
    });

    await this.updatePortfolioValue(holding.portfolioId);
  }

  // Transaction Management
  async addTransaction(portfolioId: string, userId: string, data: AddTransactionData) {
    const portfolio = await prisma.portfolio.findFirst({
      where: { id: portfolioId, userId },
    });

    if (!portfolio) {
      throw new Error('Portfolio not found');
    }

    const totalAmount = data.quantity * data.price;

    const transaction = await prisma.transaction.create({
      data: {
        portfolioId,
        holdingId: data.holdingId,
        symbol: data.symbol,
        type: data.type,
        quantity: data.quantity,
        price: data.price,
        totalAmount,
        fee: data.fee || 0,
        note: data.note,
        executedAt: data.executedAt,
      },
    });

    // Update holding if it's a buy/sell transaction
    if (data.holdingId && (data.type === 'BUY' || data.type === 'SELL')) {
      await this.recalculateHolding(data.holdingId);
    }

    await this.updatePortfolioValue(portfolioId);

    return transaction;
  }

  async getTransactionHistory(portfolioId: string, userId: string, page = 1, limit = 20) {
    const portfolio = await prisma.portfolio.findFirst({
      where: { id: portfolioId, userId },
    });

    if (!portfolio) {
      throw new Error('Portfolio not found');
    }

    const [transactions, total] = await Promise.all([
      prisma.transaction.findMany({
        where: { portfolioId },
        orderBy: { executedAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.transaction.count({ where: { portfolioId } }),
    ]);

    return {
      transactions,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  // Market Data Management
  async updateMarketData(data: MarketDataUpdate) {
    return await prisma.marketData.upsert({
      where: { symbol: data.symbol },
      update: {
        name: data.name,
        type: data.type as any,
        currentPrice: data.currentPrice,
        change: data.change || 0,
        changePercent: data.changePercent || 0,
        volume: data.volume || 0,
        marketCap: data.marketCap,
        high52w: data.high52w,
        low52w: data.low52w,
      },
      create: {
        symbol: data.symbol,
        name: data.name,
        type: data.type as any,
        currentPrice: data.currentPrice,
        change: data.change || 0,
        changePercent: data.changePercent || 0,
        volume: data.volume || 0,
        marketCap: data.marketCap,
        high52w: data.high52w,
        low52w: data.low52w,
      },
    });
  }

  async getMarketData(symbols: string[]) {
    return await prisma.marketData.findMany({
      where: {
        symbol: { in: symbols },
      },
    });
  }

  async searchMarketData(query: string, type?: string) {
    const where: any = {
      OR: [
        { symbol: { contains: query, mode: 'insensitive' } },
        { name: { contains: query, mode: 'insensitive' } },
      ],
    };

    if (type) {
      where.type = type;
    }

    return await prisma.marketData.findMany({
      where,
      take: 20,
      orderBy: { symbol: 'asc' },
    });
  }

  // Watchlist Management
  async addToWatchlist(userId: string, symbol: string, name: string, type: string) {
    try {
      return await prisma.watchlist.create({
        data: {
          userId,
          symbol,
          name,
          type: type as any,
        },
      });
    } catch (error: any) {
      if (error.code === 'P2002') {
        throw new Error('Symbol already in watchlist');
      }
      throw error;
    }
  }

  async removeFromWatchlist(userId: string, symbol: string) {
    return await prisma.watchlist.delete({
      where: {
        userId_symbol: {
          userId,
          symbol,
        },
      },
    });
  }

  async getUserWatchlist(userId: string) {
    const watchlist = await prisma.watchlist.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    const symbols = watchlist.map(item => item.symbol);
    const marketData = await this.getMarketData(symbols);

    return watchlist.map(item => ({
      ...item,
      marketData: marketData.find(data => data.symbol === item.symbol),
    }));
  }

  // Portfolio Analytics
  async getPortfolioAnalytics(portfolioId: string, userId: string) {
    const portfolio = await this.getPortfolio(portfolioId, userId);

    const totalValue = portfolio.holdings.reduce((sum, holding) => sum + holding.totalValue, 0);
    const totalCost = portfolio.holdings.reduce((sum, holding) => sum + (holding.quantity * holding.averagePrice), 0);
    const totalProfitLoss = totalValue - totalCost;
    const totalProfitLossRate = totalCost > 0 ? (totalProfitLoss / totalCost) * 100 : 0;

    const assetAllocation = portfolio.holdings.reduce((acc: any, holding) => {
      const type = holding.type;
      if (!acc[type]) {
        acc[type] = { value: 0, percentage: 0 };
      }
      acc[type].value += holding.totalValue;
      return acc;
    }, {});

    // Calculate percentages
    Object.keys(assetAllocation).forEach(type => {
      assetAllocation[type].percentage = totalValue > 0 ? (assetAllocation[type].value / totalValue) * 100 : 0;
    });

    return {
      totalValue,
      totalCost,
      totalProfitLoss,
      totalProfitLossRate,
      assetAllocation,
      topHoldings: portfolio.holdings
        .sort((a, b) => b.totalValue - a.totalValue)
        .slice(0, 5),
    };
  }

  // Private helper methods
  private async recalculateHolding(holdingId: string) {
    const holding = await prisma.holding.findUnique({
      where: { id: holdingId },
      include: {
        transactions: {
          where: {
            type: { in: ['BUY', 'SELL'] },
          },
          orderBy: { executedAt: 'asc' },
        },
      },
    });

    if (!holding) return;

    let totalQuantity = 0;
    let totalCost = 0;

    holding.transactions.forEach(transaction => {
      if (transaction.type === 'BUY') {
        totalQuantity += transaction.quantity;
        totalCost += transaction.totalAmount;
      } else if (transaction.type === 'SELL') {
        totalQuantity -= transaction.quantity;
        // For sold shares, reduce cost proportionally
        const costPerShare = totalCost / (totalQuantity + transaction.quantity);
        totalCost -= costPerShare * transaction.quantity;
      }
    });

    const averagePrice = totalQuantity > 0 ? totalCost / totalQuantity : 0;
    const totalValue = totalQuantity * holding.currentPrice;
    const profitLoss = totalValue - totalCost;
    const profitLossRate = totalCost > 0 ? (profitLoss / totalCost) * 100 : 0;

    await prisma.holding.update({
      where: { id: holdingId },
      data: {
        quantity: totalQuantity,
        averagePrice,
        totalValue,
        profitLoss,
        profitLossRate,
      },
    });
  }

  private async updatePortfolioValue(portfolioId: string) {
    const holdings = await prisma.holding.findMany({
      where: { portfolioId },
    });

    const totalValue = holdings.reduce((sum, holding) => sum + holding.totalValue, 0);
    const totalCost = holdings.reduce((sum, holding) => sum + (holding.quantity * holding.averagePrice), 0);

    await prisma.portfolio.update({
      where: { id: portfolioId },
      data: {
        totalValue,
        totalCost,
      },
    });
  }

  // Market data simulation (for demo purposes)
  async simulateMarketUpdate() {
    const marketData = await prisma.marketData.findMany();

    for (const data of marketData) {
      const changePercent = (Math.random() - 0.5) * 10; // Random change between -5% and +5%
      const newPrice = data.currentPrice * (1 + changePercent / 100);
      const change = newPrice - data.currentPrice;

      await prisma.marketData.update({
        where: { id: data.id },
        data: {
          currentPrice: newPrice,
          change,
          changePercent,
        },
      });

      // Update all holdings with this symbol
      const holdings = await prisma.holding.findMany({
        where: { symbol: data.symbol },
      });

      for (const holding of holdings) {
        await this.updateHolding(holding.id, '', newPrice);
      }
    }
  }
}

export default new InvestmentService();
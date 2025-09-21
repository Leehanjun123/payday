import apiClient from './apiClient';
import { MarketplaceItem } from './marketplaceService';

export interface Auction {
  id: string;
  itemId: string;
  startPrice: number;
  currentBid?: number;
  buyNowPrice?: number;
  startTime: string;
  endTime: string;
  status: 'SCHEDULED' | 'ACTIVE' | 'ENDED' | 'CANCELLED';
  winnerId?: string;
  createdAt: string;
  updatedAt: string;
  item: MarketplaceItem;
  winner?: {
    id: string;
    name: string;
    profileImage?: string;
  };
  bids: Bid[];
  _count?: {
    bids: number;
  };
}

export interface Bid {
  id: string;
  itemId: string;
  auctionId?: string;
  amount: number;
  isWinning: boolean;
  createdAt: string;
  bidder: {
    id: string;
    name: string;
    profileImage?: string;
  };
  item?: MarketplaceItem;
  auction?: {
    id: string;
    endTime: string;
    status: string;
    winnerId?: string;
  };
}

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

export interface TimeRemaining {
  days: number;
  hours: number;
  minutes: number;
  seconds: number;
  isExpired: boolean;
}

export interface AuctionResponse {
  auctions: Auction[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

export interface BidResponse {
  bids: Bid[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

class AuctionService {
  async getAuctions(
    status?: string,
    page = 1,
    limit = 20
  ): Promise<AuctionResponse> {
    const params = new URLSearchParams({
      page: String(page),
      limit: String(limit),
    });

    if (status) {
      params.append('status', status);
    }

    return apiClient.get(`/api/v1/auctions?${params.toString()}`);
  }

  async createAuction(data: CreateAuctionData): Promise<{ message: string; auction: Auction }> {
    return apiClient.post('/api/v1/auctions', {
      ...data,
      startTime: data.startTime.toISOString(),
      endTime: data.endTime.toISOString(),
    });
  }

  async getAuction(auctionId: string): Promise<{ auction: Auction }> {
    return apiClient.get(`/api/v1/auctions/${auctionId}`);
  }

  async placeBid(auctionId: string, data: PlaceBidData): Promise<{ message: string; bid: Bid }> {
    return apiClient.post(`/api/v1/auctions/${auctionId}/bids`, data);
  }

  async endAuction(auctionId: string): Promise<{ message: string; auction: Auction }> {
    return apiClient.post(`/api/v1/auctions/${auctionId}/end`);
  }

  async getUserBids(page = 1, limit = 20): Promise<BidResponse> {
    const params = new URLSearchParams({
      page: String(page),
      limit: String(limit),
    });

    return apiClient.get(`/api/v1/auctions/user/bids?${params.toString()}`);
  }

  async getUserAuctions(page = 1, limit = 20): Promise<AuctionResponse> {
    const params = new URLSearchParams({
      page: String(page),
      limit: String(limit),
    });

    return apiClient.get(`/api/v1/auctions/user/auctions?${params.toString()}`);
  }

  async getTimeRemaining(auctionId: string): Promise<{ timeRemaining: TimeRemaining }> {
    return apiClient.get(`/api/v1/auctions/${auctionId}/time-remaining`);
  }

  calculateTimeRemaining(endTime: string): TimeRemaining {
    const now = new Date();
    const end = new Date(endTime);
    const timeLeft = end.getTime() - now.getTime();

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

  formatTimeRemaining(timeRemaining: TimeRemaining): string {
    if (timeRemaining.isExpired) {
      return '경매 종료';
    }

    if (timeRemaining.days > 0) {
      return `${timeRemaining.days}일 ${timeRemaining.hours}시간`;
    } else if (timeRemaining.hours > 0) {
      return `${timeRemaining.hours}시간 ${timeRemaining.minutes}분`;
    } else if (timeRemaining.minutes > 0) {
      return `${timeRemaining.minutes}분 ${timeRemaining.seconds}초`;
    } else {
      return `${timeRemaining.seconds}초`;
    }
  }

  formatPrice(price: number): string {
    return `₩${price.toLocaleString('ko-KR')}`;
  }

  getStatusText(status: string): string {
    switch (status) {
      case 'SCHEDULED':
        return '경매 예정';
      case 'ACTIVE':
        return '경매 진행중';
      case 'ENDED':
        return '경매 종료';
      case 'CANCELLED':
        return '경매 취소';
      default:
        return status;
    }
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'SCHEDULED':
        return '#FF9800';
      case 'ACTIVE':
        return '#4CAF50';
      case 'ENDED':
        return '#666';
      case 'CANCELLED':
        return '#F44336';
      default:
        return '#666';
    }
  }

  calculateMinimumBid(currentBid?: number, startPrice?: number): number {
    const basePrice = currentBid || startPrice || 0;
    return basePrice + 1000; // Minimum increment of 1000 KRW
  }

  isAuctionActive(auction: Auction): boolean {
    const now = new Date();
    const startTime = new Date(auction.startTime);
    const endTime = new Date(auction.endTime);

    return auction.status === 'ACTIVE' && now >= startTime && now <= endTime;
  }

  isUserWinning(auction: Auction, userId: string): boolean {
    if (!auction.bids || auction.bids.length === 0) {
      return false;
    }

    const winningBid = auction.bids.find(bid => bid.isWinning);
    return winningBid?.bidder.id === userId;
  }

  getHighestBid(auction: Auction): Bid | null {
    if (!auction.bids || auction.bids.length === 0) {
      return null;
    }

    return auction.bids.reduce((highest, current) =>
      current.amount > highest.amount ? current : highest
    );
  }

  getBidIncrement(currentPrice: number): number {
    if (currentPrice < 10000) {
      return 1000;
    } else if (currentPrice < 50000) {
      return 5000;
    } else if (currentPrice < 100000) {
      return 10000;
    } else if (currentPrice < 500000) {
      return 50000;
    } else {
      return 100000;
    }
  }

  getSuggestedBids(currentBid?: number, startPrice?: number): number[] {
    const basePrice = currentBid || startPrice || 0;
    const increment = this.getBidIncrement(basePrice);

    return [
      basePrice + increment,
      basePrice + increment * 2,
      basePrice + increment * 3,
      basePrice + increment * 5,
    ];
  }

  formatDateTime(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('ko-KR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  }

  formatDateTimeShort(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString('ko-KR', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  }
}

export default new AuctionService();
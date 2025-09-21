import apiClient from './apiClient';

export interface MarketplaceItem {
  id: string;
  title: string;
  description: string;
  category: string;
  condition: 'NEW' | 'LIKE_NEW' | 'GOOD' | 'FAIR' | 'POOR';
  price: number;
  images: string[];
  location?: string;
  isNegotiable: boolean;
  status: 'ACTIVE' | 'SOLD' | 'RESERVED' | 'INACTIVE' | 'DELETED';
  views: number;
  createdAt: string;
  updatedAt: string;
  seller: {
    id: string;
    name: string;
    profileImage?: string;
    level: number;
  };
  auction?: {
    id: string;
    currentBid?: number;
    endTime: string;
    status: string;
  };
  _count: {
    bids: number;
    offers: number;
    favorites: number;
  };
}

export interface MarketplaceCategory {
  name: string;
  count: number;
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

export interface Offer {
  id: string;
  itemId: string;
  amount: number;
  message?: string;
  status: 'PENDING' | 'ACCEPTED' | 'REJECTED' | 'WITHDRAWN' | 'EXPIRED';
  createdAt: string;
  updatedAt: string;
  buyer: {
    id: string;
    name: string;
    profileImage?: string;
    level: number;
  };
  item: MarketplaceItem;
}

export interface CreateOfferData {
  amount: number;
  message?: string;
}

export interface MarketplaceResponse {
  items: MarketplaceItem[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

class MarketplaceService {
  async getItems(
    filters: MarketplaceFilters = {},
    page = 1,
    limit = 20
  ): Promise<MarketplaceResponse> {
    const params = new URLSearchParams({
      page: String(page),
      limit: String(limit),
    });

    Object.entries(filters).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') {
        params.append(key, String(value));
      }
    });

    return apiClient.get(`/api/v1/marketplace?${params.toString()}`);
  }

  async getCategories(): Promise<{ categories: MarketplaceCategory[] }> {
    return apiClient.get('/api/v1/marketplace/categories');
  }

  async createItem(data: CreateMarketplaceItemData): Promise<{ message: string; item: MarketplaceItem }> {
    return apiClient.post('/api/v1/marketplace', data);
  }

  async getItem(itemId: string): Promise<{ item: MarketplaceItem }> {
    return apiClient.get(`/api/v1/marketplace/${itemId}`);
  }

  async updateItem(
    itemId: string,
    data: UpdateMarketplaceItemData
  ): Promise<{ message: string; item: MarketplaceItem }> {
    return apiClient.put(`/api/v1/marketplace/${itemId}`, data);
  }

  async deleteItem(itemId: string): Promise<{ message: string }> {
    return apiClient.delete(`/api/v1/marketplace/${itemId}`);
  }

  async getUserItems(page = 1, limit = 20): Promise<MarketplaceResponse> {
    const params = new URLSearchParams({
      page: String(page),
      limit: String(limit),
    });

    return apiClient.get(`/api/v1/marketplace/user/items?${params.toString()}`);
  }

  async addToFavorites(itemId: string): Promise<{ message: string }> {
    return apiClient.post(`/api/v1/marketplace/${itemId}/favorite`);
  }

  async removeFromFavorites(itemId: string): Promise<{ message: string }> {
    return apiClient.delete(`/api/v1/marketplace/${itemId}/favorite`);
  }

  async getFavorites(page = 1, limit = 20): Promise<MarketplaceResponse> {
    const params = new URLSearchParams({
      page: String(page),
      limit: String(limit),
    });

    return apiClient.get(`/api/v1/marketplace/user/favorites?${params.toString()}`);
  }

  async createOffer(itemId: string, data: CreateOfferData): Promise<{ message: string; offer: Offer }> {
    return apiClient.post(`/api/v1/marketplace/${itemId}/offers`, data);
  }

  async getItemOffers(itemId: string): Promise<{ offers: Offer[] }> {
    return apiClient.get(`/api/v1/marketplace/${itemId}/offers`);
  }

  async getUserOffers(
    type: 'sent' | 'received',
    page = 1,
    limit = 20
  ): Promise<{ offers: Offer[]; pagination: any }> {
    const params = new URLSearchParams({
      page: String(page),
      limit: String(limit),
    });

    return apiClient.get(`/api/v1/marketplace/user/offers/${type}?${params.toString()}`);
  }

  async updateOffer(offerId: string, data: { amount?: number; message?: string }): Promise<{ message: string; offer: Offer }> {
    return apiClient.put(`/api/v1/marketplace/offers/${offerId}`, data);
  }

  async acceptOffer(offerId: string): Promise<{ message: string; offer: Offer }> {
    return apiClient.post(`/api/v1/marketplace/offers/${offerId}/accept`);
  }

  async rejectOffer(offerId: string): Promise<{ message: string; offer: Offer }> {
    return apiClient.post(`/api/v1/marketplace/offers/${offerId}/reject`);
  }

  async withdrawOffer(offerId: string): Promise<{ message: string; offer: Offer }> {
    return apiClient.post(`/api/v1/marketplace/offers/${offerId}/withdraw`);
  }

  formatPrice(price: number): string {
    return `₩${price.toLocaleString('ko-KR')}`;
  }

  getConditionText(condition: string): string {
    switch (condition) {
      case 'NEW':
        return '새 상품';
      case 'LIKE_NEW':
        return '거의 새 것';
      case 'GOOD':
        return '좋음';
      case 'FAIR':
        return '보통';
      case 'POOR':
        return '나쁨';
      default:
        return condition;
    }
  }

  getConditionColor(condition: string): string {
    switch (condition) {
      case 'NEW':
        return '#4CAF50';
      case 'LIKE_NEW':
        return '#8BC34A';
      case 'GOOD':
        return '#FF9800';
      case 'FAIR':
        return '#FF5722';
      case 'POOR':
        return '#F44336';
      default:
        return '#666';
    }
  }

  getStatusText(status: string): string {
    switch (status) {
      case 'ACTIVE':
        return '판매중';
      case 'SOLD':
        return '판매완료';
      case 'RESERVED':
        return '예약중';
      case 'INACTIVE':
        return '비활성';
      default:
        return status;
    }
  }

  getStatusColor(status: string): string {
    switch (status) {
      case 'ACTIVE':
        return '#4CAF50';
      case 'SOLD':
        return '#666';
      case 'RESERVED':
        return '#FF9800';
      case 'INACTIVE':
        return '#F44336';
      default:
        return '#666';
    }
  }

  getOfferStatusText(status: string): string {
    switch (status) {
      case 'PENDING':
        return '대기중';
      case 'ACCEPTED':
        return '수락됨';
      case 'REJECTED':
        return '거절됨';
      case 'WITHDRAWN':
        return '철회됨';
      case 'EXPIRED':
        return '만료됨';
      default:
        return status;
    }
  }

  getOfferStatusColor(status: string): string {
    switch (status) {
      case 'PENDING':
        return '#FF9800';
      case 'ACCEPTED':
        return '#4CAF50';
      case 'REJECTED':
        return '#F44336';
      case 'WITHDRAWN':
        return '#9C27B0';
      case 'EXPIRED':
        return '#666';
      default:
        return '#666';
    }
  }
}

export default new MarketplaceService();
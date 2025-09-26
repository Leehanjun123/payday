import { prisma } from '../lib/prisma';

// 디지털 콘텐츠 거래 (NFT 아닌 일반 디지털 자산)
interface DigitalAsset {
  id: string;
  type: 'PHOTO' | 'VIDEO' | 'MUSIC' | 'TEMPLATE' | 'DATASET';
  title: string;
  price: number;
  creatorId: string;
  royaltyPercentage: number; // 창작자 로열티 5~15%
  license: 'PERSONAL' | 'COMMERCIAL' | 'EXTENDED';
}

interface VirtualGoods {
  id: string;
  name: string;
  category: 'GAME_ITEM' | 'AVATAR' | 'EMOJI' | 'FILTER';
  price: number; // $0.10~10.00
  limitedEdition: boolean;
  totalSupply?: number;
}

class DigitalAssetService {
  private static instance: DigitalAssetService;

  static getInstance(): DigitalAssetService {
    if (!DigitalAssetService.instance) {
      DigitalAssetService.instance = new DigitalAssetService();
    }
    return DigitalAssetService.instance;
  }

  // 사용자 제작 콘텐츠 판매
  async sellUserContent(userId: string, content: Partial<DigitalAsset>): Promise<number> {
    const pricing = {
      'STOCK_PHOTO': { min: 0.50, max: 5.00 }, // $0.50~5 (650~6,500원)
      'VIDEO_CLIP': { min: 2.00, max: 20.00 }, // $2~20 (2,600~26,000원)
      'MUSIC_BEAT': { min: 5.00, max: 50.00 }, // $5~50 (6,500~65,000원)
      'DESIGN_TEMPLATE': { min: 1.00, max: 10.00 }, // $1~10 (1,300~13,000원)
    };

    // 플랫폼 수수료 30%
    const platformFee = 0.30;
    const creatorEarning = 5.00 * (1 - platformFee); // 예시

    return creatorEarning;
  }

  // 가상 상품 거래
  async tradeVirtualGoods(buyerId: string, itemId: string, price: number) {
    // 게임 아이템, 아바타 등 거래
    // 중개 수수료 10%
    const tradingFee = price * 0.10;

    return {
      buyerPays: price,
      sellerReceives: price - tradingFee,
      platformEarns: tradingFee
    };
  }
}
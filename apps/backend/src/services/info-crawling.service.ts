import axios from 'axios';
import * as cheerio from 'cheerio';

// 수익 정보 크롤링 및 제공 서비스
interface EarningOpportunity {
  id: string;
  title: string;
  category: 'INVESTMENT' | 'FREELANCE' | 'AUCTION' | 'CROWDFUNDING' | 'CRYPTO' | 'STOCK';
  platform: string;
  potentialEarning: string;
  difficulty: 'EASY' | 'MEDIUM' | 'HARD';
  timeRequired: string;
  description: string;
  howToStart: string[];
  platformUrl: string;
  requirements: string[];
  pros: string[];
  cons: string[];
}

class InfoCrawlingService {
  private static instance: InfoCrawlingService;

  static getInstance(): InfoCrawlingService {
    if (!InfoCrawlingService.instance) {
      InfoCrawlingService.instance = new InfoCrawlingService();
    }
    return InfoCrawlingService.instance;
  }

  // 경매 플랫폼 정보 제공
  getAuctionPlatforms(): EarningOpportunity[] {
    return [
      {
        id: 'auction_1',
        title: '중고나라 경매',
        category: 'AUCTION',
        platform: '중고나라',
        potentialEarning: '월 10~100만원',
        difficulty: 'MEDIUM',
        timeRequired: '일 1~2시간',
        description: '희귀 물품, 한정판 제품 경매로 수익 창출',
        howToStart: [
          '1. 중고나라 가입',
          '2. 시세 파악 및 물품 리서치',
          '3. 저가 매입 → 고가 판매',
          '4. 경매 타이밍 파악'
        ],
        platformUrl: 'https://cafe.naver.com/joonggonara',
        requirements: ['초기 자본 10만원 이상', '시장 분석 능력'],
        pros: ['높은 수익률 가능', '재미있는 과정'],
        cons: ['손실 위험', '시간 투자 필요']
      },
      {
        id: 'auction_2',
        title: '이베이 글로벌 셀링',
        category: 'AUCTION',
        platform: 'eBay',
        potentialEarning: '월 50~500만원',
        difficulty: 'HARD',
        timeRequired: '일 3~5시간',
        description: '한국 제품을 해외에 판매하여 수익 창출',
        howToStart: [
          '1. eBay 셀러 계정 생성',
          '2. PayPal 비즈니스 계정 연결',
          '3. 한국 인기 상품 리서치',
          '4. 영어 상품 설명 작성',
          '5. 국제 배송 설정'
        ],
        platformUrl: 'https://www.ebay.com',
        requirements: ['기본 영어 능력', '초기 재고 자금'],
        pros: ['글로벌 시장', '높은 마진'],
        cons: ['환율 리스크', '배송 클레임']
      }
    ];
  }

  // 크라우드펀딩 투자 정보
  getCrowdfundingInfo(): EarningOpportunity[] {
    return [
      {
        id: 'crowd_1',
        title: '와디즈 투자',
        category: 'CROWDFUNDING',
        platform: '와디즈',
        potentialEarning: '연 5~20% 수익',
        difficulty: 'MEDIUM',
        timeRequired: '월 2~3시간',
        description: '스타트업 투자로 수익 창출',
        howToStart: [
          '1. 와디즈 투자자 인증',
          '2. 투자 한도 확인 (연 500만원)',
          '3. 기업 분석 및 선별',
          '4. 분산 투자 진행'
        ],
        platformUrl: 'https://www.wadiz.kr',
        requirements: ['투자자 자격', '여유 자금'],
        pros: ['높은 수익 가능성', '스타트업 지원'],
        cons: ['원금 손실 위험', '유동성 낮음']
      },
      {
        id: 'crowd_2',
        title: '텀블벅 리워드',
        category: 'CROWDFUNDING',
        platform: '텀블벅',
        potentialEarning: '제품 할인 구매',
        difficulty: 'EASY',
        timeRequired: '월 1시간',
        description: '신제품 선구매로 할인 혜택',
        howToStart: [
          '1. 텀블벅 가입',
          '2. 관심 프로젝트 탐색',
          '3. 얼리버드 리워드 선택',
          '4. 펀딩 참여'
        ],
        platformUrl: 'https://tumblbug.com',
        requirements: ['신용카드'],
        pros: ['독특한 제품', '할인 가격'],
        cons: ['배송 지연', '품질 리스크']
      }
    ];
  }

  // P2P 금융 정보
  getP2PFinanceInfo(): EarningOpportunity[] {
    return [
      {
        id: 'p2p_1',
        title: '카카오페이 투자',
        category: 'INVESTMENT',
        platform: '카카오페이',
        potentialEarning: '연 3~8%',
        difficulty: 'EASY',
        timeRequired: '월 30분',
        description: 'P2P 소액 투자',
        howToStart: [
          '1. 카카오페이 앱 설치',
          '2. 투자 서비스 신청',
          '3. 상품별 수익률 비교',
          '4. 분산 투자'
        ],
        platformUrl: 'https://www.kakaopay.com',
        requirements: ['만 19세 이상', '본인 인증'],
        pros: ['간편한 투자', '소액 가능'],
        cons: ['원금 손실 가능', '중도 해지 제한']
      }
    ];
  }

  // 프리랜서 플랫폼 정보
  getFreelancePlatforms(): EarningOpportunity[] {
    return [
      {
        id: 'free_1',
        title: '크몽 재능판매',
        category: 'FREELANCE',
        platform: '크몽',
        potentialEarning: '월 50~500만원',
        difficulty: 'MEDIUM',
        timeRequired: '일 2~8시간',
        description: '전문 기술/재능 판매',
        howToStart: [
          '1. 크몽 전문가 등록',
          '2. 포트폴리오 작성',
          '3. 서비스 가격 설정',
          '4. 홍보 및 리뷰 관리'
        ],
        platformUrl: 'https://kmong.com',
        requirements: ['전문 기술', '포트폴리오'],
        pros: ['자유로운 시간', '높은 단가'],
        cons: ['경쟁 심함', '수수료 20%']
      },
      {
        id: 'free_2',
        title: '숨고 레슨',
        category: 'FREELANCE',
        platform: '숨고',
        potentialEarning: '시간당 3~10만원',
        difficulty: 'EASY',
        timeRequired: '주 5~20시간',
        description: '과외, 레슨 매칭',
        howToStart: [
          '1. 숨고 고수 등록',
          '2. 프로필 인증',
          '3. 견적서 발송',
          '4. 레슨 진행'
        ],
        platformUrl: 'https://soomgo.com',
        requirements: ['전문 분야', '경력 증명'],
        pros: ['지역 기반', '정기 수입'],
        cons: ['초기 고객 확보 어려움']
      }
    ];
  }

  // 암호화폐 정보
  getCryptoInfo(): EarningOpportunity[] {
    return [
      {
        id: 'crypto_1',
        title: '업비트 스테이킹',
        category: 'CRYPTO',
        platform: '업비트',
        potentialEarning: '연 3~12%',
        difficulty: 'EASY',
        timeRequired: '월 1시간',
        description: '암호화폐 스테이킹 보상',
        howToStart: [
          '1. 업비트 가입 및 인증',
          '2. 스테이킹 지원 코인 구매',
          '3. 스테이킹 신청',
          '4. 일일 보상 수령'
        ],
        platformUrl: 'https://upbit.com',
        requirements: ['신분증', '계좌 연결'],
        pros: ['패시브 인컴', '복리 효과'],
        cons: ['코인 가격 변동성', '락업 기간']
      }
    ];
  }

  // 모든 정보 통합 제공
  async getAllEarningInfo(): Promise<EarningOpportunity[]> {
    return [
      ...this.getAuctionPlatforms(),
      ...this.getCrowdfundingInfo(),
      ...this.getP2PFinanceInfo(),
      ...this.getFreelancePlatforms(),
      ...this.getCryptoInfo()
    ];
  }

  // 실시간 정보 크롤링 (법적 문제 없는 공개 정보만)
  async crawlPublicInfo(category: string): Promise<any> {
    // RSS 피드, 공개 API 활용
    const publicSources = {
      'STOCK': 'https://finance.naver.com/rss/',
      'CRYPTO': 'https://api.coingecko.com/api/v3/coins/markets',
      'JOBS': 'https://www.saramin.co.kr/zf_user/rss'
    };

    // 공개된 정보만 수집
    return {
      disclaimer: '제공되는 정보는 참고용이며, 투자 책임은 본인에게 있습니다.',
      source: publicSources[category],
      lastUpdated: new Date()
    };
  }
}

export default InfoCrawlingService;
// 실제 수익 검증된 부업 카테고리 데이터
export const incomeCategories = {
  // 💻 디지털 크리에이티브 (월 50-200만원)
  digital_creative: {
    name: '디지털 크리에이티브',
    icon: '💻',
    averageIncome: '50-200만원',
    subcategories: [
      {
        id: 'blog_adsense',
        name: '블로그 & 애드센스',
        description: '블로그 운영 + 구글 애드센스 광고 수익',
        avgIncome: '30-300만원',
        difficulty: '중급',
        startupCost: '0-10만원',
        timeToProfit: '2-6개월',
        skills: ['글쓰기', 'SEO', '키워드 분석'],
        platforms: ['네이버블로그', '티스토리', '워드프레스'],
        tips: ['특정 키워드 타겟팅', '꾸준한 포스팅', 'SEO 최적화']
      },
      {
        id: 'youtube_shorts',
        name: '유튜브 쇼츠',
        description: '짧은 영상 제작으로 조회수 기반 수익',
        avgIncome: '20-150만원',
        difficulty: '초급',
        startupCost: '0-30만원',
        timeToProfit: '1-3개월',
        skills: ['영상편집', '트렌드 분석', '썸네일 제작'],
        platforms: ['유튜브', '틱톡', '인스타그램 릴스'],
        tips: ['트렌드 키워드 활용', '일관된 업로드', '시청자 참여 유도']
      },
      {
        id: 'design_templates',
        name: '디자인 템플릿 판매',
        description: '미리캔버스, 크몽에서 디자인 자산 판매',
        avgIncome: '30-200만원',
        difficulty: '중급',
        startupCost: '10-50만원',
        timeToProfit: '1-4개월',
        skills: ['포토샵', '일러스트', '디자인 트렌드'],
        platforms: ['미리캔버스', '크몽', 'Shutterstock'],
        tips: ['1000개 이상 등록', '트렌드 연구', '키워드 최적화']
      }
    ]
  },

  // 🛍️ 온라인 커머스 (월 100-500만원)
  online_commerce: {
    name: '온라인 커머스',
    icon: '🛍️',
    averageIncome: '100-500만원',
    subcategories: [
      {
        id: 'coupang_seller',
        name: '쿠팡 온라인 셀러',
        description: '쿠팡 파트너스 + 직접 판매',
        avgIncome: '100-300만원',
        difficulty: '중급',
        startupCost: '100-300만원',
        timeToProfit: '1-2개월',
        skills: ['상품 소싱', '마케팅', '고객 응대'],
        platforms: ['쿠팡', '네이버쇼핑', '11번가'],
        tips: ['원가 1000원 상품도 수익 가능', '트렌드 상품 발굴', 'CS 관리']
      },
      {
        id: 'smart_store',
        name: '스마트스토어 운영',
        description: '네이버 스마트스토어 상품 판매',
        avgIncome: '50-200만원',
        difficulty: '중급',
        startupCost: '50-200만원',
        timeToProfit: '2-4개월',
        skills: ['상품 기획', '마케팅', '재고 관리'],
        platforms: ['네이버 스마트스토어', '카카오톡 스토어'],
        tips: ['상품 차별화', '광고 운영', '리뷰 관리']
      },
      {
        id: 'dropshipping',
        name: '드롭쉬핑',
        description: '재고 없이 중간 유통업',
        avgIncome: '30-150만원',
        difficulty: '초급',
        startupCost: '10-50만원',
        timeToProfit: '1-3개월',
        skills: ['상품 선별', '고객 관리', '공급업체 관리'],
        platforms: ['쇼피파이', '카페24', '메이크샵'],
        tips: ['신뢰할 수 있는 공급업체', '빠른 배송', '품질 관리']
      }
    ]
  },

  // 🚚 플랫폼 서비스 (월 80-200만원)
  platform_services: {
    name: '플랫폼 서비스',
    icon: '🚚',
    averageIncome: '80-200만원',
    subcategories: [
      {
        id: 'delivery_driver',
        name: '배달 라이더',
        description: '배민커넥트, 쿠팡이츠 배달 대행',
        avgIncome: '80-180만원',
        difficulty: '초급',
        startupCost: '50-200만원',
        timeToProfit: '즉시',
        skills: ['운전', '길찾기', '체력 관리'],
        platforms: ['배민커넥트', '쿠팡이츠', '요기요'],
        tips: ['피크타임 집중', '효율적인 동선', '안전 운전'],
        realIncome: {
          baemin: '1건당 3,000-4,000원',
          coupang: '피크타임 높음, 평시 낮음',
          weekly: '하루 3시간 × 7일 = 15-20만원'
        }
      },
      {
        id: 'designated_driver',
        name: '대리운전',
        description: '카카오T 대리, 앱 기반 대리운전',
        avgIncome: '160만원',
        difficulty: '중급',
        startupCost: '10-30만원',
        timeToProfit: '즉시',
        skills: ['운전', '고객 서비스', '야간 근무'],
        platforms: ['카카오T 대리', 'K-대리운전'],
        tips: ['야간/주말 집중', '단골 고객 확보', '안전 운전'],
        realIncome: {
          monthly: '평균 161만원 (수수료 제외 후)',
          hourly: '6,800원 (최저임금 70% 수준)',
          commission: '20% 수수료 + 교통비'
        }
      },
      {
        id: 'quick_service',
        name: '퀵서비스',
        description: '바로고, 부릉 퀵배송 서비스',
        avgIncome: '120-250만원',
        difficulty: '중급',
        startupCost: '100-300만원',
        timeToProfit: '즉시',
        skills: ['오토바이 운전', '배송 관리', '고객 응대'],
        platforms: ['바로고', '부릉', '라스트마일'],
        tips: ['B2B 배송 집중', '정기 고객 확보', '배송 효율성']
      }
    ]
  },

  // 🎨 프리랜서 서비스 (월 50-300만원)
  freelance_services: {
    name: '프리랜서 서비스',
    icon: '🎨',
    averageIncome: '50-300만원',
    subcategories: [
      {
        id: 'design_freelance',
        name: '디자인 프리랜서',
        description: '로고, 브랜딩, 웹디자인 등',
        avgIncome: '80-300만원',
        difficulty: '고급',
        startupCost: '50-200만원',
        timeToProfit: '1-2개월',
        skills: ['포토샵', '일러스트', '디자인 이론'],
        platforms: ['크몽', '탈잉', '프리랜서'],
        tips: ['포트폴리오 구축', '차별화된 스타일', '빠른 소통']
      },
      {
        id: 'development',
        name: '개발 프리랜서',
        description: '웹개발, 앱개발, 자동화 툴',
        avgIncome: '100-500만원',
        difficulty: '고급',
        startupCost: '20-100만원',
        timeToProfit: '1-3개월',
        skills: ['프로그래밍', '데이터베이스', 'API'],
        platforms: ['크몽', '프리랜서', '업워크'],
        tips: ['기술 스택 전문화', '코드 품질', '유지보수 서비스']
      },
      {
        id: 'translation',
        name: '번역 서비스',
        description: '영어, 중국어, 일어 번역',
        avgIncome: '30-120만원',
        difficulty: '중급',
        startupCost: '0-10만원',
        timeToProfit: '즉시',
        skills: ['외국어', '전문 분야 지식', '번역 툴'],
        platforms: ['크몽', '번역센터', '플리토'],
        tips: ['전문 분야 특화', '빠른 납기', '정확성']
      }
    ]
  },

  // 📚 교육 서비스 (월 40-200만원)
  education_services: {
    name: '교육 서비스',
    icon: '📚',
    averageIncome: '40-200만원',
    subcategories: [
      {
        id: 'online_tutoring',
        name: '온라인 과외',
        description: '화상 과외, 온라인 강의',
        avgIncome: '60-200만원',
        difficulty: '중급',
        startupCost: '10-50만원',
        timeToProfit: '즉시',
        skills: ['교수법', '과목 전문성', '소통 능력'],
        platforms: ['탈잉', '클래스101', '숨고'],
        tips: ['차별화된 커리큘럼', '학생 관리', '후기 관리']
      },
      {
        id: 'class_creation',
        name: '온라인 클래스',
        description: '취미, 전문 기술 클래스 제작',
        avgIncome: '30-150만원',
        difficulty: '중급',
        startupCost: '20-100만원',
        timeToProfit: '2-4개월',
        skills: ['전문 기술', '영상 제작', '강의 기획'],
        platforms: ['클래스101', '탈잉', '프립'],
        tips: ['트렌드 주제 선택', '실습 중심', '피드백 제공']
      }
    ]
  },

  // 💰 투자 & 금융 (월 20-무제한)
  investment_finance: {
    name: '투자 & 금융',
    icon: '💰',
    averageIncome: '20만원-무제한',
    subcategories: [
      {
        id: 'real_estate_auction',
        name: '부동산 소액 경매',
        description: '500만-5,000만원 소액 경매 투자',
        avgIncome: '변동적',
        difficulty: '고급',
        startupCost: '500-5,000만원',
        timeToProfit: '3-12개월',
        skills: ['부동산 분석', '경매 절차', '리스크 관리'],
        platforms: ['비브릭', '위펀딩', '법원 경매'],
        tips: ['권리분석 철저히', '시세 조사', '자금 계획']
      },
      {
        id: 'crowdfunding_investment',
        name: '크라우드펀딩 투자',
        description: '1만원부터 소액 분산 투자',
        avgIncome: '연 3-12%',
        difficulty: '초급',
        startupCost: '1만원-',
        timeToProfit: '3-24개월',
        skills: ['투자 분석', '리스크 관리', '분산 투자'],
        platforms: ['와디즈', '크라우디', '8퍼센트'],
        tips: ['분산 투자', '업체 신뢰도 확인', '장기 투자']
      },
      {
        id: 'reselling_business',
        name: '리셀링 사업',
        description: '한정판, 희귀템 거래',
        avgIncome: '50-300만원',
        difficulty: '중급',
        startupCost: '100-500만원',
        timeToProfit: '즉시-3개월',
        skills: ['시장 분석', '진품 감별', '네트워킹'],
        platforms: ['크림', '솔드아웃', '번개장터'],
        tips: ['트렌드 파악', '진품 확인', '타이밍']
      }
    ]
  },

  // 🎯 마케팅 & 세일즈 (월 30-200만원)
  marketing_sales: {
    name: '마케팅 & 세일즈',
    icon: '🎯',
    averageIncome: '30-200만원',
    subcategories: [
      {
        id: 'affiliate_marketing',
        name: '제휴 마케팅',
        description: '쿠팡 파트너스, 제품 홍보 수수료',
        avgIncome: '20-100만원',
        difficulty: '초급',
        startupCost: '0-30만원',
        timeToProfit: '1-6개월',
        skills: ['마케팅', 'SNS 운영', '콘텐츠 제작'],
        platforms: ['쿠팡 파트너스', '11번가', '위메프'],
        tips: ['신뢰도 구축', '정직한 리뷰', '타겟 고객 분석']
      },
      {
        id: 'influencer_marketing',
        name: '인플루언서 마케팅',
        description: '인스타그램, 틱톡 광고 수익',
        avgIncome: '50-300만원',
        difficulty: '중급',
        startupCost: '0-50만원',
        timeToProfit: '3-12개월',
        skills: ['콘텐츠 제작', 'SNS 마케팅', '브랜딩'],
        platforms: ['인스타그램', '틱톡', '유튜브'],
        tips: ['일관된 컨셉', '팔로워 관리', '브랜드와의 협업']
      }
    ]
  },

  // 🔧 전문 서비스 (월 40-300만원)
  professional_services: {
    name: '전문 서비스',
    icon: '🔧',
    averageIncome: '40-300만원',
    subcategories: [
      {
        id: 'consulting',
        name: '컨설팅 서비스',
        description: '비즈니스, 재테크, 커리어 컨설팅',
        avgIncome: '100-500만원',
        difficulty: '고급',
        startupCost: '10-100만원',
        timeToProfit: '1-6개월',
        skills: ['전문 지식', '커뮤니케이션', '문제 해결'],
        platforms: ['크몽', '숨고', '독립 운영'],
        tips: ['전문성 구축', '성과 사례', '지속 관계']
      },
      {
        id: 'content_creation',
        name: '콘텐츠 제작',
        description: '영상, 사진, 글 콘텐츠 제작',
        avgIncome: '50-200만원',
        difficulty: '중급',
        startupCost: '50-300만원',
        timeToProfit: '1-3개월',
        skills: ['창작 능력', '기술적 스킬', '트렌드 감각'],
        platforms: ['크몽', '프리랜서', '직접 영업'],
        tips: ['포트폴리오 관리', '빠른 대응', '품질 유지']
      }
    ]
  },

  // 🏠 공간 & 자산 활용 (월 30-150만원)
  space_asset_utilization: {
    name: '공간 & 자산 활용',
    icon: '🏠',
    averageIncome: '30-150만원',
    subcategories: [
      {
        id: 'airbnb_hosting',
        name: '에어비앤비 호스팅',
        description: '빈 공간 숙박 서비스 제공',
        avgIncome: '50-200만원',
        difficulty: '중급',
        startupCost: '100-500만원',
        timeToProfit: '즉시',
        skills: ['공간 관리', '고객 서비스', '청소'],
        platforms: ['에어비앤비', '야놀자'],
        tips: ['위치 선택', '인테리어', '서비스 품질']
      },
      {
        id: 'car_sharing',
        name: '차량 공유',
        description: '개인 차량 렌탈 서비스',
        avgIncome: '30-100만원',
        difficulty: '초급',
        startupCost: '0원',
        timeToProfit: '즉시',
        skills: ['차량 관리', '고객 응대'],
        platforms: ['타바타', '그린카'],
        tips: ['차량 상태 관리', '보험 확인', '위치 최적화']
      },
      {
        id: 'storage_rental',
        name: '창고/주차장 대여',
        description: '빈 공간 임대 서비스',
        avgIncome: '20-80만원',
        difficulty: '초급',
        startupCost: '0-50만원',
        timeToProfit: '즉시',
        skills: ['공간 관리', '계약 관리'],
        platforms: ['직접 운영', '중개 플랫폼'],
        tips: ['접근성', '보안', '합리적 가격']
      }
    ]
  }
};

export const getIncomeData = () => incomeCategories;

export const getHighIncomeCategories = () => {
  return Object.values(incomeCategories).filter(category =>
    parseInt(category.averageIncome.split('-')[1]?.replace('만원', '') || '0') >= 100
  );
};

export const getLowRiskCategories = () => {
  const lowRiskIds = ['affiliate_marketing', 'blog_adsense', 'online_tutoring', 'car_sharing'];
  const result: any[] = [];

  Object.values(incomeCategories).forEach(category => {
    category.subcategories.forEach(sub => {
      if (lowRiskIds.includes(sub.id)) {
        result.push({ ...sub, categoryName: category.name });
      }
    });
  });

  return result;
};

export const getQuickStartCategories = () => {
  const result: any[] = [];

  Object.values(incomeCategories).forEach(category => {
    category.subcategories.forEach(sub => {
      if (sub.timeToProfit.includes('즉시') || sub.timeToProfit.includes('1개월')) {
        result.push({ ...sub, categoryName: category.name });
      }
    });
  });

  return result;
};
import '../models/income_source.dart';

class IncomeDataService {
  static final IncomeDataService _instance = IncomeDataService._internal();
  factory IncomeDataService() => _instance;
  IncomeDataService._internal();

  // 실제 API로 교체 가능한 구조
  bool _useMockData = true; // false로 변경하면 실제 API 사용

  // 모든 수익원 데이터 가져오기
  Future<List<IncomeSource>> getAllIncomeSources() async {
    if (_useMockData) {
      return _getMockIncomeSources();
    } else {
      // TODO: 실제 API 호출
      return _fetchFromAPI();
    }
  }

  // 앱 내 수익원만 가져오기
  Future<List<IncomeSource>> getInAppIncomeSources() async {
    final all = await getAllIncomeSources();
    return all.where((s) => s.category == IncomeCategory.inApp).toList();
  }

  // 외부 플랫폼 수익원만 가져오기
  Future<List<IncomeSource>> getExternalIncomeSources() async {
    final all = await getAllIncomeSources();
    return all.where((s) => s.category == IncomeCategory.external).toList();
  }

  // 목업 데이터
  List<IncomeSource> _getMockIncomeSources() {
    final now = DateTime.now();
    return [
      // ========== 앱 내 직접 수익 ==========
      IncomeSource(
        id: 'reward_ad',
        title: '리워드 광고',
        description: '동영상 광고 시청',
        icon: '🎬',
        category: IncomeCategory.inApp,
        type: IncomeType.rewardAd,
        monthlyIncome: 45000,
        todayIncome: 1500,
        totalIncome: 234000,
        changePercent: 12.5,
        isActive: true,
        metadata: {
          'adsWatched': 145,
          'averageReward': 300,
          'dailyLimit': 10,
          'remainingToday': 7,
        },
        lastUpdated: now,
      ),
      IncomeSource(
        id: 'daily_mission',
        title: '일일 미션',
        description: '미션 완료 보상',
        icon: '✅',
        category: IncomeCategory.inApp,
        type: IncomeType.dailyMission,
        monthlyIncome: 30000,
        todayIncome: 1000,
        totalIncome: 156000,
        changePercent: 8.3,
        isActive: true,
        metadata: {
          'completedMissions': 89,
          'currentStreak': 7,
          'maxStreak': 21,
        },
        lastUpdated: now,
      ),
      IncomeSource(
        id: 'referral',
        title: '친구 초대',
        description: '추천 보너스',
        icon: '👥',
        category: IncomeCategory.inApp,
        type: IncomeType.referral,
        monthlyIncome: 25000,
        todayIncome: 0,
        totalIncome: 125000,
        changePercent: 15.0,
        isActive: true,
        metadata: {
          'referredFriends': 25,
          'pendingRewards': 2,
          'bonusPerReferral': 5000,
        },
        lastUpdated: now,
      ),
      IncomeSource(
        id: 'survey',
        title: '설문조사',
        description: '간단한 설문 참여',
        icon: '📋',
        category: IncomeCategory.inApp,
        type: IncomeType.survey,
        monthlyIncome: 18000,
        todayIncome: 600,
        totalIncome: 89000,
        changePercent: 5.2,
        isActive: true,
        metadata: {
          'completedSurveys': 45,
          'averageReward': 2000,
          'availableSurveys': 3,
        },
        lastUpdated: now,
      ),
      IncomeSource(
        id: 'quiz',
        title: '퀴즈 참여',
        description: '지식 퀴즈 도전',
        icon: '🎯',
        category: IncomeCategory.inApp,
        type: IncomeType.quiz,
        monthlyIncome: 12000,
        todayIncome: 400,
        totalIncome: 67000,
        changePercent: 3.8,
        isActive: true,
        metadata: {
          'correctAnswers': 234,
          'winRate': 0.78,
          'currentLevel': 15,
        },
        lastUpdated: now,
      ),
      IncomeSource(
        id: 'walking',
        title: '걸음 수 보상',
        description: '만보기 리워드',
        icon: '🚶',
        category: IncomeCategory.inApp,
        type: IncomeType.walking,
        monthlyIncome: 15000,
        todayIncome: 500,
        totalIncome: 78000,
        changePercent: 6.7,
        isActive: true,
        metadata: {
          'todaySteps': 8456,
          'monthlySteps': 245678,
          'rewardPer1000Steps': 100,
        },
        lastUpdated: now,
      ),
      IncomeSource(
        id: 'game',
        title: '미니게임',
        description: '룰렛, 복권 등',
        icon: '🎮',
        category: IncomeCategory.inApp,
        type: IncomeType.game,
        monthlyIncome: 8000,
        todayIncome: 200,
        totalIncome: 45000,
        changePercent: -2.1,
        isActive: true,
        metadata: {
          'gamesPlayed': 567,
          'winnings': 45000,
          'jackpotWins': 2,
        },
        lastUpdated: now,
      ),

      // ========== 외부 플랫폼 연동 ==========
      IncomeSource(
        id: 'youtube',
        title: 'YouTube',
        description: '광고 수익 & 슈퍼챗',
        icon: '📺',
        category: IncomeCategory.external,
        type: IncomeType.youtube,
        monthlyIncome: 285000,
        todayIncome: 9500,
        totalIncome: 3420000,
        changePercent: 23.5,
        isActive: true,
        metadata: {
          'channelName': '한준 TV',
          'subscribers': 15234,
          'monthlyViews': 456789,
          'videos': 89,
          'averageWatchTime': 4.5,
          'cpm': 1.2,
        },
        lastUpdated: now,
      ),
      IncomeSource(
        id: 'blog',
        title: '블로그 애드센스',
        description: '네이버/티스토리',
        icon: '✍️',
        category: IncomeCategory.external,
        type: IncomeType.blog,
        monthlyIncome: 156000,
        todayIncome: 5200,
        totalIncome: 1872000,
        changePercent: 18.3,
        isActive: true,
        metadata: {
          'dailyVisitors': 4567,
          'pageViews': 12345,
          'ctr': 2.3,
          'blogPosts': 234,
        },
        lastUpdated: now,
      ),
      IncomeSource(
        id: 'tiktok',
        title: 'TikTok',
        description: '크리에이터 펀드',
        icon: '🎵',
        category: IncomeCategory.external,
        type: IncomeType.tiktok,
        monthlyIncome: 67000,
        todayIncome: 2200,
        totalIncome: 402000,
        changePercent: 45.2,
        isActive: true,
        metadata: {
          'followers': 23456,
          'monthlyViews': 2345678,
          'likes': 345678,
          'videos': 145,
        },
        lastUpdated: now,
      ),
      IncomeSource(
        id: 'instagram',
        title: 'Instagram',
        description: '제휴 마케팅',
        icon: '📷',
        category: IncomeCategory.external,
        type: IncomeType.instagram,
        monthlyIncome: 125000,
        todayIncome: 0,
        totalIncome: 750000,
        changePercent: 8.9,
        isActive: true,
        metadata: {
          'followers': 8945,
          'engagementRate': 4.5,
          'sponsoredPosts': 12,
          'reelsViews': 567890,
        },
        lastUpdated: now,
      ),
      IncomeSource(
        id: 'freelance',
        title: '프리랜서',
        description: '크몽/숨고/탈잉',
        icon: '💼',
        category: IncomeCategory.external,
        type: IncomeType.freelance,
        monthlyIncome: 3850000,
        todayIncome: 0,
        totalIncome: 23100000,
        changePercent: 32.1,
        isActive: true,
        metadata: {
          'platforms': ['크몽', '숨고', '위시켓'],
          'activeProjects': 3,
          'completedProjects': 45,
          'averageRating': 4.8,
          'skills': ['웹개발', 'UI/UX', '번역'],
        },
        lastUpdated: now,
      ),
      IncomeSource(
        id: 'stock',
        title: '주식 배당',
        description: '국내/해외 주식',
        icon: '📈',
        category: IncomeCategory.external,
        type: IncomeType.stock,
        monthlyIncome: 187000,
        todayIncome: 0,
        totalIncome: 2244000,
        changePercent: 5.6,
        isActive: true,
        metadata: {
          'portfolio': [
            {'name': '삼성전자', 'dividend': 45000},
            {'name': 'SK하이닉스', 'dividend': 23000},
            {'name': 'AAPL', 'dividend': 67000},
            {'name': 'MSFT', 'dividend': 52000},
          ],
          'totalValue': 45670000,
          'yearlyYield': 2.8,
        },
        lastUpdated: now,
      ),
      IncomeSource(
        id: 'crypto',
        title: '암호화폐',
        description: '스테이킹 & DeFi',
        icon: '🪙',
        category: IncomeCategory.external,
        type: IncomeType.crypto,
        monthlyIncome: 234000,
        todayIncome: 7800,
        totalIncome: 1404000,
        changePercent: -12.3,
        isActive: true,
        metadata: {
          'stakingRewards': {
            'ETH': 89000,
            'ADA': 45000,
            'DOT': 67000,
            'ATOM': 33000,
          },
          'defiYield': 15.6,
          'totalStaked': 8900000,
        },
        lastUpdated: now,
      ),
      IncomeSource(
        id: 'realestate',
        title: '부동산 임대',
        description: '월세 수익',
        icon: '🏠',
        category: IncomeCategory.external,
        type: IncomeType.realestate,
        monthlyIncome: 850000,
        todayIncome: 0,
        totalIncome: 10200000,
        changePercent: 0.0,
        isActive: true,
        metadata: {
          'properties': [
            {'type': '원룸', 'location': '강남구', 'rent': 850000},
          ],
          'occupancyRate': 100,
          'managementFee': 50000,
        },
        lastUpdated: now,
      ),
      IncomeSource(
        id: 'delivery',
        title: '배달 대행',
        description: '배민커넥트/쿠팡플렉스',
        icon: '🛵',
        category: IncomeCategory.external,
        type: IncomeType.delivery,
        monthlyIncome: 456000,
        todayIncome: 15200,
        totalIncome: 2736000,
        changePercent: 8.7,
        isActive: true,
        metadata: {
          'platforms': ['배민커넥트', '쿠팡플렉스'],
          'deliveriesThisMonth': 152,
          'averagePerDelivery': 3000,
          'workingHours': 48,
        },
        lastUpdated: now,
      ),
      IncomeSource(
        id: 'ecommerce',
        title: '쿠팡파트너스',
        description: '제휴 마케팅',
        icon: '🛍️',
        category: IncomeCategory.external,
        type: IncomeType.ecommerce,
        monthlyIncome: 345000,
        todayIncome: 11500,
        totalIncome: 4140000,
        changePercent: 28.9,
        isActive: true,
        metadata: {
          'clicks': 23456,
          'conversions': 567,
          'conversionRate': 2.4,
          'averageCommission': 608,
        },
        lastUpdated: now,
      ),
      IncomeSource(
        id: 'education',
        title: '온라인 강의',
        description: '인프런/클래스101',
        icon: '📚',
        category: IncomeCategory.external,
        type: IncomeType.education,
        monthlyIncome: 1234000,
        todayIncome: 41100,
        totalIncome: 7404000,
        changePercent: 15.3,
        isActive: true,
        metadata: {
          'platforms': ['인프런', '클래스101', '패스트캠퍼스'],
          'courses': 5,
          'students': 1234,
          'averageRating': 4.7,
        },
        lastUpdated: now,
      ),
      IncomeSource(
        id: 'nft',
        title: 'NFT 거래',
        description: '오픈씨/클레이튼',
        icon: '🎨',
        category: IncomeCategory.external,
        type: IncomeType.nft,
        monthlyIncome: 567000,
        todayIncome: 0,
        totalIncome: 3402000,
        changePercent: -23.4,
        isActive: false,
        metadata: {
          'collections': 3,
          'nftsSold': 23,
          'floorPrice': 234000,
          'totalVolume': 3402000,
        },
        lastUpdated: now,
      ),
    ];
  }

  // 실제 API 호출 (나중에 구현)
  Future<List<IncomeSource>> _fetchFromAPI() async {
    // TODO: 실제 백엔드 API 호출
    throw UnimplementedError('API integration pending');
  }

  // 일일 미션 가져오기
  Future<List<DailyMission>> getDailyMissions() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    return [
      DailyMission(
        id: 'dm1',
        title: '광고 5개 시청',
        description: '리워드 광고를 5개 시청하세요',
        reward: 500,
        progress: 2,
        target: 5,
        isCompleted: false,
        expiresAt: tomorrow,
      ),
      DailyMission(
        id: 'dm2',
        title: '5,000보 걷기',
        description: '오늘 5,000보를 걸어보세요',
        reward: 300,
        progress: 3456,
        target: 5000,
        isCompleted: false,
        expiresAt: tomorrow,
      ),
      DailyMission(
        id: 'dm3',
        title: '친구 1명 초대',
        description: '친구를 초대하고 보너스를 받으세요',
        reward: 1000,
        progress: 0,
        target: 1,
        isCompleted: false,
        expiresAt: tomorrow,
      ),
      DailyMission(
        id: 'dm4',
        title: '설문조사 완료',
        description: '간단한 설문조사에 참여하세요',
        reward: 200,
        progress: 1,
        target: 1,
        isCompleted: true,
        expiresAt: tomorrow,
      ),
    ];
  }

  // 프리랜서 프로젝트 가져오기
  Future<List<FreelanceProject>> getFreelanceProjects() async {
    return [
      FreelanceProject(
        id: 'fp1',
        title: '쇼핑몰 웹사이트 개발',
        platform: '크몽',
        amount: 3500000,
        progress: 0.65,
        deadline: DateTime.now().add(Duration(days: 12)),
        status: '진행중',
      ),
      FreelanceProject(
        id: 'fp2',
        title: '모바일 앱 UI 디자인',
        platform: '숨고',
        amount: 2200000,
        progress: 0.30,
        deadline: DateTime.now().add(Duration(days: 25)),
        status: '진행중',
      ),
      FreelanceProject(
        id: 'fp3',
        title: '데이터 분석 대시보드',
        platform: '위시켓',
        amount: 1800000,
        progress: 0.90,
        deadline: DateTime.now().add(Duration(days: 3)),
        status: '마감임박',
      ),
    ];
  }

  // 주식 포트폴리오 가져오기
  Future<List<StockPortfolio>> getStockPortfolio() async {
    return [
      StockPortfolio(
        ticker: '005930',
        name: '삼성전자',
        shares: 100,
        purchasePrice: 71000,
        currentPrice: 73000,
        dividendYield: 2.1,
        yearlyDividend: 153300,
      ),
      StockPortfolio(
        ticker: '000660',
        name: 'SK하이닉스',
        shares: 50,
        purchasePrice: 125000,
        currentPrice: 135000,
        dividendYield: 1.8,
        yearlyDividend: 121500,
      ),
      StockPortfolio(
        ticker: 'AAPL',
        name: 'Apple',
        shares: 10,
        purchasePrice: 150,
        currentPrice: 175,
        dividendYield: 0.5,
        yearlyDividend: 8750,
      ),
    ];
  }
}
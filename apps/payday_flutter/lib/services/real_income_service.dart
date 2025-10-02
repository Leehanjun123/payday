import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'data_service.dart';
import 'api_service.dart';

/// 2024년 12월 기준 실제 부수익 플랫폼 통합 서비스
class RealIncomeService {
  static final RealIncomeService _instance = RealIncomeService._internal();
  factory RealIncomeService() => _instance;
  RealIncomeService._internal();

  final DataService _dataService = DataService();
  final ApiService _apiService = ApiService();

  // 실제 부수익 플랫폼 정보
  static const Map<String, Map<String, dynamic>> INCOME_PLATFORMS = {
    // 걷기/건강 앱
    'cashwalk': {
      'name': '캐시워크',
      'category': '걷기/건강',
      'description': '하루 최대 20,000보까지 캐시 적립',
      'earning_rate': '100보당 1캐시',
      'max_daily': 200,
      'url': 'https://cashwalk.com',
      'app_store': 'id1220307907',
      'play_store': 'com.cashwalk.cashwalk',
      'icon': '🚶',
    },
    'toss': {
      'name': '토스',
      'category': '금융/리워드',
      'description': '만보기, 출석체크, 행운퀴즈 등',
      'earning_rate': '일 평균 911원',
      'max_daily': 41226,
      'url': 'https://toss.im',
      'app_store': 'id839333328',
      'play_store': 'viva.republica.toss',
      'icon': '💙',
    },
    'cashdoc': {
      'name': '캐시닥',
      'category': '걷기/건강',
      'description': '용돈퀴즈, 걷기 리워드',
      'earning_rate': '다양한 미션',
      'max_daily': 500,
      'url': 'https://cashdoc.me',
      'icon': '💊',
    },
    'bitwork': {
      'name': '비트워크',
      'category': '걷기',
      'description': '걷기로 비트코인 채굴',
      'earning_rate': '1000보당 1사토시',
      'max_daily': 100,
      'icon': '₿',
    },
    'superwork': {
      'name': '슈퍼워크',
      'category': '걷기',
      'description': '걷기 + 광고시청 리워드',
      'earning_rate': '100보당 1포인트',
      'max_daily': 150,
      'icon': '🏃',
    },

    // 커머스/판매
    'coupang_partners': {
      'name': '쿠팡 파트너스',
      'category': '제휴마케팅',
      'description': '상품 추천 수수료 3-5%',
      'earning_rate': '판매액의 3-5%',
      'max_daily': -1, // 무제한
      'url': 'https://partners.coupang.com',
      'icon': '🛒',
      'api_available': true,
    },
    'naver_adpost': {
      'name': '네이버 애드포스트',
      'category': '블로그',
      'description': '블로그 광고 수익',
      'earning_rate': 'CPC 10-500원',
      'max_daily': -1,
      'url': 'https://adpost.naver.com',
      'icon': '📝',
    },
    'kmong': {
      'name': '크몽',
      'category': '프리랜서',
      'description': '재능 판매 플랫폼',
      'earning_rate': '프로젝트당 10만원~',
      'max_daily': -1,
      'url': 'https://kmong.com',
      'icon': '🎨',
    },
    'daangn': {
      'name': '당근마켓',
      'category': '중고거래',
      'description': '중고물품 거래',
      'earning_rate': '물품별 상이',
      'max_daily': -1,
      'url': 'https://www.daangn.com',
      'icon': '🥕',
    },

    // 설문/리서치
    'panel_now': {
      'name': '패널나우',
      'category': '설문조사',
      'description': '설문조사 참여 리워드',
      'earning_rate': '건당 500-5000원',
      'max_daily': 10000,
      'url': 'https://www.panelnow.co.kr',
      'icon': '📊',
    },
    'embrain': {
      'name': '엠브레인',
      'category': '설문조사',
      'description': '전문 리서치 패널',
      'earning_rate': '건당 1000-10000원',
      'max_daily': 20000,
      'url': 'https://www.embrain.com',
      'icon': '🧠',
    },

    // 콘텐츠 플랫폼
    'youtube': {
      'name': '유튜브',
      'category': '콘텐츠',
      'description': '광고 수익 + 슈퍼챗',
      'earning_rate': '조회수 1000회당 \$1-5',
      'max_daily': -1,
      'url': 'https://youtube.com',
      'icon': '📺',
      'api_available': true,
    },
    'tiktok': {
      'name': '틱톡',
      'category': '콘텐츠',
      'description': '크리에이터 펀드',
      'earning_rate': '조회수 기반',
      'max_daily': -1,
      'url': 'https://www.tiktok.com',
      'icon': '🎵',
    },
    'instagram': {
      'name': '인스타그램',
      'category': '콘텐츠',
      'description': '릴스 플레이 보너스',
      'earning_rate': '조회수 기반',
      'max_daily': -1,
      'url': 'https://instagram.com',
      'icon': '📸',
    },

    // 배달/운송
    'baemin_connect': {
      'name': '배민커넥트',
      'category': '배달',
      'description': '배달 라이더',
      'earning_rate': '건당 3000-8000원',
      'max_daily': 200000,
      'url': 'https://connect.baemin.com',
      'icon': '🛵',
    },
    'coupang_flex': {
      'name': '쿠팡플렉스',
      'category': '배송',
      'description': '새벽/일반 배송',
      'earning_rate': '시간당 15000-25000원',
      'max_daily': 300000,
      'url': 'https://rocketyourcareer.kr.coupang.com',
      'icon': '📦',
    },

    // 투자/금융
    'toss_securities': {
      'name': '토스증권',
      'category': '투자',
      'description': '주식/ETF 투자',
      'earning_rate': '수익률 기반',
      'max_daily': -1,
      'url': 'https://tossinvest.com',
      'icon': '📈',
    },
    'upbit': {
      'name': '업비트',
      'category': '암호화폐',
      'description': '암호화폐 거래',
      'earning_rate': '시세 변동',
      'max_daily': -1,
      'url': 'https://upbit.com',
      'icon': '🪙',
    },
  };

  // 플랫폼별 연동 상태
  Map<String, bool> _connectedPlatforms = {};
  Map<String, Map<String, dynamic>> _platformData = {};

  Future<void> initialize() async {
    await _loadConnectedPlatforms();
    await _syncPlatformData();
  }

  // 연결된 플랫폼 불러오기
  Future<void> _loadConnectedPlatforms() async {
    final saved = await _dataService.getSetting('connected_platforms');
    if (saved != null) {
      _connectedPlatforms = Map<String, bool>.from(saved);
    }
  }

  // 플랫폼 데이터 동기화
  Future<void> _syncPlatformData() async {
    for (final platform in _connectedPlatforms.keys) {
      if (_connectedPlatforms[platform] == true) {
        await _fetchPlatformData(platform);
      }
    }
  }

  // 플랫폼별 데이터 가져오기
  Future<void> _fetchPlatformData(String platformId) async {
    try {
      // 실제 API가 있는 플랫폼만 데이터 fetch
      if (INCOME_PLATFORMS[platformId]?['api_available'] == true) {
        final response = await _apiService.get('/api/platforms/$platformId/earnings');
        _platformData[platformId] = response;
      } else {
        // API가 없는 경우 수동 입력 데이터 사용
        _platformData[platformId] = await _getManualData(platformId);
      }
    } catch (e) {
      print('Failed to fetch $platformId data: $e');
    }
  }

  // 수동 입력 데이터 가져오기
  Future<Map<String, dynamic>> _getManualData(String platformId) async {
    final data = await _dataService.getSetting('platform_data_$platformId');
    return data ?? {
      'daily_earnings': 0.0,
      'total_earnings': 0.0,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  // 플랫폼 연결
  Future<bool> connectPlatform(String platformId) async {
    final platform = INCOME_PLATFORMS[platformId];
    if (platform == null) return false;

    // 앱/웹 링크 열기
    final url = platform['url'];
    if (url != null && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }

    // 연결 상태 저장
    _connectedPlatforms[platformId] = true;
    await _dataService.saveSetting('connected_platforms', _connectedPlatforms);

    return true;
  }

  // 플랫폼 연결 해제
  Future<void> disconnectPlatform(String platformId) async {
    _connectedPlatforms[platformId] = false;
    _platformData.remove(platformId);
    await _dataService.saveSetting('connected_platforms', _connectedPlatforms);
  }

  // 수익 업데이트 (수동)
  Future<void> updatePlatformEarnings(String platformId, double amount) async {
    final data = _platformData[platformId] ?? {
      'daily_earnings': 0.0,
      'total_earnings': 0.0,
    };

    // 오늘 날짜 체크
    final lastUpdated = data['last_updated'];
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastDate = lastUpdated?.split('T')[0];

    if (lastDate != today) {
      // 새로운 날
      data['daily_earnings'] = amount;
    } else {
      // 같은 날 누적
      data['daily_earnings'] = (data['daily_earnings'] ?? 0.0) + amount;
    }

    data['total_earnings'] = (data['total_earnings'] ?? 0.0) + amount;
    data['last_updated'] = DateTime.now().toIso8601String();

    _platformData[platformId] = data;
    await _dataService.saveSetting('platform_data_$platformId', data);

    // 전체 수익에 추가
    await _dataService.addEarning(
      source: INCOME_PLATFORMS[platformId]?['name'] ?? platformId,
      amount: amount,
      description: '${INCOME_PLATFORMS[platformId]?['category']} 수익',
    );
  }

  // 오늘의 총 수익
  double getTodayTotalEarnings() {
    double total = 0;
    final today = DateTime.now().toIso8601String().split('T')[0];

    for (final data in _platformData.values) {
      final lastDate = data['last_updated']?.split('T')[0];
      if (lastDate == today) {
        total += data['daily_earnings'] ?? 0;
      }
    }

    return total;
  }

  // 전체 누적 수익
  double getTotalEarnings() {
    double total = 0;
    for (final data in _platformData.values) {
      total += data['total_earnings'] ?? 0;
    }
    return total;
  }

  // 카테고리별 플랫폼 가져오기
  List<Map<String, dynamic>> getPlatformsByCategory(String category) {
    return INCOME_PLATFORMS.entries
        .where((e) => e.value['category'] == category)
        .map((e) => {
              'id': e.key,
              ...e.value,
              'connected': _connectedPlatforms[e.key] ?? false,
              'earnings': _platformData[e.key]?['daily_earnings'] ?? 0,
            })
        .toList();
  }

  // 연결된 플랫폼 목록
  List<Map<String, dynamic>> getConnectedPlatforms() {
    return INCOME_PLATFORMS.entries
        .where((e) => _connectedPlatforms[e.key] == true)
        .map((e) => {
              'id': e.key,
              ...e.value,
              'data': _platformData[e.key],
            })
        .toList();
  }

  // 추천 플랫폼 (미연결 중 인기)
  List<Map<String, dynamic>> getRecommendedPlatforms() {
    final recommendations = [
      'cashwalk',
      'toss',
      'coupang_partners',
      'kmong',
      'panel_now'
    ];

    return recommendations
        .where((id) => _connectedPlatforms[id] != true)
        .map((id) => {
              'id': id,
              ...INCOME_PLATFORMS[id]!,
            })
        .toList();
  }

  // 모든 플랫폼 가져오기
  List<Map<String, dynamic>> getAllPlatforms() {
    return INCOME_PLATFORMS.entries
        .map((e) => {
              'id': e.key,
              ...e.value,
              'connected': _connectedPlatforms[e.key] ?? false,
            })
        .toList();
  }

  // 걷기 앱 자동 동기화
  Future<void> syncWalkingApps() async {
    final walkingApps = ['cashwalk', 'toss', 'cashdoc', 'bitwork', 'superwork'];

    for (final appId in walkingApps) {
      if (_connectedPlatforms[appId] == true) {
        // 각 앱의 예상 수익 계산 (하루 10,000보 기준)
        double dailyEarning = 0;
        switch (appId) {
          case 'cashwalk':
            dailyEarning = 100; // 10,000보 = 100캐시
            break;
          case 'toss':
            dailyEarning = 911; // 평균 일일 수익
            break;
          case 'cashdoc':
            dailyEarning = 150; // 예상치
            break;
          case 'bitwork':
            dailyEarning = 50; // 예상치
            break;
          case 'superwork':
            dailyEarning = 75; // 예상치
            break;
        }

        await updatePlatformEarnings(appId, dailyEarning);
      }
    }
  }

  // 일일 미션 체크
  Future<Map<String, dynamic>> getDailyMissions() async {
    return {
      'walking': {
        'title': '오늘의 걸음 목표',
        'target': 10000,
        'current': await _getStepCount(),
        'reward': 200,
      },
      'survey': {
        'title': '설문조사 참여',
        'target': 3,
        'current': await _getSurveyCount(),
        'reward': 5000,
      },
      'content': {
        'title': '콘텐츠 업로드',
        'target': 1,
        'current': await _getContentCount(),
        'reward': 1000,
      },
    };
  }

  // 보조 메서드들
  Future<int> _getStepCount() async {
    // 실제로는 헬스킷/구글핏 연동
    return 5432;
  }

  Future<int> _getSurveyCount() async {
    final count = await _dataService.getSetting('today_survey_count');
    return count ?? 0;
  }

  Future<int> _getContentCount() async {
    final count = await _dataService.getSetting('today_content_count');
    return count ?? 0;
  }

  // 플랫폼 앱 설치 링크
  Future<void> installApp(String platformId) async {
    final platform = INCOME_PLATFORMS[platformId];
    if (platform == null) return;

    String? storeUrl;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final appId = platform['app_store'];
      if (appId != null) {
        storeUrl = 'https://apps.apple.com/app/$appId';
      }
    } else {
      final packageId = platform['play_store'];
      if (packageId != null) {
        storeUrl = 'https://play.google.com/store/apps/details?id=$packageId';
      }
    }

    if (storeUrl != null && await canLaunchUrl(Uri.parse(storeUrl))) {
      await launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication);
    }
  }
}
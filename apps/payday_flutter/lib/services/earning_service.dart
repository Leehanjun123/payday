import 'package:dio/dio.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/app_config.dart';

class EarningService {
  static final EarningService _instance = EarningService._internal();
  factory EarningService() => _instance;
  EarningService._internal();

  final Dio _dio = Dio();

  // 사용자 잔액 (실제 DB와 연동)
  double _userBalance = 0.0;
  int _userPoints = 0;

  // Google AdMob 광고
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadRewardedAd();
  }

  // ========================
  // 1. 광고 시청으로 수익
  // ========================
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AppConfig.admobRewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadRewardedAd(); // 다음 광고 미리 로드
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('광고 로드 실패: $error');
          _isRewardedAdReady = false;
          // 5초 후 재시도
          Future.delayed(const Duration(seconds: 5), _loadRewardedAd);
        },
      ),
    );
  }

  Future<bool> showRewardedAd() async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      return false;
    }

    bool rewarded = false;

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        // 실제 보상 지급 (서버 검증 필요)
        _addEarning(
          type: 'ad_watch',
          amount: 100, // 100원
          points: reward.amount.toInt(),
        );
        rewarded = true;
      },
    );

    return rewarded;
  }

  // ========================
  // 2. 설문조사 수익
  // ========================
  Future<List<Survey>> getAvailableSurveys() async {
    try {
      // CPX Research API 호출
      final response = await _dio.get(
        'https://offers.cpx-research.com/api/v2/surveys',
        queryParameters: {
          'app_id': AppConfig.cpxResearchAppId,
          'user_id': await _getUserId(),
        },
      );

      return (response.data['surveys'] as List)
          .map((s) => Survey.fromJson(s))
          .toList();
    } catch (e) {
      print('설문조사 로드 실패: $e');
      return [];
    }
  }

  Future<String> getSurveyUrl(String surveyId) async {
    final userId = await _getUserId();
    // CPX Research 설문조사 URL 생성
    return 'https://offers.cpx-research.com/index.php'
        '?app_id=${AppConfig.cpxResearchAppId}'
        '&ext_user_id=$userId'
        '&survey_id=$surveyId';
  }

  // ========================
  // 3. 쿠팡 파트너스 (캐시백)
  // ========================
  Future<List<CashbackOffer>> getCashbackOffers() async {
    try {
      // 쿠팡 파트너스 API
      final response = await _dio.post(
        'https://api-gateway.coupang.com/v2/providers/affiliate_open_api/apis/openapi/v1/deeplink',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConfig.coupangPartnersId}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'coupangUrls': [
            'https://www.coupang.com/np/search?q=인기상품',
          ],
        },
      );

      // 캐시백 상품 목록 반환
      return [
        CashbackOffer(
          title: '쿠팡 인기 상품',
          cashbackRate: 0.03, // 3%
          estimatedEarning: '구매 금액의 3%',
          url: response.data['rCode'] == '0'
              ? response.data['data'][0]
              : 'https://www.coupang.com',
        ),
      ];
    } catch (e) {
      print('캐시백 오퍼 로드 실패: $e');
      return [];
    }
  }

  // ========================
  // 4. 미션 완료 보상
  // ========================
  Future<void> completeMission(String missionId) async {
    try {
      // 서버에 미션 완료 요청
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/missions/complete',
        data: {
          'mission_id': missionId,
          'user_id': await _getUserId(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (response.data['success']) {
        final reward = response.data['reward'];
        _addEarning(
          type: 'mission',
          amount: reward['amount'],
          points: reward['points'],
        );
      }
    } catch (e) {
      print('미션 완료 실패: $e');
    }
  }

  // ========================
  // 5. 출금 시스템
  // ========================
  Future<bool> requestWithdrawal(double amount, String bankAccount) async {
    if (amount < AppConfig.minWithdrawalAmount) {
      throw Exception('최소 출금 금액은 ${AppConfig.minWithdrawalAmount}원입니다.');
    }

    if (amount > _userBalance) {
      throw Exception('잔액이 부족합니다.');
    }

    try {
      // 토스페이먼츠 정산 API 호출
      final response = await _dio.post(
        'https://api.tosspayments.com/v1/payouts',
        options: Options(
          headers: {
            'Authorization': 'Basic ${AppConfig.tossPaymentsSecretKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'amount': amount - AppConfig.withdrawalFee,
          'bank': _extractBankCode(bankAccount),
          'accountNumber': _extractAccountNumber(bankAccount),
          'holderName': await _getUserName(),
        },
      );

      if (response.data['status'] == 'SUCCESS') {
        _userBalance -= amount;
        return true;
      }

      return false;
    } catch (e) {
      print('출금 요청 실패: $e');
      return false;
    }
  }

  // ========================
  // 내부 헬퍼 메서드
  // ========================
  void _addEarning({
    required String type,
    required double amount,
    required int points,
  }) async {
    _userBalance += amount;
    _userPoints += points;

    // 서버에 수익 기록
    try {
      await _dio.post(
        '${AppConfig.apiBaseUrl}/earnings/add',
        data: {
          'user_id': await _getUserId(),
          'type': type,
          'amount': amount,
          'points': points,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      print('수익 기록 실패: $e');
    }
  }

  Future<String> _getUserId() async {
    // SharedPreferences에서 사용자 ID 가져오기
    return 'user_123'; // 임시
  }

  Future<String> _getUserName() async {
    return '홍길동'; // 임시
  }

  String _extractBankCode(String bankAccount) {
    // 은행 코드 추출 로직
    return '088'; // 신한은행 예시
  }

  String _extractAccountNumber(String bankAccount) {
    // 계좌번호 추출 로직
    return '110123456789';
  }

  // Getters
  double get userBalance => _userBalance;
  int get userPoints => _userPoints;
  bool get isRewardedAdReady => _isRewardedAdReady;
}

// 데이터 모델
class Survey {
  final String id;
  final String title;
  final int estimatedTime; // 분
  final double reward; // 원
  final String provider;

  Survey({
    required this.id,
    required this.title,
    required this.estimatedTime,
    required this.reward,
    required this.provider,
  });

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      id: json['survey_id'],
      title: json['survey_name'],
      estimatedTime: json['loi'], // Length of Interview
      reward: (json['cpi'] * 1000).toDouble(), // CPI to KRW
      provider: json['provider'] ?? 'CPX Research',
    );
  }
}

class CashbackOffer {
  final String title;
  final double cashbackRate;
  final String estimatedEarning;
  final String url;

  CashbackOffer({
    required this.title,
    required this.cashbackRate,
    required this.estimatedEarning,
    required this.url,
  });
}
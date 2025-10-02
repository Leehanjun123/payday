import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'railway_service.dart';
import 'cloud_cash_service.dart';

/// AdMob 실제 수익 검증 및 분배 서비스
class AdMobRevenueService {
  static final AdMobRevenueService _instance = AdMobRevenueService._internal();
  factory AdMobRevenueService() => _instance;
  AdMobRevenueService._internal();

  final RailwayService _railway = RailwayService();
  final CloudCashService _cashService = CloudCashService();

  // AdMob Reporting API 설정
  static const String _admobApiBaseUrl = 'https://admob.googleapis.com/v1';
  static const String _serviceAccountKey = 'YOUR_SERVICE_ACCOUNT_KEY'; // 서비스 계정 키

  // 수익 검증 및 분배 설정
  static const double _userSharePercentage = 0.5; // 사용자에게 50% 분배
  static const double _minimumRevenueUsd = 0.01; // 최소 수익 (1센트)

  String? _accessToken;
  Timer? _revenueCheckTimer;

  // 초기화
  Future<void> initialize() async {
    await _getAccessToken();
    await _startPeriodicRevenueCheck();
  }

  // Google OAuth 2.0 액세스 토큰 획득
  Future<void> _getAccessToken() async {
    try {
      // 서비스 계정 키를 사용하여 JWT 생성 및 토큰 요청
      // 실제 구현에서는 google_auth_library 패키지 사용 권장

      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': _generateJWT(), // JWT 토큰 생성
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        print('✅ AdMob API 인증 완료');
      } else {
        print('❌ AdMob API 인증 실패: ${response.body}');
      }
    } catch (e) {
      print('AdMob API 인증 오류: $e');
    }
  }

  String _generateJWT() {
    // JWT 토큰 생성 로직
    // 실제로는 jose 패키지나 google_auth_library 사용
    return 'YOUR_JWT_TOKEN';
  }

  // 주기적 수익 확인 시작 (실시간은 아니고 30분마다)
  Future<void> _startPeriodicRevenueCheck() async {
    _revenueCheckTimer = Timer.periodic(const Duration(minutes: 30), (timer) async {
      await _checkAndDistributeRevenue();
    });
  }

  // AdMob 수익 확인 및 분배
  Future<void> _checkAndDistributeRevenue() async {
    if (_accessToken == null) {
      await _getAccessToken();
      if (_accessToken == null) return;
    }

    try {
      // 1. 최근 수익 데이터 가져오기
      final revenueData = await _fetchRecentRevenue();

      // 2. 각 광고 노출에 대해 수익 분배
      for (final revenue in revenueData) {
        await _processAdRevenue(revenue);
      }

      print('✅ AdMob 수익 확인 및 분배 완료');
    } catch (e) {
      print('AdMob 수익 처리 오류: $e');
    }
  }

  // AdMob Reporting API에서 수익 데이터 가져오기
  Future<List<Map<String, dynamic>>> _fetchRecentRevenue() async {
    try {
      // 최근 1시간의 수익 데이터 요청
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(hours: 1));

      final response = await http.get(
        Uri.parse(
          '$_admobApiBaseUrl/accounts/YOUR_PUBLISHER_ID/networkReport:generate'
          '?reportSpec.dateRange.startDate.year=${startDate.year}'
          '&reportSpec.dateRange.startDate.month=${startDate.month}'
          '&reportSpec.dateRange.startDate.day=${startDate.day}'
          '&reportSpec.dateRange.endDate.year=${endDate.year}'
          '&reportSpec.dateRange.endDate.month=${endDate.month}'
          '&reportSpec.dateRange.endDate.day=${endDate.day}'
          '&reportSpec.dimensions=DATE,APP,AD_UNIT,COUNTRY'
          '&reportSpec.metrics=ESTIMATED_EARNINGS'
        ),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseRevenueData(data);
      } else {
        print('AdMob 수익 조회 실패: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('AdMob 수익 조회 오류: $e');
      return [];
    }
  }

  // AdMob 응답 데이터 파싱
  List<Map<String, dynamic>> _parseRevenueData(Map<String, dynamic> data) {
    final List<Map<String, dynamic>> revenues = [];

    try {
      final rows = data['rows'] as List<dynamic>? ?? [];

      for (final row in rows) {
        final dimensionValues = row['dimensionValues'] as Map<String, dynamic>;
        final metricValues = row['metricValues'] as Map<String, dynamic>;

        final revenue = {
          'date': dimensionValues['DATE']?['value'],
          'app_name': dimensionValues['APP']?['displayLabel'],
          'ad_unit_id': dimensionValues['AD_UNIT']?['value'],
          'country': dimensionValues['COUNTRY']?['value'],
          'estimated_earnings_usd': double.tryParse(
            metricValues['ESTIMATED_EARNINGS']?['integerValue'] ?? '0'
          ) ?? 0.0,
        };

        if (revenue['estimated_earnings_usd']! >= _minimumRevenueUsd) {
          revenues.add(revenue);
        }
      }
    } catch (e) {
      print('AdMob 데이터 파싱 오류: $e');
    }

    return revenues;
  }

  // 개별 광고 수익 처리
  Future<void> _processAdRevenue(Map<String, dynamic> revenue) async {
    try {
      final adUnitId = revenue['ad_unit_id'] as String;
      final earningsUsd = revenue['estimated_earnings_usd'] as double;

      // 1. USD → KRW 변환
      final exchangeRate = await _getExchangeRate();
      final earningsKrw = earningsUsd * exchangeRate;

      // 2. 사용자 분배금 계산
      final userShare = earningsKrw * _userSharePercentage;

      // 3. Railway 데이터베이스에 수익 기록
      await _railway.recordEarning(
        earningMethod: 'admob_verified',
        amount: userShare,
        description: 'AdMob 검증된 실제 수익',
        metadata: {
          'ad_unit_id': adUnitId,
          'original_usd': earningsUsd,
          'exchange_rate': exchangeRate,
          'platform_share': earningsKrw * (1 - _userSharePercentage),
          'user_share': userShare,
          'verification_date': DateTime.now().toIso8601String(),
        },
      );

      // 4. 사용자에게 실제 수익 분배
      await _distributeTOUsers(adUnitId, userShare, revenue);

      print('💰 AdMob 수익 분배 완료: \$${earningsUsd.toStringAsFixed(4)} → ₩${userShare.toStringAsFixed(0)}');

    } catch (e) {
      print('AdMob 수익 처리 실패: $e');
    }
  }

  // 사용자에게 수익 분배
  Future<void> _distributeTOUsers(
    String adUnitId,
    double totalUserShare,
    Map<String, dynamic> revenueData,
  ) async {
    try {
      // Railway 데이터베이스에서 해당 광고 단위를 본 사용자들 조회
      final users = await _getUsersByAdUnit(adUnitId, revenueData['date']);

      if (users.isEmpty) {
        print('⚠️ 해당 광고에 대한 사용자 기록 없음: $adUnitId');
        return;
      }

      // 사용자당 분배 금액 계산
      final amountPerUser = totalUserShare / users.length;

      // 각 사용자에게 분배
      for (final user in users) {
        await _distributeToUser(user, amountPerUser, adUnitId, revenueData);
      }

      print('👥 ${users.length}명의 사용자에게 수익 분배 완료');

    } catch (e) {
      print('사용자 수익 분배 실패: $e');
    }
  }

  // 특정 광고 단위를 본 사용자들 조회
  Future<List<Map<String, dynamic>>> _getUsersByAdUnit(
    String adUnitId,
    String date,
  ) async {
    // 실제로는 Railway API 호출
    // 해당 날짜에 해당 광고 단위에서 수익을 올린 사용자들을 조회
    return [];
  }

  // 개별 사용자에게 수익 분배
  Future<void> _distributeToUser(
    Map<String, dynamic> user,
    double amount,
    String adUnitId,
    Map<String, dynamic> revenueData,
  ) async {
    try {
      // 사용자의 실제 잔액에 추가
      await _railway.recordEarning(
        earningMethod: 'admob_real_revenue',
        amount: amount,
        description: 'AdMob 실제 수익 분배',
        metadata: {
          'ad_unit_id': adUnitId,
          'revenue_date': revenueData['date'],
          'original_revenue_usd': revenueData['estimated_earnings_usd'],
          'distribution_type': 'verified_revenue',
        },
      );

      print('💰 사용자 ${user['id']}에게 ₩${amount.toStringAsFixed(0)} 분배');

    } catch (e) {
      print('개별 사용자 분배 실패: $e');
    }
  }

  // 실시간 환율 조회
  Future<double> _getExchangeRate() async {
    try {
      // 무료 환율 API 사용 (실제로는 더 안정적인 API 권장)
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/USD'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['rates']['KRW'] as num).toDouble();
      }
    } catch (e) {
      print('환율 조회 실패: $e');
    }

    // 기본값 (대략적인 USD-KRW 환율)
    return 1300.0;
  }

  // 실시간 광고 노출 추적
  Future<void> trackAdImpression({
    required String userId,
    required String adUnitId,
    required String impressionId,
    double? estimatedRevenue,
  }) async {
    try {
      // 광고 노출을 Railway 데이터베이스에 기록
      await _railway.recordEarning(
        earningMethod: 'ad_impression',
        amount: 0, // 추정 수익은 나중에 실제 검증 후 업데이트
        description: '광고 노출 추적',
        metadata: {
          'user_id': userId,
          'ad_unit_id': adUnitId,
          'impression_id': impressionId,
          'estimated_revenue_usd': estimatedRevenue,
          'tracked_at': DateTime.now().toIso8601String(),
          'status': 'pending_verification',
        },
      );

      print('📊 광고 노출 추적: $impressionId');

    } catch (e) {
      print('광고 노출 추적 실패: $e');
    }
  }

  // AdMob 콜백 처리 (Webhook)
  Future<void> handleAdMobWebhook(Map<String, dynamic> webhookData) async {
    try {
      // AdMob에서 실시간으로 보내는 수익 데이터 처리
      final adUnitId = webhookData['ad_unit_id'];
      final impressionId = webhookData['impression_id'];
      final revenueUsd = webhookData['revenue_usd'];

      if (revenueUsd >= _minimumRevenueUsd) {
        // 즉시 수익 분배 처리
        await _processWebhookRevenue(webhookData);
      }

      print('🔔 AdMob Webhook 처리 완료: $impressionId');

    } catch (e) {
      print('AdMob Webhook 처리 실패: $e');
    }
  }

  Future<void> _processWebhookRevenue(Map<String, dynamic> data) async {
    // Webhook으로 받은 실시간 수익 데이터 처리
    // 즉시 사용자에게 분배
  }

  // 수익 통계 조회
  Future<Map<String, dynamic>> getRevenueStatistics({
    String period = 'today',
  }) async {
    try {
      // AdMob API에서 통계 데이터 조회
      final stats = await _fetchRevenueStatistics(period);

      return {
        'total_revenue_usd': stats['total_revenue_usd'] ?? 0.0,
        'total_revenue_krw': stats['total_revenue_krw'] ?? 0.0,
        'user_share_krw': stats['user_share_krw'] ?? 0.0,
        'platform_share_krw': stats['platform_share_krw'] ?? 0.0,
        'impression_count': stats['impression_count'] ?? 0,
        'user_count': stats['user_count'] ?? 0,
        'average_per_user': stats['average_per_user'] ?? 0.0,
        'period': period,
        'updated_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('수익 통계 조회 실패: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _fetchRevenueStatistics(String period) async {
    // AdMob Reporting API에서 통계 데이터 조회
    return {};
  }

  // 리소스 정리
  void dispose() {
    _revenueCheckTimer?.cancel();
  }
}
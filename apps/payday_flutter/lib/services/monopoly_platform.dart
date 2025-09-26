import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// 전 세계 재택 부수입 통합 플랫폼
class MonopolyPlatform {
  static final MonopolyPlatform _instance = MonopolyPlatform._internal();
  factory MonopolyPlatform() => _instance;
  MonopolyPlatform._internal();

  final Dio _dio = Dio();

  // 실시간 수익 스트림
  late StreamController<IncomeUpdate> _incomeStream;
  Stream<IncomeUpdate> get incomeStream => _incomeStream.stream;

  // 사용자 통합 수익 데이터
  UserIncomeProfile? _userProfile;

  // 연동된 플랫폼들
  final Map<String, PlatformConnector> _connectedPlatforms = {};

  Future<void> initialize() async {
    _incomeStream = StreamController<IncomeUpdate>.broadcast();
    await _loadUserProfile();
    await _initializeConnectors();
    _startRealTimeSync();
  }

  // 1. 모든 기존 플랫폼 연동
  Future<void> _initializeConnectors() async {
    // 한국 플랫폼들
    _connectedPlatforms['cashwalk'] = CashWalkConnector();
    _connectedPlatforms['cashslide'] = CashSlideConnector();
    _connectedPlatforms['panelnow'] = PanelNowConnector();
    _connectedPlatforms['embrain'] = EmbrainConnector();
    _connectedPlatforms['mileage'] = MileageConnector();

    // 글로벌 플랫폼들
    _connectedPlatforms['swagbucks'] = SwagbucksConnector();
    _connectedPlatforms['surveyjunkie'] = SurveyJunkieConnector();
    _connectedPlatforms['usertesting'] = UserTestingConnector();
    _connectedPlatforms['upwork'] = UpworkConnector();
    _connectedPlatforms['fiverr'] = FiverrConnector();

    // 아시아 플랫폼들
    _connectedPlatforms['crowdworks_jp'] = CrowdWorksJapanConnector();
    _connectedPlatforms['zbj_cn'] = ZhuBaJieConnector(); // 猪八戒网
    _connectedPlatforms['grab'] = GrabConnector();

    // 모든 플랫폼 초기화
    for (var connector in _connectedPlatforms.values) {
      await connector.initialize();
    }
  }

  // 2. 실시간 수익 동기화
  void _startRealTimeSync() {
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _syncAllPlatforms();
    });
  }

  Future<void> _syncAllPlatforms() async {
    double totalIncome = 0;
    final updates = <PlatformIncome>[];

    for (var entry in _connectedPlatforms.entries) {
      try {
        final income = await entry.value.fetchLatestIncome();
        if (income != null) {
          totalIncome += income.amount;
          updates.add(income);
        }
      } catch (e) {
        debugPrint('${entry.key} 동기화 실패: $e');
      }
    }

    if (updates.isNotEmpty) {
      _incomeStream.add(IncomeUpdate(
        totalIncome: totalIncome,
        platformUpdates: updates,
        timestamp: DateTime.now(),
      ));
    }
  }

  // 3. AI 수익 최적화 엔진
  Future<List<IncomeOpportunity>> getOptimizedIncomeStrategy() async {
    final response = await _dio.post('/ai/optimize-income', data: {
      'user_profile': _userProfile?.toJson(),
      'connected_platforms': _connectedPlatforms.keys.toList(),
      'current_earnings': await _calculateTotalEarnings(),
      'available_time': _userProfile?.availableHours ?? 2,
      'skills': _userProfile?.skills ?? [],
      'preferences': _userProfile?.preferences ?? {},
    });

    return (response.data['opportunities'] as List)
        .map((json) => IncomeOpportunity.fromJson(json))
        .toList();
  }

  // 4. 수익 거래소
  Future<List<IncomeExchangeOffer>> getIncomeExchangeOffers() async {
    final response = await _dio.get('/exchange/offers');
    return (response.data['offers'] as List)
        .map((json) => IncomeExchangeOffer.fromJson(json))
        .toList();
  }

  Future<bool> createIncomeOffer({
    required String type,
    required double price,
    required String description,
    required DateTime deadline,
  }) async {
    final response = await _dio.post('/exchange/create-offer', data: {
      'type': type,
      'price': price,
      'description': description,
      'deadline': deadline.toIso8601String(),
      'user_id': _userProfile?.userId,
    });
    return response.data['success'] == true;
  }

  // 5. 수익 보험 시스템
  Future<IncomeInsurance?> getIncomeInsurance() async {
    final response = await _dio.get('/insurance/plans');
    return IncomeInsurance.fromJson(response.data);
  }

  Future<bool> subscribeToInsurance(String planId) async {
    final response = await _dio.post('/insurance/subscribe', data: {
      'plan_id': planId,
      'user_id': _userProfile?.userId,
    });
    return response.data['success'] == true;
  }

  // 6. 통합 출금 시스템
  Future<WithdrawalResult> requestUnifiedWithdrawal({
    required double amount,
    required String bankAccount,
    required List<String> platformIds,
  }) async {
    // 모든 플랫폼에서 동시 출금
    final withdrawalTasks = <Future<bool>>[];

    for (final platformId in platformIds) {
      final connector = _connectedPlatforms[platformId];
      if (connector != null) {
        withdrawalTasks.add(connector.requestWithdrawal(amount));
      }
    }

    final results = await Future.wait(withdrawalTasks);
    final successCount = results.where((r) => r).length;

    // 통합 정산 처리
    if (successCount > 0) {
      await _dio.post('/withdrawal/unified', data: {
        'user_id': _userProfile?.userId,
        'total_amount': amount,
        'bank_account': bankAccount,
        'successful_platforms': successCount,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }

    return WithdrawalResult(
      success: successCount == platformIds.length,
      successfulPlatforms: successCount,
      totalPlatforms: platformIds.length,
      amount: amount,
    );
  }

  // 7. 세금 자동 계산
  Future<TaxCalculation> calculateTaxes() async {
    final response = await _dio.post('/tax/calculate', data: {
      'user_id': _userProfile?.userId,
      'income_data': await _getAnnualIncomeData(),
      'year': DateTime.now().year,
    });
    return TaxCalculation.fromJson(response.data);
  }

  // 8. 글로벌 마켓플레이스
  Future<List<GlobalOpportunity>> getGlobalOpportunities() async {
    final response = await _dio.get('/global/opportunities', queryParameters: {
      'country': _userProfile?.country ?? 'KR',
      'language': _userProfile?.language ?? 'ko',
      'timezone': _userProfile?.timezone ?? 'Asia/Seoul',
    });

    return (response.data['opportunities'] as List)
        .map((json) => GlobalOpportunity.fromJson(json))
        .toList();
  }

  // 9. 수익 예측 및 분석
  Future<IncomeAnalytics> getIncomeAnalytics() async {
    final response = await _dio.get('/analytics/income', queryParameters: {
      'user_id': _userProfile?.userId,
      'period': '30d',
    });
    return IncomeAnalytics.fromJson(response.data);
  }

  // 10. 네트워크 효과 시스템
  Future<NetworkRewards> getNetworkRewards() async {
    final response = await _dio.get('/network/rewards/${_userProfile?.userId}');
    return NetworkRewards.fromJson(response.data);
  }

  Future<bool> inviteFriend(String email) async {
    final response = await _dio.post('/network/invite', data: {
      'inviter_id': _userProfile?.userId,
      'invitee_email': email,
    });
    return response.data['success'] == true;
  }

  // 헬퍼 메서드들
  Future<double> _calculateTotalEarnings() async {
    double total = 0;
    for (var connector in _connectedPlatforms.values) {
      final balance = await connector.getBalance();
      total += balance;
    }
    return total;
  }

  Future<Map<String, dynamic>> _getAnnualIncomeData() async {
    final data = <String, dynamic>{};
    for (var entry in _connectedPlatforms.entries) {
      data[entry.key] = await entry.value.getAnnualIncome();
    }
    return data;
  }

  Future<void> _loadUserProfile() async {
    // SharedPreferences에서 사용자 프로필 로드
    // 임시 데이터
    _userProfile = UserIncomeProfile(
      userId: 'user_123',
      availableHours: 3,
      skills: ['writing', 'translation', 'survey'],
      preferences: {'language': 'ko', 'timezone': 'Asia/Seoul'},
      country: 'KR',
      language: 'ko',
      timezone: 'Asia/Seoul',
    );
  }

  void dispose() {
    _incomeStream.close();
  }
}

// 데이터 모델들
class UserIncomeProfile {
  final String userId;
  final int availableHours;
  final List<String> skills;
  final Map<String, dynamic> preferences;
  final String country;
  final String language;
  final String timezone;

  UserIncomeProfile({
    required this.userId,
    required this.availableHours,
    required this.skills,
    required this.preferences,
    required this.country,
    required this.language,
    required this.timezone,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'available_hours': availableHours,
    'skills': skills,
    'preferences': preferences,
    'country': country,
    'language': language,
    'timezone': timezone,
  };
}

class IncomeUpdate {
  final double totalIncome;
  final List<PlatformIncome> platformUpdates;
  final DateTime timestamp;

  IncomeUpdate({
    required this.totalIncome,
    required this.platformUpdates,
    required this.timestamp,
  });
}

class PlatformIncome {
  final String platformId;
  final String platformName;
  final double amount;
  final String type;
  final DateTime timestamp;

  PlatformIncome({
    required this.platformId,
    required this.platformName,
    required this.amount,
    required this.type,
    required this.timestamp,
  });
}

class IncomeOpportunity {
  final String id;
  final String title;
  final String description;
  final double estimatedEarning;
  final int estimatedTimeMinutes;
  final String category;
  final double aiScore;
  final List<String> requirements;

  IncomeOpportunity({
    required this.id,
    required this.title,
    required this.description,
    required this.estimatedEarning,
    required this.estimatedTimeMinutes,
    required this.category,
    required this.aiScore,
    required this.requirements,
  });

  factory IncomeOpportunity.fromJson(Map<String, dynamic> json) {
    return IncomeOpportunity(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      estimatedEarning: json['estimated_earning'].toDouble(),
      estimatedTimeMinutes: json['estimated_time_minutes'],
      category: json['category'],
      aiScore: json['ai_score'].toDouble(),
      requirements: List<String>.from(json['requirements']),
    );
  }
}

class IncomeExchangeOffer {
  final String id;
  final String type;
  final double price;
  final String description;
  final DateTime deadline;
  final String sellerId;
  final double rating;

  IncomeExchangeOffer({
    required this.id,
    required this.type,
    required this.price,
    required this.description,
    required this.deadline,
    required this.sellerId,
    required this.rating,
  });

  factory IncomeExchangeOffer.fromJson(Map<String, dynamic> json) {
    return IncomeExchangeOffer(
      id: json['id'],
      type: json['type'],
      price: json['price'].toDouble(),
      description: json['description'],
      deadline: DateTime.parse(json['deadline']),
      sellerId: json['seller_id'],
      rating: json['rating'].toDouble(),
    );
  }
}

class IncomeInsurance {
  final String planId;
  final String name;
  final double monthlyPremium;
  final double guaranteedIncome;
  final List<String> benefits;

  IncomeInsurance({
    required this.planId,
    required this.name,
    required this.monthlyPremium,
    required this.guaranteedIncome,
    required this.benefits,
  });

  factory IncomeInsurance.fromJson(Map<String, dynamic> json) {
    return IncomeInsurance(
      planId: json['plan_id'],
      name: json['name'],
      monthlyPremium: json['monthly_premium'].toDouble(),
      guaranteedIncome: json['guaranteed_income'].toDouble(),
      benefits: List<String>.from(json['benefits']),
    );
  }
}

class WithdrawalResult {
  final bool success;
  final int successfulPlatforms;
  final int totalPlatforms;
  final double amount;

  WithdrawalResult({
    required this.success,
    required this.successfulPlatforms,
    required this.totalPlatforms,
    required this.amount,
  });
}

class TaxCalculation {
  final double totalIncome;
  final double taxableIncome;
  final double taxAmount;
  final double netIncome;
  final List<TaxBreakdown> breakdown;

  TaxCalculation({
    required this.totalIncome,
    required this.taxableIncome,
    required this.taxAmount,
    required this.netIncome,
    required this.breakdown,
  });

  factory TaxCalculation.fromJson(Map<String, dynamic> json) {
    return TaxCalculation(
      totalIncome: json['total_income'].toDouble(),
      taxableIncome: json['taxable_income'].toDouble(),
      taxAmount: json['tax_amount'].toDouble(),
      netIncome: json['net_income'].toDouble(),
      breakdown: (json['breakdown'] as List)
          .map((e) => TaxBreakdown.fromJson(e))
          .toList(),
    );
  }
}

class TaxBreakdown {
  final String source;
  final double amount;
  final double tax;

  TaxBreakdown({
    required this.source,
    required this.amount,
    required this.tax,
  });

  factory TaxBreakdown.fromJson(Map<String, dynamic> json) {
    return TaxBreakdown(
      source: json['source'],
      amount: json['amount'].toDouble(),
      tax: json['tax'].toDouble(),
    );
  }
}

class GlobalOpportunity {
  final String id;
  final String title;
  final String country;
  final double paymentUSD;
  final String requirements;
  final String timezone;

  GlobalOpportunity({
    required this.id,
    required this.title,
    required this.country,
    required this.paymentUSD,
    required this.requirements,
    required this.timezone,
  });

  factory GlobalOpportunity.fromJson(Map<String, dynamic> json) {
    return GlobalOpportunity(
      id: json['id'],
      title: json['title'],
      country: json['country'],
      paymentUSD: json['payment_usd'].toDouble(),
      requirements: json['requirements'],
      timezone: json['timezone'],
    );
  }
}

class IncomeAnalytics {
  final double monthlyGrowth;
  final Map<String, double> platformBreakdown;
  final List<IncomeForcast> forecast;
  final double averageHourlyRate;

  IncomeAnalytics({
    required this.monthlyGrowth,
    required this.platformBreakdown,
    required this.forecast,
    required this.averageHourlyRate,
  });

  factory IncomeAnalytics.fromJson(Map<String, dynamic> json) {
    return IncomeAnalytics(
      monthlyGrowth: json['monthly_growth'].toDouble(),
      platformBreakdown: Map<String, double>.from(json['platform_breakdown']),
      forecast: (json['forecast'] as List)
          .map((e) => IncomeForcast.fromJson(e))
          .toList(),
      averageHourlyRate: json['average_hourly_rate'].toDouble(),
    );
  }
}

class IncomeForcast {
  final DateTime date;
  final double predictedIncome;
  final double confidence;

  IncomeForcast({
    required this.date,
    required this.predictedIncome,
    required this.confidence,
  });

  factory IncomeForcast.fromJson(Map<String, dynamic> json) {
    return IncomeForcast(
      date: DateTime.parse(json['date']),
      predictedIncome: json['predicted_income'].toDouble(),
      confidence: json['confidence'].toDouble(),
    );
  }
}

class NetworkRewards {
  final int invitedFriends;
  final double totalRewards;
  final double monthlyBonus;
  final int tier;

  NetworkRewards({
    required this.invitedFriends,
    required this.totalRewards,
    required this.monthlyBonus,
    required this.tier,
  });

  factory NetworkRewards.fromJson(Map<String, dynamic> json) {
    return NetworkRewards(
      invitedFriends: json['invited_friends'],
      totalRewards: json['total_rewards'].toDouble(),
      monthlyBonus: json['monthly_bonus'].toDouble(),
      tier: json['tier'],
    );
  }
}

// 플랫폼 커넥터들의 기본 인터페이스
abstract class PlatformConnector {
  Future<void> initialize();
  Future<PlatformIncome?> fetchLatestIncome();
  Future<double> getBalance();
  Future<bool> requestWithdrawal(double amount);
  Future<double> getAnnualIncome();
}

// 개별 플랫폼 커넥터 구현 예시
class CashWalkConnector extends PlatformConnector {
  @override
  Future<void> initialize() async {
    // CashWalk API 초기화
  }

  @override
  Future<PlatformIncome?> fetchLatestIncome() async {
    // CashWalk에서 최신 수익 정보 가져오기
    return PlatformIncome(
      platformId: 'cashwalk',
      platformName: 'CashWalk',
      amount: 500.0,
      type: 'walking',
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<double> getBalance() async {
    return 15000.0;
  }

  @override
  Future<bool> requestWithdrawal(double amount) async {
    // CashWalk 출금 요청
    return true;
  }

  @override
  Future<double> getAnnualIncome() async {
    return 180000.0;
  }
}

class SwagbucksConnector extends PlatformConnector {
  @override
  Future<void> initialize() async {
    // Swagbucks API 초기화
  }

  @override
  Future<PlatformIncome?> fetchLatestIncome() async {
    return PlatformIncome(
      platformId: 'swagbucks',
      platformName: 'Swagbucks',
      amount: 2.5, // USD
      type: 'survey',
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<double> getBalance() async {
    return 45.80; // USD
  }

  @override
  Future<bool> requestWithdrawal(double amount) async {
    return true;
  }

  @override
  Future<double> getAnnualIncome() async {
    return 1200.0; // USD
  }
}

// 기타 플랫폼 커넥터들도 동일한 방식으로 구현
class CashSlideConnector extends PlatformConnector {
  @override
  Future<void> initialize() async {}
  @override
  Future<PlatformIncome?> fetchLatestIncome() async => null;
  @override
  Future<double> getBalance() async => 0.0;
  @override
  Future<bool> requestWithdrawal(double amount) async => false;
  @override
  Future<double> getAnnualIncome() async => 0.0;
}

class PanelNowConnector extends PlatformConnector {
  @override
  Future<void> initialize() async {}
  @override
  Future<PlatformIncome?> fetchLatestIncome() async => null;
  @override
  Future<double> getBalance() async => 0.0;
  @override
  Future<bool> requestWithdrawal(double amount) async => false;
  @override
  Future<double> getAnnualIncome() async => 0.0;
}

class EmbrainConnector extends PlatformConnector {
  @override
  Future<void> initialize() async {}
  @override
  Future<PlatformIncome?> fetchLatestIncome() async => null;
  @override
  Future<double> getBalance() async => 0.0;
  @override
  Future<bool> requestWithdrawal(double amount) async => false;
  @override
  Future<double> getAnnualIncome() async => 0.0;
}

class MileageConnector extends PlatformConnector {
  @override
  Future<void> initialize() async {}
  @override
  Future<PlatformIncome?> fetchLatestIncome() async => null;
  @override
  Future<double> getBalance() async => 0.0;
  @override
  Future<bool> requestWithdrawal(double amount) async => false;
  @override
  Future<double> getAnnualIncome() async => 0.0;
}

class SurveyJunkieConnector extends PlatformConnector {
  @override
  Future<void> initialize() async {}
  @override
  Future<PlatformIncome?> fetchLatestIncome() async => null;
  @override
  Future<double> getBalance() async => 0.0;
  @override
  Future<bool> requestWithdrawal(double amount) async => false;
  @override
  Future<double> getAnnualIncome() async => 0.0;
}

class UserTestingConnector extends PlatformConnector {
  @override
  Future<void> initialize() async {}
  @override
  Future<PlatformIncome?> fetchLatestIncome() async => null;
  @override
  Future<double> getBalance() async => 0.0;
  @override
  Future<bool> requestWithdrawal(double amount) async => false;
  @override
  Future<double> getAnnualIncome() async => 0.0;
}

class UpworkConnector extends PlatformConnector {
  @override
  Future<void> initialize() async {}
  @override
  Future<PlatformIncome?> fetchLatestIncome() async => null;
  @override
  Future<double> getBalance() async => 0.0;
  @override
  Future<bool> requestWithdrawal(double amount) async => false;
  @override
  Future<double> getAnnualIncome() async => 0.0;
}

class FiverrConnector extends PlatformConnector {
  @override
  Future<void> initialize() async {}
  @override
  Future<PlatformIncome?> fetchLatestIncome() async => null;
  @override
  Future<double> getBalance() async => 0.0;
  @override
  Future<bool> requestWithdrawal(double amount) async => false;
  @override
  Future<double> getAnnualIncome() async => 0.0;
}

class CrowdWorksJapanConnector extends PlatformConnector {
  @override
  Future<void> initialize() async {}
  @override
  Future<PlatformIncome?> fetchLatestIncome() async => null;
  @override
  Future<double> getBalance() async => 0.0;
  @override
  Future<bool> requestWithdrawal(double amount) async => false;
  @override
  Future<double> getAnnualIncome() async => 0.0;
}

class ZhuBaJieConnector extends PlatformConnector {
  @override
  Future<void> initialize() async {}
  @override
  Future<PlatformIncome?> fetchLatestIncome() async => null;
  @override
  Future<double> getBalance() async => 0.0;
  @override
  Future<bool> requestWithdrawal(double amount) async => false;
  @override
  Future<double> getAnnualIncome() async => 0.0;
}

class GrabConnector extends PlatformConnector {
  @override
  Future<void> initialize() async {}
  @override
  Future<PlatformIncome?> fetchLatestIncome() async => null;
  @override
  Future<double> getBalance() async => 0.0;
  @override
  Future<bool> requestWithdrawal(double amount) async => false;
  @override
  Future<double> getAnnualIncome() async => 0.0;
}
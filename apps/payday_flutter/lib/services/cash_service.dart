import 'dart:async';
import 'package:flutter/material.dart';
import 'data_service.dart';
import 'analytics_service.dart';

class CashService {
  static final CashService _instance = CashService._internal();
  factory CashService() => _instance;
  CashService._internal();

  final DataService _dataService = DataService();

  // 캐시 관련 상수 (실제 원화)
  static const int MIN_WITHDRAWAL = 5000; // 최소 출금 금액 5,000원
  static const double WITHDRAWAL_FEE_RATE = 0.03; // 출금 수수료 3%

  // 수익률 (원화 기준)
  static const Map<String, int> EARNING_RATES = {
    'walking': 1,        // 100보당 1원
    'ad_view': 20,       // 광고 시청 20원
    'ad_click': 50,      // 광고 클릭 50원
    'rewarded_ad': 100,  // 리워드 광고 100원
    'survey': 500,       // 설문조사 완료 500원
    'daily_login': 10,   // 일일 출석 10원
    'referral': 1000,    // 친구 초대 1000원
    'lockscreen_ad': 10, // 잠금화면 광고 기본 10원
  };

  // 미션 보상 (원화 기준)
  static const Map<String, int> MISSION_REWARDS = {
    'daily_mission_easy': 10,      // 쉬운 일일 미션 10원
    'daily_mission_medium': 30,    // 중간 일일 미션 30원
    'daily_mission_hard': 50,      // 어려운 일일 미션 50원
    'weekly_mission': 500,         // 주간 미션 500원
    'achievement_bronze': 100,     // 브론즈 업적 100원
    'achievement_silver': 500,     // 실버 업적 500원
    'achievement_gold': 1000,      // 골드 업적 1000원
  };

  // 현재 캐시 잔액
  double _currentBalance = 0.0;

  // 오늘 수익
  double _todayEarnings = 0.0;
  DateTime? _lastResetDate;

  // 캐시 변경 스트림
  final _cashStreamController = StreamController<double>.broadcast();
  Stream<double> get cashStream => _cashStreamController.stream;

  // 초기화
  Future<void> initialize() async {
    await _loadBalance();
    await _checkDailyReset();
  }

  // 잔액 불러오기
  Future<void> _loadBalance() async {
    try {
      // 로컬 캐시에서 먼저 읽기
      final cachedBalance = await _dataService.getSetting('cash_balance');
      _currentBalance = (cachedBalance is num) ? cachedBalance.toDouble() : 0.0;

      final cachedTodayEarnings = await _dataService.getSetting('today_earnings');
      _todayEarnings = (cachedTodayEarnings is num) ? cachedTodayEarnings.toDouble() : 0.0;

      final lastReset = await _dataService.getSetting('last_earnings_reset');
      if (lastReset != null) {
        _lastResetDate = DateTime.parse(lastReset);
      }

      // 서버에서 최신 잔액 동기화 (실제 구현 시)
      // final response = await _apiService.getUserBalance();
      // _currentBalance = response['cash'] ?? 0.0;

      _cashStreamController.add(_currentBalance);
    } catch (e) {
      print('캐시 잔액 로드 실패: $e');
    }
  }

  // 일일 수익 리셋 체크
  Future<void> _checkDailyReset() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastResetDate == null ||
        _lastResetDate!.day != today.day ||
        _lastResetDate!.month != today.month ||
        _lastResetDate!.year != today.year) {
      _todayEarnings = 0.0;
      _lastResetDate = today;
      await _dataService.saveSetting('today_earnings', 0.0);
      await _dataService.saveSetting('last_earnings_reset', today.toIso8601String());
    }
  }

  // 캐시 획득 (원화)
  Future<bool> earnCash({
    required String source,
    required double amount,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 서버에 캐시 적립 요청 (실제 구현 시)
      // final response = await _apiService.processEarning(
      //   source: source,
      //   amount: amount,
      //   description: description,
      // );

      // 로컬 업데이트
      _currentBalance += amount;
      _todayEarnings += amount;

      await _dataService.saveSetting('cash_balance', _currentBalance);
      await _dataService.saveSetting('today_earnings', _todayEarnings);
      _cashStreamController.add(_currentBalance);

      // 거래 내역 저장
      await _saveTransaction(
        type: 'earn',
        amount: amount,
        source: source,
        description: description,
        metadata: metadata,
      );

      // 통계 업데이트
      await _updateStatistics(source, amount);

      // 애널리틱스 로깅
      await AnalyticsService.logEarningEvent(
        earningType: source,
        amount: amount,
        source: source,
      );

      // 알림 표시
      _showCashNotification(amount, true);

      return true;
    } catch (e) {
      print('캐시 적립 실패: $e');
      return false;
    }
  }

  // 캐시 사용/출금
  Future<bool> withdrawCash({
    required double amount,
    required String method, // 'bank_transfer', 'gift_card', etc.
    required String accountInfo,
    Map<String, dynamic>? metadata,
  }) async {
    // 최소 출금 금액 확인
    if (amount < MIN_WITHDRAWAL) {
      throw '최소 출금 금액은 ${MIN_WITHDRAWAL}원입니다.';
    }

    // 잔액 확인
    if (_currentBalance < amount) {
      throw '잔액이 부족합니다. (현재: ${_currentBalance.toStringAsFixed(0)}원)';
    }

    try {
      // 수수료 계산
      final fee = amount * WITHDRAWAL_FEE_RATE;
      final actualAmount = amount - fee;

      // 서버에 출금 요청 (실제 구현 시)
      // final response = await _apiService.processWithdrawal(
      //   amount: amount,
      //   method: method,
      //   accountInfo: accountInfo,
      // );

      // 잔액 업데이트
      _currentBalance -= amount;
      await _dataService.saveSetting('cash_balance', _currentBalance);
      _cashStreamController.add(_currentBalance);

      // 거래 내역 저장
      await _saveTransaction(
        type: 'withdraw',
        amount: amount,
        source: method,
        description: '출금 - 실수령액: ${actualAmount.toStringAsFixed(0)}원',
        metadata: {
          ...?metadata,
          'fee': fee,
          'actualAmount': actualAmount,
          'method': method,
        },
      );

      // 애널리틱스
      await AnalyticsService.logEvent(
        name: 'cash_withdrawal',
        parameters: {
          'amount': amount,
          'method': method,
          'fee': fee,
        },
      );

      return true;
    } catch (e) {
      print('출금 실패: $e');
      return false;
    }
  }

  // 걷기 수익 (원화)
  Future<void> earnWalkingCash(int steps) async {
    final cash = (steps ~/ 100) * EARNING_RATES['walking']!.toDouble(); // 100보당 1원
    if (cash > 0) {
      await earnCash(
        source: 'walking',
        amount: cash,
        description: '${steps}보 걷기',
        metadata: {'steps': steps},
      );
    }
  }

  // 광고 시청 수익 (원화)
  Future<void> earnAdCash(String adType, {String? adUnitId}) async {
    double cash = 0;
    String description = '';

    switch (adType) {
      case 'rewarded':
        cash = 100; // 리워드 광고 100원
        description = '리워드 광고 시청';
        break;
      case 'interstitial':
        cash = 50; // 전면 광고 50원
        description = '전면 광고 시청';
        break;
      case 'banner_click':
        cash = 10; // 배너 클릭 10원
        description = '배너 광고 클릭';
        break;
      default:
        cash = 20; // 기본 광고 20원
        description = '광고 시청';
    }

    await earnCash(
      source: 'ad_$adType',
      amount: cash,
      description: description,
      metadata: {'adType': adType, 'adUnitId': adUnitId},
    );
  }

  // 일일 출석 보너스 (원화)
  Future<bool> claimDailyBonus() async {
    final lastClaim = await _dataService.getSetting('last_daily_claim');
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (lastClaim == today) {
      return false; // 이미 받음
    }

    // 연속 출석 체크
    int streak = await _dataService.getSetting('attendance_streak') ?? 0;
    final yesterday = DateTime.now().subtract(Duration(days: 1)).toIso8601String().split('T')[0];

    if (lastClaim == yesterday) {
      streak++; // 연속 출석
    } else {
      streak = 1; // 연속 출석 리셋
    }

    // 연속 출석 보너스 (원화)
    final bonusCash = 10 + (streak - 1) * 5.0; // 기본 10원 + 연속일수 * 5원
    final maxBonus = 100.0; // 최대 100원
    final actualCash = bonusCash > maxBonus ? maxBonus : bonusCash;

    await earnCash(
      source: 'daily_bonus',
      amount: actualCash,
      description: '${streak}일 연속 출석',
      metadata: {'streak': streak},
    );

    // 출석 정보 저장
    await _dataService.saveSetting('last_daily_claim', today);
    await _dataService.saveSetting('attendance_streak', streak);

    return true;
  }

  // 친구 초대 보너스 (원화)
  Future<void> earnReferralBonus(String referralCode) async {
    await earnCash(
      source: 'referral',
      amount: EARNING_RATES['referral']!.toDouble(),
      description: '친구 초대 성공',
      metadata: {'referralCode': referralCode},
    );
  }

  // 거래 내역 저장
  Future<void> _saveTransaction({
    required String type,
    required double amount,
    required String source,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final transaction = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'type': type,
      'amount': amount,
      'source': source,
      'description': description,
      'metadata': metadata,
      'timestamp': DateTime.now().toIso8601String(),
      'balance_after': _currentBalance,
    };

    // 최근 거래 내역 저장 (최대 100개)
    List<dynamic> transactions = await _dataService.getSetting('cash_transactions') ?? [];
    transactions.insert(0, transaction);
    if (transactions.length > 100) {
      transactions = transactions.sublist(0, 100);
    }
    await _dataService.saveSetting('cash_transactions', transactions);
  }

  // 거래 내역 조회
  Future<List<Map<String, dynamic>>> getTransactionHistory({int limit = 50}) async {
    List<dynamic> transactions = await _dataService.getSetting('cash_transactions') ?? [];
    return transactions
        .take(limit)
        .map((t) => Map<String, dynamic>.from(t))
        .toList();
  }

  // 통계 업데이트
  Future<void> _updateStatistics(String source, double amount) async {
    // 총 수익 업데이트
    double totalEarned = await _dataService.getSetting('total_cash_earned') ?? 0.0;
    await _dataService.saveSetting('total_cash_earned', totalEarned + amount);

    // 소스별 수익 업데이트
    Map<String, dynamic> sourceStats =
        Map<String, dynamic>.from(await _dataService.getSetting('earning_by_source') ?? {});
    sourceStats[source] = (sourceStats[source] ?? 0.0) + amount;
    await _dataService.saveSetting('earning_by_source', sourceStats);
  }

  // 캐시 통계
  Future<Map<String, dynamic>> getCashStatistics() async {
    final transactions = await getTransactionHistory(limit: 100);

    double totalEarned = 0;
    double totalWithdrawn = 0;
    Map<String, double> earnBySource = {};

    for (var transaction in transactions) {
      if (transaction['type'] == 'earn') {
        totalEarned += transaction['amount'];
        final source = transaction['source'] as String;
        earnBySource[source] = (earnBySource[source] ?? 0) + transaction['amount'];
      } else if (transaction['type'] == 'withdraw') {
        totalWithdrawn += transaction['amount'];
      }
    }

    return {
      'balance': _currentBalance,
      'todayEarnings': _todayEarnings,
      'totalEarned': await _dataService.getSetting('total_cash_earned') ?? 0.0,
      'totalWithdrawn': totalWithdrawn,
      'earnBySource': earnBySource,
      'transactionCount': transactions.length,
    };
  }

  // 캐시 알림 표시
  void _showCashNotification(double amount, bool isEarn) {
    // TODO: 실제 알림 구현
    print(isEarn
      ? '💵 ${amount.toStringAsFixed(0)}원 획득!'
      : '💸 ${amount.toStringAsFixed(0)}원 출금');
  }

  // 현재 잔액
  double get balance => _currentBalance;

  // 오늘 수익
  double get todayEarnings => _todayEarnings;

  // 최소 출금 가능 여부
  bool get canWithdraw => _currentBalance >= MIN_WITHDRAWAL;

  // 출금 수수료 계산
  double calculateWithdrawalFee(double amount) {
    return amount * WITHDRAWAL_FEE_RATE;
  }

  // 실제 수령액 계산
  double calculateActualAmount(double requestAmount) {
    return requestAmount - calculateWithdrawalFee(requestAmount);
  }

  // 리소스 정리
  void dispose() {
    _cashStreamController.close();
  }
}
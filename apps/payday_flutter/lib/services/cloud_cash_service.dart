import 'dart:async';
import 'package:flutter/material.dart';
import 'local_storage_service.dart';
import 'railway_service.dart';
import 'analytics_service.dart';

/// 클라우드 연동 캐시 서비스
/// 로컬 저장소 + Railway 데이터베이스를 함께 사용하는 하이브리드 방식
class CloudCashService {
  static final CloudCashService _instance = CloudCashService._internal();
  factory CloudCashService() => _instance;
  CloudCashService._internal();

  final LocalStorageService _localStorage = LocalStorageService();
  final RailwayService _railway = RailwayService();

  // 수익률 (원화 기준) - 서버에서 동기화됨
  Map<String, Map<String, dynamic>> _earningMethods = {};

  // 현재 캐시 잔액 (로컬 + 서버 동기화)
  double _localBalance = 0.0;
  double _serverBalance = 0.0;
  double _todayEarnings = 0.0;

  // 네트워크 상태
  bool _isOnline = false;
  Timer? _syncTimer;

  // 캐시 변경 스트림
  final _cashStreamController = StreamController<Map<String, double>>.broadcast();
  Stream<Map<String, double>> get cashStream => _cashStreamController.stream;

  // 초기화
  Future<void> initialize() async {
    await _localStorage.initialize();
    await _railway.initialize();
    await _loadLocalBalance();
    await _checkOnlineStatus();
    await _syncWithServer();
    await _startPeriodicSync();

    print('🚀 CloudCashService 초기화 완료');
    print('💰 로컬 잔액: $_localBalance원');
    print('☁️ 서버 잔액: $_serverBalance원');
  }

  // 온라인 상태 확인
  Future<void> _checkOnlineStatus() async {
    _isOnline = await _railway.checkConnection();
    print(_isOnline ? '🌐 온라인 모드' : '📱 오프라인 모드');
  }

  // 로컬 잔액 불러오기
  Future<void> _loadLocalBalance() async {
    try {
      _localBalance = await _localStorage.getCashBalance();
      _todayEarnings = await _localStorage.getTodayEarnings();
      _updateCashStream();
    } catch (e) {
      print('로컬 잔액 로드 실패: $e');
    }
  }

  // 서버와 동기화
  Future<void> _syncWithServer() async {
    if (!_isOnline) return;

    try {
      // 1. 서버 설정 가져오기
      final settings = await _railway.getSystemSettings();
      if (settings != null) {
        _earningMethods = Map<String, Map<String, dynamic>>.from(
          settings['earning_rates'] ?? {}
        );
      }

      // 2. 서버 잔액 가져오기
      final serverBalance = await _railway.getUserBalance();
      if (serverBalance != null) {
        _serverBalance = serverBalance;
      }

      // 3. Railway 서비스와 동기화
      await _railway.syncWithLocal();

      // 4. 잔액 스트림 업데이트
      _updateCashStream();

      print('✅ 서버 동기화 완료');
    } catch (e) {
      print('서버 동기화 실패: $e');
    }
  }

  // 주기적 동기화 시작
  Future<void> _startPeriodicSync() async {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _checkOnlineStatus();
      if (_isOnline) {
        await _syncWithServer();
      }
    });
  }

  // 캐시 스트림 업데이트
  void _updateCashStream() {
    _cashStreamController.add({
      'local': _localBalance,
      'server': _serverBalance,
      'today': _todayEarnings,
      'total': _localBalance + _serverBalance,
    });
  }

  // 수익 가능 여부 체크 (로컬 + 서버)
  Future<bool> canEarn(String source) async {
    // 1. 로컬 일일 제한 체크
    final localLimit = await _localStorage.getDailyEarningCount(source);
    final method = _earningMethods[source];
    if (method != null) {
      final dailyLimit = method['dailyLimit'] ?? 999;
      if (localLimit >= dailyLimit) {
        return false;
      }
    }

    // 2. 온라인이면 서버 제한도 체크
    if (_isOnline) {
      return await _railway.checkDailyLimit(source);
    }

    return true;
  }

  // 캐시 획득 (하이브리드 방식)
  Future<bool> earnCash({
    required String source,
    required double amount,
    String? description,
    Map<String, dynamic>? metadata,
    String? adUnitId,
    String? adImpressionId,
  }) async {
    try {
      // 1. 수익 가능 여부 체크
      if (!await canEarn(source)) {
        print('일일 한도 초과: $source');
        return false;
      }

      // 2. 로컬에 즉시 반영 (빠른 UX)
      await _earnLocal(
        source: source,
        amount: amount,
        description: description,
        metadata: metadata,
      );

      // 3. 온라인이면 서버에도 기록
      if (_isOnline && _railway.isAuthenticated) {
        final success = await _railway.recordEarning(
          earningMethod: source,
          amount: amount,
          description: description ?? _getDefaultDescription(source),
          metadata: metadata,
          adUnitId: adUnitId,
          adImpressionId: adImpressionId,
        );

        if (success) {
          print('💰 서버에 수익 기록 완료: ${amount.toStringAsFixed(0)}원');
        } else {
          // 서버 기록 실패 시 오프라인 대기열에 추가
          await _railway.addPendingTransaction({
            'source': source,
            'amount': amount,
            'description': description,
            'metadata': metadata,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      } else {
        // 오프라인이면 대기열에 추가
        await _railway.addPendingTransaction({
          'source': source,
          'amount': amount,
          'description': description,
          'metadata': metadata,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      // 4. 애널리틱스 로깅
      await AnalyticsService.logEarningEvent(
        earningType: source,
        amount: amount,
        source: source,
      );

      print('💰 $source: ${amount.toStringAsFixed(0)}원 획득!');
      return true;

    } catch (e) {
      print('캐시 적립 실패: $e');
      return false;
    }
  }

  // 로컬 수익 처리
  Future<void> _earnLocal({
    required String source,
    required double amount,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    // 잔액 업데이트
    _localBalance += amount;
    _todayEarnings += amount;

    // 로컬 저장소에 저장
    await _localStorage.setCashBalance(_localBalance);
    await _localStorage.setTodayEarnings(_todayEarnings);

    // 일일 카운터 증가
    await _localStorage.incrementDailyEarningCount(source);

    // 거래 내역 저장
    await _saveLocalTransaction(
      type: 'earn',
      amount: amount,
      source: source,
      description: description ?? _getDefaultDescription(source),
      metadata: metadata,
    );

    // 스트림 업데이트
    _updateCashStream();
  }

  // AdMob 수익 검증 및 처리
  Future<bool> earnVerifiedAdCash({
    required String adUnitId,
    required String impressionId,
    required double estimatedRevenue,
  }) async {
    try {
      if (_isOnline && _railway.isAuthenticated) {
        // 서버에서 실제 AdMob 수익 검증
        final verified = await _railway.verifyAdRevenue(
          adUnitId: adUnitId,
          impressionId: impressionId,
          revenueUsd: estimatedRevenue,
        );

        if (verified) {
          print('✅ AdMob 수익 검증 완료');
          return true;
        } else {
          print('❌ AdMob 수익 검증 실패');
          return false;
        }
      } else {
        // 오프라인이면 기본 보상으로 처리
        return await earnCash(
          source: 'ad_view',
          amount: 100, // 기본 광고 보상
          description: '리워드 광고 시청 (오프라인)',
          metadata: {
            'ad_unit_id': adUnitId,
            'impression_id': impressionId,
            'offline_mode': true,
          },
        );
      }
    } catch (e) {
      print('AdMob 수익 처리 실패: $e');
      return false;
    }
  }

  // 출금 요청
  Future<String?> requestWithdrawal({
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
    required String pin,
  }) async {
    if (!_isOnline || !_railway.isAuthenticated) {
      throw Exception('출금은 온라인 상태에서만 가능합니다');
    }

    if (amount > totalBalance) {
      throw Exception('잔액이 부족합니다');
    }

    try {
      final withdrawalId = await _railway.requestWithdrawal(
        amount: amount,
        bankName: bankName,
        accountNumber: accountNumber,
        accountHolderName: accountHolderName,
        pin: pin,
      );

      if (withdrawalId != null) {
        // 로컬 잔액에서 차감 (출금 처리 중)
        _localBalance -= amount;
        await _localStorage.setCashBalance(_localBalance);
        _updateCashStream();

        print('💸 출금 요청 완료: ${amount.toStringAsFixed(0)}원');
      }

      return withdrawalId;
    } catch (e) {
      print('출금 요청 실패: $e');
      rethrow;
    }
  }

  // 로컬 거래 내역 저장
  Future<void> _saveLocalTransaction({
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
      'metadata': metadata ?? {},
      'timestamp': DateTime.now().toIso8601String(),
      'balance_after': _localBalance,
      'synced': false,
    };

    await _localStorage.addTransaction(transaction);
  }

  // 헬퍼 메서드들
  String _getDefaultDescription(String source) {
    final method = _earningMethods[source];
    return method?['description'] ?? '수익 획득';
  }

  // 통계 조회 (로컬 + 서버)
  Future<Map<String, dynamic>> getCashStatistics() async {
    final localTransactions = await _localStorage.getTransactionHistory();
    final earningsBySource = await _localStorage.getEarningsBySource();
    final totalEarned = await _localStorage.getTotalEarned();

    return {
      'localBalance': _localBalance,
      'serverBalance': _serverBalance,
      'totalBalance': totalBalance,
      'todayEarnings': _todayEarnings,
      'totalEarned': totalEarned,
      'earningsBySource': earningsBySource,
      'transactionCount': localTransactions.length,
      'availableMethods': _earningMethods,
      'isOnline': _isOnline,
      'syncStatus': _isOnline ? 'synced' : 'offline',
    };
  }

  // 수익 방법별 편의 메서드들 (기존 것들 유지)
  Future<bool> earnAdCash(String adType, {String? adUnitId}) async {
    return await earnCash(
      source: 'ad_view',
      amount: 100,
      description: '리워드 광고 시청',
      metadata: {'adType': adType, 'adUnitId': adUnitId},
    );
  }

  Future<void> earnWalkingCash(int steps) async {
    final earnings = (steps ~/ 100);
    for (int i = 0; i < earnings; i++) {
      if (await canEarn('walking')) {
        await earnCash(
          source: 'walking',
          amount: 1,
          description: '100보 걷기',
          metadata: {'steps': 100},
        );
      } else {
        break;
      }
    }
  }

  Future<bool> claimDailyBonus() async {
    if (!await canEarn('daily_login')) {
      return false;
    }

    final streak = await _calculateAttendanceStreak();
    final bonusCash = 10 + (streak - 1) * 5.0;
    final maxBonus = 100.0;
    final actualCash = bonusCash > maxBonus ? maxBonus : bonusCash;

    final success = await earnCash(
      source: 'daily_login',
      amount: actualCash,
      description: '${streak}일 연속 출석',
      metadata: {'streak': streak},
    );

    if (success) {
      await _localStorage.setAttendanceStreak(streak);
      await _localStorage.setLastAttendanceDate(
        DateTime.now().toIso8601String().split('T')[0]
      );
    }

    return success;
  }

  Future<int> _calculateAttendanceStreak() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final yesterday = DateTime.now()
        .subtract(Duration(days: 1))
        .toIso8601String()
        .split('T')[0];

    final lastAttendance = await _localStorage.getLastAttendanceDate();
    int currentStreak = await _localStorage.getAttendanceStreak();

    if (lastAttendance == yesterday) {
      return currentStreak + 1;
    } else if (lastAttendance == today) {
      return currentStreak;
    } else {
      return 1;
    }
  }

  // 수동 동기화
  Future<void> forcSync() async {
    await _checkOnlineStatus();
    if (_isOnline) {
      await _syncWithServer();
      print('🔄 수동 동기화 완료');
    } else {
      print('❌ 오프라인 상태로 동기화 불가');
    }
  }

  // Getters
  double get localBalance => _localBalance;
  double get serverBalance => _serverBalance;
  double get totalBalance => _localBalance + _serverBalance;
  double get todayEarnings => _todayEarnings;
  bool get isOnline => _isOnline;
  bool get isAuthenticated => _railway.isAuthenticated;

  // 리소스 정리
  void dispose() {
    _syncTimer?.cancel();
    _cashStreamController.close();
  }
}
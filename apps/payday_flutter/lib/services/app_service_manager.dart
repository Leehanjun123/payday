import 'dart:async';
import 'package:flutter/foundation.dart';
import 'local_storage_service.dart';
import 'railway_service.dart';
import 'cloud_cash_service.dart';
import 'auth_service.dart';
import 'admob_revenue_service.dart';
import 'withdrawal_service.dart';
import 'payment_service.dart';
import 'analytics_service.dart';

/// PayDay 앱 전체 서비스 관리자
/// 모든 서비스들을 통합 관리하고 초기화 순서를 보장
class AppServiceManager {
  static final AppServiceManager _instance = AppServiceManager._internal();
  factory AppServiceManager() => _instance;
  AppServiceManager._internal();

  // 서비스 인스턴스들
  final LocalStorageService _localStorage = LocalStorageService();
  final RailwayService _railway = RailwayService();
  final AuthService _auth = AuthService();
  final CloudCashService _cashService = CloudCashService();
  final AdMobRevenueService _adMobRevenue = AdMobRevenueService();
  final WithdrawalService _withdrawal = WithdrawalService();
  final PaymentService _payment = PaymentService();

  // 초기화 상태
  bool _isInitialized = false;
  bool _isInitializing = false;
  final Completer<void> _initCompleter = Completer<void>();

  // 서비스 상태 스트림
  final _serviceStatusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get serviceStatusStream => _serviceStatusController.stream;

  // 전체 앱 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      await _initCompleter.future;
      return;
    }

    _isInitializing = true;
    print('🚀 PayDay 앱 서비스 초기화 시작...');

    try {
      // 1단계: 기본 서비스 초기화 (순서 중요)
      await _initializePhaseOne();

      // 2단계: 인증 및 데이터 서비스 초기화
      await _initializePhaseTwo();

      // 3단계: 비즈니스 로직 서비스 초기화
      await _initializePhaseThree();

      // 4단계: 백그라운드 서비스 시작
      await _initializePhaseFour();

      _isInitialized = true;
      _isInitializing = false;
      _initCompleter.complete();

      _updateServiceStatus();
      print('✅ PayDay 앱 초기화 완료!');

    } catch (e) {
      _isInitializing = false;
      _initCompleter.completeError(e);
      print('❌ PayDay 앱 초기화 실패: $e');
      rethrow;
    }
  }

  // 1단계: 기본 서비스 초기화
  Future<void> _initializePhaseOne() async {
    print('📱 1단계: 로컬 저장소 및 분석 서비스 초기화...');

    // 로컬 저장소 (가장 먼저)
    await _localStorage.initialize();
    print('✓ 로컬 저장소 초기화 완료');

    // 분석 서비스
    await AnalyticsService.initialize();
    print('✓ 분석 서비스 초기화 완료');

    // 앱 시작 이벤트 로깅
    await AnalyticsService.logAppStart();
  }

  // 2단계: 인증 및 데이터 서비스 초기화
  Future<void> _initializePhaseTwo() async {
    print('🔐 2단계: 인증 및 클라우드 서비스 초기화...');

    // Railway 서비스 (클라우드 데이터베이스)
    await _railway.initialize();
    print('✓ Railway 데이터베이스 연결 완료');

    // 사용자 인증 서비스
    await _auth.initialize();
    print('✓ 사용자 인증 서비스 초기화 완료');

    // 자동 게스트 로그인 (신규 사용자)
    if (!_auth.isAuthenticated) {
      final guestSuccess = await _auth.startAsGuest();
      if (guestSuccess) {
        print('✓ 게스트 자동 로그인 완료');
        await AnalyticsService.logUserSignIn('guest');
      }
    } else {
      print('✓ 기존 사용자 자동 로그인');
      await AnalyticsService.logUserSignIn(_auth.userProfile?['auth_type'] ?? 'unknown');
    }

    // 캐시 서비스 (인증 후)
    await _cashService.initialize();
    print('✓ 캐시 서비스 초기화 완료');
  }

  // 3단계: 비즈니스 로직 서비스 초기화
  Future<void> _initializePhaseThree() async {
    print('💰 3단계: 수익 및 출금 서비스 초기화...');

    // 출금 서비스
    await _withdrawal.initialize();
    print('✓ 출금 서비스 초기화 완료');

    // 오픈뱅킹 결제 서비스
    await _payment.initialize();
    print('✓ 오픈뱅킹 서비스 초기화 완료');
  }

  // 4단계: 백그라운드 서비스 시작
  Future<void> _initializePhaseFour() async {
    print('🔄 4단계: 백그라운드 서비스 시작...');

    // AdMob 수익 검증 서비스 (백그라운드)
    try {
      await _adMobRevenue.initialize();
      print('✓ AdMob 수익 검증 서비스 시작');
    } catch (e) {
      print('⚠️ AdMob 서비스 초기화 실패 (계속 진행): $e');
    }

    // 주기적 동기화 시작
    _startPeriodicTasks();
    print('✓ 주기적 작업 스케줄링 완료');
  }

  // 주기적 작업들
  void _startPeriodicTasks() {
    // 5분마다 서비스 상태 업데이트
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _updateServiceStatus();
    });

    // 1시간마다 전체 동기화
    Timer.periodic(const Duration(hours: 1), (timer) async {
      await syncAllServices();
    });

    // 일일 정리 작업 (자정)
    _scheduleDailyMaintenance();
  }

  // 서비스 상태 업데이트
  void _updateServiceStatus() {
    final status = {
      'isInitialized': _isInitialized,
      'timestamp': DateTime.now().toIso8601String(),
      'services': {
        'localStorage': _localStorage.isInitialized,
        'railway': _railway.isAuthenticated,
        'auth': _auth.isAuthenticated,
        'cashService': _cashService.isOnline,
        'payment': _payment.isConnected,
        'withdrawal': _withdrawal.hasActiveBankAccount,
      },
      'user': {
        'isAuthenticated': _auth.isAuthenticated,
        'authType': _auth.userProfile?['auth_type'],
        'nickname': _auth.nickname,
        'userId': _auth.userId,
      },
      'balance': {
        'local': _cashService.localBalance,
        'server': _cashService.serverBalance,
        'total': _cashService.totalBalance,
        'today': _cashService.todayEarnings,
      },
      'withdrawal': {
        'hasAccount': _withdrawal.hasActiveBankAccount,
        'hasPending': _withdrawal.hasPendingWithdrawal,
        'minimumAmount': _withdrawal.minimumWithdrawal,
      }
    };

    _serviceStatusController.add(status);
  }

  // 전체 서비스 동기화
  Future<void> syncAllServices() async {
    if (!_isInitialized) return;

    try {
      print('🔄 전체 서비스 동기화 시작...');

      // 캐시 서비스 동기화
      await _cashService.forcSync();

      // 출금 내역 동기화
      if (_withdrawal.hasPendingWithdrawal) {
        // 처리 중인 출금 상태 확인
      }

      // 서비스 상태 업데이트
      _updateServiceStatus();

      print('✅ 전체 서비스 동기화 완료');
      await AnalyticsService.logCustomEvent('service_sync_completed');

    } catch (e) {
      print('❌ 서비스 동기화 실패: $e');
      await AnalyticsService.logCustomEvent('service_sync_failed', {
        'error': e.toString(),
      });
    }
  }

  // 일일 정리 작업 스케줄링
  void _scheduleDailyMaintenance() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = nextMidnight.difference(now);

    Timer(timeUntilMidnight, () {
      _performDailyMaintenance();

      // 매일 반복
      Timer.periodic(const Duration(days: 1), (timer) {
        _performDailyMaintenance();
      });
    });
  }

  // 일일 정리 작업 실행
  Future<void> _performDailyMaintenance() async {
    try {
      print('🧹 일일 정리 작업 시작...');

      // 로컬 저장소 정리
      await _localStorage.performDailyCleanup();

      // 일일 제한 리셋 확인
      await _cashService.forcSync();

      // 분석 데이터 전송
      await AnalyticsService.logDailyActive();

      print('✅ 일일 정리 작업 완료');
    } catch (e) {
      print('❌ 일일 정리 작업 실패: $e');
    }
  }

  // 긴급 상황 대응 (네트워크 오류 등)
  Future<void> handleEmergency(String type, Map<String, dynamic> details) async {
    print('🚨 긴급 상황 발생: $type');

    await AnalyticsService.logCustomEvent('emergency_handled', {
      'type': type,
      'details': details,
      'timestamp': DateTime.now().toIso8601String(),
    });

    switch (type) {
      case 'network_error':
        // 오프라인 모드로 전환
        break;
      case 'auth_expired':
        // 재인증 요청
        break;
      case 'server_error':
        // 로컬 백업 모드
        break;
    }

    _updateServiceStatus();
  }

  // 앱 종료 시 정리
  Future<void> dispose() async {
    try {
      print('🔄 앱 서비스 정리 중...');

      // 백그라운드 서비스 중지
      _adMobRevenue.dispose();
      _cashService.dispose();

      // 스트림 정리
      await _serviceStatusController.close();

      // 최종 분석 데이터 전송
      await AnalyticsService.logAppEnd();

      print('✅ 앱 서비스 정리 완료');
    } catch (e) {
      print('❌ 앱 정리 중 오류: $e');
    }
  }

  // 편의 메서드들
  Future<bool> earnCash({
    required String source,
    required double amount,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isInitialized) return false;
    return await _cashService.earnCash(
      source: source,
      amount: amount,
      description: description,
      metadata: metadata,
    );
  }

  Future<String?> requestWithdrawal({
    required double amount,
    required String pin,
    String? memo,
  }) async {
    if (!_isInitialized) return null;
    return await _withdrawal.createWithdrawalRequest(
      amount: amount,
      pin: pin,
      memo: memo,
    );
  }

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) return false;
    final success = await _auth.signInWithEmail(
      email: email,
      password: password,
    );

    if (success) {
      await _cashService.initialize(); // 사용자 변경 후 캐시 서비스 재초기화
      _updateServiceStatus();
      await AnalyticsService.logUserSignIn('email');
    }

    return success;
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? nickname,
    String? referralCode,
  }) async {
    if (!_isInitialized) return false;
    final success = await _auth.signUpWithEmail(
      email: email,
      password: password,
      nickname: nickname,
      referralCode: referralCode,
    );

    if (success) {
      await _cashService.initialize();
      _updateServiceStatus();
      await AnalyticsService.logUserSignUp('email');
    }

    return success;
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isOnline => _cashService.isOnline;
  bool get isAuthenticated => _auth.isAuthenticated;

  AuthService get auth => _auth;
  CloudCashService get cashService => _cashService;
  WithdrawalService get withdrawal => _withdrawal;
  PaymentService get payment => _payment;
  RailwayService get railway => _railway;
  LocalStorageService get localStorage => _localStorage;

  double get totalBalance => _cashService.totalBalance;
  double get todayEarnings => _cashService.todayEarnings;
  String? get nickname => _auth.nickname;
  String? get userId => _auth.userId;
}
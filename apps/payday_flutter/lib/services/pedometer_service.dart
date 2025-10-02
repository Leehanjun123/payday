import 'dart:async';
import 'package:flutter/services.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'data_service.dart';

/// 캐시워크 스타일 걷기 리워드 서비스
class PedometerService {
  static final PedometerService _instance = PedometerService._internal();
  factory PedometerService() => _instance;
  PedometerService._internal();

  final DataService _dataService = DataService();

  StreamSubscription<StepCount>? _stepCountStream;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusStream;

  int _todaySteps = 0;
  int _lastSavedSteps = 0;
  DateTime _lastResetDate = DateTime.now();
  bool _isWalking = false;

  // 리워드 설정 (캐시워크 스타일)
  static const int COINS_PER_100_STEPS = 1;
  static const int MAX_DAILY_COINS = 100; // 하루 최대 100코인
  static const int MAX_DAILY_STEPS = 10000; // 만보까지만 리워드

  // 보너스 챌린지
  static const Map<int, int> MILESTONE_BONUSES = {
    1000: 5,   // 1,000보 보너스
    3000: 10,  // 3,000보 보너스
    5000: 15,  // 5,000보 보너스
    10000: 30, // 10,000보 보너스
  };

  /// 초기화 및 권한 요청
  Future<bool> initialize() async {
    // 권한 확인
    final status = await Permission.activityRecognition.request();
    if (!status.isGranted) {
      print('❌ 걸음 수 권한이 거부되었습니다');
      return false;
    }

    // 저장된 데이터 로드
    await _loadSavedData();

    // 자정 리셋 체크
    _checkDailyReset();

    // 걸음 수 모니터링 시작
    _startStepCounting();

    return true;
  }

  /// 저장된 데이터 로드
  Future<void> _loadSavedData() async {
    _todaySteps = await _dataService.getSetting('today_steps') ?? 0;
    _lastSavedSteps = await _dataService.getSetting('last_saved_steps') ?? 0;

    final lastReset = await _dataService.getSetting('last_reset_date');
    if (lastReset != null) {
      _lastResetDate = DateTime.parse(lastReset);
    }
  }

  /// 자정 리셋 체크
  void _checkDailyReset() {
    final now = DateTime.now();
    if (now.day != _lastResetDate.day) {
      // 어제 기록 저장
      _saveYesterdayRecord();

      // 오늘 걸음 수 리셋
      _todaySteps = 0;
      _lastSavedSteps = 0;
      _lastResetDate = now;

      _dataService.saveSetting('today_steps', 0);
      _dataService.saveSetting('last_saved_steps', 0);
      _dataService.saveSetting('last_reset_date', now.toIso8601String());
    }
  }

  /// 어제 기록 저장
  Future<void> _saveYesterdayRecord() async {
    if (_todaySteps > 0) {
      final coins = calculateCoins(_todaySteps);

      await _dataService.addEarning(
        source: '걷기 리워드',
        amount: coins.toDouble(),
        description: '${_todaySteps}걸음 달성',
      );

      print('📊 어제 기록: ${_todaySteps}걸음, ${coins}코인 적립');
    }
  }

  /// 걸음 수 측정 시작
  void _startStepCounting() {
    _stepCountStream = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepCountError,
    );

    _pedestrianStatusStream = Pedometer.pedestrianStatusStream.listen(
      _onPedestrianStatusChanged,
      onError: _onPedestrianStatusError,
    );
  }

  /// 걸음 수 업데이트
  void _onStepCount(StepCount event) {
    final deviceSteps = event.steps;

    // 오늘 걸음 수 계산
    if (_lastSavedSteps == 0) {
      _lastSavedSteps = deviceSteps;
    }

    _todaySteps = deviceSteps - _lastSavedSteps;

    // 저장
    _dataService.saveSetting('today_steps', _todaySteps);
    _dataService.saveSetting('last_saved_steps', _lastSavedSteps);

    // 마일스톤 체크
    _checkMilestones();
  }

  /// 걷기 상태 변경
  void _onPedestrianStatusChanged(PedestrianStatus event) {
    _isWalking = event.status == 'walking';
  }

  /// 에러 핸들링
  void _onStepCountError(error) {
    print('걸음 수 측정 오류: $error');
  }

  void _onPedestrianStatusError(error) {
    print('걷기 상태 오류: $error');
  }

  /// 마일스톤 체크 및 보너스 지급
  void _checkMilestones() async {
    for (final entry in MILESTONE_BONUSES.entries) {
      final milestone = entry.key;
      final bonus = entry.value;
      final key = 'milestone_${milestone}_${_lastResetDate.day}';
      final achieved = await _dataService.getSetting(key) ?? false;

      if (achieved == false && _todaySteps >= milestone) {
        // 보너스 지급
        _dataService.addEarning(
          source: '걷기 보너스',
          amount: bonus.toDouble(),
          description: '${milestone}보 달성 보너스',
        );

        _dataService.saveSetting(key, true);
        print('🎉 ${milestone}보 달성! 보너스 ${bonus}코인');
      }
    }
  }

  /// 코인 계산
  int calculateCoins(int steps) {
    if (steps > MAX_DAILY_STEPS) {
      steps = MAX_DAILY_STEPS;
    }

    int coins = steps ~/ 100 * COINS_PER_100_STEPS;

    if (coins > MAX_DAILY_COINS) {
      coins = MAX_DAILY_COINS;
    }

    return coins;
  }

  /// 오늘의 진행 상황
  Map<String, dynamic> getTodayProgress() {
    final coins = calculateCoins(_todaySteps);
    final progress = (_todaySteps / MAX_DAILY_STEPS).clamp(0.0, 1.0);

    return {
      'steps': _todaySteps,
      'coins': coins,
      'maxCoins': MAX_DAILY_COINS,
      'progress': progress,
      'isWalking': _isWalking,
      'nextMilestone': _getNextMilestone(),
    };
  }

  /// 다음 마일스톤
  int? _getNextMilestone() {
    for (final milestone in MILESTONE_BONUSES.keys) {
      if (_todaySteps < milestone) {
        return milestone;
      }
    }
    return null;
  }

  /// 주간 통계
  Future<Map<String, dynamic>> getWeeklyStats() async {
    // 최근 7일 데이터
    final List<Map<String, dynamic>> weekData = [];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final steps = await _dataService.getSetting('steps_${date.day}_${date.month}') ?? 0;

      weekData.add({
        'date': date,
        'steps': steps,
        'coins': calculateCoins(steps),
      });
    }

    return {
      'data': weekData,
      'totalSteps': weekData.fold(0, (sum, day) => sum + day['steps'] as int),
      'totalCoins': weekData.fold(0, (sum, day) => sum + day['coins'] as int),
      'avgSteps': weekData.fold(0, (sum, day) => sum + day['steps'] as int) ~/ 7,
    };
  }

  // Getters
  int get todaySteps => _todaySteps;
  int get todayCoins => calculateCoins(_todaySteps);
  bool get isWalking => _isWalking;
  double get dailyProgress => (_todaySteps / MAX_DAILY_STEPS).clamp(0.0, 1.0);

  /// 종료
  void dispose() {
    _stepCountStream?.cancel();
    _pedestrianStatusStream?.cancel();
  }
}
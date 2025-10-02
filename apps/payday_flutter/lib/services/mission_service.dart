import 'dart:async';
import 'dart:math';
import 'data_service.dart';
import 'enhanced_cash_service.dart';
import 'analytics_service.dart';

class MissionService {
  static final MissionService _instance = MissionService._internal();
  factory MissionService() => _instance;
  MissionService._internal();

  final DataService _dataService = DataService();
  final EnhancedCashService _cashService = EnhancedCashService();

  // 미션 타입
  static const Map<String, dynamic> MISSION_TYPES = {
    'daily_login': {
      'name': '일일 출석',
      'description': '오늘 앱에 접속하기',
      'points': 10,
      'icon': '📅',
      'type': 'automatic',
    },
    'watch_ads': {
      'name': '광고 시청',
      'description': '광고 3개 시청하기',
      'points': 30,
      'icon': '📺',
      'type': 'counter',
      'target': 3,
    },
    'complete_survey': {
      'name': '설문 참여',
      'description': '설문조사 1개 완료하기',
      'points': 50,
      'icon': '📋',
      'type': 'counter',
      'target': 1,
    },
    'walk_steps': {
      'name': '걷기 목표',
      'description': '5000보 걷기',
      'points': 100,
      'icon': '🚶',
      'type': 'counter',
      'target': 5000,
    },
    'share_app': {
      'name': '앱 공유',
      'description': '친구에게 앱 공유하기',
      'points': 50,
      'icon': '📱',
      'type': 'action',
    },
    'consecutive_days': {
      'name': '연속 출석',
      'description': '3일 연속 출석하기',
      'points': 200,
      'icon': '🔥',
      'type': 'streak',
      'target': 3,
    },
    'earn_points': {
      'name': '포인트 수집가',
      'description': '오늘 500P 이상 획득하기',
      'points': 100,
      'icon': '💰',
      'type': 'counter',
      'target': 500,
    },
    'use_feature': {
      'name': '기능 탐험가',
      'description': '3가지 다른 기능 사용하기',
      'points': 30,
      'icon': '🔍',
      'type': 'counter',
      'target': 3,
    },
  };

  // 주간 미션
  static const Map<String, dynamic> WEEKLY_MISSIONS = {
    'weekly_login': {
      'name': '주간 출석왕',
      'description': '일주일 중 5일 이상 접속',
      'points': 500,
      'icon': '👑',
      'type': 'counter',
      'target': 5,
    },
    'weekly_points': {
      'name': '포인트 마스터',
      'description': '일주일간 3000P 획득',
      'points': 1000,
      'icon': '🏆',
      'type': 'counter',
      'target': 3000,
    },
    'weekly_surveys': {
      'name': '설문 전문가',
      'description': '일주일간 설문 10개 완료',
      'points': 800,
      'icon': '📊',
      'type': 'counter',
      'target': 10,
    },
  };

  // 현재 미션 상태
  List<Map<String, dynamic>> _dailyMissions = [];
  List<Map<String, dynamic>> _weeklyMissions = [];
  DateTime? _lastMissionResetDate;
  Map<String, int> _missionProgress = {};

  // 초기화
  Future<void> initialize() async {
    await _loadMissionData();
    await _checkAndResetMissions();
    await _generateDailyMissions();
  }

  // 미션 데이터 로드
  Future<void> _loadMissionData() async {
    _missionProgress = Map<String, int>.from(
      await _dataService.getSetting('mission_progress') ?? {},
    );

    final lastReset = await _dataService.getSetting('last_mission_reset');
    if (lastReset != null) {
      _lastMissionResetDate = DateTime.parse(lastReset);
    }

    // 저장된 미션 목록 로드
    final savedDaily = await _dataService.getSetting('daily_missions');
    if (savedDaily != null && savedDaily is List) {
      _dailyMissions = savedDaily.cast<Map<String, dynamic>>();
    }

    final savedWeekly = await _dataService.getSetting('weekly_missions');
    if (savedWeekly != null && savedWeekly is List) {
      _weeklyMissions = savedWeekly.cast<Map<String, dynamic>>();
    }
  }

  // 미션 리셋 체크
  Future<void> _checkAndResetMissions() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 일일 미션 리셋
    if (_lastMissionResetDate == null ||
        !_isSameDay(_lastMissionResetDate!, now)) {
      await _resetDailyMissions();
    }

    // 주간 미션 리셋 (월요일마다)
    if (_lastMissionResetDate == null ||
        _getWeekNumber(now) != _getWeekNumber(_lastMissionResetDate!)) {
      await _resetWeeklyMissions();
    }

    _lastMissionResetDate = today;
    await _dataService.saveSetting('last_mission_reset', today.toIso8601String());
  }

  // 일일 미션 생성
  Future<void> _generateDailyMissions() async {
    if (_dailyMissions.isNotEmpty) return;

    final random = Random();
    final missionKeys = MISSION_TYPES.keys.toList();

    // 랜덤으로 5개 미션 선택
    missionKeys.shuffle(random);
    _dailyMissions = [];

    for (int i = 0; i < 5 && i < missionKeys.length; i++) {
      final key = missionKeys[i];
      final mission = Map<String, dynamic>.from(MISSION_TYPES[key]!);
      mission['id'] = '${key}_${DateTime.now().millisecondsSinceEpoch}';
      mission['missionKey'] = key;
      mission['isCompleted'] = false;
      mission['progress'] = _missionProgress[key] ?? 0;
      mission['claimedAt'] = null;

      _dailyMissions.add(mission);
    }

    // 항상 포함되는 미션 (일일 출석)
    if (!_dailyMissions.any((m) => m['missionKey'] == 'daily_login')) {
      final loginMission = Map<String, dynamic>.from(MISSION_TYPES['daily_login']!);
      loginMission['id'] = 'daily_login_${DateTime.now().millisecondsSinceEpoch}';
      loginMission['missionKey'] = 'daily_login';
      loginMission['isCompleted'] = false;
      loginMission['progress'] = _missionProgress['daily_login'] ?? 0;
      loginMission['claimedAt'] = null;
      _dailyMissions.insert(0, loginMission);
    }

    await _saveMissions();
  }

  // 주간 미션 생성
  Future<void> _generateWeeklyMissions() async {
    if (_weeklyMissions.isNotEmpty) return;

    _weeklyMissions = [];

    WEEKLY_MISSIONS.forEach((key, missionData) {
      final mission = Map<String, dynamic>.from(missionData);
      mission['id'] = '${key}_${DateTime.now().millisecondsSinceEpoch}';
      mission['missionKey'] = key;
      mission['isCompleted'] = false;
      mission['progress'] = _missionProgress[key] ?? 0;
      mission['claimedAt'] = null;

      _weeklyMissions.add(mission);
    });

    await _saveMissions();
  }

  // 일일 미션 리셋
  Future<void> _resetDailyMissions() async {
    _dailyMissions.clear();

    // 일일 미션 진행도 리셋
    MISSION_TYPES.keys.forEach((key) {
      _missionProgress[key] = 0;
    });

    await _dataService.saveSetting('mission_progress', _missionProgress);
    await _generateDailyMissions();
  }

  // 주간 미션 리셋
  Future<void> _resetWeeklyMissions() async {
    _weeklyMissions.clear();

    // 주간 미션 진행도 리셋
    WEEKLY_MISSIONS.keys.forEach((key) {
      _missionProgress[key] = 0;
    });

    await _dataService.saveSetting('mission_progress', _missionProgress);
    await _generateWeeklyMissions();
  }

  // 미션 진행도 업데이트
  Future<void> updateProgress(String missionKey, {int? increment}) async {
    final currentProgress = _missionProgress[missionKey] ?? 0;
    _missionProgress[missionKey] = currentProgress + (increment ?? 1);

    // 일일 미션 업데이트
    for (var mission in _dailyMissions) {
      if (mission['missionKey'] == missionKey) {
        mission['progress'] = _missionProgress[missionKey];

        // 목표 달성 체크
        if (mission['type'] == 'counter' || mission['type'] == 'streak') {
          final target = mission['target'] as int?;
          if (target != null && mission['progress'] >= target) {
            mission['isCompleted'] = true;
          }
        } else if (mission['type'] == 'automatic' || mission['type'] == 'action') {
          mission['isCompleted'] = true;
        }
      }
    }

    // 주간 미션 업데이트
    for (var mission in _weeklyMissions) {
      if (mission['missionKey'] == missionKey) {
        mission['progress'] = _missionProgress[missionKey];

        final target = mission['target'] as int?;
        if (target != null && mission['progress'] >= target) {
          mission['isCompleted'] = true;
        }
      }
    }

    await _dataService.saveSetting('mission_progress', _missionProgress);
    await _saveMissions();
  }

  // 미션 보상 받기
  Future<bool> claimReward(String missionId) async {
    // 일일 미션에서 찾기
    Map<String, dynamic>? mission;
    bool isDaily = true;

    mission = _dailyMissions.firstWhere(
      (m) => m['id'] == missionId,
      orElse: () => {},
    );

    if (mission.isEmpty) {
      // 주간 미션에서 찾기
      mission = _weeklyMissions.firstWhere(
        (m) => m['id'] == missionId,
        orElse: () => {},
      );
      isDaily = false;
    }

    if (mission.isEmpty || !mission['isCompleted'] || mission['claimedAt'] != null) {
      return false;
    }

    // 캐시 지급 (실제 원화)
    final cash = (mission['points'] as int).toDouble();
    final earnResult = await _cashService.earnCash(
      source: 'mission',
      amount: cash,
      description: '${mission['name']} 미션 완료',
      metadata: {
        'mission_id': missionId,
        'mission_type': isDaily ? 'daily' : 'weekly',
      },
    );

    if (!earnResult) {
      return false;
    }

    // 보상 받은 시간 기록
    mission['claimedAt'] = DateTime.now().toIso8601String();
    await _saveMissions();

    // 통계 업데이트
    await _updateStatistics(isDaily);

    // 애널리틱스
    await AnalyticsService.logEvent(
      name: 'mission_completed',
      parameters: {
        'mission_id': missionId,
        'mission_type': isDaily ? 'daily' : 'weekly',
        'points_earned': 0, // TODO: Get actual points
      },
    );

    return true;
  }

  // 미션 저장
  Future<void> _saveMissions() async {
    await _dataService.saveSetting('daily_missions', _dailyMissions);
    await _dataService.saveSetting('weekly_missions', _weeklyMissions);
  }

  // 통계 업데이트
  Future<void> _updateStatistics(bool isDaily) async {
    final key = isDaily ? 'daily_missions_completed' : 'weekly_missions_completed';
    final completed = await _dataService.getSetting(key) ?? 0;
    await _dataService.saveSetting(key, completed + 1);

    // 연속 미션 완료 체크
    if (isDaily) {
      final streak = await _dataService.getSetting('mission_streak') ?? 0;
      final lastCompleted = await _dataService.getSetting('last_mission_completed');
      final today = DateTime.now();

      if (lastCompleted != null) {
        final lastDate = DateTime.parse(lastCompleted);
        if (_isSameDay(lastDate, today.subtract(Duration(days: 1)))) {
          // 연속 미션 유지
          await _dataService.saveSetting('mission_streak', streak + 1);
        } else if (!_isSameDay(lastDate, today)) {
          // 연속 미션 리셋
          await _dataService.saveSetting('mission_streak', 1);
        }
      } else {
        await _dataService.saveSetting('mission_streak', 1);
      }

      await _dataService.saveSetting('last_mission_completed', today.toIso8601String());
    }
  }

  // 미션 목록 가져오기
  List<Map<String, dynamic>> getDailyMissions() {
    return List.from(_dailyMissions);
  }

  List<Map<String, dynamic>> getWeeklyMissions() {
    return List.from(_weeklyMissions);
  }

  // 완료된 미션 수
  int getCompletedDailyCount() {
    return _dailyMissions.where((m) => m['isCompleted'] == true).length;
  }

  int getCompletedWeeklyCount() {
    return _weeklyMissions.where((m) => m['isCompleted'] == true).length;
  }

  // 받을 수 있는 보상 수
  int getClaimableRewardsCount() {
    int count = 0;
    count += _dailyMissions.where((m) =>
      m['isCompleted'] == true && m['claimedAt'] == null
    ).length;
    count += _weeklyMissions.where((m) =>
      m['isCompleted'] == true && m['claimedAt'] == null
    ).length;
    return count;
  }

  // 날짜 비교 헬퍼
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // 주 번호 계산
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(firstDayOfYear).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  // 미션 타입별 진행도 가져오기
  int getProgress(String missionKey) {
    return _missionProgress[missionKey] ?? 0;
  }

  // 특정 미션 완료 처리
  Future<void> completeMission(String missionKey) async {
    await updateProgress(missionKey, increment: 9999); // 충분히 큰 수로 완료 처리
  }
}
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_service.dart';
import 'advanced_ad_service.dart';

class RewardService {
  static final RewardService _instance = RewardService._internal();
  factory RewardService() => _instance;
  RewardService._internal();

  final DataService _dataService = DataService();
  final AdvancedAdService _adService = AdvancedAdService();

  // 리워드 레벨 시스템
  static const Map<int, Map<String, dynamic>> _rewardLevels = {
    1: {'name': '브론즈', 'multiplier': 1.0, 'color': 0xFFCD7F32, 'nextLevel': 1000},
    2: {'name': '실버', 'multiplier': 1.1, 'color': 0xFFC0C0C0, 'nextLevel': 5000},
    3: {'name': '골드', 'multiplier': 1.2, 'color': 0xFFFFD700, 'nextLevel': 15000},
    4: {'name': '플래티넘', 'multiplier': 1.3, 'color': 0xFFE5E4E2, 'nextLevel': 30000},
    5: {'name': '다이아몬드', 'multiplier': 1.5, 'color': 0xFFB9F2FF, 'nextLevel': 50000},
    6: {'name': '마스터', 'multiplier': 2.0, 'color': 0xFF9370DB, 'nextLevel': 100000},
  };

  // 일일 미션 시스템
  static const List<Map<String, dynamic>> _dailyMissions = [
    {
      'id': 'ads_5',
      'title': '광고 5회 시청',
      'description': '오늘 광고를 5회 시청하세요',
      'target': 5,
      'reward': 500,
      'type': 'ads',
    },
    {
      'id': 'ads_10',
      'title': '광고 10회 시청',
      'description': '오늘 광고를 10회 시청하세요',
      'target': 10,
      'reward': 1200,
      'type': 'ads',
    },
    {
      'id': 'survey_3',
      'title': '설문조사 3개 완료',
      'description': '오늘 설문조사를 3개 완료하세요',
      'target': 3,
      'reward': 1000,
      'type': 'survey',
    },
    {
      'id': 'earn_5000',
      'title': '5,000원 수익 달성',
      'description': '오늘 총 5,000원을 벌어보세요',
      'target': 5000,
      'reward': 800,
      'type': 'earnings',
    },
    {
      'id': 'login_streak',
      'title': '연속 출석',
      'description': '매일 앱에 접속하세요',
      'target': 1,
      'reward': 300,
      'type': 'login',
    },
  ];

  // 업적 시스템
  static const List<Map<String, dynamic>> _achievements = [
    // 광고 관련 업적
    {'id': 'ads_100', 'title': '광고 마니아', 'description': '광고 100회 시청', 'target': 100, 'reward': 5000, 'type': 'ads', 'icon': '📺'},
    {'id': 'ads_500', 'title': '광고 전문가', 'description': '광고 500회 시청', 'target': 500, 'reward': 15000, 'type': 'ads', 'icon': '🎬'},
    {'id': 'ads_1000', 'title': '광고 마스터', 'description': '광고 1,000회 시청', 'target': 1000, 'reward': 30000, 'type': 'ads', 'icon': '🏆'},

    // 설문조사 관련 업적
    {'id': 'survey_10', 'title': '설문조사 입문', 'description': '설문조사 10개 완료', 'target': 10, 'reward': 3000, 'type': 'survey', 'icon': '📝'},
    {'id': 'survey_50', 'title': '설문조사 전문가', 'description': '설문조사 50개 완료', 'target': 50, 'reward': 10000, 'type': 'survey', 'icon': '📊'},
    {'id': 'survey_100', 'title': '리서처', 'description': '설문조사 100개 완료', 'target': 100, 'reward': 25000, 'type': 'survey', 'icon': '🔍'},

    // 수익 관련 업적
    {'id': 'earn_10k', 'title': '첫 만원', 'description': '누적 수익 10,000원 달성', 'target': 10000, 'reward': 2000, 'type': 'total_earnings', 'icon': '💰'},
    {'id': 'earn_50k', 'title': '5만원 달성', 'description': '누적 수익 50,000원 달성', 'target': 50000, 'reward': 10000, 'type': 'total_earnings', 'icon': '💵'},
    {'id': 'earn_100k', 'title': '10만원 돌파', 'description': '누적 수익 100,000원 달성', 'target': 100000, 'reward': 25000, 'type': 'total_earnings', 'icon': '💎'},
    {'id': 'earn_500k', 'title': '하프 밀리언', 'description': '누적 수익 500,000원 달성', 'target': 500000, 'reward': 100000, 'type': 'total_earnings', 'icon': '🏅'},

    // 연속 출석 업적
    {'id': 'streak_7', 'title': '일주일 개근', 'description': '7일 연속 출석', 'target': 7, 'reward': 2000, 'type': 'login_streak', 'icon': '📅'},
    {'id': 'streak_30', 'title': '한 달 개근', 'description': '30일 연속 출석', 'target': 30, 'reward': 15000, 'type': 'login_streak', 'icon': '📆'},
    {'id': 'streak_100', 'title': '100일 도전', 'description': '100일 연속 출석', 'target': 100, 'reward': 50000, 'type': 'login_streak', 'icon': '🗓️'},
  ];

  // 보너스 룰렛 시스템
  static const List<Map<String, dynamic>> _rouletteRewards = [
    {'amount': 100, 'weight': 30, 'label': '100원'},
    {'amount': 200, 'weight': 25, 'label': '200원'},
    {'amount': 500, 'weight': 20, 'label': '500원'},
    {'amount': 1000, 'weight': 15, 'label': '1,000원'},
    {'amount': 2000, 'weight': 7, 'label': '2,000원'},
    {'amount': 5000, 'weight': 2, 'label': '5,000원'},
    {'amount': 10000, 'weight': 1, 'label': '잭팟! 10,000원'},
  ];

  // 사용자 리워드 데이터
  Map<String, dynamic> _userRewardData = {
    'level': 1,
    'currentExp': 0,
    'totalEarnings': 0,
    'loginStreak': 0,
    'lastLoginDate': null,
    'completedMissions': [],
    'unlockedAchievements': [],
    'lastRouletteTime': null,
    'dailyBonusClaimed': false,
  };

  // 초기화
  Future<void> initialize() async {
    await _loadUserRewardData();
    await _checkDailyReset();
    await _updateLoginStreak();
  }

  // 사용자 리워드 데이터 로드
  Future<void> _loadUserRewardData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('userRewardData');

    if (savedData != null) {
      _userRewardData = jsonDecode(savedData);
    }
  }

  // 사용자 리워드 데이터 저장
  Future<void> _saveUserRewardData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRewardData', jsonEncode(_userRewardData));
  }

  // 일일 초기화 확인
  Future<void> _checkDailyReset() async {
    final now = DateTime.now();
    final today = '${now.year}_${now.month}_${now.day}';
    final lastReset = _userRewardData['lastResetDate'];

    if (lastReset != today) {
      _userRewardData['completedMissions'] = [];
      _userRewardData['dailyBonusClaimed'] = false;
      _userRewardData['lastResetDate'] = today;
      await _saveUserRewardData();
    }
  }

  // 로그인 스트릭 업데이트
  Future<void> _updateLoginStreak() async {
    final now = DateTime.now();
    final today = '${now.year}_${now.month}_${now.day}';
    final lastLogin = _userRewardData['lastLoginDate'];

    if (lastLogin != null) {
      final lastDate = DateTime.parse(lastLogin.replaceAll('_', '-'));
      final difference = now.difference(lastDate).inDays;

      if (difference == 1) {
        _userRewardData['loginStreak'] = (_userRewardData['loginStreak'] ?? 0) + 1;
      } else if (difference > 1) {
        _userRewardData['loginStreak'] = 1;
      }
    } else {
      _userRewardData['loginStreak'] = 1;
    }

    _userRewardData['lastLoginDate'] = today;
    await _saveUserRewardData();

    // 로그인 보상 지급
    await _claimLoginReward();
  }

  // 로그인 보상 지급
  Future<void> _claimLoginReward() async {
    final streak = _userRewardData['loginStreak'] ?? 1;
    final baseReward = 100;
    final streakBonus = min(streak * 10, 500); // 최대 500원 보너스
    final totalReward = baseReward + streakBonus;

    await _dataService.addEarning(
      source: '출석 보상',
      amount: totalReward.toDouble(),
      description: '${streak}일 연속 출석 (보너스 +$streakBonus원)',
    );

    // 출석 미션 체크
    await checkMissionProgress('login', 1);
  }

  // 경험치 추가 및 레벨업 체크
  Future<Map<String, dynamic>> addExperience(int exp) async {
    _userRewardData['currentExp'] = (_userRewardData['currentExp'] ?? 0) + exp;

    final currentLevel = _userRewardData['level'] ?? 1;
    final levelConfig = _rewardLevels[currentLevel];
    final nextLevelExp = levelConfig?['nextLevel'] ?? 999999;

    Map<String, dynamic> result = {
      'expGained': exp,
      'currentExp': _userRewardData['currentExp'],
      'currentLevel': currentLevel,
      'leveledUp': false,
    };

    // 레벨업 체크
    if (_userRewardData['currentExp'] >= nextLevelExp && currentLevel < 6) {
      _userRewardData['level'] = currentLevel + 1;
      _userRewardData['currentExp'] -= nextLevelExp;

      // 레벨업 보상
      final levelUpReward = nextLevelExp ~/ 10; // 필요 경험치의 10% 보상
      await _dataService.addEarning(
        source: '레벨업 보상',
        amount: levelUpReward.toDouble(),
        description: '레벨 ${currentLevel + 1} 달성!',
      );

      result['leveledUp'] = true;
      result['newLevel'] = currentLevel + 1;
      result['levelUpReward'] = levelUpReward;
    }

    await _saveUserRewardData();
    return result;
  }

  // 미션 진행도 체크
  Future<Map<String, dynamic>> checkMissionProgress(String type, dynamic progress) async {
    final todayMissions = _dailyMissions.where((m) => m['type'] == type).toList();
    final completedToday = List<String>.from(_userRewardData['completedMissions'] ?? []);

    List<Map<String, dynamic>> newlyCompleted = [];

    for (var mission in todayMissions) {
      if (completedToday.contains(mission['id'])) continue;

      bool isCompleted = false;

      switch (type) {
        case 'ads':
          final adStats = await _adService.getAdStats();
          final todayAds = adStats['todayAdCount'] ?? 0;
          isCompleted = todayAds >= mission['target'];
          break;

        case 'survey':
          // 설문조사 완료 카운트 체크
          final surveyStats = await _dataService.getSetting('surveyStats');
          if (surveyStats != null) {
            final stats = jsonDecode(surveyStats as String);
            final todaySurveys = stats['todaySurveys'] ?? 0;
            isCompleted = todaySurveys >= mission['target'];
          }
          break;

        case 'earnings':
          final stats = await _dataService.getStatistics();
          final todayEarnings = stats['todayEarnings'] ?? 0;
          isCompleted = todayEarnings >= mission['target'];
          break;

        case 'login':
          isCompleted = true; // 로그인 미션은 이미 완료
          break;
      }

      if (isCompleted) {
        completedToday.add(mission['id']);
        newlyCompleted.add(mission);

        // 미션 보상 지급
        await _dataService.addEarning(
          source: '미션 완료',
          amount: mission['reward'].toDouble(),
          description: mission['title'],
        );

        // 경험치 지급
        await addExperience(100);
      }
    }

    _userRewardData['completedMissions'] = completedToday;
    await _saveUserRewardData();

    return {
      'newlyCompleted': newlyCompleted,
      'totalCompleted': completedToday.length,
      'totalMissions': _dailyMissions.length,
    };
  }

  // 업적 체크
  Future<Map<String, dynamic>> checkAchievements(String type, int value) async {
    final unlockedIds = List<String>.from(_userRewardData['unlockedAchievements'] ?? []);
    final relevantAchievements = _achievements.where((a) => a['type'] == type).toList();

    List<Map<String, dynamic>> newlyUnlocked = [];

    for (var achievement in relevantAchievements) {
      if (unlockedIds.contains(achievement['id'])) continue;

      if (value >= achievement['target']) {
        unlockedIds.add(achievement['id']);
        newlyUnlocked.add(achievement);

        // 업적 보상 지급
        await _dataService.addEarning(
          source: '업적 달성',
          amount: achievement['reward'].toDouble(),
          description: achievement['title'],
        );

        // 경험치 지급
        await addExperience(500);
      }
    }

    _userRewardData['unlockedAchievements'] = unlockedIds;
    await _saveUserRewardData();

    return {
      'newlyUnlocked': newlyUnlocked,
      'totalUnlocked': unlockedIds.length,
      'totalAchievements': _achievements.length,
    };
  }

  // 보너스 룰렛 돌리기
  Future<Map<String, dynamic>> spinRoulette() async {
    // 쿨다운 체크 (4시간)
    final lastSpin = _userRewardData['lastRouletteTime'];
    if (lastSpin != null) {
      final lastTime = DateTime.parse(lastSpin);
      final timeSince = DateTime.now().difference(lastTime).inHours;
      if (timeSince < 4) {
        return {
          'success': false,
          'message': '${4 - timeSince}시간 후에 다시 돌릴 수 있습니다',
          'remainingHours': 4 - timeSince,
        };
      }
    }

    // 가중치 기반 랜덤 선택
    int totalWeight = 0;
    for (var reward in _rouletteRewards) {
      totalWeight += (reward['weight'] as int);
    }

    int randomValue = Random().nextInt(totalWeight);
    int currentWeight = 0;
    Map<String, dynamic>? selectedReward;

    for (var reward in _rouletteRewards) {
      currentWeight += (reward['weight'] as int);
      if (randomValue < currentWeight) {
        selectedReward = reward;
        break;
      }
    }

    if (selectedReward == null) {
      selectedReward = _rouletteRewards.first;
    }

    // 레벨 보너스 적용
    final level = _userRewardData['level'] ?? 1;
    final levelMultiplier = _rewardLevels[level]?['multiplier'] ?? 1.0;
    final finalAmount = (selectedReward['amount'] * levelMultiplier).round();

    // 보상 지급
    await _dataService.addEarning(
      source: '럭키 룰렛',
      amount: finalAmount.toDouble(),
      description: selectedReward['label'],
    );

    // 마지막 룰렛 시간 저장
    _userRewardData['lastRouletteTime'] = DateTime.now().toIso8601String();
    await _saveUserRewardData();

    // 경험치 지급
    await addExperience(50);

    return {
      'success': true,
      'reward': selectedReward,
      'amount': finalAmount,
      'levelBonus': levelMultiplier > 1.0,
    };
  }

  // 일일 보너스 받기
  Future<Map<String, dynamic>> claimDailyBonus() async {
    if (_userRewardData['dailyBonusClaimed'] == true) {
      return {
        'success': false,
        'message': '오늘의 보너스를 이미 받으셨습니다',
      };
    }

    final streak = _userRewardData['loginStreak'] ?? 1;
    final baseBonus = 500;
    final streakMultiplier = 1 + (streak * 0.1); // 연속 출석일수당 10% 추가
    final finalBonus = (baseBonus * streakMultiplier).round();

    // 보너스 지급
    await _dataService.addEarning(
      source: '일일 보너스',
      amount: finalBonus.toDouble(),
      description: '${streak}일 연속 출석 보너스',
    );

    _userRewardData['dailyBonusClaimed'] = true;
    await _saveUserRewardData();

    // 경험치 지급
    await addExperience(100);

    return {
      'success': true,
      'amount': finalBonus,
      'streak': streak,
    };
  }

  // 리워드 대시보드 데이터
  Future<Map<String, dynamic>> getRewardDashboard() async {
    final currentLevel = _userRewardData['level'] ?? 1;
    final levelConfig = _rewardLevels[currentLevel];
    final nextLevelConfig = _rewardLevels[currentLevel + 1];

    // 미션 진행도
    final completedMissions = List<String>.from(_userRewardData['completedMissions'] ?? []);
    final missionProgress = _dailyMissions.map((m) {
      final isCompleted = completedMissions.contains(m['id']);
      return {
        ...m,
        'completed': isCompleted,
        'progress': isCompleted ? m['target'] : 0, // 실제 진행도 계산 필요
      };
    }).toList();

    // 업적 진행도
    final unlockedAchievements = List<String>.from(_userRewardData['unlockedAchievements'] ?? []);

    // 룰렛 쿨다운
    int rouletteRemainingHours = 0;
    if (_userRewardData['lastRouletteTime'] != null) {
      final lastTime = DateTime.parse(_userRewardData['lastRouletteTime']);
      final hoursSince = DateTime.now().difference(lastTime).inHours;
      rouletteRemainingHours = max(0, 4 - hoursSince);
    }

    return {
      'level': currentLevel,
      'levelName': levelConfig?['name'] ?? '브론즈',
      'levelColor': levelConfig?['color'] ?? 0xFFCD7F32,
      'currentExp': _userRewardData['currentExp'] ?? 0,
      'nextLevelExp': levelConfig?['nextLevel'] ?? 0,
      'expProgress': nextLevelConfig != null
          ? (_userRewardData['currentExp'] ?? 0) / (levelConfig?['nextLevel'] ?? 1)
          : 1.0,
      'multiplier': levelConfig?['multiplier'] ?? 1.0,
      'loginStreak': _userRewardData['loginStreak'] ?? 0,
      'dailyMissions': missionProgress,
      'completedMissionsCount': completedMissions.length,
      'totalMissionsCount': _dailyMissions.length,
      'unlockedAchievementsCount': unlockedAchievements.length,
      'totalAchievementsCount': _achievements.length,
      'dailyBonusAvailable': !(_userRewardData['dailyBonusClaimed'] ?? false),
      'rouletteAvailable': rouletteRemainingHours == 0,
      'rouletteRemainingHours': rouletteRemainingHours,
    };
  }

  // 업적 목록 가져오기
  List<Map<String, dynamic>> getAchievements() {
    final unlockedIds = List<String>.from(_userRewardData['unlockedAchievements'] ?? []);

    return _achievements.map((achievement) {
      return {
        ...achievement,
        'unlocked': unlockedIds.contains(achievement['id']),
      };
    }).toList();
  }

  // 미션 목록 가져오기
  List<Map<String, dynamic>> getDailyMissions() {
    final completedIds = List<String>.from(_userRewardData['completedMissions'] ?? []);

    return _dailyMissions.map((mission) {
      return {
        ...mission,
        'completed': completedIds.contains(mission['id']),
      };
    }).toList();
  }
}
import 'package:flutter/material.dart';
import 'database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// 업적 모델
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int requiredValue;
  final AchievementType type;
  final String shareMessage;
  bool isUnlocked;
  DateTime? unlockedAt;
  int currentProgress;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.requiredValue,
    required this.type,
    required this.shareMessage,
    this.isUnlocked = false,
    this.unlockedAt,
    this.currentProgress = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'currentProgress': currentProgress,
  };

  factory Achievement.fromJson(Map<String, dynamic> json, Achievement template) {
    return Achievement(
      id: template.id,
      title: template.title,
      description: template.description,
      icon: template.icon,
      color: template.color,
      requiredValue: template.requiredValue,
      type: template.type,
      shareMessage: template.shareMessage,
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
        ? DateTime.parse(json['unlockedAt'])
        : null,
      currentProgress: json['currentProgress'] ?? 0,
    );
  }
}

enum AchievementType {
  incomeCount,      // 수익 기록 횟수
  totalIncome,      // 총 수익 금액
  streak,           // 연속 기록 일수
  goalComplete,     // 목표 달성 횟수
  incomeTypes,      // 다양한 수익원
  milestone,        // 특별한 마일스톤
}

class AchievementService {
  final DatabaseService _dbService = DatabaseService();
  late SharedPreferences _prefs;
  List<Achievement> _achievements = [];

  // 모든 업적 정의
  final List<Achievement> _achievementTemplates = [
    // 수익 기록 횟수 업적
    Achievement(
      id: 'first_income',
      title: '첫 발걸음',
      description: '첫 수익을 기록하세요',
      icon: Icons.celebration,
      color: Colors.blue,
      requiredValue: 1,
      type: AchievementType.incomeCount,
      shareMessage: '🎉 PayDay에서 첫 수익을 기록했습니다!',
    ),
    Achievement(
      id: 'income_10',
      title: '꾸준한 기록자',
      description: '10개의 수익 기록',
      icon: Icons.trending_up,
      color: Colors.green,
      requiredValue: 10,
      type: AchievementType.incomeCount,
      shareMessage: '💪 PayDay에서 10개의 수익을 기록했습니다!',
    ),
    Achievement(
      id: 'income_50',
      title: '수익 마스터',
      description: '50개의 수익 기록',
      icon: Icons.star,
      color: Colors.orange,
      requiredValue: 50,
      type: AchievementType.incomeCount,
      shareMessage: '⭐ PayDay에서 50개의 수익을 달성했습니다!',
    ),
    Achievement(
      id: 'income_100',
      title: '백전백승',
      description: '100개의 수익 기록',
      icon: Icons.military_tech,
      color: Colors.purple,
      requiredValue: 100,
      type: AchievementType.incomeCount,
      shareMessage: '🏆 PayDay에서 100개의 수익을 달성했습니다!',
    ),

    // 총 수익 금액 업적
    Achievement(
      id: 'total_100k',
      title: '10만원 달성',
      description: '총 수익 10만원 돌파',
      icon: Icons.attach_money,
      color: Colors.green,
      requiredValue: 100000,
      type: AchievementType.totalIncome,
      shareMessage: '💰 총 수익 10만원을 달성했습니다!',
    ),
    Achievement(
      id: 'total_1m',
      title: '백만장자',
      description: '총 수익 100만원 돌파',
      icon: Icons.account_balance,
      color: Colors.blue,
      requiredValue: 1000000,
      type: AchievementType.totalIncome,
      shareMessage: '🎊 총 수익 100만원을 돌파했습니다!',
    ),
    Achievement(
      id: 'total_10m',
      title: '천만장자',
      description: '총 수익 1000만원 돌파',
      icon: Icons.diamond,
      color: Colors.purple,
      requiredValue: 10000000,
      type: AchievementType.totalIncome,
      shareMessage: '💎 총 수익 1000만원을 돌파했습니다!',
    ),

    // 연속 기록 업적
    Achievement(
      id: 'streak_7',
      title: '일주일 연속',
      description: '7일 연속 수익 기록',
      icon: Icons.local_fire_department,
      color: Colors.orange,
      requiredValue: 7,
      type: AchievementType.streak,
      shareMessage: '🔥 7일 연속 수익을 기록했습니다!',
    ),
    Achievement(
      id: 'streak_30',
      title: '한달 연속',
      description: '30일 연속 수익 기록',
      icon: Icons.whatshot,
      color: Colors.red,
      requiredValue: 30,
      type: AchievementType.streak,
      shareMessage: '🔥🔥 30일 연속 수익을 기록했습니다!',
    ),
    Achievement(
      id: 'streak_100',
      title: '100일 연속',
      description: '100일 연속 수익 기록',
      icon: Icons.emoji_events,
      color: Colors.amber,
      requiredValue: 100,
      type: AchievementType.streak,
      shareMessage: '🏅 100일 연속 수익 기록 달성!',
    ),

    // 목표 달성 업적
    Achievement(
      id: 'goal_first',
      title: '목표 달성!',
      description: '첫 목표를 달성하세요',
      icon: Icons.flag,
      color: Colors.teal,
      requiredValue: 1,
      type: AchievementType.goalComplete,
      shareMessage: '🎯 첫 목표를 달성했습니다!',
    ),
    Achievement(
      id: 'goal_5',
      title: '목표 전문가',
      description: '5개의 목표 달성',
      icon: Icons.sports_score,
      color: Colors.indigo,
      requiredValue: 5,
      type: AchievementType.goalComplete,
      shareMessage: '🎯🎯 5개의 목표를 달성했습니다!',
    ),

    // 다양한 수익원 업적
    Achievement(
      id: 'diverse_3',
      title: '다각화 시작',
      description: '3가지 다른 수익원',
      icon: Icons.diversity_3,
      color: Colors.cyan,
      requiredValue: 3,
      type: AchievementType.incomeTypes,
      shareMessage: '🌈 3가지 다른 수익원을 확보했습니다!',
    ),
    Achievement(
      id: 'diverse_5',
      title: '수익원 마스터',
      description: '5가지 다른 수익원',
      icon: Icons.hub,
      color: Colors.deepPurple,
      requiredValue: 5,
      type: AchievementType.incomeTypes,
      shareMessage: '🎨 5가지 다른 수익원을 운영중입니다!',
    ),

    // 특별 마일스톤
    Achievement(
      id: 'early_bird',
      title: '얼리버드',
      description: '오전 6시 이전 수익 기록',
      icon: Icons.wb_sunny,
      color: Colors.yellow[700]!,
      requiredValue: 1,
      type: AchievementType.milestone,
      shareMessage: '🌅 이른 아침부터 수익 활동 시작!',
    ),
    Achievement(
      id: 'night_owl',
      title: '올빼미',
      description: '밤 11시 이후 수익 기록',
      icon: Icons.nights_stay,
      color: Colors.indigo[900]!,
      requiredValue: 1,
      type: AchievementType.milestone,
      shareMessage: '🦉 늦은 밤까지 수익 활동!',
    ),
    Achievement(
      id: 'weekend_warrior',
      title: '주말 전사',
      description: '주말에 5개 이상 수익 기록',
      icon: Icons.weekend,
      color: Colors.pink,
      requiredValue: 5,
      type: AchievementType.milestone,
      shareMessage: '💪 주말에도 쉬지 않는 수익 활동!',
    ),
  ];

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final savedData = _prefs.getString('achievements');

    if (savedData != null) {
      final Map<String, dynamic> savedAchievements = jsonDecode(savedData);

      _achievements = _achievementTemplates.map((template) {
        if (savedAchievements.containsKey(template.id)) {
          return Achievement.fromJson(savedAchievements[template.id], template);
        }
        return template;
      }).toList();
    } else {
      _achievements = List.from(_achievementTemplates);
    }
  }

  Future<void> _saveAchievements() async {
    final Map<String, dynamic> saveData = {};
    for (var achievement in _achievements) {
      saveData[achievement.id] = achievement.toJson();
    }
    await _prefs.setString('achievements', jsonEncode(saveData));
  }

  // 업적 확인 및 업데이트
  Future<List<Achievement>> checkAchievements() async {
    await _dbService.database;
    final List<Achievement> newlyUnlocked = [];

    // 수익 데이터 가져오기
    final incomes = await _dbService.getAllIncomes();
    final goals = await _dbService.getAllGoals();

    // 수익 기록 횟수 업적 체크
    final incomeCount = incomes.length;
    for (var achievement in _achievements.where((a) =>
        a.type == AchievementType.incomeCount && !a.isUnlocked)) {
      achievement.currentProgress = incomeCount;
      if (incomeCount >= achievement.requiredValue) {
        achievement.isUnlocked = true;
        achievement.unlockedAt = DateTime.now();
        newlyUnlocked.add(achievement);
      }
    }

    // 총 수익 금액 업적 체크
    double totalIncome = 0;
    for (var income in incomes) {
      totalIncome += (income['amount'] as num).toDouble();
    }
    for (var achievement in _achievements.where((a) =>
        a.type == AchievementType.totalIncome && !a.isUnlocked)) {
      achievement.currentProgress = totalIncome.toInt();
      if (totalIncome >= achievement.requiredValue) {
        achievement.isUnlocked = true;
        achievement.unlockedAt = DateTime.now();
        newlyUnlocked.add(achievement);
      }
    }

    // 연속 기록 업적 체크
    final streak = await _calculateStreak();
    for (var achievement in _achievements.where((a) =>
        a.type == AchievementType.streak && !a.isUnlocked)) {
      achievement.currentProgress = streak;
      if (streak >= achievement.requiredValue) {
        achievement.isUnlocked = true;
        achievement.unlockedAt = DateTime.now();
        newlyUnlocked.add(achievement);
      }
    }

    // 목표 달성 업적 체크
    final completedGoals = goals.where((g) =>
        g['progress'] != null && g['progress'] >= 1.0).length;
    for (var achievement in _achievements.where((a) =>
        a.type == AchievementType.goalComplete && !a.isUnlocked)) {
      achievement.currentProgress = completedGoals;
      if (completedGoals >= achievement.requiredValue) {
        achievement.isUnlocked = true;
        achievement.unlockedAt = DateTime.now();
        newlyUnlocked.add(achievement);
      }
    }

    // 수익원 다양성 업적 체크
    final uniqueTypes = incomes.map((i) => i['type']).toSet().length;
    for (var achievement in _achievements.where((a) =>
        a.type == AchievementType.incomeTypes && !a.isUnlocked)) {
      achievement.currentProgress = uniqueTypes;
      if (uniqueTypes >= achievement.requiredValue) {
        achievement.isUnlocked = true;
        achievement.unlockedAt = DateTime.now();
        newlyUnlocked.add(achievement);
      }
    }

    // 특별 마일스톤 체크
    await _checkMilestoneAchievements(incomes, newlyUnlocked);

    // 저장
    if (newlyUnlocked.isNotEmpty) {
      await _saveAchievements();
    }

    return newlyUnlocked;
  }

  Future<int> _calculateStreak() async {
    final incomes = await _dbService.getAllIncomes();
    if (incomes.isEmpty) return 0;

    // 날짜별로 정렬
    incomes.sort((a, b) => b['date'].compareTo(a['date']));

    int streak = 0;
    DateTime? lastDate;

    for (var income in incomes) {
      final date = income['date'] as DateTime;
      final dateOnly = DateTime(date.year, date.month, date.day);

      if (lastDate == null) {
        streak = 1;
        lastDate = dateOnly;
      } else {
        final difference = lastDate.difference(dateOnly).inDays;
        if (difference == 1) {
          streak++;
          lastDate = dateOnly;
        } else if (difference > 1) {
          break;
        }
      }
    }

    return streak;
  }

  Future<void> _checkMilestoneAchievements(
    List<Map<String, dynamic>> incomes,
    List<Achievement> newlyUnlocked,
  ) async {
    // 얼리버드 체크
    final earlyBird = _achievements.firstWhere((a) => a.id == 'early_bird');
    if (!earlyBird.isUnlocked) {
      final hasEarlyIncome = incomes.any((i) {
        final date = i['date'] as DateTime;
        return date.hour < 6;
      });
      if (hasEarlyIncome) {
        earlyBird.isUnlocked = true;
        earlyBird.unlockedAt = DateTime.now();
        earlyBird.currentProgress = 1;
        newlyUnlocked.add(earlyBird);
      }
    }

    // 올빼미 체크
    final nightOwl = _achievements.firstWhere((a) => a.id == 'night_owl');
    if (!nightOwl.isUnlocked) {
      final hasLateIncome = incomes.any((i) {
        final date = i['date'] as DateTime;
        return date.hour >= 23;
      });
      if (hasLateIncome) {
        nightOwl.isUnlocked = true;
        nightOwl.unlockedAt = DateTime.now();
        nightOwl.currentProgress = 1;
        newlyUnlocked.add(nightOwl);
      }
    }

    // 주말 전사 체크
    final weekendWarrior = _achievements.firstWhere((a) => a.id == 'weekend_warrior');
    if (!weekendWarrior.isUnlocked) {
      final weekendIncomes = incomes.where((i) {
        final date = i['date'] as DateTime;
        return date.weekday == 6 || date.weekday == 7;
      }).length;
      weekendWarrior.currentProgress = weekendIncomes;
      if (weekendIncomes >= 5) {
        weekendWarrior.isUnlocked = true;
        weekendWarrior.unlockedAt = DateTime.now();
        newlyUnlocked.add(weekendWarrior);
      }
    }
  }

  // Getters
  List<Achievement> get allAchievements => _achievements;

  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => a.isUnlocked).toList();

  List<Achievement> get lockedAchievements =>
      _achievements.where((a) => !a.isUnlocked).toList();

  double get overallProgress {
    if (_achievements.isEmpty) return 0;
    return unlockedAchievements.length / _achievements.length;
  }

  // 다음 달성 가능한 업적
  Achievement? get nextAchievable {
    final locked = lockedAchievements;
    if (locked.isEmpty) return null;

    locked.sort((a, b) {
      final progressA = a.currentProgress / a.requiredValue;
      final progressB = b.currentProgress / b.requiredValue;
      return progressB.compareTo(progressA);
    });

    return locked.first;
  }

  // 특정 업적 진행률
  double getProgress(Achievement achievement) {
    if (achievement.isUnlocked) return 1.0;
    return (achievement.currentProgress / achievement.requiredValue).clamp(0.0, 1.0);
  }
}
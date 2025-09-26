// 게이미피케이션 시스템 모델

import 'package:flutter/material.dart';

enum UserLevel {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}

class LevelInfo {
  final UserLevel level;
  final String name;
  final int minPoints;
  final int maxPoints;
  final Color primaryColor;
  final Color secondaryColor;
  final List<Color> gradientColors;
  final String badge;
  final double bonusMultiplier;

  LevelInfo({
    required this.level,
    required this.name,
    required this.minPoints,
    required this.maxPoints,
    required this.primaryColor,
    required this.secondaryColor,
    required this.gradientColors,
    required this.badge,
    required this.bonusMultiplier,
  });

  static LevelInfo getLevelInfo(int points) {
    if (points < 1000) {
      return LevelInfo(
        level: UserLevel.bronze,
        name: '브론즈',
        minPoints: 0,
        maxPoints: 999,
        primaryColor: Color(0xFFCD7F32),
        secondaryColor: Color(0xFFB87333),
        gradientColors: [Color(0xFFCD7F32), Color(0xFFB87333)],
        badge: '🥉',
        bonusMultiplier: 1.0,
      );
    } else if (points < 5000) {
      return LevelInfo(
        level: UserLevel.silver,
        name: '실버',
        minPoints: 1000,
        maxPoints: 4999,
        primaryColor: Color(0xFFC0C0C0),
        secondaryColor: Color(0xFFAAAAAA),
        gradientColors: [Color(0xFFC0C0C0), Color(0xFFAAAAAA)],
        badge: '🥈',
        bonusMultiplier: 1.1,
      );
    } else if (points < 10000) {
      return LevelInfo(
        level: UserLevel.gold,
        name: '골드',
        minPoints: 5000,
        maxPoints: 9999,
        primaryColor: Color(0xFFFFD700),
        secondaryColor: Color(0xFFFFA500),
        gradientColors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        badge: '🥇',
        bonusMultiplier: 1.2,
      );
    } else if (points < 50000) {
      return LevelInfo(
        level: UserLevel.platinum,
        name: '플래티넘',
        minPoints: 10000,
        maxPoints: 49999,
        primaryColor: Color(0xFFE5E4E2),
        secondaryColor: Color(0xFF667EEA),
        gradientColors: [Color(0xFFE5E4E2), Color(0xFF667EEA)],
        badge: '💎',
        bonusMultiplier: 1.3,
      );
    } else {
      return LevelInfo(
        level: UserLevel.diamond,
        name: '다이아몬드',
        minPoints: 50000,
        maxPoints: 999999,
        primaryColor: Color(0xFFB9F2FF),
        secondaryColor: Color(0xFF00D4FF),
        gradientColors: [
          Color(0xFFB9F2FF),
          Color(0xFF00D4FF),
          Color(0xFF667EEA),
        ],
        badge: '💠',
        bonusMultiplier: 1.5,
      );
    }
  }

  double get progress {
    return 0.0; // This will be calculated based on current points
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int points;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final AchievementType type;
  final int progress;
  final int target;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.points,
    required this.isUnlocked,
    this.unlockedAt,
    required this.type,
    required this.progress,
    required this.target,
  });

  double get progressPercent => progress / target;
}

enum AchievementType {
  earning,      // 수익 관련
  streak,       // 연속 출석
  referral,     // 친구 초대
  level,        // 레벨 달성
  milestone,    // 마일스톤
  special,      // 특별 이벤트
}

class DailyQuest {
  final String id;
  final String title;
  final String description;
  final int reward;
  final int experience;
  final QuestType type;
  final int currentProgress;
  final int targetProgress;
  final bool isCompleted;
  final DateTime expiresAt;
  final String icon;

  DailyQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    required this.experience,
    required this.type,
    required this.currentProgress,
    required this.targetProgress,
    required this.isCompleted,
    required this.expiresAt,
    required this.icon,
  });

  double get progressPercent => currentProgress / targetProgress;
}

enum QuestType {
  watchAds,
  completeProfile,
  inviteFriend,
  earnAmount,
  checkIn,
  walkSteps,
  completeSurvey,
}

class StreakInfo {
  final int currentStreak;
  final int bestStreak;
  final DateTime lastCheckIn;
  final int streakBonus;
  final bool todayCheckedIn;

  StreakInfo({
    required this.currentStreak,
    required this.bestStreak,
    required this.lastCheckIn,
    required this.streakBonus,
    required this.todayCheckedIn,
  });

  int get nextStreakBonus {
    if (currentStreak < 7) return 100;
    if (currentStreak < 30) return 200;
    if (currentStreak < 100) return 500;
    return 1000;
  }

  String get streakEmoji {
    if (currentStreak == 0) return '😔';
    if (currentStreak < 3) return '😊';
    if (currentStreak < 7) return '😃';
    if (currentStreak < 14) return '🔥';
    if (currentStreak < 30) return '🔥🔥';
    if (currentStreak < 100) return '🔥🔥🔥';
    return '🌟🔥🌟';
  }
}

class LeaderboardEntry {
  final String userId;
  final String userName;
  final String userAvatar;
  final int rank;
  final int points;
  final double earnings;
  final UserLevel level;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.rank,
    required this.points,
    required this.earnings,
    required this.level,
    required this.isCurrentUser,
  });

  String get rankEmoji {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }
}

// 감성 그라디언트 테마
class EmotionalTheme {
  final String name;
  final List<Color> colors;
  final String emoji;
  final double minEarning;
  final double maxEarning;

  EmotionalTheme({
    required this.name,
    required this.colors,
    required this.emoji,
    required this.minEarning,
    required this.maxEarning,
  });

  static EmotionalTheme getThemeByEarnings(double dailyEarnings) {
    if (dailyEarnings < 1000) {
      return EmotionalTheme(
        name: '시작',
        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        emoji: '🌱',
        minEarning: 0,
        maxEarning: 999,
      );
    } else if (dailyEarnings < 5000) {
      return EmotionalTheme(
        name: '성장',
        colors: [Color(0xFF00c896), Color(0xFF00b4d8)],
        emoji: '🌿',
        minEarning: 1000,
        maxEarning: 4999,
      );
    } else if (dailyEarnings < 10000) {
      return EmotionalTheme(
        name: '발전',
        colors: [Color(0xFFFFA500), Color(0xFFFF6B6B)],
        emoji: '🔥',
        minEarning: 5000,
        maxEarning: 9999,
      );
    } else if (dailyEarnings < 50000) {
      return EmotionalTheme(
        name: '도약',
        colors: [Color(0xFFFF6B6B), Color(0xFFFFD700)],
        emoji: '🚀',
        minEarning: 10000,
        maxEarning: 49999,
      );
    } else {
      return EmotionalTheme(
        name: '최고',
        colors: [
          Color(0xFFFFD700),
          Color(0xFFFF69B4),
          Color(0xFF00D4FF),
        ],
        emoji: '👑',
        minEarning: 50000,
        maxEarning: double.infinity,
      );
    }
  }
}

// 플로우 애니메이션 설정
class FlowAnimation {
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration cardAnimation = Duration(milliseconds: 200);
  static const Duration counterAnimation = Duration(milliseconds: 1500);
  static const Duration celebrationAnimation = Duration(seconds: 2);

  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutQuart;
}
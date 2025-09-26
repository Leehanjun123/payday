import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';

// 사용자 프로필
class UserProfile {
  final String id;
  final String nickname;
  final String avatar;
  final int level;
  final double totalIncome;
  final int streak;
  final int achievementCount;
  final DateTime joinDate;
  final String bio;
  final String badge;
  final int rank;

  UserProfile({
    required this.id,
    required this.nickname,
    required this.avatar,
    required this.level,
    required this.totalIncome,
    required this.streak,
    required this.achievementCount,
    required this.joinDate,
    required this.bio,
    required this.badge,
    required this.rank,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'avatar': avatar,
    'level': level,
    'totalIncome': totalIncome,
    'streak': streak,
    'achievementCount': achievementCount,
    'joinDate': joinDate.toIso8601String(),
    'bio': bio,
    'badge': badge,
    'rank': rank,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'],
    nickname: json['nickname'],
    avatar: json['avatar'],
    level: json['level'],
    totalIncome: json['totalIncome'].toDouble(),
    streak: json['streak'],
    achievementCount: json['achievementCount'],
    joinDate: DateTime.parse(json['joinDate']),
    bio: json['bio'],
    badge: json['badge'],
    rank: json['rank'],
  );
}

// 리더보드 항목
class LeaderboardEntry {
  final String userId;
  final String nickname;
  final String avatar;
  final int rank;
  final double score;
  final int level;
  final String badge;
  final double change; // 순위 변동
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.rank,
    required this.score,
    required this.level,
    required this.badge,
    required this.change,
    required this.isCurrentUser,
  });
}

// 리더보드 타입
enum LeaderboardType {
  weekly,    // 주간 수익
  monthly,   // 월간 수익
  allTime,   // 전체 기간
  streak,    // 연속 기록
  level,     // 레벨
}

// 챌린지
class Challenge {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final double targetAmount;
  final int participants;
  final String reward;
  final bool isActive;
  final double currentProgress;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.targetAmount,
    required this.participants,
    required this.reward,
    required this.isActive,
    required this.currentProgress,
  });
}

// 커뮤니티 포스트
class CommunityPost {
  final String id;
  final String userId;
  final String nickname;
  final String avatar;
  final String content;
  final DateTime timestamp;
  final int likes;
  final int comments;
  final bool isLiked;
  final String? imageUrl;
  final String postType; // achievement, milestone, tip, motivation

  CommunityPost({
    required this.id,
    required this.userId,
    required this.nickname,
    required this.avatar,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.isLiked,
    this.imageUrl,
    required this.postType,
  });
}

class CommunityService {
  final DatabaseService _dbService = DatabaseService();
  static const String _profileKey = 'user_profile';
  static const String _leaderboardCacheKey = 'leaderboard_cache';

  // 현재 사용자 프로필
  UserProfile? _currentUserProfile;

  // 사용자 프로필 생성/로드
  Future<UserProfile> getCurrentUserProfile() async {
    if (_currentUserProfile != null) return _currentUserProfile!;

    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileKey);

    if (profileJson != null) {
      _currentUserProfile = UserProfile.fromJson(
        Map<String, dynamic>.from(Map.from(jsonDecode(profileJson))),
      );
    } else {
      // 새 프로필 생성
      _currentUserProfile = await _createNewProfile();
      await _saveProfile(_currentUserProfile!);
    }

    return _currentUserProfile!;
  }

  // 새 프로필 생성
  Future<UserProfile> _createNewProfile() async {
    final totalIncome = await _calculateTotalIncome();
    final streak = await _calculateCurrentStreak();
    final achievementCount = await _calculateAchievementCount();

    return UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nickname: _generateRandomNickname(),
      avatar: _getRandomAvatar(),
      level: _calculateLevel(totalIncome),
      totalIncome: totalIncome,
      streak: streak,
      achievementCount: achievementCount,
      joinDate: DateTime.now(),
      bio: '열심히 수익을 만들어가는 중!',
      badge: _getBadgeForLevel(_calculateLevel(totalIncome)),
      rank: 0,
    );
  }

  // 프로필 업데이트
  Future<void> updateProfile({
    String? nickname,
    String? avatar,
    String? bio,
  }) async {
    if (_currentUserProfile == null) {
      await getCurrentUserProfile();
    }

    _currentUserProfile = UserProfile(
      id: _currentUserProfile!.id,
      nickname: nickname ?? _currentUserProfile!.nickname,
      avatar: avatar ?? _currentUserProfile!.avatar,
      level: _currentUserProfile!.level,
      totalIncome: await _calculateTotalIncome(),
      streak: await _calculateCurrentStreak(),
      achievementCount: await _calculateAchievementCount(),
      joinDate: _currentUserProfile!.joinDate,
      bio: bio ?? _currentUserProfile!.bio,
      badge: _currentUserProfile!.badge,
      rank: _currentUserProfile!.rank,
    );

    await _saveProfile(_currentUserProfile!);
  }

  // 프로필 저장
  Future<void> _saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  // 리더보드 가져오기
  Future<List<LeaderboardEntry>> getLeaderboard(LeaderboardType type) async {
    // 실제 앱에서는 서버에서 가져오지만, 여기서는 더미 데이터 생성
    final currentUser = await getCurrentUserProfile();
    final entries = <LeaderboardEntry>[];

    // 더미 사용자들 생성
    final dummyUsers = _generateDummyUsers();

    // 현재 사용자 추가
    dummyUsers.add({
      'id': currentUser.id,
      'nickname': currentUser.nickname,
      'avatar': currentUser.avatar,
      'level': currentUser.level,
      'score': _getScoreByType(currentUser, type),
      'badge': currentUser.badge,
    });

    // 정렬
    dummyUsers.sort((a, b) => b['score'].compareTo(a['score']));

    // LeaderboardEntry로 변환
    for (int i = 0; i < dummyUsers.length; i++) {
      final user = dummyUsers[i];
      entries.add(LeaderboardEntry(
        userId: user['id'],
        nickname: user['nickname'],
        avatar: user['avatar'],
        rank: i + 1,
        score: user['score'].toDouble(),
        level: user['level'],
        badge: user['badge'],
        change: Random().nextDouble() * 10 - 5, // -5 ~ +5
        isCurrentUser: user['id'] == currentUser.id,
      ));
    }

    return entries;
  }

  // 챌린지 목록 가져오기
  Future<List<Challenge>> getChallenges() async {
    final now = DateTime.now();
    return [
      Challenge(
        id: '1',
        title: '주간 10만원 도전',
        description: '이번 주 10만원 달성하기',
        startDate: now.subtract(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 5)),
        targetAmount: 100000,
        participants: 234,
        reward: '🏆 주간 챔피언 배지',
        isActive: true,
        currentProgress: 0.65,
      ),
      Challenge(
        id: '2',
        title: '30일 연속 기록',
        description: '30일 동안 매일 수익 기록하기',
        startDate: now.subtract(const Duration(days: 15)),
        endDate: now.add(const Duration(days: 15)),
        targetAmount: 0,
        participants: 567,
        reward: '🔥 불꽃 스트릭 배지',
        isActive: true,
        currentProgress: 0.5,
      ),
      Challenge(
        id: '3',
        title: '월간 백만원 클럽',
        description: '이번 달 100만원 달성',
        startDate: DateTime(now.year, now.month, 1),
        endDate: DateTime(now.year, now.month + 1, 0),
        targetAmount: 1000000,
        participants: 89,
        reward: '💎 다이아몬드 배지',
        isActive: true,
        currentProgress: 0.3,
      ),
    ];
  }

  // 커뮤니티 포스트 가져오기
  Future<List<CommunityPost>> getCommunityPosts() async {
    final currentUser = await getCurrentUserProfile();

    // 더미 포스트 생성
    return [
      CommunityPost(
        id: '1',
        userId: currentUser.id,
        nickname: currentUser.nickname,
        avatar: currentUser.avatar,
        content: '드디어 월 100만원 달성했어요! 🎉 꾸준함이 답이네요.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        likes: 45,
        comments: 12,
        isLiked: false,
        postType: 'milestone',
      ),
      CommunityPost(
        id: '2',
        userId: '2',
        nickname: '수익왕김씨',
        avatar: '👨‍💼',
        content: '오늘의 팁: 아침 시간을 활용하면 생산성이 2배는 올라가요! 새벽 5시 기상 추천합니다.',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        likes: 78,
        comments: 23,
        isLiked: true,
        postType: 'tip',
      ),
      CommunityPost(
        id: '3',
        userId: '3',
        nickname: '열정만수르',
        avatar: '🦸',
        content: '연속 30일 달성! 이제 습관이 된 것 같아요. 다들 화이팅!',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        likes: 156,
        comments: 34,
        isLiked: true,
        postType: 'achievement',
      ),
      CommunityPost(
        id: '4',
        userId: '4',
        nickname: '부자되는중',
        avatar: '💰',
        content: '실패는 성공의 어머니! 오늘은 수익이 없었지만 내일은 더 열심히 💪',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        likes: 92,
        comments: 18,
        isLiked: false,
        postType: 'motivation',
      ),
    ];
  }

  // 포스트 좋아요
  Future<void> likePost(String postId) async {
    // 실제로는 서버 API 호출
    // 여기서는 로컬 처리만
  }

  // 챌린지 참여
  Future<void> joinChallenge(String challengeId) async {
    // 실제로는 서버 API 호출
    // 여기서는 로컬 처리만
  }

  // Helper 메서드들
  Future<double> _calculateTotalIncome() async {
    final incomes = await _dbService.getAllIncomes();
    double total = 0;
    for (var income in incomes) {
      total += (income['amount'] as num).toDouble();
    }
    return total;
  }

  Future<int> _calculateCurrentStreak() async {
    final incomes = await _dbService.getAllIncomes();
    if (incomes.isEmpty) return 0;

    final dates = <String>{};
    for (var income in incomes) {
      final date = income['date'] as String;
      dates.add(date.split(' ')[0]);
    }

    int streak = 0;
    var checkDate = DateTime.now();

    while (true) {
      final dateStr = '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (dates.contains(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  Future<int> _calculateAchievementCount() async {
    // 실제로는 업적 서비스와 연동
    return Random().nextInt(20);
  }

  int _calculateLevel(double totalIncome) {
    // 수익 기반 레벨 계산
    if (totalIncome < 10000) return 1;
    if (totalIncome < 50000) return 2;
    if (totalIncome < 100000) return 3;
    if (totalIncome < 500000) return 4;
    if (totalIncome < 1000000) return 5;
    if (totalIncome < 5000000) return 6;
    if (totalIncome < 10000000) return 7;
    if (totalIncome < 50000000) return 8;
    if (totalIncome < 100000000) return 9;
    return 10;
  }

  String _getBadgeForLevel(int level) {
    final badges = ['🥉', '🥈', '🥇', '💎', '👑', '🏆', '⭐', '🌟', '✨', '🔥'];
    return badges[level - 1];
  }

  String _generateRandomNickname() {
    final adjectives = ['열정적인', '성실한', '부지런한', '똑똑한', '창의적인', '도전적인'];
    final nouns = ['수익러', '부자씨', '성공맨', '돈벌이', '워커', '챌린저'];
    final random = Random();
    return '${adjectives[random.nextInt(adjectives.length)]}${nouns[random.nextInt(nouns.length)]}';
  }

  String _getRandomAvatar() {
    final avatars = ['👤', '👨‍💼', '👩‍💼', '🧑‍💻', '👨‍🎓', '👩‍🎓', '🦸', '🦹', '🧙', '🎭'];
    return avatars[Random().nextInt(avatars.length)];
  }

  double _getScoreByType(UserProfile profile, LeaderboardType type) {
    switch (type) {
      case LeaderboardType.weekly:
        return Random().nextDouble() * 500000; // 주간 수익 (더미)
      case LeaderboardType.monthly:
        return Random().nextDouble() * 2000000; // 월간 수익 (더미)
      case LeaderboardType.allTime:
        return profile.totalIncome;
      case LeaderboardType.streak:
        return profile.streak.toDouble();
      case LeaderboardType.level:
        return profile.level.toDouble();
    }
  }

  List<Map<String, dynamic>> _generateDummyUsers() {
    final names = [
      '수익대장', '부자왕', '성공가도', '돈모으기', '열정맨',
      '도전자', '위너', '파이터', '드림러', '골드러시',
      '머니메이커', '캐시킹', '프로수익러', '탑클래스', '엘리트',
      '챔피언', '레전드', '마스터', '그랜드마스터', '아이언맨'
    ];

    final users = <Map<String, dynamic>>[];
    final random = Random();

    for (int i = 0; i < 20; i++) {
      users.add({
        'id': 'dummy_$i',
        'nickname': names[i],
        'avatar': _getRandomAvatar(),
        'level': random.nextInt(10) + 1,
        'score': random.nextDouble() * 1000000,
        'badge': _getBadgeForLevel(random.nextInt(10) + 1),
      });
    }

    return users;
  }
}

// JSON 관련 import
import 'dart:convert';
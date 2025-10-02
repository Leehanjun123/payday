import 'dart:async';
import 'package:flutter/material.dart';
import 'local_storage_service.dart';
import 'analytics_service.dart';

class EnhancedCashService {
  static final EnhancedCashService _instance = EnhancedCashService._internal();
  factory EnhancedCashService() => _instance;
  EnhancedCashService._internal();

  final LocalStorageService _storage = LocalStorageService();

  // 수익률 (원화 기준) - 확장된 버전
  static const Map<String, Map<String, dynamic>> EARNING_METHODS = {
    // 기존 수익 방법들
    'walking': {
      'rate': 1,
      'unit': '100보',
      'description': '걷기로 건강도 챙기고 돈도 벌어요',
      'icon': Icons.directions_walk,
      'color': Colors.orange,
      'dailyLimit': 50, // 하루 최대 50회 (5000보)
    },
    'ad_view': {
      'rate': 100,
      'unit': '광고',
      'description': '광고 시청으로 쉽게 돈벌기',
      'icon': Icons.play_circle_filled,
      'color': Colors.red,
      'dailyLimit': 20, // 하루 최대 20개 광고
    },
    'survey': {
      'rate': 500,
      'unit': '설문',
      'description': '설문조사 참여로 높은 수익',
      'icon': Icons.assignment,
      'color': Colors.purple,
      'dailyLimit': 5, // 하루 최대 5개 설문
    },
    'daily_login': {
      'rate': 10,
      'unit': '출석',
      'description': '매일 출석만 해도 돈이 쌓여요',
      'icon': Icons.today,
      'color': Colors.blue,
      'dailyLimit': 1, // 하루 1회
    },
    'referral': {
      'rate': 1000,
      'unit': '초대',
      'description': '친구 초대하고 큰 보상 받기',
      'icon': Icons.people,
      'color': Colors.green,
      'dailyLimit': 10, // 하루 최대 10명
    },

    // 새로운 수익 방법들
    'app_review': {
      'rate': 100,
      'unit': '리뷰',
      'description': '앱 리뷰 작성하고 보상 받기',
      'icon': Icons.star_rate,
      'color': Colors.amber,
      'dailyLimit': 3, // 하루 최대 3개 리뷰
    },
    'social_share': {
      'rate': 30,
      'unit': '공유',
      'description': 'SNS 공유하고 친구들에게 알리기',
      'icon': Icons.share,
      'color': Colors.pink,
      'dailyLimit': 10, // 하루 최대 10회 공유
    },
    'video_watch': {
      'rate': 10,
      'unit': '분',
      'description': '동영상 시청하며 쉬운 수익',
      'icon': Icons.play_arrow,
      'color': Colors.deepOrange,
      'dailyLimit': 60, // 하루 최대 60분 (600원)
    },
    'news_read': {
      'rate': 20,
      'unit': '기사',
      'description': '뉴스 읽기로 지식과 수익 동시에',
      'icon': Icons.article,
      'color': Colors.indigo,
      'dailyLimit': 20, // 하루 최대 20개 기사
    },
    'quiz_correct': {
      'rate': 50,
      'unit': '퀴즈',
      'description': '퀴즈 맞히고 즐겁게 돈벌기',
      'icon': Icons.quiz,
      'color': Colors.teal,
      'dailyLimit': 15, // 하루 최대 15개 퀴즈
    },
    'water_drink': {
      'rate': 10,
      'unit': '컵',
      'description': '물 마시기 인증으로 건강 관리',
      'icon': Icons.local_drink,
      'color': Colors.lightBlue,
      'dailyLimit': 8, // 하루 최대 8컵
    },
    'exercise_log': {
      'rate': 100,
      'unit': '운동',
      'description': '운동 인증하고 건강한 수익',
      'icon': Icons.fitness_center,
      'color': Colors.red,
      'dailyLimit': 3, // 하루 최대 3회 운동
    },
    'sleep_record': {
      'rate': 50,
      'unit': '수면',
      'description': '수면 시간 기록하고 보상',
      'icon': Icons.bedtime,
      'color': Colors.deepPurple,
      'dailyLimit': 1, // 하루 1회
    },
    'qr_scan': {
      'rate': 15,
      'unit': '스캔',
      'description': 'QR코드 스캔하고 간편 수익',
      'icon': Icons.qr_code_scanner,
      'color': Colors.cyan,
      'dailyLimit': 20, // 하루 최대 20회
    },
    'location_checkin': {
      'rate': 25,
      'unit': '체크인',
      'description': '위치 체크인으로 발걸음 보상',
      'icon': Icons.location_on,
      'color': Colors.green,
      'dailyLimit': 10, // 하루 최대 10회
    },
  };

  // 현재 캐시 잔액
  double _currentBalance = 0.0;
  double _todayEarnings = 0.0;

  // 캐시 변경 스트림
  final _cashStreamController = StreamController<double>.broadcast();
  Stream<double> get cashStream => _cashStreamController.stream;

  // 초기화
  Future<void> initialize() async {
    await _storage.initialize();
    await _loadBalance();
    await _storage.checkDailyReset();
  }

  // 잔액 불러오기
  Future<void> _loadBalance() async {
    try {
      _currentBalance = await _storage.getCashBalance();
      _todayEarnings = await _storage.getTodayEarnings();
      _cashStreamController.add(_currentBalance);
    } catch (e) {
      print('캐시 잔액 로드 실패: $e');
    }
  }

  // 수익 가능 여부 체크
  Future<bool> canEarn(String source) async {
    final method = EARNING_METHODS[source];
    if (method == null) return false;

    final dailyCount = await _storage.getDailyEarningCount(source);
    final dailyLimit = method['dailyLimit'] as int;

    return dailyCount < dailyLimit;
  }

  // 남은 수익 기회 확인
  Future<int> getRemainingEarnings(String source) async {
    final method = EARNING_METHODS[source];
    if (method == null) return 0;

    final dailyCount = await _storage.getDailyEarningCount(source);
    final dailyLimit = method['dailyLimit'] as int;

    return (dailyLimit - dailyCount).clamp(0, dailyLimit);
  }

  // 캐시 획득 (향상된 버전)
  Future<bool> earnCash({
    required String source,
    required double amount,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 수익 가능 여부 체크
      if (!await canEarn(source)) {
        print('일일 한도 초과: $source');
        return false;
      }

      // 잔액 업데이트
      _currentBalance += amount;
      _todayEarnings += amount;

      // 로컬 저장소에 저장
      await _storage.setCashBalance(_currentBalance);
      await _storage.setTodayEarnings(_todayEarnings);

      // 일일 카운터 증가
      await _storage.incrementDailyEarningCount(source);

      // 거래 내역 저장
      await _saveTransaction(
        type: 'earn',
        amount: amount,
        source: source,
        description: description ?? _getDefaultDescription(source),
        metadata: metadata,
      );

      // 통계 업데이트
      await _updateStatistics(source, amount);

      // 스트림 업데이트
      _cashStreamController.add(_currentBalance);

      // 애널리틱스 로깅
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

  // 새로운 수익 방법들을 위한 편의 메서드들
  Future<bool> earnFromAppReview(String appName, int rating) async {
    if (rating < 4) return false; // 4성 이상만 보상

    return await earnCash(
      source: 'app_review',
      amount: EARNING_METHODS['app_review']!['rate'].toDouble(),
      description: '$appName 앱 리뷰 작성',
      metadata: {'appName': appName, 'rating': rating},
    );
  }

  Future<bool> earnFromSocialShare(String platform) async {
    return await earnCash(
      source: 'social_share',
      amount: EARNING_METHODS['social_share']!['rate'].toDouble(),
      description: '$platform 공유',
      metadata: {'platform': platform},
    );
  }

  Future<bool> earnFromVideoWatch(int minutes) async {
    final amount = minutes * EARNING_METHODS['video_watch']!['rate'].toDouble();
    return await earnCash(
      source: 'video_watch',
      amount: amount,
      description: '동영상 ${minutes}분 시청',
      metadata: {'minutes': minutes},
    );
  }

  Future<bool> earnFromNewsRead(String title) async {
    return await earnCash(
      source: 'news_read',
      amount: EARNING_METHODS['news_read']!['rate'].toDouble(),
      description: '뉴스 기사 읽기',
      metadata: {'title': title},
    );
  }

  Future<bool> earnFromQuiz(String category, bool isCorrect) async {
    if (!isCorrect) return false; // 정답만 보상

    return await earnCash(
      source: 'quiz_correct',
      amount: EARNING_METHODS['quiz_correct']!['rate'].toDouble(),
      description: '$category 퀴즈 정답',
      metadata: {'category': category},
    );
  }

  Future<bool> earnFromWaterDrink() async {
    return await earnCash(
      source: 'water_drink',
      amount: EARNING_METHODS['water_drink']!['rate'].toDouble(),
      description: '물 마시기 인증',
    );
  }

  Future<bool> earnFromExercise(String exerciseType, int duration) async {
    return await earnCash(
      source: 'exercise_log',
      amount: EARNING_METHODS['exercise_log']!['rate'].toDouble(),
      description: '$exerciseType ${duration}분',
      metadata: {'exerciseType': exerciseType, 'duration': duration},
    );
  }

  Future<bool> earnFromSleep(int hours) async {
    if (hours < 6 || hours > 10) return false; // 적정 수면 시간만 보상

    return await earnCash(
      source: 'sleep_record',
      amount: EARNING_METHODS['sleep_record']!['rate'].toDouble(),
      description: '수면 ${hours}시간 기록',
      metadata: {'hours': hours},
    );
  }

  Future<bool> earnFromQRScan(String qrData) async {
    return await earnCash(
      source: 'qr_scan',
      amount: EARNING_METHODS['qr_scan']!['rate'].toDouble(),
      description: 'QR코드 스캔',
      metadata: {'qrData': qrData},
    );
  }

  Future<bool> earnFromLocationCheckin(String locationName) async {
    return await earnCash(
      source: 'location_checkin',
      amount: EARNING_METHODS['location_checkin']!['rate'].toDouble(),
      description: '$locationName 체크인',
      metadata: {'locationName': locationName},
    );
  }

  // 기존 메서드들 (호환성 유지)
  Future<void> earnWalkingCash(int steps) async {
    final earnings = (steps ~/ 100);
    for (int i = 0; i < earnings; i++) {
      if (await canEarn('walking')) {
        await earnCash(
          source: 'walking',
          amount: EARNING_METHODS['walking']!['rate'].toDouble(),
          description: '100보 걷기',
          metadata: {'steps': 100},
        );
      } else {
        break;
      }
    }
  }

  Future<void> earnAdCash(String adType, {String? adUnitId}) async {
    await earnCash(
      source: 'ad_view',
      amount: EARNING_METHODS['ad_view']!['rate'].toDouble(),
      description: '리워드 광고 시청',
      metadata: {'adType': adType, 'adUnitId': adUnitId},
    );
  }

  Future<bool> claimDailyBonus() async {
    if (!await canEarn('daily_login')) {
      return false; // 이미 받음
    }

    // 연속 출석 체크
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
      await _storage.setAttendanceStreak(streak);
      await _storage.setLastAttendanceDate(
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

    final lastAttendance = await _storage.getLastAttendanceDate();
    int currentStreak = await _storage.getAttendanceStreak();

    if (lastAttendance == yesterday) {
      return currentStreak + 1; // 연속 출석
    } else if (lastAttendance == today) {
      return currentStreak; // 오늘 이미 출석
    } else {
      return 1; // 연속 출석 리셋
    }
  }

  // 헬퍼 메서드들
  String _getDefaultDescription(String source) {
    final method = EARNING_METHODS[source];
    return method?['description'] ?? '수익 획득';
  }

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
      'metadata': metadata ?? {},
      'timestamp': DateTime.now().toIso8601String(),
      'balance_after': _currentBalance,
    };

    await _storage.addTransaction(transaction);
  }

  Future<void> _updateStatistics(String source, double amount) async {
    // 총 수익 업데이트
    final totalEarned = await _storage.getTotalEarned();
    await _storage.setTotalEarned(totalEarned + amount);

    // 소스별 수익 업데이트
    final earningsBySource = await _storage.getEarningsBySource();
    earningsBySource[source] = (earningsBySource[source] ?? 0.0) + amount;
    await _storage.setEarningsBySource(earningsBySource);
  }

  // 통계 조회
  Future<Map<String, dynamic>> getCashStatistics() async {
    final transactions = await _storage.getTransactionHistory();
    final earningsBySource = await _storage.getEarningsBySource();
    final totalEarned = await _storage.getTotalEarned();

    return {
      'balance': _currentBalance,
      'todayEarnings': _todayEarnings,
      'totalEarned': totalEarned,
      'earningsBySource': earningsBySource,
      'transactionCount': transactions.length,
      'availableMethods': EARNING_METHODS,
    };
  }

  Future<List<Map<String, dynamic>>> getTransactionHistory({int limit = 50}) async {
    final transactions = await _storage.getTransactionHistory();
    return transactions.take(limit).toList();
  }

  // Getters
  double get balance => _currentBalance;
  double get todayEarnings => _todayEarnings;

  // 리소스 정리
  void dispose() {
    _cashStreamController.close();
  }
}
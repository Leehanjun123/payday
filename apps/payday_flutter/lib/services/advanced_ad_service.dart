import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admob_service.dart';
import 'data_service.dart';

class AdvancedAdService {
  static final AdvancedAdService _instance = AdvancedAdService._internal();
  factory AdvancedAdService() => _instance;
  AdvancedAdService._internal();

  final AdMobService _adMobService = AdMobService();
  final DataService _dataService = DataService();

  // 광고 수익률 설정 (실제 AdMob eCPM 기반)
  static const Map<String, Map<String, dynamic>> _adRevenueConfig = {
    'rewarded': {
      'min': 50.0,
      'max': 100.0,
      'cooldown': 300, // 5분 (초)
      'dailyLimit': 288, // 하루 최대 288회
      'bonus': 1.5, // 연속 시청 보너스 배율
    },
    'interstitial': {
      'min': 30.0,
      'max': 50.0,
      'cooldown': 600, // 10분
      'dailyLimit': 144,
      'bonus': 1.3,
    },
    'banner': {
      'min': 5.0,
      'max': 10.0,
      'cooldown': 0, // 배너는 지속적으로 표시
      'dailyLimit': 0, // 제한 없음
      'bonus': 1.0,
    },
  };

  // 사용자별 광고 상태 추적
  Map<String, DateTime> _lastAdWatched = {};
  Map<String, int> _dailyAdCount = {};
  int _currentStreak = 0;
  double _totalEarningsToday = 0.0;

  // 초기화
  Future<void> initialize() async {
    await _adMobService.initialize();
    await _loadUserAdStats();
    _startDailyReset();
  }

  // 사용자 광고 통계 로드
  Future<void> _loadUserAdStats() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();

    _totalEarningsToday = prefs.getDouble('${today}_earnings') ?? 0.0;
    _currentStreak = prefs.getInt('ad_streak') ?? 0;

    // 일별 광고 카운트 로드
    _dailyAdCount['rewarded'] = prefs.getInt('${today}_rewarded_count') ?? 0;
    _dailyAdCount['interstitial'] = prefs.getInt('${today}_interstitial_count') ?? 0;
  }

  // 자정마다 일일 통계 초기화
  void _startDailyReset() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = tomorrow.difference(now);

    Timer(timeUntilMidnight, () {
      _resetDailyStats();
      _startDailyReset(); // 다음날 리셋 예약
    });
  }

  // 일일 통계 초기화
  Future<void> _resetDailyStats() async {
    _dailyAdCount.clear();
    _totalEarningsToday = 0.0;

    final prefs = await SharedPreferences.getInstance();
    final yesterday = _getYesterdayKey();

    // 어제 광고를 시청했는지 확인하여 스트릭 유지/초기화
    if (prefs.getInt('${yesterday}_rewarded_count') == 0) {
      _currentStreak = 0;
      await prefs.setInt('ad_streak', 0);
    }
  }

  // 보상형 광고 시청
  Future<Map<String, dynamic>> watchRewardedAd() async {
    final adType = 'rewarded';

    // 쿨다운 확인
    if (!_canWatchAd(adType)) {
      final remainingTime = _getRemainingCooldown(adType);
      return {
        'success': false,
        'message': '${remainingTime}초 후에 다시 시도해주세요',
        'remainingTime': remainingTime,
      };
    }

    // 일일 제한 확인
    if (!_checkDailyLimit(adType)) {
      return {
        'success': false,
        'message': '오늘의 광고 시청 제한에 도달했습니다',
        'dailyLimit': true,
      };
    }

    // 광고 표시
    final success = await _adMobService.showRewardedAd();

    if (success) {
      // 수익 계산
      final revenue = _calculateRevenue(adType);

      // 기록 저장
      await _recordAdView(adType, revenue);

      // 백엔드에 수익 전송
      await _dataService.addEarning(
        source: '광고 시청 (보상형)',
        amount: revenue,
        description: '보상형 광고 ${_dailyAdCount[adType]}회차',
      );

      return {
        'success': true,
        'revenue': revenue,
        'streak': _currentStreak,
        'todayTotal': _totalEarningsToday,
        'watchedToday': _dailyAdCount[adType],
        'message': '+${revenue.toStringAsFixed(0)}원 획득!',
      };
    }

    return {
      'success': false,
      'message': '광고 로드 실패. 잠시 후 다시 시도해주세요',
    };
  }

  // 전면 광고 시청
  Future<Map<String, dynamic>> watchInterstitialAd() async {
    final adType = 'interstitial';

    if (!_canWatchAd(adType)) {
      final remainingTime = _getRemainingCooldown(adType);
      return {
        'success': false,
        'message': '${remainingTime}초 후에 다시 시도해주세요',
        'remainingTime': remainingTime,
      };
    }

    if (!_checkDailyLimit(adType)) {
      return {
        'success': false,
        'message': '오늘의 광고 시청 제한에 도달했습니다',
        'dailyLimit': true,
      };
    }

    final success = await _adMobService.showInterstitialAd();

    if (success) {
      final revenue = _calculateRevenue(adType);
      await _recordAdView(adType, revenue);

      await _dataService.addEarning(
        source: '광고 시청 (전면)',
        amount: revenue,
        description: '전면 광고 ${_dailyAdCount[adType]}회차',
      );

      return {
        'success': true,
        'revenue': revenue,
        'todayTotal': _totalEarningsToday,
        'watchedToday': _dailyAdCount[adType],
      };
    }

    return {
      'success': false,
      'message': '광고 로드 실패',
    };
  }

  // 광고 시청 가능 여부 확인
  bool _canWatchAd(String adType) {
    final lastWatched = _lastAdWatched[adType];
    if (lastWatched == null) return true;

    final cooldown = _adRevenueConfig[adType]!['cooldown'] as int;
    if (cooldown == 0) return true;

    final elapsed = DateTime.now().difference(lastWatched).inSeconds;
    return elapsed >= cooldown;
  }

  // 남은 쿨다운 시간
  int _getRemainingCooldown(String adType) {
    final lastWatched = _lastAdWatched[adType];
    if (lastWatched == null) return 0;

    final cooldown = _adRevenueConfig[adType]!['cooldown'] as int;
    final elapsed = DateTime.now().difference(lastWatched).inSeconds;

    return max(0, cooldown - elapsed);
  }

  // 일일 제한 확인
  bool _checkDailyLimit(String adType) {
    final limit = _adRevenueConfig[adType]!['dailyLimit'] as int;
    if (limit == 0) return true;

    final count = _dailyAdCount[adType] ?? 0;
    return count < limit;
  }

  // 수익 계산
  double _calculateRevenue(String adType) {
    final config = _adRevenueConfig[adType]!;
    final min = config['min'] as double;
    final max = config['max'] as double;
    final bonus = config['bonus'] as double;

    // 기본 수익 (랜덤)
    final baseRevenue = min + Random().nextDouble() * (max - min);

    // 스트릭 보너스 적용
    final streakBonus = 1 + (_currentStreak * 0.01); // 연속일수당 1% 보너스

    // 시간대별 보너스 (피크타임)
    final hour = DateTime.now().hour;
    final timeBonus = (hour >= 19 && hour <= 22) ? 1.2 : 1.0;

    return baseRevenue * bonus * streakBonus * timeBonus;
  }

  // 광고 시청 기록
  Future<void> _recordAdView(String adType, double revenue) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = _getTodayKey();

    // 마지막 시청 시간 업데이트
    _lastAdWatched[adType] = now;

    // 일일 카운트 증가
    _dailyAdCount[adType] = (_dailyAdCount[adType] ?? 0) + 1;
    await prefs.setInt('${today}_${adType}_count', _dailyAdCount[adType]!);

    // 총 수익 증가
    _totalEarningsToday += revenue;
    await prefs.setDouble('${today}_earnings', _totalEarningsToday);

    // 스트릭 업데이트
    await _updateStreak();
  }

  // 스트릭 업데이트
  Future<void> _updateStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final lastStreakDate = prefs.getString('last_streak_date') ?? '';
    final today = _getTodayKey();

    if (lastStreakDate != today) {
      final yesterday = _getYesterdayKey();

      if (lastStreakDate == yesterday) {
        _currentStreak++;
      } else {
        _currentStreak = 1;
      }

      await prefs.setInt('ad_streak', _currentStreak);
      await prefs.setString('last_streak_date', today);
    }
  }

  // 광고 통계 가져오기
  Future<Map<String, dynamic>> getAdStats() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayKey();

    // 주간/월간 통계 계산
    double weeklyEarnings = 0;
    double monthlyEarnings = 0;
    int weeklyAdCount = 0;
    int monthlyAdCount = 0;

    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.year}_${date.month}_${date.day}';

      final dayEarnings = prefs.getDouble('${key}_earnings') ?? 0;
      final dayRewarded = prefs.getInt('${key}_rewarded_count') ?? 0;
      final dayInterstitial = prefs.getInt('${key}_interstitial_count') ?? 0;

      if (i < 7) {
        weeklyEarnings += dayEarnings;
        weeklyAdCount += dayRewarded + dayInterstitial;
      }

      monthlyEarnings += dayEarnings;
      monthlyAdCount += dayRewarded + dayInterstitial;
    }

    return {
      'todayEarnings': _totalEarningsToday,
      'weeklyEarnings': weeklyEarnings,
      'monthlyEarnings': monthlyEarnings,
      'todayAdCount': (_dailyAdCount['rewarded'] ?? 0) + (_dailyAdCount['interstitial'] ?? 0),
      'weeklyAdCount': weeklyAdCount,
      'monthlyAdCount': monthlyAdCount,
      'currentStreak': _currentStreak,
      'rewardedWatched': _dailyAdCount['rewarded'] ?? 0,
      'interstitialWatched': _dailyAdCount['interstitial'] ?? 0,
      'rewardedRemaining': max(0, 288 - (_dailyAdCount['rewarded'] ?? 0)),
      'interstitialRemaining': max(0, 144 - (_dailyAdCount['interstitial'] ?? 0)),
      'nextRewardedIn': _getRemainingCooldown('rewarded'),
      'nextInterstitialIn': _getRemainingCooldown('interstitial'),
      'averagePerAd': weeklyAdCount > 0 ? weeklyEarnings / weeklyAdCount : 0,
    };
  }

  // 다음 광고까지 남은 시간
  Map<String, int> getNextAdTiming() {
    return {
      'rewarded': _getRemainingCooldown('rewarded'),
      'interstitial': _getRemainingCooldown('interstitial'),
    };
  }

  // 오늘의 키
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}_${now.month}_${now.day}';
  }

  // 어제의 키
  String _getYesterdayKey() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return '${yesterday.year}_${yesterday.month}_${yesterday.day}';
  }

  // 광고 준비 상태
  Map<String, bool> getAdReadiness() {
    return {
      'rewarded': _adMobService.isRewardedAdReady && _canWatchAd('rewarded'),
      'interstitial': _adMobService.isInterstitialAdReady && _canWatchAd('interstitial'),
    };
  }

  // 예상 일일 수익
  double getEstimatedDailyRevenue() {
    const rewardedPerDay = 288; // 5분마다
    const interstitialPerDay = 144; // 10분마다

    const avgRewardedRevenue = 75.0; // 평균 75원
    const avgInterstitialRevenue = 40.0; // 평균 40원

    return (rewardedPerDay * avgRewardedRevenue) + (interstitialPerDay * avgInterstitialRevenue);
  }
}
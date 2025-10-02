import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'data_service.dart';
import 'cash_service.dart';
import 'admob_service.dart';
import 'analytics_service.dart';

class LockscreenAdService {
  static final LockscreenAdService _instance = LockscreenAdService._internal();
  factory LockscreenAdService() => _instance;
  LockscreenAdService._internal();

  final DataService _dataService = DataService();
  final CashService _cashService = CashService();
  final AdMobService _adMobService = AdMobService();

  // 잠금화면 광고 설정
  bool _isEnabled = false;
  int _multiplier = 1; // 포인트 배수 (1x, 2x, 3x, 5x)

  // 광고 수익 배수 (활성화 시)
  static const Map<int, String> MULTIPLIER_BENEFITS = {
    1: '기본 포인트',
    2: '2배 포인트 (광고 1개)',
    3: '3배 포인트 (광고 2개)',
    5: '5배 포인트 (광고 3개)',
  };

  // 예상 수익 (월 기준 - 실제 원화)
  static const Map<int, int> EXPECTED_EARNINGS = {
    1: 3000,    // 기본: 3,000원/월
    2: 6000,    // 2배: 6,000원/월
    3: 9000,    // 3배: 9,000원/월
    5: 15000,   // 5배: 15,000원/월
  };

  // 일일 광고 제한
  static const int MAX_DAILY_ADS = 50;
  int _todayAdsWatched = 0;
  String? _lastResetDate;

  // 전면 광고
  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;

  // 리워드 광고
  RewardedAd? _rewardedAd;
  bool _isRewardedReady = false;

  // 초기화
  Future<void> initialize() async {
    await _loadSettings();
    await _checkDailyReset();
    if (_isEnabled) {
      await _preloadAds();
    }
  }

  // 설정 불러오기
  Future<void> _loadSettings() async {
    _isEnabled = await _dataService.getSetting('lockscreen_ad_enabled') ?? false;
    _multiplier = await _dataService.getSetting('lockscreen_ad_multiplier') ?? 1;
    _todayAdsWatched = await _dataService.getSetting('today_ads_watched') ?? 0;
    _lastResetDate = await _dataService.getSetting('last_ad_reset_date');
  }

  // 일일 리셋 체크
  Future<void> _checkDailyReset() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (_lastResetDate != today) {
      _todayAdsWatched = 0;
      _lastResetDate = today;
      await _dataService.saveSetting('today_ads_watched', 0);
      await _dataService.saveSetting('last_ad_reset_date', today);
    }
  }

  // 잠금화면 광고 활성화/비활성화
  Future<bool> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    await _dataService.saveSetting('lockscreen_ad_enabled', enabled);

    if (enabled) {
      await _preloadAds();
      // 활성화 보너스 (100원)
      await _cashService.earnCash(
        source: 'lockscreen_activation',
        amount: 100,
        description: '잠금화면 광고 활성화 보너스',
        metadata: {'action': 'activate'},
      );
    } else {
      _disposeAds();
    }

    // 애널리틱스
    await AnalyticsService.logEvent(
      name: 'lockscreen_ad_toggle',
      parameters: {
        'enabled': enabled,
        'multiplier': _multiplier,
      },
    );

    return true;
  }

  // 배수 설정 변경
  Future<bool> setMultiplier(int multiplier) async {
    if (!MULTIPLIER_BENEFITS.containsKey(multiplier)) {
      return false;
    }

    _multiplier = multiplier;
    await _dataService.saveSetting('lockscreen_ad_multiplier', multiplier);

    // 광고 재로드
    if (_isEnabled) {
      await _preloadAds();
    }

    return true;
  }

  // 광고 미리 로드
  Future<void> _preloadAds() async {
    // 전면 광고 로드
    if (_multiplier >= 2) {
      await _loadInterstitialAd();
    }

    // 리워드 광고 로드
    if (_multiplier >= 3) {
      await _loadRewardedAd();
    }
  }

  // 전면 광고 로드
  Future<void> _loadInterstitialAd() async {
    await InterstitialAd.load(
      adUnitId: AdMobService.interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          print('잠금화면 전면 광고 로드 완료');
        },
        onAdFailedToLoad: (error) {
          print('잠금화면 전면 광고 로드 실패: $error');
          _isInterstitialReady = false;
        },
      ),
    );
  }

  // 리워드 광고 로드
  Future<void> _loadRewardedAd() async {
    await RewardedAd.load(
      adUnitId: AdMobService.rewardedAdUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedReady = true;
          print('잠금화면 리워드 광고 로드 완료');
        },
        onAdFailedToLoad: (error) {
          print('잠금화면 리워드 광고 로드 실패: $error');
          _isRewardedReady = false;
        },
      ),
    );
  }

  // 앱 시작 시 광고 표시
  Future<Map<String, dynamic>> showLockscreenAds() async {
    if (!_isEnabled) {
      return {'shown': false, 'reason': 'disabled'};
    }

    if (_todayAdsWatched >= MAX_DAILY_ADS) {
      return {'shown': false, 'reason': 'daily_limit'};
    }

    int adsShown = 0;
    double totalCash = 0;

    // 기본 캐시 (광고 없이)
    double baseCash = 10;

    try {
      // 배수별 광고 표시
      switch (_multiplier) {
        case 2: // 2배: 전면 광고 1개
          if (_isInterstitialReady) {
            await _showInterstitialAd();
            adsShown++;
            baseCash *= 2;
          }
          break;

        case 3: // 3배: 전면 광고 1개 + 리워드 광고 1개
          if (_isInterstitialReady) {
            await _showInterstitialAd();
            adsShown++;
          }
          if (_isRewardedReady) {
            await _showRewardedAd();
            adsShown++;
          }
          baseCash *= 3;
          break;

        case 5: // 5배: 전면 광고 2개 + 리워드 광고 1개
          if (_isInterstitialReady) {
            await _showInterstitialAd();
            adsShown++;
            // 두 번째 전면 광고 로드 및 표시
            await _loadInterstitialAd();
            if (_isInterstitialReady) {
              await Future.delayed(Duration(seconds: 1));
              await _showInterstitialAd();
              adsShown++;
            }
          }
          if (_isRewardedReady) {
            await _showRewardedAd();
            adsShown++;
          }
          baseCash *= 5;
          break;

        default:
          // 1배: 광고 없음
          break;
      }

      // 캐시 지급 (실제 원화)
      if (adsShown > 0 || _multiplier == 1) {
        totalCash = baseCash;
        await _cashService.earnCash(
          source: 'lockscreen_ad',
          amount: totalCash,
          description: '잠금화면 광고 시청 (${_multiplier}x)',
          metadata: {
            'multiplier': _multiplier,
            'ads_shown': adsShown,
          },
        );

        // 일일 광고 카운트 증가
        _todayAdsWatched += adsShown;
        await _dataService.saveSetting('today_ads_watched', _todayAdsWatched);
      }

      // 광고 재로드
      await _preloadAds();

      return {
        'shown': true,
        'ads_count': adsShown,
        'cash_earned': totalCash,
        'multiplier': _multiplier,
      };
    } catch (e) {
      print('잠금화면 광고 표시 실패: $e');
      return {'shown': false, 'error': e.toString()};
    }
  }

  // 전면 광고 표시
  Future<void> _showInterstitialAd() async {
    if (_interstitialAd == null) return;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialReady = false;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialReady = false;
      },
    );

    await _interstitialAd!.show();
  }

  // 리워드 광고 표시
  Future<void> _showRewardedAd() async {
    if (_rewardedAd == null) return;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedReady = false;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedReady = false;
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        print('리워드 획득: ${reward.amount}');
      },
    );
  }

  // 광고 정리
  void _disposeAds() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
    _isInterstitialReady = false;
    _isRewardedReady = false;
  }

  // 통계 조회
  Future<Map<String, dynamic>> getStatistics() async {
    final totalEarned = await _dataService.getSetting('total_lockscreen_cash') ?? 0.0;
    final totalAdsWatched = await _dataService.getSetting('total_lockscreen_ads') ?? 0;

    return {
      'enabled': _isEnabled,
      'multiplier': _multiplier,
      'today_ads': _todayAdsWatched,
      'daily_limit': MAX_DAILY_ADS,
      'total_cash': totalEarned,
      'total_ads': totalAdsWatched,
      'expected_monthly': EXPECTED_EARNINGS[_multiplier] ?? 0,
    };
  }

  // Getters
  bool get isEnabled => _isEnabled;
  int get multiplier => _multiplier;
  int get todayAdsWatched => _todayAdsWatched;
  int get remainingAds => MAX_DAILY_ADS - _todayAdsWatched;
  bool get canShowAds => _isEnabled && _todayAdsWatched < MAX_DAILY_ADS;

  // 리소스 정리
  void dispose() {
    _disposeAds();
  }
}
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // 개발 중에는 테스트 ID 사용 (실제 출시 시 변경)
  static const bool _useTestAds = true; // 테스트 광고로 다시 변경

  // 실제 광고 ID
  static const String _realBannerAdUnitId = 'ca-app-pub-6385395341660988/6786561002';
  static const String _realInterstitialAdUnitId = 'ca-app-pub-6385395341660988/4391320196';
  static const String _realRewardedAdUnitId = 'ca-app-pub-6385395341660988/4160397668';

  // 광고 Unit ID 가져오기
  static String get _bannerAdUnitId => _useTestAds
      ? (Platform.isIOS
          ? 'ca-app-pub-3940256099942544/2934735716'
          : 'ca-app-pub-3940256099942544/6300978111')
      : _realBannerAdUnitId;

  static String get _rewardedAdUnitId => _useTestAds
      ? (Platform.isIOS
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-3940256099942544/5224354917')
      : _realRewardedAdUnitId;

  static String get _interstitialAdUnitId => _useTestAds
      ? (Platform.isIOS
          ? 'ca-app-pub-3940256099942544/4411468910'
          : 'ca-app-pub-3940256099942544/1033173712')
      : _realInterstitialAdUnitId;

  // Public getters for external access
  static String get rewardedAdUnitId => _rewardedAdUnitId;
  static String get interstitialAdUnitId => _interstitialAdUnitId;

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _isRewardedAdReady = false;
  bool _isInterstitialAdReady = false;

  final ApiService _apiService = ApiService();

  // Initialize AdMob
  Future<void> initialize() async {
    try {
      // Initialize ApiService first
      _apiService.initialize();

      print('Initializing AdMob...');
      final initResult = await MobileAds.instance.initialize();
      print('AdMob SDK initialized');

      // 초기화 상태 확인
      initResult.adapterStatuses.forEach((key, value) {
        print('Adapter: $key - State: ${value.state}');
      });

      // 테스트 디바이스 설정 - 실제 기기의 IDFA 추가 필요
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: [
          'SIMULATOR', // iOS 시뮬레이터
          'YOUR_TEST_DEVICE_ID', // 실제 기기 ID는 콘솔에서 확인
        ]),
      );

      await _loadRewardedAd();
      print('AdMob initialized successfully');
    } catch (e) {
      print('Failed to initialize AdMob: $e');
      print('Error details: ${e.toString()}');
    }
  }

  // Load rewarded ad
  Future<void> _loadRewardedAd() async {
    try {
      print('Loading rewarded ad with ID: $_rewardedAdUnitId');
      await RewardedAd.load(
        adUnitId: _rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedAd = ad;
            _isRewardedAdReady = true;
            _setRewardedAdCallbacks();
            if (kDebugMode) {
              print('Rewarded ad loaded successfully - Ready to show');
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isRewardedAdReady = false;
            if (kDebugMode) {
              print('Rewarded ad failed to load: ${error.message}');
              print('Error code: ${error.code}');
              print('Error domain: ${error.domain}');
            }
            // 실패 시 재시도는 한 번만
            // Future.delayed(Duration(seconds: 3), () {
            //   if (!_isRewardedAdReady) {
            //     print('Retrying to load rewarded ad...');
            //     _loadRewardedAd();
            //   }
            // });
          },
        ),
      );
    } catch (e) {
      print('Error loading rewarded ad: $e');
      _isRewardedAdReady = false;
    }
  }

  // Set rewarded ad callbacks
  void _setRewardedAdCallbacks() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        _isRewardedAdReady = false;
        _loadRewardedAd(); // Load next ad
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        _isRewardedAdReady = false;
        print('Rewarded ad failed to show: $error');
        _loadRewardedAd(); // Load next ad
      },
    );
  }

  // Show rewarded ad
  Future<bool> showRewardedAd() async {
    print('showRewardedAd called - isReady: $_isRewardedAdReady, ad: ${_rewardedAd != null}');

    // 개발 중 Mock 모드 - 실제 광고 대신 가짜 성공 반환
    if (kDebugMode && !_isRewardedAdReady) {
      print('DEBUG MODE: Simulating successful ad view');
      await Future.delayed(Duration(seconds: 2)); // 광고 시청 시뮬레이션
      return true; // 개발 중에는 항상 성공 반환
    }

    if (!_isRewardedAdReady || _rewardedAd == null) {
      if (kDebugMode) {
        print('Rewarded ad not ready, loading...');
      }
      await _loadRewardedAd();

      // 잠시 대기 후 다시 체크
      await Future.delayed(Duration(seconds: 1));

      if (!_isRewardedAdReady || _rewardedAd == null) {
        print('Ad failed to load after retry');
        return false;
      }
      print('Ad loaded successfully, showing now...');
    }

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
          if (kDebugMode) {
            print('User earned reward: ${reward.amount} ${reward.type}');
          }

          // Send reward to backend
          await _processAdReward(_rewardedAdUnitId, 'REWARDED', reward.amount.toDouble());
        },
      );

      // 광고가 표시되면 일단 true 반환 (실제 보상은 콜백에서 처리)
      print('Ad shown successfully');
      return true;
    } catch (e) {
      print('Error showing rewarded ad: $e');
      return false;
    }
  }

  // Load interstitial ad
  Future<void> _loadInterstitialAd() async {
    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _isInterstitialAdReady = true;
            _setInterstitialAdCallbacks();
            if (kDebugMode) {
              print('Interstitial ad loaded successfully');
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isInterstitialAdReady = false;
            if (kDebugMode) {
              print('Interstitial ad failed to load: $error');
            }
          },
        ),
      );
    } catch (e) {
      print('Error loading interstitial ad: $e');
    }
  }

  // Set interstitial ad callbacks
  void _setInterstitialAdCallbacks() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _isInterstitialAdReady = false;
        _loadInterstitialAd(); // Load next ad
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        _isInterstitialAdReady = false;
        print('Interstitial ad failed to show: $error');
        _loadInterstitialAd(); // Load next ad
      },
    );
  }

  // Show interstitial ad
  Future<bool> showInterstitialAd() async {
    if (!_isInterstitialAdReady || _interstitialAd == null) {
      await _loadInterstitialAd();
      return false;
    }

    try {
      await _interstitialAd!.show();
      return true;
    } catch (e) {
      print('Error showing interstitial ad: $e');
      return false;
    }
  }

  // Create banner ad
  BannerAd createBannerAd({
    required AdSize adSize,
    required void Function(Ad ad, LoadAdError error) onAdFailedToLoad,
    required void Function(Ad ad) onAdLoaded,
  }) {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdOpened: (Ad ad) {
          if (kDebugMode) {
            print('Banner ad opened');
          }
        },
        onAdClosed: (Ad ad) {
          if (kDebugMode) {
            print('Banner ad closed');
          }
        },
      ),
    );
  }

  // Process ad reward with backend
  Future<void> _processAdReward(String adUnitId, String adType, double amount) async {
    try {
      await _apiService.processAdReward(adUnitId, adType);
      if (kDebugMode) {
        print('Ad reward processed: \$${amount.toStringAsFixed(2)}');
      }
    } catch (e) {
      print('Failed to process ad reward: $e');
    }
  }

  // Get ad revenue stats
  Future<Map<String, dynamic>> getAdRevenueStats({String period = 'daily'}) async {
    try {
      return await _apiService.getAdRevenueStats(period);
    } catch (e) {
      print('Failed to get ad revenue stats: $e');
      return {
        'totalEarnings': 0.0,
        'adsWatched': 0,
        'averagePerAd': 0.0,
        'streak': 0,
      };
    }
  }

  // Check if rewarded ad is ready
  bool get isRewardedAdReady => _isRewardedAdReady;

  // Check if interstitial ad is ready
  bool get isInterstitialAdReady => _isInterstitialAdReady;

  // Dispose ads
  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
  }
}
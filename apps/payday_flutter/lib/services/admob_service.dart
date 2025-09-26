import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // Test Ad Unit IDs - Replace with real ones in production
  static const String _testRewardedAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';

  static const String _testInterstitialAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  static const String _testBannerAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _isRewardedAdReady = false;
  bool _isInterstitialAdReady = false;

  final ApiService _apiService = ApiService();

  // Initialize AdMob
  Future<void> initialize() async {
    try {
      await MobileAds.instance.initialize();
      await _loadRewardedAd();
      print('AdMob initialized successfully');
    } catch (e) {
      print('Failed to initialize AdMob: $e');
    }
  }

  // Load rewarded ad
  Future<void> _loadRewardedAd() async {
    try {
      await RewardedAd.load(
        adUnitId: _testRewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedAd = ad;
            _isRewardedAdReady = true;
            _setRewardedAdCallbacks();
            if (kDebugMode) {
              print('Rewarded ad loaded successfully');
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            _isRewardedAdReady = false;
            if (kDebugMode) {
              print('Rewarded ad failed to load: $error');
            }
          },
        ),
      );
    } catch (e) {
      print('Error loading rewarded ad: $e');
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
    if (!_isRewardedAdReady || _rewardedAd == null) {
      if (kDebugMode) {
        print('Rewarded ad not ready, loading...');
      }
      await _loadRewardedAd();
      return false;
    }

    bool adCompleted = false;
    double rewardAmount = 0.0;

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
          adCompleted = true;
          rewardAmount = reward.amount.toDouble();

          if (kDebugMode) {
            print('User earned reward: ${reward.amount} ${reward.type}');
          }

          // Send reward to backend
          await _processAdReward(_testRewardedAdUnitId, 'REWARDED', rewardAmount);
        },
      );

      return adCompleted;
    } catch (e) {
      print('Error showing rewarded ad: $e');
      return false;
    }
  }

  // Load interstitial ad
  Future<void> _loadInterstitialAd() async {
    try {
      await InterstitialAd.load(
        adUnitId: _testInterstitialAdUnitId,
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
      adUnitId: _testBannerAdUnitId,
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
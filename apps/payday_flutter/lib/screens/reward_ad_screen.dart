import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';
import '../services/enhanced_cash_service.dart';
import '../widgets/share_achievement_card.dart';

class RewardAdScreen extends StatefulWidget {
  const RewardAdScreen({Key? key}) : super(key: key);

  @override
  State<RewardAdScreen> createState() => _RewardAdScreenState();
}

class _RewardAdScreenState extends State<RewardAdScreen>
    with TickerProviderStateMixin {
  final AdMobService _adMobService = AdMobService();
  final EnhancedCashService _cashService = EnhancedCashService();

  late AnimationController _pulseController;
  late AnimationController _coinController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _coinAnimation;

  bool _isAdReady = false;
  bool _isWatchingAd = false;
  int _todayAdsWatched = 0;
  int _totalAdsWatched = 0;
  double _totalEarned = 0.0;
  double _todayEarned = 0.0;

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeCashService();
    _loadAdStatus();
    _loadBannerAd();
  }

  Future<void> _initializeCashService() async {
    await _cashService.initialize();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _coinController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _coinAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _coinController,
      curve: Curves.bounceOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _loadAdStatus() {
    setState(() {
      _isAdReady = _adMobService.isRewardedAdReady;
    });

    // 광고 통계 로드 (실제 구현 시)
    _loadAdStatistics();
  }

  void _loadAdStatistics() async {
    // 실제 통계 데이터 로드
    final stats = await _adMobService.getAdRevenueStats();
    setState(() {
      _todayAdsWatched = stats['adsWatched'] ?? 0;
      _totalAdsWatched = stats['totalAds'] ?? 0;
      _totalEarned = stats['totalEarnings'] ?? 0.0;
      _todayEarned = stats['todayEarnings'] ?? 0.0;
    });
  }

  void _loadBannerAd() {
    _bannerAd = _adMobService.createBannerAd(
      adSize: AdSize.banner,
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        ad.dispose();
        setState(() => _isBannerAdReady = false);
      },
      onAdLoaded: (Ad ad) {
        setState(() => _isBannerAdReady = true);
      },
    );
    _bannerAd?.load();
  }

  Future<void> _watchRewardedAd() async {
    if (_isWatchingAd) return;

    setState(() => _isWatchingAd = true);

    try {
      final success = await _adMobService.showRewardedAd();

      if (success) {
        // 보상 지급 - 새로운 EnhancedCashService 사용
        await _cashService.earnAdCash('rewarded');

        // 애니메이션 실행
        _coinController.forward().then((_) {
          _coinController.reset();
        });

        // 통계 업데이트
        setState(() {
          _todayAdsWatched++;
          _totalAdsWatched++;
          _todayEarned += 100.0; // 리워드 광고 100원
          _totalEarned += 100.0;
        });

        // 성공 메시지
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.monetization_on, color: Colors.yellow[700]),
                  const SizedBox(width: 8),
                  const Text('100원 획득! 🎉'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // 실패 메시지
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('광고를 불러올 수 없습니다. 잠시 후 다시 시도해주세요.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('광고 시청 중 오류: $e');
    } finally {
      setState(() => _isWatchingAd = false);
      _loadAdStatus(); // 광고 상태 다시 확인
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _coinController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          '리워드 광고',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 메인 광고 시청 카드
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6C63FF),
                      Color(0xFF4F46E5),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // 광고 아이콘과 제목
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.play_circle_filled,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          '리워드 광고 시청',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 보상 정보
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _coinAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1 + (_coinAnimation.value * 0.5),
                                child: Icon(
                                  Icons.monetization_on,
                                  color: Colors.yellow[300],
                                  size: 28,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '100원 획득',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 광고 시청 버튼
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isAdReady ? _pulseAnimation.value : 1.0,
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isWatchingAd || !_isAdReady ? null : _watchRewardedAd,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF6C63FF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                              ),
                              child: _isWatchingAd
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Color(0xFF6C63FF),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          '광고 로딩 중...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      _isAdReady ? '광고 시청하고 100원 받기' : '광고 준비 중...',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 오늘의 통계
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '오늘 시청',
                    _todayAdsWatched.toString(),
                    '회',
                    Icons.today,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '오늘 수익',
                    _todayEarned.toStringAsFixed(0),
                    '원',
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 전체 통계
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    '총 시청',
                    _totalAdsWatched.toString(),
                    '회',
                    Icons.bar_chart,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    '총 수익',
                    _totalEarned.toStringAsFixed(0),
                    '원',
                    Icons.savings,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 광고 팁 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        const Text(
                          '광고 시청 팁',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• 광고는 마지막까지 시청해야 보상을 받을 수 있습니다\n'
                      '• 하루에 최대 20회까지 시청 가능합니다\n'
                      '• 네트워크 연결 상태를 확인해 주세요\n'
                      '• 광고 차단 앱이 켜져 있으면 광고가 나오지 않을 수 있습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 배너 광고
            if (_isBannerAdReady)
              Container(
                alignment: Alignment.center,
                child: AdWidget(ad: _bannerAd!),
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
              ),

            const SizedBox(height: 16),

            // 공유 카드
            ShareAchievementCard(
              totalAmount: _totalEarned,
              period: '광고 수익',
              topCategories: {'광고 시청': _totalEarned},
              totalDays: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String amount, String unit, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
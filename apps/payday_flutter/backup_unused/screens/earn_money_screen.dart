import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/admob_service.dart';
import '../services/data_service.dart';

class EarnMoneyScreen extends StatefulWidget {
  const EarnMoneyScreen({Key? key}) : super(key: key);

  @override
  State<EarnMoneyScreen> createState() => _EarnMoneyScreenState();
}

class _EarnMoneyScreenState extends State<EarnMoneyScreen> with TickerProviderStateMixin {
  final AdMobService _adService = AdMobService();
  final DataService _dataService = DataService();

  bool _isLoadingAd = false;
  Map<String, dynamic> _stats = {
    'todayEarnings': 0.0,
    'adsWatched': 0,
    'streak': 0,
    'nextRewardTime': DateTime.now(),
  };

  late AnimationController _pulseController;
  late AnimationController _coinController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _coinAnimation;

  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadStats();
    _startCountdown();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _coinController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _coinController,
      curve: Curves.elasticOut,
    ));
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _adService.getAdRevenueStats(period: 'daily');
      final statistics = await _dataService.getStatistics();

      setState(() {
        _stats = {
          'todayEarnings': statistics['todayEarnings'] ?? 0.0,
          'adsWatched': stats['adsWatched'] ?? 0,
          'streak': stats['streak'] ?? 0,
          'nextRewardTime': DateTime.now().add(const Duration(minutes: 5)),
        };
      });
    } catch (e) {
      print('Failed to load stats: $e');
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final diff = _stats['nextRewardTime'].difference(now).inSeconds;

      setState(() {
        _remainingSeconds = diff > 0 ? diff : 0;
      });

      if (_remainingSeconds <= 0) {
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _watchRewardedAd() async {
    print('_watchRewardedAd called - isLoading: $_isLoadingAd, remaining: $_remainingSeconds');

    if (_isLoadingAd || _remainingSeconds > 0) {
      print('Cannot watch ad - isLoading: $_isLoadingAd, remainingSeconds: $_remainingSeconds');
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _isLoadingAd = true;
    });

    print('Calling AdMobService.showRewardedAd()...');
    try {
      final success = await _adService.showRewardedAd();
      print('showRewardedAd returned: $success');

      if (success) {
        _coinController.forward(from: 0);

        // 실제 수익 추가 (광고당 50-100원)
        final earnings = 50 + (DateTime.now().millisecond % 51); // 50-100원 랜덤
        await _dataService.addEarning(
          source: '광고 시청',
          amount: earnings.toDouble(),
          description: 'AdMob 보상형 광고 시청',
        );

        await _loadStats();

        setState(() {
          _stats['nextRewardTime'] = DateTime.now().add(const Duration(minutes: 5));
        });
        _startCountdown();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('+$earnings원 획득!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error watching ad: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('광고 로드 실패. 잠시 후 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingAd = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _coinController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade800,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      '광고 수익',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      onPressed: _showInfoDialog,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // 오늘의 수익
                _buildTodayEarnings(),

                const SizedBox(height: 30),

                // 광고 시청 버튼
                _buildWatchAdButton(),

                const SizedBox(height: 30),

                // 통계 카드들
                Row(
                  children: [
                    Expanded(child: _buildStatCard(
                      '오늘 시청',
                      '${_stats['adsWatched']}개',
                      Icons.play_circle_outline,
                      Colors.blue,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard(
                      '연속 시청',
                      '${_stats['streak']}일',
                      Icons.local_fire_department,
                      Colors.orange,
                    )),
                  ],
                ),

                const SizedBox(height: 20),

                // 수익 계산기
                _buildEarningsCalculator(),

                const SizedBox(height: 20),

                // 팁 카드
                _buildTipCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTodayEarnings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            '오늘의 수익',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _coinAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + (_coinAnimation.value * 0.2),
                child: Text(
                  '${_stats['todayEarnings'].toStringAsFixed(0)}원',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWatchAdButton() {
    final bool canWatch = _remainingSeconds == 0 && !_isLoadingAd;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: canWatch ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: canWatch ? _watchRewardedAd : null,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: canWatch
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.yellow, Colors.orange],
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade600, Colors.grey.shade700],
                      ),
                boxShadow: canWatch
                    ? [
                        BoxShadow(
                          color: Colors.yellow.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isLoadingAd)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  else if (canWatch)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 60,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '광고 시청',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '+50~100원',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.timer,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatTime(_remainingSeconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '다음 광고까지',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCalculator() {
    final dailyAds = 288; // 24시간 * 60분 / 5분 = 288개
    final minDaily = dailyAds * 50;
    final maxDaily = dailyAds * 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calculate, color: Colors.white70, size: 20),
              SizedBox(width: 8),
              Text(
                '예상 일 수익',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '최대 시청 시',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '${minDaily.toStringAsFixed(0)}~${maxDaily.toStringAsFixed(0)}원',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '월 예상 수익',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                '${(minDaily * 30 / 1000).toStringAsFixed(0)}~${(maxDaily * 30 / 1000).toStringAsFixed(0)}만원',
                style: const TextStyle(
                  color: Colors.yellowAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.purple.shade700],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb,
              color: Colors.yellow,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '수익 극대화 팁',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '5분마다 꾸준히 광고를 시청하면 하루 최대 28,800원까지 벌 수 있어요!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text(
          '광고 수익 안내',
          style: TextStyle(color: Colors.white),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• 광고 1개당 50~100원 지급',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text(
              '• 5분마다 새 광고 시청 가능',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text(
              '• 하루 최대 288개 시청 가능',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text(
              '• 5,000원부터 출금 가능',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../widgets/income_detail_template.dart';
import '../../models/income_source.dart';

class RewardAdDetailScreen extends StatefulWidget {
  const RewardAdDetailScreen({Key? key}) : super(key: key);

  @override
  State<RewardAdDetailScreen> createState() => _RewardAdDetailScreenState();
}

class _RewardAdDetailScreenState extends State<RewardAdDetailScreen>
    with TickerProviderStateMixin, IncomeDetailMixin {
  late AnimationController _headerController;
  late AnimationController _progressController;
  late AnimationController _rewardController;
  late Animation<double> _headerScale;
  late Animation<double> _progressAnimation;
  late Animation<double> _rewardBounce;

  // Mock Data Service
  final MockRewardAdData _mockData = MockRewardAdData();

  // State variables
  bool _isWatchingAd = false;
  int _currentAdIndex = 0;
  double _watchProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _headerController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: Duration(seconds: 30), // 30초 광고
      vsync: this,
    );

    _rewardController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _headerScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.elasticOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    ));

    _rewardBounce = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _rewardController,
      curve: Curves.elasticOut,
    ));

    _headerController.forward();

    // Progress animation listener
    _progressController.addListener(() {
      setState(() {
        _watchProgress = _progressAnimation.value;
      });
    });

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _completeAd();
      }
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _progressController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adData = _mockData.getCurrentAdData();
    final stats = _mockData.getDailyStats();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B46C1),
              Color(0xFF9333EA),
              Color(0xFF7C3AED),
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeader(adData, stats),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildAdPlayer(adData),
                      SizedBox(height: 24),
                      _buildDailyProgress(stats),
                      SizedBox(height: 24),
                      _buildAvailableAds(),
                      SizedBox(height: 24),
                      _buildRewardHistory(),
                      SizedBox(height: 24),
                      _buildTipsSection(),
                      SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Watch Ad Button
      bottomSheet: _isWatchingAd ? null : _buildWatchButton(adData),
    );
  }

  Widget _buildHeader(AdData adData, DailyStats stats) {
    return Container(
      padding: EdgeInsets.all(20),
      child: AnimatedBuilder(
        animation: _headerScale,
        builder: (context, child) {
          return Transform.scale(
            scale: _headerScale.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '리워드 광고',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeaderStat(
                      '오늘 수익',
                      '\$${stats.todayEarnings.toStringAsFixed(2)}',
                      Icons.attach_money,
                    ),
                    SizedBox(width: 40),
                    _buildHeaderStat(
                      '시청 완료',
                      '${stats.watchedCount}/${stats.dailyLimit}',
                      Icons.check_circle,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAdPlayer(AdData adData) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: _isWatchingAd ? _buildActiveAdPlayer(adData) : _buildIdlePlayer(adData),
    );
  }

  Widget _buildActiveAdPlayer(AdData adData) {
    return Column(
      children: [
        // Ad Video Placeholder
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Mock Video Player
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple, Colors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, color: Colors.white, size: 60),
                      SizedBox(height: 8),
                      Text(
                        adData.advertiserName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        adData.adTitle,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Skip button (disabled)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(30 * (1 - _watchProgress)).toInt()}초',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Progress Bar
        Container(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '시청 중...',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  Text(
                    '${(_watchProgress * 100).toInt()}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: _watchProgress,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 8,
              ),
              SizedBox(height: 8),
              Text(
                '보상: \$${adData.reward.toStringAsFixed(3)}',
                style: TextStyle(
                  color: Colors.yellow,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdlePlayer(AdData adData) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.play_circle_outline,
            color: Colors.white54,
            size: 80,
          ),
          SizedBox(height: 16),
          Text(
            '광고를 시청하고 보상을 받으세요',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '다음 보상: \$${adData.reward.toStringAsFixed(3)}',
            style: TextStyle(
              color: Colors.yellow,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '예상 시간: ${adData.duration}초',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgress(DailyStats stats) {
    final progress = stats.watchedCount / stats.dailyLimit;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '일일 진행도',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: progress >= 1
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: progress >= 1 ? Colors.green : Colors.orange,
                  ),
                ),
                child: Text(
                  progress >= 1 ? '완료!' : '진행 중',
                  style: TextStyle(
                    color: progress >= 1 ? Colors.green : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Progress circles
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 8,
            children: List.generate(stats.dailyLimit, (index) {
              final isCompleted = index < stats.watchedCount;
              return Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green
                      : Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? Colors.green
                        : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                ),
              );
            }),
          ),

          SizedBox(height: 16),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProgressStat('시청 완료', '${stats.watchedCount}'),
              _buildProgressStat('남은 광고', '${stats.dailyLimit - stats.watchedCount}'),
              _buildProgressStat('추가 보너스', stats.watchedCount >= stats.dailyLimit ? '\$1.00' : '\$0.00'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableAds() {
    final ads = _mockData.getAvailableAds();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '시청 가능한 광고',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${ads.length}개',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: ads.length,
              itemBuilder: (context, index) {
                final ad = ads[index];
                return _buildAdCard(ad);
              },
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAdCard(AdData ad) {
    return Container(
      width: 140,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: ad.isPremium
              ? [Colors.amber, Colors.orange]
              : [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _currentAdIndex = _mockData.getAvailableAds().indexOf(ad);
            });
          },
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      ad.isPremium ? Icons.star : Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                    if (ad.isPremium)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'PREMIUM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.advertiserName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '\$${ad.reward.toStringAsFixed(3)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${ad.duration}초',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardHistory() {
    final history = _mockData.getRewardHistory();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '최근 보상 내역',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full history
                },
                child: Text(
                  '전체 보기',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          ...history.take(5).map((item) => _buildHistoryItem(item)).toList(),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(RewardHistoryItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.isCompleted
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.isCompleted ? Icons.check : Icons.timer,
              color: item.isCompleted ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.advertiserName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatTime(item.timestamp),
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+\$${item.reward.toStringAsFixed(3)}',
            style: TextStyle(
              color: Colors.green,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.yellow, size: 24),
              SizedBox(width: 12),
              Text(
                '수익 극대화 팁',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildTip('매일 모든 광고를 시청하면 보너스 \$1.00 추가'),
          _buildTip('프리미엄 광고는 일반 광고보다 2배 높은 보상'),
          _buildTip('오전 시간대에 더 많은 광고가 제공됩니다'),
          _buildTip('친구를 초대하면 광고 슬롯이 추가됩니다'),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchButton(AdData adData) {
    final stats = _mockData.getDailyStats();
    final canWatch = stats.watchedCount < stats.dailyLimit;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black87,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: canWatch ? () => _startWatchingAd() : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canWatch ? Colors.green : Colors.grey,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                canWatch ? Icons.play_arrow : Icons.lock,
                color: Colors.white,
              ),
              SizedBox(width: 8),
              Text(
                canWatch
                    ? '광고 시청하고 \$${adData.reward.toStringAsFixed(3)} 받기'
                    : '오늘의 광고를 모두 시청했습니다',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startWatchingAd() {
    setState(() {
      _isWatchingAd = true;
      _watchProgress = 0.0;
    });

    HapticFeedback.mediumImpact();
    _progressController.forward(from: 0);
  }

  void _completeAd() {
    setState(() {
      _isWatchingAd = false;
      _mockData.completeAd(_currentAdIndex);
    });

    HapticFeedback.heavyImpact();
    _rewardController.forward(from: 0);

    // Show reward dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildRewardDialog(),
    );
  }

  Widget _buildRewardDialog() {
    final adData = _mockData.getCurrentAdData();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.blue],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _rewardBounce,
              builder: (context, child) {
                return Transform.scale(
                  scale: _rewardBounce.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            Text(
              '축하합니다!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '\$${adData.reward.toStringAsFixed(3)}',
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '보상을 받았습니다',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _progressController.reset();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                '확인',
                style: TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
    }
  }
}

// Mock Data Classes
class MockRewardAdData {
  List<AdData> _availableAds = [];
  List<RewardHistoryItem> _history = [];
  int _watchedToday = 3;

  MockRewardAdData() {
    _generateMockAds();
    _generateMockHistory();
  }

  void _generateMockAds() {
    _availableAds = [
      AdData(
        id: '1',
        advertiserName: 'Samsung',
        adTitle: 'Galaxy S24 Ultra',
        duration: 30,
        reward: 0.005,
        isPremium: true,
      ),
      AdData(
        id: '2',
        advertiserName: 'Nike',
        adTitle: 'Just Do It Campaign',
        duration: 15,
        reward: 0.002,
        isPremium: false,
      ),
      AdData(
        id: '3',
        advertiserName: 'Coca Cola',
        adTitle: 'Share a Coke',
        duration: 20,
        reward: 0.003,
        isPremium: false,
      ),
      AdData(
        id: '4',
        advertiserName: 'Apple',
        adTitle: 'iPhone 15 Pro',
        duration: 30,
        reward: 0.008,
        isPremium: true,
      ),
      AdData(
        id: '5',
        advertiserName: 'McDonald\'s',
        adTitle: 'I\'m Lovin\' It',
        duration: 15,
        reward: 0.002,
        isPremium: false,
      ),
    ];
  }

  void _generateMockHistory() {
    final now = DateTime.now();
    _history = [
      RewardHistoryItem(
        advertiserName: 'Google Ads',
        reward: 0.003,
        timestamp: now.subtract(Duration(minutes: 30)),
        isCompleted: true,
      ),
      RewardHistoryItem(
        advertiserName: 'Amazon Prime',
        reward: 0.005,
        timestamp: now.subtract(Duration(hours: 1)),
        isCompleted: true,
      ),
      RewardHistoryItem(
        advertiserName: 'Netflix',
        reward: 0.004,
        timestamp: now.subtract(Duration(hours: 2)),
        isCompleted: true,
      ),
      RewardHistoryItem(
        advertiserName: 'Spotify',
        reward: 0.002,
        timestamp: now.subtract(Duration(hours: 3)),
        isCompleted: true,
      ),
      RewardHistoryItem(
        advertiserName: 'Uber Eats',
        reward: 0.003,
        timestamp: now.subtract(Duration(hours: 5)),
        isCompleted: true,
      ),
    ];
  }

  AdData getCurrentAdData() {
    return _availableAds.first;
  }

  List<AdData> getAvailableAds() {
    return _availableAds;
  }

  DailyStats getDailyStats() {
    return DailyStats(
      watchedCount: _watchedToday,
      dailyLimit: 10,
      todayEarnings: _watchedToday * 0.003,
    );
  }

  List<RewardHistoryItem> getRewardHistory() {
    return _history;
  }

  void completeAd(int index) {
    _watchedToday++;
    final ad = _availableAds[index];
    _history.insert(0, RewardHistoryItem(
      advertiserName: ad.advertiserName,
      reward: ad.reward,
      timestamp: DateTime.now(),
      isCompleted: true,
    ));
  }
}

class AdData {
  final String id;
  final String advertiserName;
  final String adTitle;
  final int duration; // seconds
  final double reward; // USD
  final bool isPremium;

  AdData({
    required this.id,
    required this.advertiserName,
    required this.adTitle,
    required this.duration,
    required this.reward,
    required this.isPremium,
  });
}

class DailyStats {
  final int watchedCount;
  final int dailyLimit;
  final double todayEarnings;

  DailyStats({
    required this.watchedCount,
    required this.dailyLimit,
    required this.todayEarnings,
  });
}

class RewardHistoryItem {
  final String advertiserName;
  final double reward;
  final DateTime timestamp;
  final bool isCompleted;

  RewardHistoryItem({
    required this.advertiserName,
    required this.reward,
    required this.timestamp,
    required this.isCompleted,
  });
}
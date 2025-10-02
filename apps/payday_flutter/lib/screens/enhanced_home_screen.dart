import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/income_service.dart';
import '../services/data_service.dart';
import '../services/admob_service.dart';
import '../services/enhanced_cash_service.dart';
import '../widgets/share_achievement_card.dart';
import 'walking_reward_screen.dart';
import 'survey_list_screen.dart';
import 'mission_screen.dart';
import 'reward_ad_screen.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen>
    with TickerProviderStateMixin {
  final _incomeService = IncomeServiceProvider.instance;
  final DataService _databaseService = DataService();
  final AdMobService _adMobService = AdMobService();
  final EnhancedCashService _cashService = EnhancedCashService();

  BannerAd? _bannerAd;
  bool _isBannerAdReady = false;

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  double _todayIncome = 0.0;
  double _weeklyIncome = 0.0;
  double _monthlyIncome = 0.0;
  double _totalIncome = 0.0;
  List<Map<String, dynamic>> _recentIncomes = [];
  List<Map<String, dynamic>> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeServices();
    _loadDashboardData();
    _loadBannerAd();
  }

  Future<void> _initializeServices() async {
    await _adMobService.initialize();
    await _cashService.initialize();
  }


  void _loadBannerAd() {
    _bannerAd = _adMobService.createBannerAd(
      adSize: AdSize.banner,
      onAdLoaded: (Ad ad) {
        setState(() {
          _isBannerAdReady = true;
        });
      },
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        ad.dispose();
        setState(() {
          _isBannerAdReady = false;
        });
      },
    );
    _bannerAd?.load();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _slideController.forward();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // DataService 초기화
      await _databaseService.initialize();
      // 수익 데이터 로드
      final totalIncome = await _incomeService.getTotalIncome();
      final allIncomes = await _incomeService.getAllIncomes();
      final goals = await _databaseService.getAllGoals();

      // 캐시 서비스 데이터 로드
      final cashStats = await _cashService.getCashStatistics();

      // 날짜별 수익 계산
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      double todayIncome = 0;
      double weeklyIncome = 0;
      double monthlyIncome = 0;
      List<Map<String, dynamic>> recentIncomes = [];

      for (var income in allIncomes) {
        if (income['date'] == null || income['amount'] == null) continue;

        final incomeDate = DateTime.parse(income['date']);
        final incomeDay = DateTime(incomeDate.year, incomeDate.month, incomeDate.day);
        final amountValue = income['amount'];
        final amount = amountValue is num ? amountValue.toDouble() : 0.0;

        if (incomeDay == today) {
          todayIncome += amount;
        }

        if (incomeDay.isAfter(weekStart.subtract(const Duration(days: 1)))) {
          weeklyIncome += amount;
        }

        if (incomeDay.isAfter(monthStart.subtract(const Duration(days: 1)))) {
          monthlyIncome += amount;
        }

        if (recentIncomes.length < 5) {
          recentIncomes.add(income);
        }
      }

      setState(() {
        _todayIncome = todayIncome + (cashStats['todayEarnings'] ?? 0.0);
        _weeklyIncome = weeklyIncome;
        _monthlyIncome = monthlyIncome;
        _totalIncome = totalIncome + (cashStats['totalEarned'] ?? 0.0);
        _recentIncomes = recentIncomes;
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 로드 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '좋은 아침이에요! ☀️';
    } else if (hour < 17) {
      return '좋은 오후에요! 🌤️';
    } else {
      return '좋은 저녁이에요! 🌙';
    }
  }

  String _formatAmount(double? amount) {
    if (amount == null) return '₩0';
    return '₩${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\\d{1,3})(?=(\\d{3})+(?!\\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  _buildGreetingSection(),
                  _buildQuickStats(),
                  _buildProgressSection(),
                  _buildRecentActivity(),
                  _buildQuickActions(),
                  _buildRewardAdButton(),
                  _buildBannerAdSection(),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      actions: [
        IconButton(
          icon: Icon(Icons.share, color: Colors.white),
          onPressed: _showShareDialog,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    'PayDay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '스마트 수익 관리',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getGreeting(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '오늘도 수익 창출을 위해 화이팅!',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(child: _buildStatCard('오늘', _formatAmount(_todayIncome), Colors.green, Icons.today)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('이번 주', _formatAmount(_weeklyIncome), Colors.blue, Icons.date_range)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('이번 달', _formatAmount(_monthlyIncome), Colors.purple, Icons.calendar_month)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: label == '오늘' ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressSection() {
    if (_goals.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final activeGoal = _goals.firstWhere(
      (goal) => goal['is_completed'] == 0,
      orElse: () => _goals.first,
    );

    final currentAmount = activeGoal['current_amount'] != null
        ? (activeGoal['current_amount'] is num ? (activeGoal['current_amount'] as num).toDouble() : 0.0)
        : 0.0;
    final targetAmount = activeGoal['target_amount'] != null
        ? (activeGoal['target_amount'] is num ? (activeGoal['target_amount'] as num).toDouble() : 1.0)
        : 1.0;
    final double progress = (targetAmount > 0 ? currentAmount / targetAmount : 0.0).clamp(0.0, 1.0);

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  '현재 목표',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              activeGoal['title'] ?? '목표 설정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatAmount(currentAmount)} / ${_formatAmount(targetAmount)}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(1)}% 달성',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: progress >= 1.0 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_recentIncomes.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '최근 수익',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...(_recentIncomes.take(3).map((income) => _buildActivityItem(income)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> income) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.add_circle,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  income['source'] ?? income['title'] ?? '수익',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  _formatDate(income['date']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatAmount(income['amount'] is num ? (income['amount'] as num).toDouble() : 0.0),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '빠른 작업',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    '수익 추가',
                    Icons.add_circle_outline,
                    Colors.green,
                    () => _showQuickAddIncome(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    '목표 확인',
                    Icons.flag_outlined,
                    Colors.blue,
                    () => _navigateToGoals(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    '걷기 보상',
                    Icons.directions_walk,
                    Colors.orange,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WalkingRewardScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    '설문조사',
                    Icons.assignment,
                    Colors.purple,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SurveyListScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    '일일 미션',
                    Icons.emoji_events,
                    Colors.amber,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MissionScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    '리워드 광고',
                    Icons.play_circle_filled,
                    Colors.red,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RewardAdScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference == 0) {
        return '오늘';
      } else if (difference == 1) {
        return '어제';
      } else if (difference < 7) {
        return '$difference일 전';
      } else {
        return '${date.month}/${date.day}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  void _showQuickAddIncome() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('빠른 수익 추가 기능이 곧 추가될 예정입니다'),
      ),
    );
  }

  void _navigateToGoals() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('목표 화면으로 이동합니다'),
      ),
    );
  }

  void _showShareDialog() async {
    // 카테고리별 수익 집계
    final allIncomes = await _incomeService.getAllIncomes();
    Map<String, double> categoryIncomes = {};

    for (var income in allIncomes) {
      final type = income['type'] ?? 'Unknown';
      categoryIncomes[type] = (categoryIncomes[type] ?? 0) + (income['amount'] ?? 0);
    }

    // 활동 일수 계산
    DateTime? earliestDate;
    for (var income in allIncomes) {
      final dateStr = income['date'];
      if (dateStr != null) {
        final date = DateTime.parse(dateStr);
        if (earliestDate == null || date.isBefore(earliestDate)) {
          earliestDate = date;
        }
      }
    }

    final totalDays = earliestDate != null
        ? DateTime.now().difference(earliestDate).inDays + 1
        : 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: ShareAchievementCard(
                  totalAmount: _totalIncome,
                  period: '이번 달',
                  topCategories: categoryIncomes,
                  totalDays: totalDays,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardAdButton() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple[400]!, Colors.pink[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _showRewardedAd,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '광고 시청하고 보상 받기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '30초 광고 시청 시 50원 적립!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRewardedAd() async {
    final success = await _adMobService.showRewardedAd();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('광고 시청 완료! 보상을 확인해보세요.'),
          backgroundColor: Colors.green,
        ),
      );
      _loadDashboardData(); // 데이터 새로고침
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('광고를 불러올 수 없습니다. 잠시 후 다시 시도해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }


  Widget _buildBannerAdSection() {
    if (!_isBannerAdReady || _bannerAd == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        height: _bannerAd!.size.height.toDouble(),
        width: _bannerAd!.size.width.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
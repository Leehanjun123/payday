import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service_simple.dart';
import 'earning_info_screen.dart';

class TossHomeScreen extends StatefulWidget {
  const TossHomeScreen({Key? key}) : super(key: key);

  @override
  State<TossHomeScreen> createState() => _TossHomeScreenState();
}

class _TossHomeScreenState extends State<TossHomeScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  int _currentIndex = 0;
  String _currentBalance = '0';
  bool _isBalanceVisible = true;
  late AnimationController _balanceAnimationController;
  late Animation<double> _balanceAnimation;

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _balanceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _balanceAnimation = CurvedAnimation(
      parent: _balanceAnimationController,
      curve: Curves.easeInOut,
    );
    _balanceAnimationController.forward();
  }

  @override
  void dispose() {
    _balanceAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    try {
      final balanceData = await _apiService.getUserBalance();
      setState(() {
        final totalBalance = balanceData['totalBalance'] ?? 0.0;
        // 정수로 표시 (토스 스타일)
        _currentBalance = totalBalance is num
            ? totalBalance.toInt().toString()
            : '0';
      });
    } catch (e) {
      print('잔액 조회 실패: $e');
    }
  }

  void _toggleBalanceVisibility() {
    HapticFeedback.lightImpact();
    setState(() {
      _isBalanceVisible = !_isBalanceVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeTab(),
            _buildBenefitsTab(),
            _buildStockTab(),
            _buildAllTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildHeader(),
              _buildBalanceCard(),
              _buildQuickActions(),
              _buildMissionSection(),
              _buildRecommendSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'PayDay',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner, size: 24),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none, size: 24),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return FadeTransition(
      opacity: _balanceAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '내 잔액',
                  style: TextStyle(
                    color: Color(0xFF6B7684),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _toggleBalanceVisibility,
                  child: Icon(
                    _isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                    color: const Color(0xFF6B7684),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _isBalanceVisible
                    ? '\$${_formatNumber(_currentBalance)}'
                    : '• • • • •',
                key: ValueKey(_isBalanceVisible),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '약 ${_calculateKRW(_currentBalance)}원',
              style: TextStyle(
                color: _isBalanceVisible ? const Color(0xFF6B7684) : Colors.transparent,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    '송금',
                    const Color(0xFF3182F7),
                    Icons.arrow_upward,
                    () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    '받기',
                    const Color(0xFFF4F6F9),
                    Icons.arrow_downward,
                    () {},
                    textColor: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    Color bgColor,
    IconData icon,
    VoidCallback onTap, {
    Color textColor = Colors.white,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: textColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.play_circle_fill, 'label': '광고 보기', 'color': const Color(0xFF3182F7)},
      {'icon': Icons.card_giftcard, 'label': '일일 보너스', 'color': const Color(0xFF00BF6E)},
      {'icon': Icons.people, 'label': '친구 초대', 'color': const Color(0xFFFF6B6B)},
      {'icon': Icons.trending_up, 'label': '투자하기', 'color': const Color(0xFF9C27B0)},
    ];

    return Container(
      margin: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions.map((action) {
          return _buildQuickActionItem(
            action['icon'] as IconData,
            action['label'] as String,
            action['color'] as Color,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActionItem(IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        if (label == '광고 보기') {
          _watchAd();
        } else if (label == '일일 보너스') {
          _claimDailyBonus();
        }
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7684),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '오늘의 미션',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  '전체보기',
                  style: TextStyle(
                    color: Color(0xFF6B7684),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMissionCard(
            '광고 10개 시청하기',
            '2/10 완료',
            0.2,
            const Color(0xFF3182F7),
            '\$0.02 보상',
          ),
          const SizedBox(height: 8),
          _buildMissionCard(
            '친구 1명 초대하기',
            '0/1 완료',
            0.0,
            const Color(0xFFFF6B6B),
            '\$0.05 보상',
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(
    String title,
    String subtitle,
    double progress,
    Color color,
    String reward,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7684),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  reward,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFE5E8EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3182F7).withOpacity(0.05),
            const Color(0xFF00BF6E).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3182F7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '수익 창출 가이드',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '투자, 경매, 프리랜서 등 다양한 수익 창출 방법을 알아보세요',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7684),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EarningInfoScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3182F7),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '가이드 보기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsTab() {
    return const Center(
      child: Text('혜택 탭 - 개발 중'),
    );
  }

  Widget _buildStockTab() {
    return const Center(
      child: Text('증권 탭 - 개발 중'),
    );
  }

  Widget _buildAllTab() {
    return const Center(
      child: Text('전체 탭 - 개발 중'),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFE5E8EB),
            width: 0.5,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticFeedback.lightImpact();
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color(0xFF6B7684),
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.diamond_outlined),
            label: '혜택',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up),
            label: '증권',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: '전체',
          ),
        ],
      ),
    );
  }

  String _formatNumber(String number) {
    try {
      final n = int.parse(number);
      if (n >= 1000000) {
        return '${(n / 1000000).toStringAsFixed(1)}M';
      } else if (n >= 1000) {
        return '${(n / 1000).toStringAsFixed(1)}K';
      }
      return n.toString();
    } catch (e) {
      return number;
    }
  }

  String _calculateKRW(String usd) {
    try {
      final amount = double.parse(usd);
      final krw = (amount * 1300).toInt();
      if (krw >= 10000) {
        return '${(krw / 10000).toStringAsFixed(1)}만';
      }
      return krw.toString();
    } catch (e) {
      return '0';
    }
  }

  Future<void> _watchAd() async {
    try {
      // 광고 시청 시뮬레이션
      await Future.delayed(const Duration(seconds: 3));

      await _apiService.processAdReward(
        'ca-app-pub-3940256099942544/5224354917',
        'REWARDED',
      );

      await _loadBalance();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('\$0.002 획득!'),
            ],
          ),
          backgroundColor: const Color(0xFF00BF6E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      print('광고 보상 처리 실패: $e');
    }
  }

  Future<void> _claimDailyBonus() async {
    try {
      await _apiService.processDailyBonus();
      await _loadBalance();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.card_giftcard, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('일일 보너스 \$0.001 획득!'),
            ],
          ),
          backgroundColor: const Color(0xFF9C27B0),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      print('일일 보너스 처리 실패: $e');
    }
  }
}
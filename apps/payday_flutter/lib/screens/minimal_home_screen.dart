import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service_simple.dart';

class MinimalHomeScreen extends StatefulWidget {
  const MinimalHomeScreen({Key? key}) : super(key: key);

  @override
  State<MinimalHomeScreen> createState() => _MinimalHomeScreenState();
}

class _MinimalHomeScreenState extends State<MinimalHomeScreen>
    with SingleTickerProviderStateMixin {
  String _balance = '0.00';
  bool _isLoading = false;
  int _selectedTab = 0;

  // 애니메이션
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final apiService = ApiService();
      final balanceData = await apiService.getUserBalance();
      setState(() {
        final totalBalance = balanceData['totalBalance'] ?? 0.0;
        _balance = totalBalance is num
            ? totalBalance.toStringAsFixed(2)
            : '0.00';
      });
    } catch (e) {
      print('데이터 로드 실패: $e');
    }
  }

  Future<void> _watchAd() async {
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      await Future.delayed(const Duration(seconds: 3));

      final apiService = ApiService();
      await apiService.processAdReward(
        'ca-app-pub-3940256099942544/5224354917',
        'REWARDED',
      );

      await _loadUserData();

      // 미니멀한 피드백
      _showMinimalFeedback('+\$0.002');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류 발생', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMinimalFeedback(String amount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      duration: const Duration(milliseconds: 300),
      builder: (context) => Container(
        height: 120,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.black,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Text(
                '획득 완료',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // 심플한 헤더
              _buildMinimalHeader(),

              // 메인 컨텐츠
              Expanded(
                child: _selectedTab == 0
                    ? _buildEarnTab()
                    : _selectedTab == 1
                        ? _buildHistoryTab()
                        : _buildProfileTab(),
              ),

              // 미니멀 네비게이션
              _buildMinimalNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'PayDay',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '\$$_balance',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarnTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 대형 잔액 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '현재 잔액',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '\$$_balance',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 56,
                    fontWeight: FontWeight.w200,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '오늘 +\$0.005',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 수익 액션
          const Text(
            '수익 창출',
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // 광고 시청 카드
          _buildMinimalActionCard(
            title: '광고 시청',
            subtitle: '30초 • \$0.002',
            icon: Icons.play_circle_outline,
            onTap: _isLoading ? null : _watchAd,
            isPrimary: true,
          ),

          // 일일 보너스 카드
          _buildMinimalActionCard(
            title: '일일 보너스',
            subtitle: '매일 1회 • \$0.001',
            icon: Icons.card_giftcard_outlined,
            onTap: null,
          ),

          // 설문조사 카드
          _buildMinimalActionCard(
            title: '설문조사',
            subtitle: '곧 출시',
            icon: Icons.assignment_outlined,
            onTap: null,
            isDisabled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final transactions = [
      {'time': '오늘 14:30', 'type': '광고 시청', 'amount': '+0.002'},
      {'time': '오늘 12:15', 'type': '일일 보너스', 'amount': '+0.001'},
      {'time': '오늘 09:20', 'type': '광고 시청', 'amount': '+0.002'},
      {'time': '어제 18:45', 'type': '광고 시청', 'amount': '+0.002'},
      {'time': '어제 14:10', 'type': '일일 보너스', 'amount': '+0.001'},
    ];

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.attach_money,
                  color: Colors.black54,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx['type']!,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tx['time']!,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${tx['amount']}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 프로필 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.black54,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Test User',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'testuser2@example.com',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 통계
          Row(
            children: [
              Expanded(
                child: _buildStatCard('총 수익', '\$15.32'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('이번 달', '\$8.45'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('광고 시청', '124회'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard('연속 출석', '7일'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    bool isPrimary = false,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey.withOpacity(0.1)
              : isPrimary
                  ? Colors.black
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: !isDisabled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(isPrimary ? 0.2 : 0.05),
                    blurRadius: isPrimary ? 20 : 10,
                    offset: Offset(0, isPrimary ? 10 : 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDisabled
                  ? Colors.grey
                  : isPrimary
                      ? Colors.white
                      : Colors.black,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDisabled
                          ? Colors.grey
                          : isPrimary
                              ? Colors.white
                              : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDisabled
                          ? Colors.grey.withOpacity(0.6)
                          : isPrimary
                              ? Colors.white70
                              : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (!isDisabled)
              Icon(
                Icons.arrow_forward_ios,
                color: isPrimary ? Colors.white54 : Colors.grey,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalNavigation() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.attach_money, '수익', 0),
          _buildNavItem(Icons.history, '기록', 1),
          _buildNavItem(Icons.person_outline, '프로필', 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTab = index);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
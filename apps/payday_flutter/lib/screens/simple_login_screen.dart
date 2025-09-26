import 'package:flutter/material.dart';
import '../services/api_service_simple.dart';
import 'earning_info_screen.dart';
import 'main_navigation_screen.dart';

class SimpleLoginScreen extends StatefulWidget {
  const SimpleLoginScreen({Key? key}) : super(key: key);

  @override
  State<SimpleLoginScreen> createState() => _SimpleLoginScreenState();
}

class _SimpleLoginScreenState extends State<SimpleLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _balance = '0.00';

  @override
  void initState() {
    super.initState();
    // 테스트 계정 자동 입력
    _emailController.text = 'testuser2@example.com';
    _passwordController.text = 'Test123!';
    // API 서비스 초기화 시 토큰 로드
    _initApiService();
  }

  Future<void> _initApiService() async {
    await ApiService().loadToken();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ApiService();

      // 로그인
      final loginResponse = await apiService.login(
        _emailController.text,
        _passwordController.text,
      );

      print('로그인 성공: ${loginResponse['user']['email']}');

      // 잔액 조회
      final balanceData = await apiService.getUserBalance();

      setState(() {
        // null 체크 및 안전한 타입 변환
        final totalBalance = balanceData['totalBalance'] ?? 0.0;
        _balance = totalBalance is num
            ? totalBalance.toStringAsFixed(2)
            : '0.00';
      });

      // Main Navigation 화면으로 이동
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 로고
              const Text(
                '💰 PayDay',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3182F7),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '매일 돈 버는 앱',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),

              // 이메일 입력
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 비밀번호 입력
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // 로그인 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3182F7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          '로그인',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 간단한 대시보드
class SimpleDashboard extends StatefulWidget {
  final String balance;
  const SimpleDashboard({Key? key, required this.balance}) : super(key: key);

  @override
  State<SimpleDashboard> createState() => _SimpleDashboardState();
}

class _SimpleDashboardState extends State<SimpleDashboard> {
  final ApiService _apiService = ApiService();
  String _currentBalance = '0.00';
  bool _isWatchingAd = false;

  @override
  void initState() {
    super.initState();
    _currentBalance = widget.balance;
  }

  Future<void> _watchAd() async {
    setState(() => _isWatchingAd = true);

    try {
      // 광고 시청 시뮬레이션 (3초 대기)
      await Future.delayed(const Duration(seconds: 3));

      // 광고 보상 처리
      await _apiService.processAdReward(
        'ca-app-pub-3940256099942544/5224354917',
        'REWARDED',
      );

      // 잔액 다시 조회
      final balanceData = await _apiService.getUserBalance();

      setState(() {
        final totalBalance = balanceData['totalBalance'] ?? 0.0;
        _currentBalance = totalBalance is num
            ? totalBalance.toStringAsFixed(2)
            : '0.00';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💰 \$0.002 획득! (약 2.6원)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      setState(() => _isWatchingAd = false);
    }
  }

  Future<void> _claimDailyBonus() async {
    try {
      await _apiService.processDailyBonus();

      // 잔액 다시 조회
      final balanceData = await _apiService.getUserBalance();

      setState(() {
        final totalBalance = balanceData['totalBalance'] ?? 0.0;
        _currentBalance = totalBalance is num
            ? totalBalance.toStringAsFixed(2)
            : '0.00';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎁 일일 보너스 \$0.001 획득! (약 1.3원)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '💰 PayDay',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 잔액 카드
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3182F7), Color(0xFF00BF6E)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3182F7).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '현재 잔액',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$$_currentBalance',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '오늘 \$0.003 획득 (약 3.9원)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 수익 창출 섹션
              const Text(
                '돈 벌기',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 광고 시청 버튼
              _buildActionCard(
                icon: Icons.play_circle_outline,
                title: '광고 시청',
                subtitle: '30초 시청하고 \$0.002 획득 (약 2.6원)',
                color: const Color(0xFF3182F7),
                onTap: _isWatchingAd ? null : _watchAd,
                isLoading: _isWatchingAd,
              ),
              const SizedBox(height: 12),

              // 일일 보너스 버튼
              _buildActionCard(
                icon: Icons.card_giftcard,
                title: '일일 보너스',
                subtitle: '매일 로그인하고 \$0.001 획득 (약 1.3원)',
                color: const Color(0xFF00BF6E),
                onTap: _claimDailyBonus,
              ),
              const SizedBox(height: 12),

              // 설문조사 (곧 출시)
              _buildActionCard(
                icon: Icons.quiz_outlined,
                title: '설문조사',
                subtitle: '곧 출시 예정',
                color: Colors.grey,
                onTap: null,
                isComingSoon: true,
              ),
              const SizedBox(height: 12),

              // 수익 정보 가이드 (NEW!)
              _buildActionCard(
                icon: Icons.school,
                title: '💎 수익 창출 가이드',
                subtitle: '경매, 투자, 프리랜서 등 정보',
                color: const Color(0xFF9C27B0),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EarningInfoScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    bool isLoading = false,
    bool isComingSoon = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      ),
                    )
                  : Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isComingSoon ? Colors.grey : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (!isComingSoon && !isLoading)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }
}
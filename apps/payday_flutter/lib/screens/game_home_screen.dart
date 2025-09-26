import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../services/api_service_simple.dart';

class GameHomeScreen extends StatefulWidget {
  const GameHomeScreen({Key? key}) : super(key: key);

  @override
  State<GameHomeScreen> createState() => _GameHomeScreenState();
}

class _GameHomeScreenState extends State<GameHomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  String _balance = '0.00';
  int _userLevel = 1;
  double _levelProgress = 0.35;
  int _dailyStreak = 7;
  bool _isLoading = false;

  // 애니메이션 컨트롤러
  late AnimationController _coinAnimController;
  late AnimationController _levelUpAnimController;
  late Animation<double> _coinRotation;
  late Animation<double> _levelUpScale;

  // 게임 요소
  final Map<String, int> _achievements = {
    'firstEarning': 1,
    'dailyWarrior': 0,
    'adMaster': 0,
    'richMan': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // 코인 회전 애니메이션
    _coinAnimController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _coinRotation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _coinAnimController,
      curve: Curves.linear,
    ));

    // 레벨업 애니메이션
    _levelUpAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _levelUpScale = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _levelUpAnimController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _coinAnimController.dispose();
    _levelUpAnimController.dispose();
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

        // 잔액에 따른 레벨 계산
        _calculateLevel(totalBalance as num);
      });
    } catch (e) {
      print('데이터 로드 실패: $e');
    }
  }

  void _calculateLevel(num balance) {
    // 레벨 계산 로직 (예: $10당 1레벨)
    _userLevel = (balance / 10).floor() + 1;
    _levelProgress = (balance % 10) / 10;
  }

  Future<void> _watchAd() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      await Future.delayed(const Duration(seconds: 3));

      final apiService = ApiService();
      await apiService.processAdReward(
        'ca-app-pub-3940256099942544/5224354917',
        'REWARDED',
      );

      await _loadUserData();

      // 경험치 획득 애니메이션
      _levelUpAnimController.forward().then((_) {
        _levelUpAnimController.reverse();
      });

      // 업적 업데이트
      setState(() {
        _achievements['adMaster'] = (_achievements['adMaster'] ?? 0) + 1;
      });

      _showRewardDialog('광고 보상', '+\$0.002', '🎬');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showRewardDialog(String title, String reward, String emoji) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1F2937),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFFBBF24), width: 2),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 60),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  reward,
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '+15 EXP',
                  style: TextStyle(
                    color: Colors.purple[300],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // 프로필 & 레벨 섹션
                _buildProfileSection(),
                const SizedBox(height: 24),

                // 잔액 카드 (보물상자 스타일)
                _buildTreasureCard(),
                const SizedBox(height: 24),

                // 퀘스트 섹션
                _buildQuestSection(),
                const SizedBox(height: 24),

                // 업적 섹션
                _buildAchievementsSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildGameBottomNav(),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.2),
            const Color(0xFF8B5CF6).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6366F1), width: 1),
      ),
      child: Row(
        children: [
          // 아바타
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '👤',
                style: TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 레벨 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Lv.',
                      style: TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ScaleTransition(
                      scale: _levelUpScale,
                      child: Text(
                        '$_userLevel',
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '돈 버는 초보자',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 경험치 바
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: 8,
                      width: MediaQuery.of(context).size.width * 0.5 * _levelProgress,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFBBF24).withOpacity(0.5),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'EXP: ${(_levelProgress * 1000).toInt()} / 1000',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // 연속 출석
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text(
                  '🔥',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                Text(
                  '$_dailyStreak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreasureCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFBBF24).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 배경 패턴
          Positioned.fill(
            child: CustomPaint(
              painter: TreasurePatternPainter(),
            ),
          ),

          // 내용
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _coinRotation,
                      builder: (context, child) => Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(_coinRotation.value),
                        child: const Text(
                          '💰',
                          style: TextStyle(fontSize: 40),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '보물 상자',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '\$$_balance',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '오늘 +\$0.005 획득',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '⚔️ 일일 퀘스트',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '2/5 완료',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 퀘스트 카드들
        _buildQuestCard(
          icon: '🎬',
          title: '광고 시청 퀘스트',
          description: '광고 3개 시청하기',
          reward: '\$0.002',
          progress: 0.66,
          onTap: _isLoading ? null : _watchAd,
        ),
        const SizedBox(height: 12),
        _buildQuestCard(
          icon: '💎',
          title: '일일 보너스',
          description: '매일 접속 보상',
          reward: '\$0.001',
          progress: 1.0,
          isCompleted: true,
        ),
        const SizedBox(height: 12),
        _buildQuestCard(
          icon: '🎯',
          title: '특별 미션',
          description: '설문조사 완료하기',
          reward: '\$0.010',
          progress: 0.0,
          isLocked: true,
        ),
      ],
    );
  }

  Widget _buildQuestCard({
    required String icon,
    required String title,
    required String description,
    required String reward,
    required double progress,
    bool isCompleted = false,
    bool isLocked = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isLocked || isCompleted ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isLocked
              ? Colors.grey.withOpacity(0.1)
              : const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF10B981)
                : isLocked
                    ? Colors.grey.withOpacity(0.3)
                    : const Color(0xFF374151),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isLocked
                    ? Colors.grey.withOpacity(0.2)
                    : isCompleted
                        ? const Color(0xFF10B981).withOpacity(0.2)
                        : const Color(0xFF6366F1).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  isLocked ? '🔒' : icon,
                  style: TextStyle(
                    fontSize: 24,
                    color: isLocked ? Colors.grey : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isLocked ? Colors.grey : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: isLocked
                          ? Colors.grey.withOpacity(0.5)
                          : Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 진행 바
                  Stack(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        height: 4,
                        width: 150 * progress,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFF10B981)
                              : const Color(0xFFFBBF24),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? const Color(0xFF10B981)
                        : isLocked
                            ? Colors.grey
                            : const Color(0xFFFBBF24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isCompleted ? '완료' : reward,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!isLocked && !isCompleted) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+20 EXP',
                    style: TextStyle(
                      color: Colors.purple[300],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🏆 업적',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAchievementBadge('첫 수익', '💵', true),
            _buildAchievementBadge('광고 마스터', '🎬', false),
            _buildAchievementBadge('일일 전사', '⚔️', false),
            _buildAchievementBadge('부자의 길', '👑', false),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementBadge(String title, String icon, bool isUnlocked) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.hexagon,
            gradient: isUnlocked
                ? const LinearGradient(
                    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                  )
                : null,
            color: !isUnlocked ? Colors.grey.withOpacity(0.2) : null,
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: const Color(0xFFFBBF24).withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              isUnlocked ? icon : '❓',
              style: TextStyle(
                fontSize: 30,
                color: isUnlocked ? null : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            color: isUnlocked ? Colors.white : Colors.grey,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGameBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF374151).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('퀘스트', '⚔️', 0),
          _buildNavItem('상점', '🛍️', 1),
          _buildNavItem('순위', '🏆', 2),
          _buildNavItem('프로필', '👤', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, String icon, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: TextStyle(
                fontSize: 24,
                color: isSelected ? const Color(0xFFFBBF24) : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFBBF24) : Colors.grey,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 육각형 Shape
class ShapesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;

    final path = Path();
    final width = size.width;
    final height = size.height;

    // 육각형 그리기
    path.moveTo(width * 0.25, 0);
    path.lineTo(width * 0.75, 0);
    path.lineTo(width, height * 0.5);
    path.lineTo(width * 0.75, height);
    path.lineTo(width * 0.25, height);
    path.lineTo(0, height * 0.5);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Hexagon 확장
extension ShapeExtension on BoxShape {
  static const BoxShape hexagon = BoxShape.circle;
}

// 보물상자 패턴 페인터
class TreasurePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 동전 패턴 그리기
    for (int i = 0; i < 5; i++) {
      for (int j = 0; j < 3; j++) {
        final center = Offset(
          size.width * 0.2 * i + 30,
          size.height * 0.3 * j + 20,
        );
        canvas.drawCircle(center, 10, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
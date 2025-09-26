import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../services/api_service_simple.dart';

class CashFlowHomeScreen extends StatefulWidget {
  const CashFlowHomeScreen({Key? key}) : super(key: key);

  @override
  State<CashFlowHomeScreen> createState() => _CashFlowHomeScreenState();
}

class _CashFlowHomeScreenState extends State<CashFlowHomeScreen>
    with TickerProviderStateMixin {
  String _balance = '0.00';
  bool _isLoading = false;

  // 애니메이션 컨트롤러
  late AnimationController _flowAnimController;
  late AnimationController _pulseAnimController;
  late Animation<double> _flowAnimation;
  late Animation<double> _pulseAnimation;

  // 수익 스트림 데이터
  final List<Map<String, dynamic>> _earningStreams = [
    {
      'title': '광고 수익',
      'amount': 0.006,
      'frequency': '일 3회',
      'icon': '📺',
      'color': const Color(0xFF00D9FF),
      'isActive': true,
    },
    {
      'title': '일일 보너스',
      'amount': 0.001,
      'frequency': '일 1회',
      'icon': '🎁',
      'color': const Color(0xFF00FF88),
      'isActive': true,
    },
    {
      'title': '설문조사',
      'amount': 0.010,
      'frequency': '주 2회',
      'icon': '📝',
      'color': const Color(0xFFFF6B6B),
      'isActive': false,
    },
    {
      'title': '추천 보상',
      'amount': 0.050,
      'frequency': '월 1회',
      'icon': '👥',
      'color': const Color(0xFFFFD93D),
      'isActive': false,
    },
  ];

  // 오늘의 수익 트랜잭션
  final List<Map<String, dynamic>> _todayTransactions = [
    {
      'time': '14:30',
      'type': '광고 시청',
      'amount': '+0.002',
      'icon': '📺',
    },
    {
      'time': '12:15',
      'type': '일일 보너스',
      'amount': '+0.001',
      'icon': '🎁',
    },
    {
      'time': '09:20',
      'type': '광고 시청',
      'amount': '+0.002',
      'icon': '📺',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // 플로우 애니메이션
    _flowAnimController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _flowAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _flowAnimController,
      curve: Curves.linear,
    ));

    // 펄스 애니메이션
    _pulseAnimController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseAnimController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _flowAnimController.dispose();
    _pulseAnimController.dispose();
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
    HapticFeedback.mediumImpact();

    try {
      await Future.delayed(const Duration(seconds: 3));

      final apiService = ApiService();
      await apiService.processAdReward(
        'ca-app-pub-3940256099942544/5224354917',
        'REWARDED',
      );

      await _loadUserData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.attach_money, color: Color(0xFF00D9FF)),
              const SizedBox(width: 8),
              const Text('광고 수익 +\$0.002 입금'),
            ],
          ),
          backgroundColor: const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            _buildHeader(),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // 메인 잔액 비주얼
                    _buildMainBalanceVisual(),

                    // 수익 스트림 섹션
                    _buildEarningStreamsSection(),

                    // 실시간 트랜잭션
                    _buildRealtimeTransactions(),

                    // 빠른 액션
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PayDay',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '실시간 수익 흐름',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00D9FF),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.notifications_none,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainBalanceVisual() {
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 배경 원형 그래프
          AnimatedBuilder(
            animation: _flowAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(250, 250),
                painter: FlowCirclePainter(
                  progress: _flowAnimation.value,
                ),
              );
            },
          ),

          // 중앙 잔액
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '총 잔액',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Text(
                      '\$$_balance',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00D9FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF00D9FF).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      color: Color(0xFF00D9FF),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '+12.5% 오늘',
                      style: TextStyle(
                        color: Color(0xFF00D9FF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 플로팅 수익 아이콘들
          ..._buildFloatingIcons(),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingIcons() {
    return [
      Positioned(
        top: 20,
        left: 30,
        child: _buildFloatingIcon('💰', 0),
      ),
      Positioned(
        top: 50,
        right: 40,
        child: _buildFloatingIcon('📺', 1),
      ),
      Positioned(
        bottom: 40,
        left: 20,
        child: _buildFloatingIcon('🎁', 2),
      ),
      Positioned(
        bottom: 30,
        right: 30,
        child: _buildFloatingIcon('📝', 3),
      ),
    ];
  }

  Widget _buildFloatingIcon(String icon, int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 1000 + (delay * 200)),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00D9FF).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEarningStreamsSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💸 수익 스트림',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._earningStreams.map((stream) => _buildStreamCard(stream)),
        ],
      ),
    );
  }

  Widget _buildStreamCard(Map<String, dynamic> stream) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: stream['isActive']
              ? stream['color'].withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: stream['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                stream['icon'],
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stream['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '\$${stream['amount'].toStringAsFixed(3)}',
                      style: TextStyle(
                        color: stream['color'],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      ' / ${stream['frequency']}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 상태 표시
          if (stream['isActive'])
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: stream['color'],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: stream['color'].withOpacity(0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
            )
          else
            Icon(
              Icons.lock_outline,
              color: Colors.grey.withOpacity(0.5),
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildRealtimeTransactions() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '⚡ 실시간 거래',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF88),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF88).withOpacity(0.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: _todayTransactions
                  .map((tx) => _buildTransactionItem(tx))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            tx['icon'],
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['type'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  tx['time'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            tx['amount'],
            style: const TextStyle(
              color: Color(0xFF00FF88),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚡ 빠른 수익',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  '광고 시청',
                  '📺',
                  const Color(0xFF00D9FF),
                  _isLoading ? null : _watchAd,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  '일일 보너스',
                  '🎁',
                  const Color(0xFF00FF88),
                  null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 플로우 서클 페인터
class FlowCirclePainter extends CustomPainter {
  final double progress;

  FlowCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // 배경 원
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawCircle(center, radius * 0.8, bgPaint);
    canvas.drawCircle(center, radius * 0.6, bgPaint);

    // 애니메이션 원호
    final sweepAngle = 2 * math.pi * progress;
    final arcPaint = Paint()
      ..color = const Color(0xFF00D9FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2 + sweepAngle,
      math.pi / 4,
      false,
      arcPaint,
    );

    final arcPaint2 = Paint()
      ..color = const Color(0xFF00FF88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.8),
      -math.pi / 2 - sweepAngle,
      math.pi / 3,
      false,
      arcPaint2,
    );

    // 파티클 효과
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) + sweepAngle;
      final x = center.dx + radius * 0.9 * math.cos(angle);
      final y = center.dy + radius * 0.9 * math.sin(angle);

      final particlePaint = Paint()
        ..color = const Color(0xFF00D9FF).withOpacity(0.6)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 2, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
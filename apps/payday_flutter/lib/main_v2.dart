import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 토스 스타일 상태바
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  runApp(const TossMoneyApp());
}

class TossMoneyApp extends StatelessWidget {
  const TossMoneyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TOSS Money - 모든 부수입을 한 곳에서',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        primaryColor: const Color(0xFF3182F7),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF3182F7),
          secondary: Color(0xFF00BF6E),
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: const Color(0xFF1A1F36),
          displayColor: const Color(0xFF1A1F36),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF1A1F36)),
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1F36),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.dark,
        ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  // 애니메이션 컨트롤러
  late AnimationController _balanceAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _balanceAnimation;

  // 실시간 수익 (1초마다 업데이트)
  double totalEarnings = 42385.0;
  Timer? _earningsTimer;

  // 오늘의 활동
  int completedTasks = 3;
  int totalTasks = 10;

  @override
  void initState() {
    super.initState();

    // 잔액 애니메이션
    _balanceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _balanceAnimation = Tween<double>(
      begin: 0,
      end: totalEarnings,
    ).animate(CurvedAnimation(
      parent: _balanceAnimationController,
      curve: Curves.easeOutCubic,
    ));
    _balanceAnimationController.forward();

    // 펄스 애니메이션
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // 실시간 수익 업데이트 (시뮬레이션)
    _earningsTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        totalEarnings += math.Random().nextDouble() * 50;
      });
    });
  }

  @override
  void dispose() {
    _balanceAnimationController.dispose();
    _pulseAnimationController.dispose();
    _earningsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 토스 스타일 앱바
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white,
                      Color(0xFFF7F8FA),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 인사말
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '안녕하세요 👋',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ).animate().fadeIn(duration: 600.ms),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00BF6E).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF00BF6E),
                                      shape: BoxShape.circle,
                                    ),
                                  ).animate(
                                    onPlay: (controller) => controller.repeat(),
                                  ).scale(
                                    duration: 1.seconds,
                                    curve: Curves.easeInOut,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '실시간 수익중',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: const Color(0xFF00BF6E),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 총 수익
                        Text(
                          '오늘의 수익',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ).animate().fadeIn(duration: 700.ms, delay: 100.ms),
                        const SizedBox(height: 8),
                        AnimatedBuilder(
                          animation: _balanceAnimation,
                          builder: (context, child) {
                            return Text(
                              '₩${totalEarnings.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            );
                          },
                        ).animate().fadeIn(duration: 800.ms, delay: 200.ms),
                        const SizedBox(height: 20),

                        // 진행률
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '일일 목표',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '₩50,000',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: LinearProgressIndicator(
                                value: totalEarnings / 50000,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF3182F7),
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(duration: 900.ms, delay: 300.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 메인 콘텐츠
          SliverToBoxAdapter(
            child: Column(
              children: [
                // 10가지 수익 방법 그리드
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💰 지금 바로 시작하기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 수익 카테고리 그리드
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.1,
                        children: [
                          _buildEarningCard(
                            icon: '📊',
                            title: '설문조사',
                            subtitle: '5분 투자',
                            earning: '₩1,000~5,000',
                            color: const Color(0xFF3182F7),
                            badge: '12개 대기',
                            onTap: () => _showEarningDetail(context, 'survey'),
                          ).animate().scale(delay: 100.ms),

                          _buildEarningCard(
                            icon: '🎬',
                            title: '광고 시청',
                            subtitle: '30초 시청',
                            earning: '₩100~500',
                            color: const Color(0xFFFF6B6B),
                            badge: '무제한',
                            onTap: () => _showEarningDetail(context, 'ad'),
                          ).animate().scale(delay: 150.ms),

                          _buildEarningCard(
                            icon: '✍️',
                            title: '콘텐츠 제작',
                            subtitle: '블로그/SNS',
                            earning: '₩5,000~30,000',
                            color: const Color(0xFF00BF6E),
                            badge: 'HOT',
                            onTap: () => _showEarningDetail(context, 'content'),
                          ).animate().scale(delay: 200.ms),

                          _buildEarningCard(
                            icon: '💼',
                            title: '마이크로 작업',
                            subtitle: '데이터 입력',
                            earning: '₩8,000/시간',
                            color: const Color(0xFFFFC107),
                            badge: '5개',
                            onTap: () => _showEarningDetail(context, 'micro'),
                          ).animate().scale(delay: 250.ms),

                          _buildEarningCard(
                            icon: '📈',
                            title: '자동 투자',
                            subtitle: '소액 투자',
                            earning: '월 3~5%',
                            color: const Color(0xFF9C27B0),
                            badge: 'AI 추천',
                            onTap: () => _showEarningDetail(context, 'invest'),
                          ).animate().scale(delay: 300.ms),

                          _buildEarningCard(
                            icon: '🎮',
                            title: '게임 리워드',
                            subtitle: 'P2E 게임',
                            earning: '₩500~10,000',
                            color: const Color(0xFF00ACC1),
                            badge: 'NFT',
                            onTap: () => _showEarningDetail(context, 'game'),
                          ).animate().scale(delay: 350.ms),

                          _buildEarningCard(
                            icon: '🛍️',
                            title: '쇼핑 캐시백',
                            subtitle: '구매시 적립',
                            earning: '1~10%',
                            color: const Color(0xFFE91E63),
                            badge: '쿠팡/네이버',
                            onTap: () => _showEarningDetail(context, 'cashback'),
                          ).animate().scale(delay: 400.ms),

                          _buildEarningCard(
                            icon: '📊',
                            title: '데이터 판매',
                            subtitle: '익명 데이터',
                            earning: '월 ₩30,000',
                            color: const Color(0xFF607D8B),
                            badge: '자동',
                            onTap: () => _showEarningDetail(context, 'data'),
                          ).animate().scale(delay: 450.ms),

                          _buildEarningCard(
                            icon: '🔄',
                            title: 'P2P 거래',
                            subtitle: '중고거래',
                            earning: '무제한',
                            color: const Color(0xFFFF9800),
                            badge: '당근',
                            onTap: () => _showEarningDetail(context, 'p2p'),
                          ).animate().scale(delay: 500.ms),

                          _buildEarningCard(
                            icon: '💻',
                            title: '프리랜서',
                            subtitle: '재능 판매',
                            earning: '₩50,000+',
                            color: const Color(0xFF4CAF50),
                            badge: '크몽',
                            onTap: () => _showEarningDetail(context, 'freelance'),
                          ).animate().scale(delay: 550.ms),
                        ],
                      ),
                    ],
                  ),
                ),

                // 실시간 수익 현황
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '🔥 실시간 수익 현황',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B6B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.trending_up,
                                  size: 12,
                                  color: const Color(0xFFFF6B6B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'LIVE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: const Color(0xFFFF6B6B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ).animate(
                            onPlay: (controller) => controller.repeat(),
                          ).scale(
                            duration: 1.seconds,
                            curve: Curves.easeInOut,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 실시간 수익 스트림
                      ..._buildLiveEarningItems(),
                    ],
                  ),
                ).animate().slideY(begin: 0.1, delay: 600.ms),

                const SizedBox(height: 20),

                // 오늘의 미션
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF667EEA),
                        Color(0xFF764BA2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '🎯 일일 미션',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '$completedTasks/$totalTasks 완료',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: completedTasks / totalTasks,
                          minHeight: 6,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '모든 미션 완료시 ₩5,000 보너스! 🎁',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(begin: 0.1, delay: 700.ms),

                const SizedBox(height: 20),

                // 출금 버튼
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF3182F7),
                          Color(0xFF1E5FCE),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3182F7).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '출금하기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ).animate().scale(delay: 800.ms),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // 토스 스타일 하단 네비게이션
      bottomNavigationBar: Container(
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, '홈', true),
                _buildNavItem(Icons.explore_rounded, '탐색', false),
                _buildNavItem(Icons.account_balance_wallet_rounded, '지갑', false),
                _buildNavItem(Icons.leaderboard_rounded, '통계', false),
                _buildNavItem(Icons.person_rounded, '내정보', false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarningCard({
    required String icon,
    required String title,
    required String subtitle,
    required String earning,
    required Color color,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      icon,
                      style: const TextStyle(fontSize: 28),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00BF6E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    earning,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF00BF6E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildLiveEarningItems() {
    final items = [
      {'name': '김*수님', 'type': '설문조사', 'amount': '₩3,000', 'time': '방금'},
      {'name': '이*희님', 'type': '광고시청', 'amount': '₩200', 'time': '1분전'},
      {'name': '박*민님', 'type': '캐시백', 'amount': '₩1,580', 'time': '2분전'},
      {'name': '최*영님', 'type': '게임리워드', 'amount': '₩5,000', 'time': '3분전'},
    ];

    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  item['name']![0],
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['name']}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${item['type']} 완료',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item['amount']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00BF6E),
                  ),
                ),
                Text(
                  '${item['time']}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ).animate().fadeIn().slideX(begin: 0.1);
    }).toList();
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF3182F7) : Colors.grey.shade400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? const Color(0xFF3182F7) : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEarningDetail(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _getDetailTitle(type),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: _buildDetailContent(type),
            ),
          ],
        ),
      ),
    );
  }

  String _getDetailTitle(String type) {
    switch (type) {
      case 'survey': return '📊 설문조사로 돈 벌기';
      case 'ad': return '🎬 광고 시청으로 돈 벌기';
      case 'content': return '✍️ 콘텐츠로 돈 벌기';
      case 'micro': return '💼 마이크로 작업';
      case 'invest': return '📈 자동 투자 수익';
      case 'game': return '🎮 게임하며 돈 벌기';
      case 'cashback': return '🛍️ 쇼핑 캐시백';
      case 'data': return '📊 데이터 판매';
      case 'p2p': return '🔄 P2P 거래';
      case 'freelance': return '💻 프리랜서 플랫폼';
      default: return '';
    }
  }

  Widget _buildDetailContent(String type) {
    // 각 카테고리별 상세 내용
    return Center(
      child: Text('$type 상세 화면'),
    );
  }
}
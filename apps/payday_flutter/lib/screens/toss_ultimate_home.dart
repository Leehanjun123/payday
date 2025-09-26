import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import 'side_income/youtube_detail_screen.dart';
import 'side_income/freelance_detail_screen.dart';

class TossUltimateHome extends StatefulWidget {
  const TossUltimateHome({Key? key}) : super(key: key);

  @override
  State<TossUltimateHome> createState() => _TossUltimateHomeState();
}

class _TossUltimateHomeState extends State<TossUltimateHome>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late ScrollController _scrollController;

  double _scrollOffset = 0;
  bool _isBalanceHidden = false;
  int _selectedTabIndex = 0;

  // 사용자 데이터
  double _totalBalance = 13718300;
  double _monthlyIncome = 850000;
  double _sideIncome = 487300;

  // 부수익 데이터
  final List<SideIncomeItem> _sideIncomeItems = [
    SideIncomeItem(
      icon: '🎬',
      title: 'YouTube 광고 수익',
      description: '이번 달 조회수 12.5만회',
      amount: 85000,
      change: 12.5,
      color: Color(0xFFFF0000),
    ),
    SideIncomeItem(
      icon: '📝',
      title: '블로그 애드센스',
      description: '일평균 방문자 3,200명',
      amount: 127000,
      change: 8.3,
      color: Color(0xFF4285F4),
    ),
    SideIncomeItem(
      icon: '🛍️',
      title: '쿠팡 파트너스',
      description: '전환율 4.2%',
      amount: 235000,
      change: 15.7,
      color: Color(0xFFFF9500),
    ),
    SideIncomeItem(
      icon: '💻',
      title: '프리랜서 프로젝트',
      description: '웹사이트 개발 2건',
      amount: 2850000,
      change: 45.0,
      color: Color(0xFF00C896),
    ),
    SideIncomeItem(
      icon: '📈',
      title: '주식 배당금',
      description: '삼성전자 외 5종목',
      amount: 87300,
      change: 3.2,
      color: Color(0xFF5856D6),
    ),
    SideIncomeItem(
      icon: '🏠',
      title: '부동산 월세',
      description: '원룸 임대 수익',
      amount: 650000,
      change: 0.0,
      color: Color(0xFF007AFF),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    )..forward();

    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(),
              _buildMainBalance(),
              _buildQuickActions(),
              _buildIncomeOverview(),
              _buildSideIncomeSection(),
              _buildEarningGuides(),
              _buildFinancialTips(),
              SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final opacity = math.max(0.0, math.min(1.0, 1 - (_scrollOffset / 100)));

    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: _scrollOffset > 10 ? 1 : 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(left: 20, bottom: 16),
        title: Opacity(
          opacity: opacity,
          child: Row(
            children: [
              Text(
                '한준님',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFF00C896),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'VIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.qr_code_scanner, color: Colors.black),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.notifications_none, color: Colors.black),
          onPressed: () {},
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMainBalance() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 자산',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isBalanceHidden = !_isBalanceHidden;
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Icon(
                    _isBalanceHidden ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: Text(
                _isBalanceHidden
                    ? '••••••••'
                    : '₩${_totalBalance.toStringAsFixed(0).replaceAllMapped(
                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                        (Match m) => '${m[1]},')}',
                key: ValueKey(_isBalanceHidden),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFF00C896).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.trending_up,
                    color: Color(0xFF00C896),
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '지난달 대비 +18.5%',
                    style: TextStyle(
                      color: Color(0xFF00C896),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.send, 'label': '송금', 'color': Color(0xFF3182F7)},
      {'icon': Icons.payment, 'label': '결제', 'color': Color(0xFF00C896)},
      {'icon': Icons.add_card, 'label': '충전', 'color': Color(0xFFFF6B6B)},
      {'icon': Icons.account_balance, 'label': '이체', 'color': Color(0xFFFFD93D)},
      {'icon': Icons.trending_up, 'label': '투자', 'color': Color(0xFF6C5CE7)},
      {'icon': Icons.receipt_long, 'label': '내역', 'color': Color(0xFF95A5A6)},
    ];

    return SliverToBoxAdapter(
      child: Container(
        height: 100,
        margin: EdgeInsets.symmetric(vertical: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
              },
              child: Container(
                width: 70,
                margin: EdgeInsets.only(right: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        action['icon'] as IconData,
                        color: action['color'] as Color,
                        size: 24,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      action['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIncomeOverview() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '이번 달 수익',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '더보기',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3182F7),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildIncomeCard(
                    '월급',
                    _monthlyIncome,
                    Icons.account_balance_wallet,
                    Color(0xFF3182F7),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildIncomeCard(
                    '부수익',
                    _sideIncome,
                    Icons.trending_up,
                    Color(0xFF00C896),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4),
          Text(
            '₩${amount.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]},')}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideIncomeSection() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '부수익 관리',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF6B6B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'HOT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Icon(Icons.add_circle_outline, color: Color(0xFF3182F7)),
              ],
            ),
            SizedBox(height: 16),
            ..._sideIncomeItems.map((item) => _buildSideIncomeItem(item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSideIncomeItem(SideIncomeItem item) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // Navigate to detail screens based on title
        if (item.title.contains('YouTube')) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const YouTubeDetailScreen()),
          );
        } else if (item.title.contains('프리랜서')) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FreelanceDetailScreen()),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(item.icon, style: TextStyle(fontSize: 24)),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₩${item.amount.toStringAsFixed(0).replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (Match m) => '${m[1]},')}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      item.change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      color: item.change > 0 ? Color(0xFF00C896) : Color(0xFFFF6B6B),
                      size: 12,
                    ),
                    Text(
                      '${item.change.abs()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: item.change > 0 ? Color(0xFF00C896) : Color(0xFFFF6B6B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningGuides() {
    final guides = [
      {
        'icon': '📚',
        'title': '초보자 가이드',
        'subtitle': '부수익 시작하기',
        'color': Color(0xFF3182F7),
      },
      {
        'icon': '🚀',
        'title': '수익 극대화',
        'subtitle': '월 100만원 만들기',
        'color': Color(0xFFFF6B6B),
      },
      {
        'icon': '💡',
        'title': '세금 & 신고',
        'subtitle': '합법적으로 절세하기',
        'color': Color(0xFFFFD93D),
      },
      {
        'icon': '🎯',
        'title': 'AI 추천',
        'subtitle': '맞춤형 부수익 추천',
        'color': Color(0xFF6C5CE7),
      },
    ];

    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '수익 창출 가이드',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: guides.length,
                itemBuilder: (context, index) {
                  final guide = guides[index];
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                    },
                    child: Container(
                      width: 140,
                      margin: EdgeInsets.only(right: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            (guide['color'] as Color).withOpacity(0.8),
                            (guide['color'] as Color),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (guide['color'] as Color).withOpacity(0.3),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            guide['icon'] as String,
                            style: TextStyle(fontSize: 32),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                guide['title'] as String,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                guide['subtitle'] as String,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialTips() {
    return SliverToBoxAdapter(
      child: Container(
        margin: EdgeInsets.all(20),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3182F7).withOpacity(0.1),
              Color(0xFF00C896).withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Color(0xFF3182F7).withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('💰', style: TextStyle(fontSize: 20)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '오늘의 재테크 TIP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'YouTube 수익을 2배로 늘리는 방법',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF3182F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '자세히 보기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    final tabs = [
      {'icon': Icons.home, 'label': '홈'},
      {'icon': Icons.attach_money, 'label': '부수익'},
      {'icon': Icons.trending_up, 'label': '투자'},
      {'icon': Icons.receipt, 'label': '소비'},
      {'icon': Icons.menu, 'label': '전체'},
    ];

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index];
                final isSelected = _selectedTabIndex == index;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                    HapticFeedback.lightImpact();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tab['icon'] as IconData,
                          color: isSelected ? Color(0xFF3182F7) : Colors.grey[400],
                          size: 24,
                        ),
                        SizedBox(height: 4),
                        Text(
                          tab['label'] as String,
                          style: TextStyle(
                            color: isSelected ? Color(0xFF3182F7) : Colors.grey[400],
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class SideIncomeItem {
  final String icon;
  final String title;
  final String description;
  final double amount;
  final double change;
  final Color color;

  SideIncomeItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.amount,
    required this.change,
    required this.color,
  });
}
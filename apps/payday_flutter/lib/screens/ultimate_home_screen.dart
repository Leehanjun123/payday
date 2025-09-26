import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';

class UltimateHomeScreen extends StatefulWidget {
  const UltimateHomeScreen({Key? key}) : super(key: key);

  @override
  State<UltimateHomeScreen> createState() => _UltimateHomeScreenState();
}

class _UltimateHomeScreenState extends State<UltimateHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late Animation<double> _cardAnimation;
  late Animation<double> _pulseAnimation;

  PageController _cardPageController = PageController(viewportFraction: 0.85);
  int _currentCardIndex = 0;
  Timer? _autoRotateTimer;
  double _balance = 8547800;
  bool _isBalanceVisible = true;
  int _selectedFilterIndex = 0;

  final List<CardInfo> _cards = [
    CardInfo(
      type: 'Premium Black',
      number: '•••• •••• •••• 4582',
      balance: 8547800,
      gradient: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFFf093fb)],
    ),
    CardInfo(
      type: 'Business Pro',
      number: '•••• •••• •••• 7391',
      balance: 3250000,
      gradient: [Color(0xFF1e3c72), Color(0xFF2a5298), Color(0xFF7e8ce0)],
    ),
    CardInfo(
      type: 'Smart Savings',
      number: '•••• •••• •••• 2468',
      balance: 1920500,
      gradient: [Color(0xFF11998e), Color(0xFF38ef7d), Color(0xFF00b894)],
    ),
  ];

  final List<Transaction> _transactions = [
    Transaction(
      icon: '🚀',
      name: '프로젝트 대금',
      time: '방금 전',
      category: '프리랜서',
      amount: 2850000,
      isIncome: true,
    ),
    Transaction(
      icon: '🛍️',
      name: '애플 스토어',
      time: '2시간 전',
      category: '쇼핑',
      amount: 189000,
      isIncome: false,
    ),
    Transaction(
      icon: '☕',
      name: '블루보틀',
      time: '오늘 오전',
      category: '카페',
      amount: 7500,
      isIncome: false,
    ),
    Transaction(
      icon: '💎',
      name: '투자 수익',
      time: '어제',
      category: '투자',
      amount: 487300,
      isIncome: true,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _cardAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _cardAnimationController.forward();
    _startAutoRotate();
  }

  void _startAutoRotate() {
    _autoRotateTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_cardPageController.hasClients) {
        int nextPage = (_currentCardIndex + 1) % _cards.length;
        _cardPageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _cardPageController.dispose();
    _autoRotateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(),

          // Floating particles
          _buildParticles(),

          // Main content
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: _buildStatusBar(),
                  ),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 240,
                    child: _build3DCards(),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        _buildQuickActions(),
                        SizedBox(height: 25),
                        _buildStats(),
                        SizedBox(height: 25),
                        _buildTransactions(),
                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // AI Assistant button
          _buildAIAssistant(),

          // Bottom navigation
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                math.sin(_particleController.value * 2 * math.pi) * 0.5,
                math.cos(_particleController.value * 2 * math.pi) * 0.5,
              ),
              radius: 1.5,
              colors: [
                Color(0xFF6c5ce7).withOpacity(0.3),
                Color(0xFF00b894).withOpacity(0.2),
                Color(0xFFfd79a8).withOpacity(0.2),
                Color(0xFFfdcb6e).withOpacity(0.1),
                Colors.black,
              ],
              stops: [0.0, 0.3, 0.5, 0.7, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticles() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return CustomPaint(
            size: Size.infinite,
            painter: ParticlePainter(_particleController.value),
          );
        },
      ),
    );
  }

  Widget _buildStatusBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '9:41',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        Row(
          children: [
            Icon(Icons.signal_cellular_alt, color: Colors.white, size: 16),
            SizedBox(width: 5),
            Icon(Icons.wifi, color: Colors.white, size: 16),
            SizedBox(width: 5),
            Icon(Icons.battery_full, color: Colors.white, size: 16),
          ],
        ),
      ],
    );
  }

  Widget _build3DCards() {
    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return PageView.builder(
          controller: _cardPageController,
          onPageChanged: (index) {
            setState(() {
              _currentCardIndex = index;
              _balance = _cards[index].balance;
            });
            HapticFeedback.lightImpact();
          },
          itemCount: _cards.length,
          itemBuilder: (context, index) {
            return AnimatedBuilder(
              animation: _cardPageController,
              builder: (context, child) {
                double value = 0.0;
                if (_cardPageController.position.haveDimensions) {
                  value = index - _cardPageController.page!;
                } else {
                  value = index - _currentCardIndex.toDouble();
                }

                double scale = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                double opacity = (1 - (value.abs() * 0.5)).clamp(0.0, 1.0);
                double rotationY = value * 0.3;

                return Center(
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(rotationY)
                      ..scale(scale),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: opacity * _cardAnimation.value,
                      child: _buildCard(_cards[index]),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCard(CardInfo card) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: card.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: card.gradient.first.withOpacity(0.5),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Holographic shimmer
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(
                          -1 + 2 * _particleController.value,
                          -1 + 2 * _particleController.value,
                        ),
                        end: Alignment(
                          1 + 2 * _particleController.value,
                          1 + 2 * _particleController.value,
                        ),
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Card content
          Padding(
            padding: EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      card.type,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFffd700), Color(0xFFffed4e)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Text(
                  card.number,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: 3,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '잔액',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          _isBalanceVisible
                              ? '₩${card.balance.toStringAsFixed(0).replaceAllMapped(
                                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                  (Match m) => '${m[1]},')}'
                              : '₩ ••••••',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'PAY',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        letterSpacing: 3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': '💸', 'label': '송금'},
      {'icon': '📊', 'label': '투자'},
      {'icon': '💳', 'label': '카드관리'},
      {'icon': '🎯', 'label': '목표'},
      {'icon': '🏦', 'label': '대출'},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
            },
            child: Container(
              width: 80,
              margin: EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.white.withOpacity(0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    actions[index]['icon']!,
                    style: TextStyle(fontSize: 28),
                  ),
                  SizedBox(height: 8),
                  Text(
                    actions[index]['label']!,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('📈', '+24.5%', '수익률'),
        ),
        SizedBox(width: 15),
        Expanded(
          child: _buildStatCard('💰', '₩1.2M', '이번달 저축'),
        ),
        SizedBox(width: 15),
        Expanded(
          child: _buildStatCard('🎯', '87%', '목표 달성'),
        ),
      ],
    );
  }

  Widget _buildStatCard(String icon, String value, String label) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: TextStyle(fontSize: 28)),
            SizedBox(height: 10),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ).createShader(bounds),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactions() {
    return Container(
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '실시간 거래',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  _buildFilterChip('전체', 0),
                  SizedBox(width: 8),
                  _buildFilterChip('수입', 1),
                  SizedBox(width: 8),
                  _buildFilterChip('지출', 2),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          ...(_selectedFilterIndex == 0
                  ? _transactions
                  : _selectedFilterIndex == 1
                      ? _transactions.where((t) => t.isIncome).toList()
                      : _transactions.where((t) => !t.isIncome).toList())
              .map((transaction) => _buildTransactionItem(transaction))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    bool isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilterIndex = index;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: Colors.white.withOpacity(0.2))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: EdgeInsets.all(15),
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF667eea).withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  transaction.icon,
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        transaction.time,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(width: 10),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          transaction.category,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: transaction.isIncome
                    ? [Color(0xFF00b894), Color(0xFF00cec9)]
                    : [Color(0xFFff7675), Color(0xFFfd79a8)],
              ).createShader(bounds),
              child: Text(
                '${transaction.isIncome ? '+' : '-'}₩${transaction.amount.toStringAsFixed(0).replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                    (Match m) => '${m[1]},')}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAssistant() {
    return Positioned(
      bottom: 100,
      right: 20,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _showBiometricAuth();
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF667eea).withOpacity(0.5),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Center(
                  child: Text('🤖', style: TextStyle(fontSize: 32)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: 15, bottom: 30),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem('🏠', '홈', true),
            _buildNavItem('💳', '카드', false),
            _buildNavItem('📊', '자산', false, hasNotification: true),
            _buildNavItem('🎯', '목표', false),
            _buildNavItem('👤', '프로필', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String icon, String label, bool isActive,
      {bool hasNotification = false}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: isActive
                ? BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF667eea).withOpacity(0.3),
                        Color(0xFF764ba2).withOpacity(0.3),
                      ],
                    ),
                    shape: BoxShape.circle,
                  )
                : null,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(icon, style: TextStyle(fontSize: 24)),
                SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (hasNotification)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFff7675), Color(0xFFfd79a8)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Center(
                  child: Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showBiometricAuth() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        return Center(
          child: TweenAnimationBuilder(
            duration: Duration(seconds: 2),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFF667eea).withOpacity(value),
                    width: 3,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100 + (50 * value),
                      height: 3,
                      color: Color(0xFF667eea),
                    ),
                    Text(
                      '👆',
                      style: TextStyle(fontSize: 80),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    Future.delayed(Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }
}

class CardInfo {
  final String type;
  final String number;
  final double balance;
  final List<Color> gradient;

  CardInfo({
    required this.type,
    required this.number,
    required this.balance,
    required this.gradient,
  });
}

class Transaction {
  final String icon;
  final String name;
  final String time;
  final String category;
  final double amount;
  final bool isIncome;

  Transaction({
    required this.icon,
    required this.name,
    required this.time,
    required this.category,
    required this.amount,
    required this.isIncome,
  });
}

class ParticlePainter extends CustomPainter {
  final double animationValue;

  ParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.3);

    for (int i = 0; i < 20; i++) {
      final x = (i * 73) % size.width;
      final y = (size.height * (1 - animationValue) + i * 47) % size.height;
      final radius = (i % 3) + 1.0;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../models/income_source.dart';
import '../services/income_data_service.dart';

class IncomeDetailScreen extends StatefulWidget {
  final IncomeSource incomeSource;

  const IncomeDetailScreen({
    Key? key,
    required this.incomeSource,
  }) : super(key: key);

  @override
  State<IncomeDetailScreen> createState() => _IncomeDetailScreenState();
}

class _IncomeDetailScreenState extends State<IncomeDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _contentController;
  late AnimationController _earningsController;
  late Animation<double> _headerScale;
  late Animation<double> _contentSlide;
  late Animation<double> _earningsCounter;

  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  // Mock data for demonstration
  final List<Map<String, dynamic>> _recentActivities = [
    {
      'date': DateTime.now().subtract(Duration(hours: 1)),
      'amount': 0.002,
      'status': 'completed',
      'description': '30초 광고 시청 완료',
    },
    {
      'date': DateTime.now().subtract(Duration(hours: 3)),
      'amount': 0.003,
      'status': 'completed',
      'description': '프리미엄 광고 시청',
    },
    {
      'date': DateTime.now().subtract(Duration(hours: 5)),
      'amount': 0.002,
      'status': 'completed',
      'description': '일반 광고 시청',
    },
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _scrollController.addListener(_onScroll);
  }

  void _setupAnimations() {
    _headerController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _earningsController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _headerScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutBack,
    ));

    _contentSlide = Tween<double>(
      begin: 50,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));

    _earningsCounter = Tween<double>(
      begin: 0,
      end: widget.incomeSource.currentEarnings,
    ).animate(CurvedAnimation(
      parent: _earningsController,
      curve: Curves.easeOutCubic,
    ));

    _headerController.forward();
    _contentController.forward();
    _earningsController.forward();
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    _earningsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headerOpacity = math.max(0.0, math.min(1.0, 1 - (_scrollOffset / 150)));
    final parallaxOffset = _scrollOffset * 0.5;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _getGradientColors(),
          ),
        ),
        child: Stack(
          children: [
            // Animated Background Pattern
            Positioned.fill(
              child: CustomPaint(
                painter: FlowPatternPainter(
                  scrollOffset: _scrollOffset,
                  color: Colors.white.withOpacity(0.03),
                ),
              ),
            ),

            // Main Content
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // App Bar
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.share, color: Colors.white),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _showShareDialog();
                      },
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Transform.translate(
                      offset: Offset(0, parallaxOffset),
                      child: AnimatedBuilder(
                        animation: _headerScale,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _headerScale.value,
                            child: Container(
                              padding: EdgeInsets.fromLTRB(20, 100, 20, 20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Icon
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      _getIconForType(widget.incomeSource.type),
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                  SizedBox(height: 20),

                                  // Title
                                  Text(
                                    widget.incomeSource.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 8),

                                  // Current Earnings
                                  AnimatedBuilder(
                                    animation: _earningsCounter,
                                    builder: (context, child) {
                                      return Text(
                                        '\$${_earningsCounter.value.toStringAsFixed(3)}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                  Text(
                                    '이번 달 수익',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _contentSlide,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _contentSlide.value),
                        child: Container(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quick Actions
                              _buildQuickActions(),
                              SizedBox(height: 24),

                              // Stats Cards
                              _buildStatsGrid(),
                              SizedBox(height: 24),

                              // Performance Chart
                              _buildPerformanceSection(),
                              SizedBox(height: 24),

                              // Recent Activities
                              _buildRecentActivities(),
                              SizedBox(height: 24),

                              // Tips Section
                              _buildTipsSection(),
                              SizedBox(height: 24),

                              // Settings
                              _buildSettingsSection(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
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
                '빠른 실행',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.incomeSource.isActive
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.incomeSource.isActive
                        ? Colors.green.withOpacity(0.5)
                        : Colors.orange.withOpacity(0.5),
                  ),
                ),
                child: Text(
                  widget.incomeSource.isActive ? '활성' : '비활성',
                  style: TextStyle(
                    color: widget.incomeSource.isActive
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.play_arrow,
                  label: '시작하기',
                  color: Colors.green,
                  onTap: () => _startEarning(),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.history,
                  label: '기록 보기',
                  color: Colors.blue,
                  onTap: () => _showHistory(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          title: '예상 월 수익',
          value: '\$${widget.incomeSource.estimatedEarning}',
          subtitle: '약 ${(widget.incomeSource.estimatedEarning * 1300).toStringAsFixed(0)}원',
          icon: Icons.trending_up,
          color: Colors.green,
        ),
        _buildStatCard(
          title: '일일 목표',
          value: '${(widget.incomeSource.estimatedEarning / 30).toStringAsFixed(3)}\$',
          subtitle: '30일 기준',
          icon: Icons.flag,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: '완료율',
          value: '${((widget.incomeSource.currentEarnings / widget.incomeSource.estimatedEarning) * 100).toStringAsFixed(0)}%',
          subtitle: '이번 달',
          icon: Icons.check_circle,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: '소요 시간',
          value: '${widget.incomeSource.timeRequired}분',
          subtitle: '일일 평균',
          icon: Icons.timer,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Icon(
                Icons.arrow_upward,
                color: Colors.green,
                size: 16,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                title,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '수익 성과',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 200,
            child: CustomPaint(
              painter: PerformanceChartPainter(),
              child: Container(),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildChartLegend('이번 주', Colors.blue),
              _buildChartLegend('지난 주', Colors.grey),
              _buildChartLegend('목표', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
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

  Widget _buildRecentActivities() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '최근 활동',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '모두 보기',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ..._recentActivities.map((activity) => _buildActivityItem(activity)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final isCompleted = activity['status'] == 'completed';
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.timer,
              color: isCompleted ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['description'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _formatDate(activity['date']),
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+\$${activity['amount']}',
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
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
          ..._getTipsForType().map((tip) => Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.arrow_right, color: Colors.blue, size: 20),
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
          )),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '설정',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildSettingItem(
            title: '알림 설정',
            subtitle: '새로운 기회 알림 받기',
            value: true,
            onChanged: (value) {},
          ),
          _buildSettingItem(
            title: '자동 실행',
            subtitle: '매일 자동으로 시작',
            value: false,
            onChanged: (value) {},
          ),
          _buildSettingItem(
            title: '목표 설정',
            subtitle: '\$${widget.incomeSource.estimatedEarning}/월',
            value: null,
            onChanged: null,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    bool? value,
    Function(bool)? onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (value != null && onChanged != null)
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.green,
            )
          else
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white24,
              size: 16,
            ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors() {
    switch (widget.incomeSource.type) {
      case IncomeType.rewardAd:
        return [Color(0xFF4158D0), Color(0xFFC850C0)];
      case IncomeType.survey:
        return [Color(0xFF0093E9), Color(0xFF80D0C7)];
      case IncomeType.youtube:
        return [Color(0xFFFF0000), Color(0xFFFF6B6B)];
      case IncomeType.stock:
        return [Color(0xFF00C896), Color(0xFF00B4D8)];
      default:
        return [Color(0xFF667eea), Color(0xFF764ba2)];
    }
  }

  IconData _getIconForType(IncomeType type) {
    switch (type) {
      case IncomeType.rewardAd:
        return Icons.play_circle_outline;
      case IncomeType.survey:
        return Icons.quiz;
      case IncomeType.youtube:
        return Icons.video_library;
      case IncomeType.stock:
        return Icons.trending_up;
      default:
        return Icons.attach_money;
    }
  }

  List<String> _getTipsForType() {
    switch (widget.incomeSource.type) {
      case IncomeType.rewardAd:
        return [
          '광고를 끝까지 시청해야 보상을 받을 수 있습니다',
          '하루 최대 시청 횟수를 확인하세요',
          '와이파이 환경에서 시청하면 데이터를 절약할 수 있습니다',
        ];
      case IncomeType.survey:
        return [
          '프로필을 정확히 작성하면 더 많은 설문을 받을 수 있습니다',
          '솔직하고 일관된 답변을 제공하세요',
          '설문 시작 전 예상 시간을 확인하세요',
        ];
      default:
        return [
          '꾸준히 활동하면 수익이 증가합니다',
          '목표를 설정하고 달성해보세요',
          '다양한 수익원을 병행하면 효과적입니다',
        ];
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
    }
  }

  void _startEarning() {
    HapticFeedback.heavyImpact();
    // Navigate to actual earning screen based on type
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.incomeSource.name} 시작!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showHistory() {
    // Show history modal
  }

  void _showShareDialog() {
    // Show share options
  }
}

// Custom Painters
class FlowPatternPainter extends CustomPainter {
  final double scrollOffset;
  final Color color;

  FlowPatternPainter({
    required this.scrollOffset,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 10; i++) {
      final y = (i * 100.0 - scrollOffset * 0.1) % size.height;
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 10) {
        path.lineTo(
          x,
          y + math.sin(x * 0.02 + scrollOffset * 0.01) * 20,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(FlowPatternPainter oldDelegate) {
    return scrollOffset != oldDelegate.scrollOffset;
  }
}

class PerformanceChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    for (int i = 0; i <= 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Draw chart lines
    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.6,
      size.width * 0.5, size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.3,
      size.width, size.height * 0.2,
    );

    canvas.drawPath(path, linePaint);

    // Draw points
    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.4),
      5,
      pointPaint,
    );
    canvas.drawCircle(
      Offset(size.width, size.height * 0.2),
      5,
      pointPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
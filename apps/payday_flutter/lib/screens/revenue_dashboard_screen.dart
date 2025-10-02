import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/revenue_service.dart';
import '../services/enhanced_cash_service.dart';
import '../services/data_service.dart';

class RevenueDashboardScreen extends StatefulWidget {
  const RevenueDashboardScreen({Key? key}) : super(key: key);

  @override
  State<RevenueDashboardScreen> createState() => _RevenueDashboardScreenState();
}

class _RevenueDashboardScreenState extends State<RevenueDashboardScreen>
    with SingleTickerProviderStateMixin {
  final RevenueService _revenueService = RevenueService();
  final EnhancedCashService _cashService = EnhancedCashService();
  final DataService _dataService = DataService();
  final NumberFormat _numberFormat = NumberFormat('#,###', 'ko_KR');

  late TabController _tabController;

  Map<String, double> _platformRevenue = {};
  Map<String, dynamic> _userStats = {};
  double _totalUserBalance = 0;
  int _activeUsers = 0;
  int _totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
    _listenToRevenueStream();
  }

  Future<void> _loadDashboardData() async {
    // 플랫폼 수익 로드
    _platformRevenue = _revenueService.getRevenueStats();

    // 사용자 통계 로드
    final users = await _dataService.getSetting('total_users') ?? 0;
    final activeToday = await _dataService.getSetting('active_users_today') ?? 0;
    final totalCashDistributed = await _dataService.getSetting('total_cash_distributed') ?? 0.0;

    setState(() {
      _totalUsers = users;
      _activeUsers = activeToday;
      _totalUserBalance = totalCashDistributed;
      _userStats = {
        'avg_revenue_per_user': _totalUsers > 0
            ? _platformRevenue['total']! / _totalUsers
            : 0,
        'daily_active_rate': _totalUsers > 0
            ? (_activeUsers / _totalUsers) * 100
            : 0,
      };
    });
  }

  void _listenToRevenueStream() {
    _revenueService.revenueStream.listen((revenue) {
      setState(() {
        _platformRevenue = revenue;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('수익 대시보드 💰'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(text: '실시간'),
            Tab(text: '통계'),
            Tab(text: '예측'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRealtimeTab(),
          _buildStatisticsTab(),
          _buildPredictionTab(),
        ],
      ),
    );
  }

  Widget _buildRealtimeTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 실시간 수익 카드
          _buildRevenueCard(
            title: '오늘 수익',
            amount: _platformRevenue['daily'] ?? 0,
            icon: Icons.today,
            color: Colors.green,
            subtitle: '플랫폼 순수익',
          ),

          SizedBox(height: 16),

          // 사용자/플랫폼 비교
          _buildComparisonCard(),

          SizedBox(height: 16),

          // 수익원별 현황
          _buildRevenueSourcesCard(),

          SizedBox(height: 16),

          // 실시간 지표
          _buildMetricsGrid(),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 기간별 수익
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '일일',
                  _platformRevenue['daily'] ?? 0,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '주간',
                  _platformRevenue['weekly'] ?? 0,
                  Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '월간',
                  _platformRevenue['monthly'] ?? 0,
                  Colors.purple,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '누적',
                  _platformRevenue['total'] ?? 0,
                  Colors.green,
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // ROI 분석
          _buildROICard(),
        ],
      ),
    );
  }

  Widget _buildPredictionTab() {
    final expectedMonthly = _revenueService.calculateExpectedRevenue(
      userCount: _totalUsers,
      avgDailyActiveRate: (_userStats['daily_active_rate'] ?? 0) / 100,
      avgRevenuePerUser: _userStats['avg_revenue_per_user'] ?? 0,
    );

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 예상 수익
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[400]!, Colors.indigo[600]!],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '이번 달 예상 수익',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${_numberFormat.format(expectedMonthly.round())}원',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '사용자 ${_totalUsers}명 기준',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // 성장 시나리오
          _buildGrowthScenarios(),

          SizedBox(height: 20),

          // 손익분기점
          _buildBreakEvenCard(),
        ],
      ),
    );
  }

  Widget _buildRevenueCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${_numberFormat.format(amount.round())}원',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard() {
    final userShare = _totalUserBalance;
    final platformShare = _platformRevenue['total'] ?? 0;
    final total = userShare + platformShare;

    return Container(
      padding: EdgeInsets.all(20),
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
          Text(
            '수익 배분 현황',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.people, color: Colors.blue, size: 32),
                    SizedBox(height: 8),
                    Text(
                      '사용자',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${_numberFormat.format(userShare.round())}원',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      '${total > 0 ? ((userShare / total) * 100).toStringAsFixed(1) : 0}%',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.grey[300],
              ),
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.business, color: Colors.green, size: 32),
                    SizedBox(height: 8),
                    Text(
                      '플랫폼',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${_numberFormat.format(platformShare.round())}원',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '${total > 0 ? ((platformShare / total) * 100).toStringAsFixed(1) : 0}%',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSourcesCard() {
    return Container(
      padding: EdgeInsets.all(20),
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
          Text(
            '수익원별 현황',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildRevenueSource('AdMob 광고', 68.4, Colors.blue),
          _buildRevenueSource('태스크 수수료', 25.2, Colors.orange),
          _buildRevenueSource('제휴 마케팅', 4.8, Colors.green),
          _buildRevenueSource('프리미엄', 1.6, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildRevenueSource(String name, double percentage, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            color: color,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          '활성 사용자',
          '$_activeUsers명',
          Icons.person_outline,
          Colors.blue,
        ),
        _buildMetricCard(
          '전체 사용자',
          '$_totalUsers명',
          Icons.group,
          Colors.green,
        ),
        _buildMetricCard(
          'ARPU',
          '${_numberFormat.format((_userStats['avg_revenue_per_user'] ?? 0).round())}원',
          Icons.attach_money,
          Colors.orange,
        ),
        _buildMetricCard(
          'DAU Rate',
          '${(_userStats['daily_active_rate'] ?? 0).toStringAsFixed(1)}%',
          Icons.trending_up,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String period, double amount, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            period,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${_numberFormat.format(amount.round())}원',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildROICard() {
    final roi = _revenueService.calculateROI(
      monthlyRevenue: _platformRevenue['monthly'] ?? 0,
      monthlyExpense: 300000, // 서버비 등
      userAcquisitionCost: 1000, // CPA
      newUsers: 100,
    );

    return Container(
      padding: EdgeInsets.all(20),
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
          Text(
            'ROI 분석',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildROIRow('수익', roi['revenue']!),
          _buildROIRow('비용', roi['expense']!),
          Divider(),
          _buildROIRow('순이익', roi['profit']!, isHighlight: true),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ROI'),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: roi['roi']! > 0 ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${roi['roi']!.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: roi['roi']! > 0 ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildROIRow(String label, double value, {bool isHighlight = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isHighlight ? Colors.black : Colors.grey[600],
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${_numberFormat.format(value.round())}원',
            style: TextStyle(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              color: isHighlight
                  ? (value > 0 ? Colors.green : Colors.red)
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthScenarios() {
    return Container(
      padding: EdgeInsets.all(20),
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
          Text(
            '성장 시나리오',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          _buildScenarioRow('1,000명', 215, Colors.blue),
          _buildScenarioRow('10,000명', 3145, Colors.orange),
          _buildScenarioRow('100,000명', 30000, Colors.green),
        ],
      ),
    );
  }

  Widget _buildScenarioRow(String users, int profit, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 80,
            child: Text(
              users,
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: profit / 30000,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          SizedBox(width: 12),
          Text(
            '${_numberFormat.format(profit)}만원',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakEvenCard() {
    final breakEvenUsers = 300;
    final currentUsers = _totalUsers;
    final progress = currentUsers / breakEvenUsers;

    return Container(
      padding: EdgeInsets.all(20),
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
          Text(
            '손익분기점',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '필요 사용자',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$breakEvenUsers명',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                progress >= 1.0 ? Icons.check_circle : Icons.arrow_forward,
                color: progress >= 1.0 ? Colors.green : Colors.grey,
                size: 24,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '현재 사용자',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '$currentUsers명',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: progress >= 1.0 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.green : Colors.orange,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            progress >= 1.0
                ? '손익분기점 달성! 🎉'
                : '${(progress * 100).toStringAsFixed(1)}% 달성',
            style: TextStyle(
              color: progress >= 1.0 ? Colors.green : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
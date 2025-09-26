import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/charts_service.dart';
import '../services/database_service.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({Key? key}) : super(key: key);

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen>
    with TickerProviderStateMixin {
  final ChartsService _chartsService = ChartsService();
  final DatabaseService _dbService = DatabaseService();

  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  int _selectedPeriod = 30; // 기본 30일
  bool _isLoading = true;

  // 차트 데이터
  LineChartData? _lineChartData;
  List<PieChartSectionData>? _pieChartData;
  BarChartData? _barChartData;
  Map<String, dynamic>? _weeklyComparison;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: _selectedPeriod));

      final lineData = await _chartsService.getIncomeLineChartData(
        startDate: startDate,
        endDate: now,
      );

      final pieData = await _chartsService.getIncomeTypePieChartData();
      final barData = await _chartsService.getMonthlyBarChartData();
      final weeklyData = await _chartsService.getWeeklyComparisonData();

      setState(() {
        _lineChartData = lineData;
        _pieChartData = pieData;
        _barChartData = barData;
        _weeklyComparison = weeklyData;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('차트 데이터 로드 실패: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 수익 분석'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '트렌드', icon: Icon(Icons.show_chart)),
            Tab(text: '유형별', icon: Icon(Icons.pie_chart)),
            Tab(text: '월별', icon: Icon(Icons.bar_chart)),
            Tab(text: '통계', icon: Icon(Icons.analytics)),
          ],
          indicatorColor: Colors.blue,
          indicatorWeight: 3,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTrendTab(isDark),
                  _buildPieTab(isDark),
                  _buildBarTab(isDark),
                  _buildStatsTab(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildTrendTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 20),
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '수익 트렌드',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_lineChartData != null)
                    Expanded(
                      child: LineChart(_lineChartData!),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildTrendInsights(isDark),
        ],
      ),
    );
  }

  Widget _buildPieTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              height: 350,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '수익 유형 분포',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_pieChartData != null)
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sections: _pieChartData!,
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              // 터치 이벤트 처리
                            },
                          ),
                        ),
                        swapAnimationDuration: const Duration(milliseconds: 500),
                        swapAnimationCurve: Curves.easeInOut,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildTypeLegend(isDark),
        ],
      ),
    );
  }

  Widget _buildBarTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              height: 350,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '월별 수익 비교',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_barChartData != null)
                    Expanded(
                      child: BarChart(
                        _barChartData!,
                        swapAnimationDuration: const Duration(milliseconds: 500),
                        swapAnimationCurve: Curves.easeInOut,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildMonthlyInsights(isDark),
        ],
      ),
    );
  }

  Widget _buildStatsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildWeeklyComparison(isDark),
          const SizedBox(height: 20),
          _buildDetailedStats(isDark),
          const SizedBox(height: 20),
          _buildPerformanceMetrics(isDark),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPeriodButton('7일', 7),
          _buildPeriodButton('30일', 30),
          _buildPeriodButton('90일', 90),
          _buildPeriodButton('1년', 365),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, int days) {
    final isSelected = _selectedPeriod == days;
    return TextButton(
      onPressed: () {
        setState(() {
          _selectedPeriod = days;
        });
        _loadChartData();
      },
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.transparent,
        foregroundColor: isSelected ? Colors.white : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );
  }

  Widget _buildTrendInsights(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                '트렌드 인사이트',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• 최근 ${_selectedPeriod}일 동안의 수익 변화를 보여줍니다',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Text(
            '• 상승 추세가 지속되고 있습니다',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeLegend(bool isDark) {
    final types = [
      {'label': '프리랜서', 'color': Colors.blue.shade400},
      {'label': '부업', 'color': Colors.purple.shade400},
      {'label': '투자', 'color': Colors.pink.shade400},
      {'label': '임대', 'color': Colors.orange.shade400},
      {'label': '판매', 'color': Colors.teal.shade400},
      {'label': '기타', 'color': Colors.indigo.shade400},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '범례',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: types.map((type) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: type['color'] as Color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    type['label'] as String,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyInsights(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.pink.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.purple.shade700),
              const SizedBox(width: 8),
              Text(
                '월별 성과',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• 최근 6개월간 월별 수익을 비교합니다',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Text(
            '• 가장 높은 수익을 기록한 달을 확인하세요',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyComparison(bool isDark) {
    if (_weeklyComparison == null) return const SizedBox();

    final thisWeek = _weeklyComparison!['thisWeek'] as double;
    final lastWeek = _weeklyComparison!['lastWeek'] as double;
    final change = _weeklyComparison!['change'] as double;
    final changePercentage = _weeklyComparison!['changePercentage'] as double;
    final isPositive = change >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [Colors.green.shade400, Colors.teal.shade400]
              : [Colors.red.shade400, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            '주간 비교',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWeekStat('이번 주', thisWeek),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildWeekStat('지난 주', lastWeek),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${changePercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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

  Widget _buildWeekStat(String label, double amount) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '₩${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStats(bool isDark) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _dbService.getAllIncomes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final incomes = snapshot.data!;
        final totalIncome = incomes.fold<double>(
          0,
          (sum, income) => sum + (income['amount'] as num).toDouble(),
        );
        final averageIncome = incomes.isEmpty ? 0 : totalIncome / incomes.length;

        // 최고/최저 수익 찾기
        double maxIncome = 0;
        double minIncome = double.infinity;
        for (var income in incomes) {
          final amount = (income['amount'] as num).toDouble();
          if (amount > maxIncome) maxIncome = amount;
          if (amount < minIncome) minIncome = amount;
        }
        if (incomes.isEmpty) minIncome = 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '상세 통계',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatRow('총 수익', '₩${totalIncome.toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.blue),
              const Divider(),
              _buildStatRow('평균 수익', '₩${averageIncome.toStringAsFixed(0)}', Icons.analytics, Colors.purple),
              const Divider(),
              _buildStatRow('최고 수익', '₩${maxIncome.toStringAsFixed(0)}', Icons.trending_up, Colors.green),
              const Divider(),
              _buildStatRow('최저 수익', '₩${minIncome.toStringAsFixed(0)}', Icons.trending_down, Colors.orange),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speed, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                '성과 지표',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricBar('목표 달성률', 0.75, Colors.green),
          const SizedBox(height: 12),
          _buildMetricBar('성장률', 0.82, Colors.blue),
          const SizedBox(height: 12),
          _buildMetricBar('일관성', 0.68, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildMetricBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text('${(value * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ],
    );
  }
}
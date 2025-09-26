import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/income_service.dart';
import '../models/income_source.dart';
import '../widgets/charts/income_line_chart.dart';
import '../widgets/charts/income_pie_chart.dart';
import '../models/income.dart';
import '../services/database_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final IncomeServiceInterface _incomeService = IncomeServiceProvider.instance;
  final DatabaseService _databaseService = DatabaseService();

  double _totalIncome = 0.0;
  Map<String, double> _incomeByTypes = {};
  List<Map<String, dynamic>> _recentIncomes = [];
  List<Income> _allIncomes = [];
  bool _isLoading = true;
  String _selectedPeriod = '이번 달';

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() => _isLoading = true);

    try {
      final totalIncome = await _incomeService.getTotalIncome();
      final incomeByTypes = await _incomeService.getIncomeByTypes();
      final recentIncomes = await _incomeService.getAllIncomes();

      // Income 모델로 변환
      List<Income> allIncomes = [];
      for (var incomeData in recentIncomes) {
        allIncomes.add(Income(
          id: incomeData['id'],
          type: incomeData['type'],
          name: incomeData['name'],
          amount: incomeData['amount'],
          date: DateTime.parse(incomeData['date']),
          description: incomeData['description'],
        ));
      }

      setState(() {
        _totalIncome = totalIncome;
        _incomeByTypes = incomeByTypes;
        _recentIncomes = recentIncomes;
        _allIncomes = allIncomes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getTypeDisplayName(String type) {
    try {
      final incomeType = IncomeType.values.firstWhere(
        (e) => e.toString() == type,
        orElse: () => IncomeType.freelance,
      );

      switch (incomeType) {
        case IncomeType.freelance: return '프리랜서';
        case IncomeType.stock: return '주식';
        case IncomeType.crypto: return '암호화폐';
        case IncomeType.youtube: return 'YouTube';
        case IncomeType.tiktok: return 'TikTok';
        case IncomeType.instagram: return 'Instagram';
        case IncomeType.blog: return '블로그';
        case IncomeType.walkingReward: return '걸음 리워드';
        case IncomeType.game: return '게임';
        case IncomeType.review: return '리뷰';
        case IncomeType.survey: return '설문조사';
        case IncomeType.quiz: return '퀴즈';
        case IncomeType.dailyMission: return '데일리 미션';
        case IncomeType.referral: return '추천인';
        case IncomeType.rewardAd: return '리워드 광고';
        default: return type;
      }
    } catch (e) {
      return type;
    }
  }

  Color _getTypeColor(String type) {
    try {
      final incomeType = IncomeType.values.firstWhere(
        (e) => e.toString() == type,
        orElse: () => IncomeType.freelance,
      );

      switch (incomeType) {
        case IncomeType.freelance: return Colors.indigo;
        case IncomeType.stock: return Colors.teal;
        case IncomeType.crypto: return Colors.orange;
        case IncomeType.youtube: return Colors.red;
        case IncomeType.tiktok: return Colors.black;
        case IncomeType.instagram: return Colors.purple;
        case IncomeType.blog: return Colors.green;
        case IncomeType.walkingReward: return Colors.lightGreen;
        case IncomeType.game: return Colors.purple;
        case IncomeType.review: return Colors.amber;
        case IncomeType.survey: return Colors.cyan;
        case IncomeType.quiz: return Colors.deepPurple;
        case IncomeType.dailyMission: return Colors.brown;
        case IncomeType.referral: return Colors.pink;
        case IncomeType.rewardAd: return Colors.deepOrange;
        default: return Colors.blue;
      }
    } catch (e) {
      return Colors.blue;
    }
  }

  String _formatAmount(double amount) {
    return '₩${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '통계',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey[600]),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCards(),
                    _buildIncomeChart(),
                    _buildInteractiveCharts(),
                    _buildTopCategories(),
                    _buildMonthlyTrend(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    final totalEntries = _recentIncomes.length;
    final avgIncome = totalEntries > 0 ? _totalIncome / totalEntries : 0.0;
    final topCategory = _incomeByTypes.isNotEmpty
        ? _incomeByTypes.entries.reduce((a, b) => a.value > b.value ? a : b)
        : null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '총 수익',
                  _formatAmount(_totalIncome),
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '총 기록',
                  '${totalEntries}건',
                  Icons.list_alt,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '평균 수익',
                  _formatAmount(avgIncome),
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  '최고 카테고리',
                  topCategory != null ? _getTypeDisplayName(topCategory.key) : '-',
                  Icons.star,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeChart() {
    if (_incomeByTypes.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            '수익 데이터가 없습니다',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    final sortedTypes = _incomeByTypes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '수익원별 분포',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Simple pie chart representation
              Container(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: SimplePieChartPainter(sortedTypes, _totalIncome),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: sortedTypes.take(5).map((entry) {
                    final percentage = (_totalIncome > 0)
                        ? (entry.value / _totalIncome * 100)
                        : 0.0;
                    final color = _getTypeColor(entry.key);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getTypeDisplayName(entry.key),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategories() {
    if (_incomeByTypes.isEmpty) return const SizedBox();

    final sortedTypes = _incomeByTypes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '수익 순위',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          ...sortedTypes.take(5).map((entry) {
            final index = sortedTypes.indexOf(entry);
            final color = _getTypeColor(entry.key);
            final percentage = (_totalIncome > 0)
                ? (entry.value / _totalIncome * 100)
                : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
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
                          _getTypeDisplayName(entry.key),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          '${percentage.toStringAsFixed(1)}% of total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatAmount(entry.value),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '월별 트렌드',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(6, (index) {
                final height = math.Random().nextDouble() * 80 + 20;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${DateTime.now().month - 5 + index}월',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveCharts() {
    if (_allIncomes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '시각화 차트',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _selectedPeriod,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              IncomeLineChart(incomes: _allIncomes),
              const SizedBox(height: 20),
              IncomePieChart(
                incomes: _allIncomes,
                title: '카테고리별 수익 분포',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SimplePieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> data;
  final double total;

  SimplePieChartPainter(this.data, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    double startAngle = -math.pi / 2;
    final colors = [
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.green,
      Colors.amber,
      Colors.cyan,
    ];

    for (int i = 0; i < data.length && i < 8; i++) {
      final sweepAngle = 2 * math.pi * (data[i].value / total);
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
import 'package:flutter/material.dart';
import '../services/ai_prediction_service.dart';
import '../services/data_service.dart';
import '../models/income.dart';
import 'dart:math' as math;

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({Key? key}) : super(key: key);

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen>
    with TickerProviderStateMixin {
  final DataService _dbService = DataService();
  PredictionResult? _predictionResult;
  List<Income> _historicalData = [];
  bool _isLoading = true;

  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDataAndPredict();
  }

  void _setupAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _loadDataAndPredict() async {
    try {
      await _dbService.database;
      final incomeData = await _dbService.getAllIncomes();
      
      // Convert database records to Income objects
      final incomes = incomeData.map((data) => Income(
        id: data['id'] as int?,
        type: data['type'] as String,
        name: data['name'] as String,
        amount: (data['amount'] as num).toDouble(),
        date: DateTime.parse(data['date'] as String),
        description: data['description'] as String?,
      )).toList();

      final prediction = AIPredictionService.predictFutureIncome(incomes);

      setState(() {
        _historicalData = incomes;
        _predictionResult = prediction;
        _isLoading = false;
      });

      _mainController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading predictions: $e');
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Colors.grey[900]!, Colors.black]
                : [Colors.blue[50]!, Colors.purple[50]!],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _predictionResult == null
                  ? _buildEmptyState()
                  : _buildContent(isDark),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'AI가 데이터를 분석중입니다...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insights,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            '예측을 위한 데이터가 부족합니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '더 많은 수익을 기록해주세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeInAnimation,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'AI 수익 예측',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    background: _buildHeader(isDark),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildPredictionCards(isDark),
                      const SizedBox(height: 24),
                      _buildTrendIndicator(isDark),
                      const SizedBox(height: 24),
                      _buildInsightsSection(isDark),
                      const SizedBox(height: 24),
                      _buildCategoryPredictions(isDark),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.blue[900]!, Colors.purple[900]!]
              : [Colors.blue[400]!, Colors.purple[400]!],
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Icon(
                Icons.auto_graph,
                size: 80,
                color: Colors.white.withOpacity(0.8),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPredictionCards(bool isDark) {
    final predictions = [
      {
        'period': '다음 달',
        'amount': _predictionResult!.nextMonthPrediction,
        'icon': Icons.calendar_today,
        'color': Colors.blue,
      },
      {
        'period': '3개월 후',
        'amount': _predictionResult!.threeMonthPrediction,
        'icon': Icons.date_range,
        'color': Colors.purple,
      },
      {
        'period': '6개월 후',
        'amount': _predictionResult!.sixMonthPrediction,
        'icon': Icons.event,
        'color': Colors.orange,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '수익 예측',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        ...predictions.map((pred) => _buildPredictionCard(
          pred['period'] as String,
          pred['amount'] as double,
          pred['icon'] as IconData,
          pred['color'] as Color,
          isDark,
        )),
      ],
    );
  }

  Widget _buildPredictionCard(
    String period,
    double amount,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatAmount(amount),
                  style: const TextStyle(
                    fontSize: 24,
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

  Widget _buildTrendIndicator(bool isDark) {
    final trend = _predictionResult!.trend;
    final confidence = _predictionResult!.confidence;

    IconData trendIcon;
    Color trendColor;
    String trendText;

    switch (trend) {
      case TrendType.growing:
        trendIcon = Icons.trending_up;
        trendColor = Colors.green;
        trendText = '상승 추세';
        break;
      case TrendType.declining:
        trendIcon = Icons.trending_down;
        trendColor = Colors.red;
        trendText = '하락 추세';
        break;
      case TrendType.stable:
        trendIcon = Icons.trending_flat;
        trendColor = Colors.orange;
        trendText = '안정적';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            trendColor.withOpacity(0.1),
            trendColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: trendColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(trendIcon, color: trendColor, size: 32),
              const SizedBox(width: 12),
              Text(
                trendText,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: trendColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.psychology,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '예측 신뢰도: ${confidence.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: confidence / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              confidence >= 80
                  ? Colors.green
                  : confidence >= 60
                      ? Colors.orange
                      : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(bool isDark) {
    final insights = _predictionResult!.insights;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI 인사이트',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        ...insights.map((insight) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildCategoryPredictions(bool isDark) {
    final categoryPredictions = _predictionResult!.categoryPredictions;
    if (categoryPredictions == null || categoryPredictions.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedCategories = categoryPredictions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '카테고리별 예상 수익',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: sortedCategories.take(5).map((entry) {
              final maxValue = sortedCategories.first.value;
              final percentage = (entry.value / maxValue) * 100;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        Text(
                          _formatAmount(entry.value),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getCategoryColor(entry.key),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.pink,
    ];
    final index = category.hashCode % colors.length;
    return colors[index];
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '₩${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '₩${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '₩${amount.toStringAsFixed(0)}';
  }
}